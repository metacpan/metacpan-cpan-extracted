package TAP::Formatter::GitHubActions::Utils;

use strict;
use warnings;
use v5.16;

our @EXPORT_OK = qw(log_annotation_line);

sub log_annotation_line {
  my (%args) = @_;

  my $body = $args{body};
  my $title = $args{title};

  # If title is given, write it, else just keep body
  my $line = $title ? (
    "::%s file=%s,line=%s,title=${title}::%s"
  ) : (
    "::%s file=%s,line=%s::%s"
  );

  $body =~ s/\n/%0A/mg;

  return sprintf(
    $line,
    $args{type}, $args{filename}, $args{line}, $body
  );
}

1;
__END__

=head1 NAME

TAP::Formatter::GitHubActions::Utils - Utils functions

=head1 FUNCTIONS

=head2 log_annotation_line(%args)

Generates an annotation line in GitHub Workflow command syntax

- For more details on the syntax, see: L<Workflow commands for GitHub Actions|https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions>

=over 2

=item line

The line referred

=item title (Optional)

Optional: Annotation title.

=item body

Annotation body.

=item type

Annotation type. Known types: C<debug>, C<notice>, C<error>.

=item filename

The filename referred. This with the C<line> will signal github where to draw
the annotation.

=back

=cut
