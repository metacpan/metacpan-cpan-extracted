use strict;
use warnings;
package Rubric::Entry::Formatter::KwikiFormatish;
{
  $Rubric::Entry::Formatter::KwikiFormatish::VERSION = '0.552';
}
# ABSTRACT: format entries with AlmostKwikiText


use Text::KwikiFormatish;


sub as_html {
  my ($class, $arg, $config) = @_;
  $config ||= {};
  return Text::KwikiFormatish::format($arg->{text}, %$config);
}

sub as_text {
  my ($class, $arg) = @_;

  return $arg->{text};
}

1;

__END__

=pod

=head1 NAME

Rubric::Entry::Formatter::KwikiFormatish - format entries with AlmostKwikiText

=head1 VERSION

version 0.552

=head1 DESCRIPTION

This formatter will use KwikiFormatish to format entries into HTML.

=head1 METHODS

=head2 as_html

=head2 as_text

=head1 METHODS

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
