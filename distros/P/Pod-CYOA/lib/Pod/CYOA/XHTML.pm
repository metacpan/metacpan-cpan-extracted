use strict;
use warnings;
package Pod::CYOA::XHTML 0.003;
use Pod::Simple::XHTML 3.13;
use base 'Pod::Simple::XHTML';
# ABSTRACT: private Pod::Simple::XHTML subclass for CYOA

#pod =head1 OVERVIEW
#pod
#pod Pod::CYOA::HTML is a private class whose interface should not yet be relied
#pod upon.
#pod
#pod It transforms Pod to HTML, with one important change: links with targets that
#pod begin with C<@> become links to relative html documents.  In other words,
#pod C<< LE<lt>the start page|@startE<gt> >> becomes a link to C<start.html> rather
#pod than the "start" section of the current page.
#pod
#pod =cut

sub resolve_pod_page_link {
  my ($self, $to, $section) = @_;

  return $self->SUPER::resolve_pod_page_link($to, $section) if $to !~ s/^\@//;

  return "$to.html";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::CYOA::XHTML - private Pod::Simple::XHTML subclass for CYOA

=head1 VERSION

version 0.003

=head1 OVERVIEW

Pod::CYOA::HTML is a private class whose interface should not yet be relied
upon.

It transforms Pod to HTML, with one important change: links with targets that
begin with C<@> become links to relative html documents.  In other words,
C<< LE<lt>the start page|@startE<gt> >> becomes a link to C<start.html> rather
than the "start" section of the current page.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
