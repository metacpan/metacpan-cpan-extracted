package TAP::Formatter::GitHubActions::ErrorGroup;

use strict;
use warnings;
use v5.16;
use base 'TAP::Object';
use TAP::Formatter::GitHubActions::Utils;
my @ATTR;

BEGIN {
  @ATTR = qw(line errors);
  __PACKAGE__->mk_methods(@ATTR);
}

sub _initialize {
  my ($self, %args) = @_;

  $self->{line} = $args{line};
  $self->{errors} = $args{errors} // [];

  return $self;
}

sub add {
  my ($self, @errors) = @_;
  push @{$self->{errors}}, $_ for @errors;
  return $self;
}

sub as_markdown_summary {
  my ($self) = @_;
  my $summary = "";

  foreach my $error (@{$self->errors}) {
    $summary .= sprintf(" - %s on line %d\n", $error->test_name, $error->line);

    if (my $context_message = $error->decorated_context_message('```', '```')) {
      $context_message =~ s/^/    /mg;
      $summary .= $context_message;
      $summary .= "\n";
    }
  }

  return $summary;
}

sub as_summary_hash {
  my ($self) = @_;

  my $error_count = scalar @{$self->errors};
  my $title = "$error_count failed test" . ($error_count > 1 ? 's' : '');
  my $body = join("\n\n", map { $_->as_plain_text } @{$self->errors});
  chomp($body);

  return {
    title => $title,
    body => $body
  };
}


sub as_gha_summary_for {
  my ($self, $test) = @_;
  my $reduction = $self->as_summary_hash();

  my $log_line = TAP::Formatter::GitHubActions::Utils::log_annotation_line(
    type => 'error',
    filename => $test,
    line => $self->line,
    title => $reduction->{title},
    body => $reduction->{body}
  );

  return "$log_line\n";
}

1;
__END__

=head1 NAME

TAP::Formatter::GitHubActions::ErrorGroup - An error group

It groups C<TAP::Formatter::GitHubActions::Error> per line.

=head1 CONSTRUCTOR

=head2 new($args)

Builds a new C<TAP::Formatter::GitHubActions::ErrorGroup> object. 

=over 2

=item line

The line where an error has ocurred

=item errors

Collection of C<TAP::Formatter::GitHubActions::Error>.

=back

=cut
