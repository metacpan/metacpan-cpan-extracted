use strict;
use warnings;
package Pod::CYOA::XHTML;
{
  $Pod::CYOA::XHTML::VERSION = '0.002';
}
use Pod::Simple::XHTML 3.13;
use base 'Pod::Simple::XHTML';
# ABSTRACT: private Pod::Simple::XHTML subclass for CYOA


sub resolve_pod_page_link {
  my ($self, $to, $section) = @_;

  return $self->SUPER::resolve_pod_page_link($to, $section) if $to !~ s/^\@//;

  return "$to.html";
}

1;

__END__

=pod

=head1 NAME

Pod::CYOA::XHTML - private Pod::Simple::XHTML subclass for CYOA

=head1 VERSION

version 0.002

=head1 OVERVIEW

Pod::CYOA::HTML is a private class whose interface should not yet be relied
upon.

It transforms Pod to HTML, with one important change: links with targets that
begin with C<@> become links to relative html documents.  In other words,
C<< LE<lt>the start page|@startE<gt> >> becomes a link to C<start.html> rather
than the "start" section of the current page.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
