#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Getopt::Long ();
use Net::Spotify;
use XML::TreePP ();

my (
    $lookup, $uri, $extras,
    $search, $query, $page,
    $humanize, $help,
);

Getopt::Long::GetOptions(
    'lookup|l' => \$lookup,
    'uri|u=s' => \$uri,
    'extras|x=s' => \$extras,

    'search|s=s' => \$search,
    'query|q=s' => \$query,
    'page|p=i' => \$page,

    'humanize|h' => \$humanize,

    'help|?' => \$help,
);

if ($help) {
    help();
}

my $spotify = Net::Spotify->new();

my $response;

if ($lookup && $uri) {
    my %request = (
        uri => $uri,
    );

    if ($extras) {
        $request{extras} = $extras;
    }

    $response = $spotify->lookup(%request);

    if ($humanize) {
        my $tpp = XML::TreePP->new();

        my $tree = $tpp->parse($response);

        if ($tree) {
            $uri =~ m{spotify:(artist|album|track):\w+};

            my $type = $1;

            if ($type eq 'artist') {
                $response = sprintf(
                    '%s -> Artist: %s',
                    $uri,
                    $tree->{artist}->{name},
                );
            }
            elsif ($type eq 'album') {
                $response = sprintf(
                    '%s -> Album: %s, Artist: %s, Year: %s',
                    $uri,
                    $tree->{album}->{name},
                    $tree->{album}->{artist}->{name},
                    $tree->{album}->{released},
                );
            }
            elsif ($type eq 'track') {
                $response = sprintf(
                    '%s -> Track: %s, Album: %s, Artist: %s',
                    $uri,
                    $tree->{track}->{name},
                    $tree->{track}->{album}->{name},
                    $tree->{track}->{artist}->{name},
                );
            }
        }
    }
}
elsif ($search && $query) {
    $page ||= 1;

    $response = $spotify->search(lc($search), q => $query, page => $page);
}
else {
    help();
}

print $response, "\n";

sub help {
    print `pod2text $0`;

    exit;
}

__END__

=pod

=head1 NAME

net-spotify-tester.pl - A simple tool for testing Net::Spotify

=head1 SYNOPSIS

  ./net-spotify-tester.pl [options]

  Options:

    -l or --lookup              For lookup requests
    -u or --uri=<uri>           Spotify URI to lookup
    -x or --extras=<extras>     Comma separated list of words for defining the detail level in the response

    -s or --search=<method>     For search requests, the value defines the type of search (artist, album, track)
    -q or --query=<query>       Search string
    -p or --page=<page>         Page of the result set to show

    -h or --humanize            Formats the response to make it easier to read

    -? or --help                Show this documentation

=head1 DESCRIPTION

Simple command line script for testing Net::Spotify.

=head1 SEE ALSO

L<Net:Spotify>

L<https://developer.spotify.com/technologies/web-api/>

=head1 AUTHOR

Edoardo Sabadelli, C<< <edoardo at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

This product uses a SPOTIFY API but is not endorsed, certified or otherwise 
approved in any way by Spotify.
Spotify is the registered trade mark of the Spotify Group.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Edoardo Sabadelli, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
