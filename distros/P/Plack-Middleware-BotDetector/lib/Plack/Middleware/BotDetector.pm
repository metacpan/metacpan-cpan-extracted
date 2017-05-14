package Plack::Middleware::BotDetector;
# ABSTRACT: Plack middleware to identify bots and spiders

# these are useful, but not useful enough for their speed/memory cost here
# use strict;
# use warnings;
# use Plack::Util::Accessor 'bot_regex';

use parent 'Plack::Middleware';

sub call
{
    # no need to copy these just to put names on them
    # my ($self, $env) = @_;

    if (my $user_agent = $_[1]->{HTTP_USER_AGENT})
    {
        my $bot_regex = $_[0]->{bot_regex};
        $_[1]->{'BotDetector.looks-like-bot'}++ if $user_agent =~ qr/$bot_regex/;
    }

    return $_[0]->app->( $_[1] );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::BotDetector - Plack middleware to identify bots and spiders

=head1 VERSION

version 1.20170315.1614

=head1 SYNOPSIS

    enable 'Plack::Middleware::BotDetector',
        bot_regex => qr/Googlebot|Baiduspider|Yahoo! Slurp/;

=head1 DESCRIPTION

Any popular web site will get a tremendous amount of traffic from bots,
spiders, and other automated processes. Sometimes you want to do (or not do)
things when such a request comes in--for example, you may not want to log bot
traffic on your site.

This middleware applies an arbitrary, user-supplied regex to incoming requests
and sets a key in the PSGI environment if the user agent of the request
matches. Any other portion of your app which understands PSGI can examine the
environment for this key to take appropriate actions.

=head1 SPONSORSHIP

This module was extracted from L<https://trendshare.org/> under the sponsorship
of L<http://bigbluemarblellc.com/>.

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
