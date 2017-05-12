use strict;
use warnings;

package Rubric::Entry::Formatter::Markdown;
{
  $Rubric::Entry::Formatter::Markdown::VERSION = '0.555';
}
# ABSTRACT: format entries with Markdown (duh!)


use Text::Markdown ();
use Text::MultiMarkdown ();


sub as_html {
  my ($class, $arg, $config) = @_;
  my %config = %$config;
  my $md = (delete $config{multimarkdown})
         ? 'Text::MultiMarkdown'
         : 'Text::Markdown';

  return $md->new(%$config)->markdown($arg->{text});
}

sub as_text {
  my ($class, $arg) = @_;

  return $arg->{text};
}

1;

__END__

=pod

=head1 NAME

Rubric::Entry::Formatter::Markdown - format entries with Markdown (duh!)

=head1 VERSION

version 0.555

=head1 DESCRIPTION

This formatter will use Markdown (specifically, Text::Markdown) to format
entries into HTML.

Configuration for the formatter is given to the Text::Markdown constructor,
with the exception of the C<multimarkdown> option.  If given and true, it will
cause the formatter to use L<Text::MultiMarkdown> instead of L<Text::Markdown>.

=head1 METHODS

=head2 as_html

=head2 as_text

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
