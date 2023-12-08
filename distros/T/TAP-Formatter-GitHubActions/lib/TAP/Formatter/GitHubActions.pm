package TAP::Formatter::GitHubActions;

use strict;
use warnings;
use v5.16;
use base 'TAP::Formatter::File';

our $VERSION = '0.3.4';

use TAP::Formatter::GitHubActions::Error;
use TAP::Formatter::GitHubActions::ErrorGroup;
use TAP::Formatter::GitHubActions::Utils;
use TAP::Formatter::GitHubActions::ErrorAggregate;

my $MONOPHASIC_REGEX = qr/^Failed\stest .+\nat/;
my $RUNNING_IN_GHA = $ENV{GITHUB_ACTIONS};
my $GHA_SKIP_SUMMARY = $ENV{GHA_SKIP_SUMMARY};

sub _stash_line_for_current_test {
  my ($self, $parser, $line) = @_;
  my $test_num = $parser->{tests_run};
  my $stash = ($parser->{_msgs_for_test}{$test_num} //= []);
  push @{$stash}, $line;
}

sub _normalize_stash {
  my $stash = shift;
  my @new_stash;

  # First phase: Join all output, and segment it by "Failed test".
  my @chunks = split(/(Failed test)/, join("\n", @{$stash}));

  # Second phase, heal the splits so we end up with every string in the stash
  # beginning with "Failed test".
  while (scalar @chunks) {
    my $chunk = shift @chunks;
    # skip empty lines (consequence of split)
    next unless $chunk;

    # if we hit the separator
    if ($chunk eq 'Failed test' && scalar @chunks) {
      # Grab a new chunk
      $chunk .= shift @chunks;
      # Cleanup the newlines for named tests.
      $chunk =~ s/\n/ / if $chunk =~ qr/$MONOPHASIC_REGEX/;
    }

    # kill off any rouge newlines
    chomp($chunk);
    my $error = TAP::Formatter::GitHubActions::Error->from_output($chunk);
    next unless $error;

    push @new_stash, $error;
  }

  # Return it
  return @new_stash;
}

sub open_test {
  my ($self, $test, $parser) = @_;
  my $session = $self->SUPER::open_test($test, $parser);

  # force verbosity to be able to read comments, yamls & unknowns.
  $self->verbosity(1);

  # We'll use the parser as a vessel, afaics there's one parser instance per
  # parallel job.

  # We'll keep track of all output of a test with this.
  $parser->{_msgs_for_test} = {};

  # In an ideal world, we'd just need to listen to `comment` and that should
  # suffice, but `throws_ok` & `lives_ok` report via `unknown`...
  # But this is real life...
  # so...
  my $handler = sub {
    my $result = shift->raw;
    # Skip Subtests
    return if $result =~ /Subtest/;
    # Ignore anything that's not a comment (plans & tests)
    return unless $result =~ /^\s*#/;
    # Skip trailing end of tests/subtests
    return if $result =~ m/Looks like you/;
    # Cleanup comment start
    $result =~ s/\s*# //;
    # Test::Exception doens't indent the messages 🤡, excluding those keywords
    # and anything that doesn't begin with a space.
    return unless $result =~ m/^( |died|found|expecting)/;
    # Skip lines only having whitespaces
    return if $result =~ m/^ +$/;
    # Cleanup indent (2 spaces)
    $result =~ s/^  //;
    $self->_stash_line_for_current_test($parser, $result);
  };

  $parser->callback(comment => $handler);
  $parser->callback(unknown => $handler);

  # Enable YAML Support
  $parser->version(13);
  $parser->callback(yaml => sub {
      my $yaml = shift->data;
      # skip notes.
      return if grep { $yaml->{emitter} eq $_ } qw(Test::More::note Test::More::diag);
      # skip empty messages (prolly never happens?)
      return unless $yaml->{message};
      $self->_stash_line_for_current_test($parser, $yaml->{message});
  });

  return $session;
}

sub header { }

sub _output_report_notice {
  my ($self, $test) = @_;
  my $workflow_url = '%WORKFLOW_URL%';

  my @workflow_vars = grep { $_ } @ENV{
    qw(
      GITHUB_SERVER_URL
      GITHUB_REPOSITORY
      GITHUB_RUN_ID
    )
  };

  if (!$GHA_SKIP_SUMMARY && !!@workflow_vars) {
    $workflow_url = sprintf("%s/%s/actions/runs/%s", @workflow_vars);
  }

  my $file_marker_line = TAP::Formatter::GitHubActions::Utils::log_annotation_line(
    type => 'notice',
    filename => $test,
    line => 1,
    title => 'More details',
    body => "See the full report in: $workflow_url"
  );

  $self->_output("$file_marker_line\n");
}

sub summary {
  my ($self, $aggregate, $interrupted) = @_;
  $self->SUPER::summary($aggregate, $interrupted);

  my $total = $aggregate->total;
  my $passed = $aggregate->passed;

  return if ($total == $passed && !$aggregate->has_problems);

  $self->_output("\n= GitHub Actions Report =\n");

  # First print a mark at the beginning of the files reporting errors with a
  # link to the workflow run for the full report.
  #
  # This is a workaround due to the fact that there's a hard limit on the
  # amount of annotations rendered by GitHub on Pull requests.
  #
  # As of writting is a max of 10 annotations per step, 50 per workflow.
  # To overcome this we'll write here to the Workflow Summary File.
  # and link back in an anotation.
  # see [0] & [1] & [2].
  foreach my $test ($aggregate->descriptions) {
    my ($parser) = $aggregate->parsers($test);
    next if $parser->passed == $parser->tests_run && !$parser->exit;

    $self->_output_report_notice($test);
  }

  # Now print all error annotations
  foreach my $test ($aggregate->descriptions) {
    my ($parser) = $aggregate->parsers($test);
    next if $parser->passed == $parser->tests_run && !$parser->exit;

    $self->_dump_test_parser($test, $parser);
  }
}

sub _dump_test_parser {
  my ($self, $test, $parser) = @_;

  my $error_aggregate = TAP::Formatter::GitHubActions::ErrorAggregate->new();

  # Transform messages into error objects and feed them into the error
  # aggregate.
  foreach my $test_num (sort keys %{$parser->{_msgs_for_test}}) {
    my $stash = $parser->{_msgs_for_test}->{$test_num};
    $error_aggregate->add(_normalize_stash($stash));
  }

  my @error_groups = $error_aggregate->as_sorted_array();
  # Print in GHA Annotation format
  $self->_output($_->as_gha_summary_for($test)) for (@error_groups);

  # Skip if not running in GitHub Actions
  return if !($RUNNING_IN_GHA && !$GHA_SKIP_SUMMARY);

  # Write full report on GHA Step Summary [2]
  open(my $summary_fd, '>>', $ENV{GITHUB_STEP_SUMMARY}) or die "Unable to open " . $ENV{GITHUB_STEP_SUMMARY} . ": $!" if $RUNNING_IN_GHA;
  print $summary_fd "## Failures in `$test`\n";
  print $summary_fd $_->as_markdown_summary() for (@error_groups);
  print $summary_fd "\n\n";
}

# [0]: https://github.com/orgs/community/discussions/26680#discussioncomment-3252835
# [1]: https://github.com/orgs/community/discussions/68471
# [2]: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#adding-a-job-summary

1;
__END__

=head1 NAME

TAP::Formatter::GitHubActions - TAP Formatter for GitHub Actions

=head1 SYNOPSIS

On the command line, with I<prove>:

  $ prove --merge --formatter TAP::Formatter::GitHubActions ...

You can also use a C<.proverc> file with

  # .proverc contents
  --lib
  --merge
  --formatter TAP::Formatter::GitHubActions

And then invoke I<prove> without flags:

  $ prove

=head2 IMPORTANT NOTE

This formatter B<needs> the C<--merge> flag, else it won't be able to process
the comments to produce GitHub-Actions-compatible output.

=head1 DESCRIPTION

C<TAP::Formatter::GitHubActions> provides GitHub-Actions-compatible output for
I<prove>.

It parses TAP output and tries it's best to guess where errors are located.
For more accurate results, use in cojunction with
L<Test2::Formatter::YAMLEnhancedTAP>.

L<Test2::Formatter::YAMLEnhancedTAP> enriches the TAP output generated by
L<Test2> and friends (L<Test::More>, L<Test::Most>) with an additional context
in YAML format (compliant with TAP version 13) that includes the precise
location of the failure.

=head1 LIMITATIONS

As of writting (3.12.2023), there is a max of 10 annotations per step, 50 per
workflow.

That means: If your test result has more than 10 failures reported, you'll only
see the first 10.

To overcome this, when running under GitHub Actions (detected via
`GITHUB_ACTIONS` env var), the formatter writes into the workflow summary and
then writes one notice on the very top of the failing file with a link to the
summary.

It's not perfect, but gets the work done.

See the following links for more info:

- L<GitHub Community Discussion#26680: Annotation limitation|https://github.com/orgs/community/discussions/26680#discussioncomment-3252835>

- L<GitHub Community Discussion#68471: Extremely low annotation limit|https://github.com/orgs/community/discussions/26680#discussioncomment-3252835>

=head1 SEE ALSO

=over 1

- L<TAP::Formatter::JUnit>: JUnit XML output for your Tests!

- L<Test2::Formatter::YAMLEnhancedTAP>: Enhanced TAP Output for your tests!

- L<GitHub Workflow Commands Documentation|https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message>: For more information about the output syntax.

=back

=head1 AUTHOR

Jose, D. Gomez R. E<lt>1josegomezr [AT] gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Jose D. Gomez R.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
