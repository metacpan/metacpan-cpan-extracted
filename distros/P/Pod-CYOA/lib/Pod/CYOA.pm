use strict;
use warnings;
package Pod::CYOA;
{
  $Pod::CYOA::VERSION = '0.002';
}
# ABSTRACT: Pod-based Choose Your Own Adventure website generator (?!)
1;

__END__

=pod

=head1 NAME

Pod::CYOA - Pod-based Choose Your Own Adventure website generator (?!)

=head1 VERSION

version 0.002

=head1 OVERVIEW

Pod::CYOA is a simple pair of libraries, L<Pod::CYOA::Transformer> and
L<Pod::CYOA::XHTML>, used to generate L<Choose Your Own
Adventure|http://en.wikipedia.org/wiki/Choose_Your_Own_Adventure> stories in
Pod.  It is not a robust, highly-extensible system, but it made available on
CPAN to make it easy to build the L<Dist::Zilla> tutorial, which is written in
Pod as a CYOA "story."

The L<Dist::Zilla tutorial|http://dzil.org/tutorial/start.html> itself includes
a L<complete sample program|http://dzil.org/tutorial/build-tutorial.html>
showing how Pod::CYOA is used to build the tutorial.  The L<dzil.org site
source code|http://github.com/rjbs/dzil.org> is also a useful place to look at
how to use Pod::CYOA.

=head1 STABILITY

Pod::CYOA makes no promises, other than that its latest version should work to
build the latest version of the Dist::Zilla tutorial.  It may grow more stable
over time if others are interested in using it.  Until that changes (and, thus,
this warning changes), you should be careful when upgrading Pod::CYOA, if you
have your own CYOA document sets.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
