package Punk::Feed;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Punk::Feed', $VERSION);

1;

__END__

=head1 NAME

Punk::Feed - Atom and RSS feeds for Punk

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    use Punk::Plugin::Feed;          # for the `feed` keyword

    host 'https://example.com';

    plugin 'Feed' => { title => 'Example', author => 'A Name' };

    feed sub {
        map +{
            loc     => "/posts/$_->{id}",
            title   => $_->{title},
            updated => $_->{updated},
            summary => $_->{excerpt},
        }, MyApp->model('Post')->recent;
    };

Which serves C<< /feed.xml >> and C<< /feed.rss >>.

=head1 SEE ALSO

L<Punk::Plugin::Feed> for the plugin, its options and the C<feed> keyword.

L<Punk::Plugin::Sitemap> for the other file a site owes a crawler, which this
is modelled on.

L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
