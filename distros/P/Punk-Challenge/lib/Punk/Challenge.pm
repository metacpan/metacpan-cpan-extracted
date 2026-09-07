package Punk::Challenge;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Punk::Challenge', $VERSION);

1;

__END__

=head1 NAME

Punk::Challenge - a proof of work challenge and a clearance cookie for Punk

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::Challenge;

    proxy;                                       # if there is one in front

    plugin 'Challenge' => {
        secret => secret('challenge.key'),
    };

    # everyone proves themselves before the login form
    challenge for => '/login', always => 1;

    # the rest of the site: past sixty requests a minute, a puzzle, not a 429
    challenge for => '/', after => { limit => 60, window => 60 };

    # one scope, as a guard, after the auth guard so a stranger sees login
    under('/account' => auth_guard)->under('' => challenge_guard(bits => 18));

=head1 DESCRIPTION

A third answer for a caller an application does not like, between "allow"
and "refuse": prove you are a browser before anything is spent on you. The
browser solves a puzzle in JavaScript and is handed a signed clearance that
says it did. No third party, no image, nothing a human has to look at.

L<Punk::Plugin::Challenge> is the plugin and carries the documentation.

=head1 SEE ALSO

L<Punk::Plugin::Challenge> for the plugin, its options, the C<challenge>
keyword and the guard.

L<Punk::Challenge::Token> for the puzzle and the clearance outside a request.

L<Punk::RateLimit>, which this is the thing you put in front of.

L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
