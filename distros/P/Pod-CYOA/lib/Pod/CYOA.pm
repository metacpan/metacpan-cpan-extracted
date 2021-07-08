use strict;
use warnings;
package Pod::CYOA 0.003;
# ABSTRACT: Pod-based Choose Your Own Adventure website generator (?!)
1;

#pod =head1 OVERVIEW
#pod
#pod Pod::CYOA is a simple pair of libraries, L<Pod::CYOA::Transformer> and
#pod L<Pod::CYOA::XHTML>, used to generate L<Choose Your Own
#pod Adventure|http://en.wikipedia.org/wiki/Choose_Your_Own_Adventure> stories in
#pod Pod.  It is not a robust, highly-extensible system, but it made available on
#pod CPAN to make it easy to build the L<Dist::Zilla> tutorial, which is written in
#pod Pod as a CYOA "story."
#pod
#pod The L<Dist::Zilla tutorial|http://dzil.org/tutorial/start.html> itself includes
#pod a L<complete sample program|http://dzil.org/tutorial/build-tutorial.html>
#pod showing how Pod::CYOA is used to build the tutorial.  The L<dzil.org site
#pod source code|http://github.com/rjbs/dzil.org> is also a useful place to look at
#pod how to use Pod::CYOA.
#pod
#pod =head1 STABILITY
#pod
#pod Pod::CYOA makes no promises, other than that its latest version should work to
#pod build the latest version of the Dist::Zilla tutorial.  It may grow more stable
#pod over time if others are interested in using it.  Until that changes (and, thus,
#pod this warning changes), you should be careful when upgrading Pod::CYOA, if you
#pod have your own CYOA document sets.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::CYOA - Pod-based Choose Your Own Adventure website generator (?!)

=head1 VERSION

version 0.003

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
