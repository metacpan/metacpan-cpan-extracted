use strict;
use warnings;
package Rubric::Entry::Formatter::Nil;
# ABSTRACT: format entries by formatting nearly not at all
$Rubric::Entry::Formatter::Nil::VERSION = '0.156';
#pod =head1 DESCRIPTION
#pod
#pod This is the default formatter.  The only formatting it performs is done by
#pod Template::Filters' C<html_para> filter.  Paragraph breaks will be
#pod retained from plaintext into HTML, but nothing else will be done.
#pod
#pod =cut

use Template::Filters;

#pod =head1 METHODS
#pod
#pod =cut

my $filter = Template::Filters->new->fetch('html_para');

sub as_html {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $filter->($arg->{text});
}

sub as_text {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $arg->{text};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::Entry::Formatter::Nil - format entries by formatting nearly not at all

=head1 VERSION

version 0.156

=head1 DESCRIPTION

This is the default formatter.  The only formatting it performs is done by
Template::Filters' C<html_para> filter.  Paragraph breaks will be
retained from plaintext into HTML, but nothing else will be done.

=head1 METHODS

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
