package Mojolicious::Command::donuts;
use Mojo::Base 'Mojolicious::Command';

use Mojo::JSON qw(encode_json);
use Mojo::Util qw(dumper);
use Getopt::Long qw(GetOptionsFromArray);
use WWW::KrispyKreme::HotLight;

our $VERSION = 0.04;

has description => 'Find fresh donuts near you!';

has usage => <<EOF;
USAGE:

    mojo donuts [OPTIONS]

OPTIONS:

    --geo, -g       Specify geo to be used for search (recommended)
    --fresh, -f     Filter results by stores serving fresh donuts
    --raw, -r       Print raw data structure returned from search response

EOF

has ua => sub { Mojo::UserAgent->new() };

has [qw( geo fresh raw )];

sub _mk_request {
    my ($self, $url, $form) = @_;
    my $tx = $form ? $self->ua->get($url) : $self->ua->post($url => form => $form);

    unless ($tx->success) {
        my $err = $tx->error;
        die join(
            '',    #
            'Trouble finding IP address.',
            'If problem persists, you might have to provide geo.',
            "$url error code and response:",
            $err->{code}, $err->{response},
        );
    }
    return $tx->res;
}

sub _ip2geo {
    my ($self, $ip) = @_;

    # fetch latitude and longitude from geocodeip.com
    my $geo = $self->_mk_request('http://www.geocodeip.com/', {IP => $ip})
      ->dom->find('div#data_display > table.table > tr > td')
      ->grep(sub { $_->text =~ /\b(?:Latitude|Longitude)\b/; })
      ->map(sub  { $_->following->first->text })->to_array;

    die 'Failed to scape geo from geocodeip.com. You may need to provide geo instead.'
      unless $geo
      && $geo->[0]
      && $geo->[1];

    return $geo;
}

sub _geocode_ip {
    my $self = shift;

    return if $self->geo;

    my $ip = $self->_mk_request('http://icanhazip.com')->body;
    return $self->_ip2geo($ip);
}

sub run {
    my ($self, @args) = @_;

    GetOptionsFromArray(
        \@args,    #
        'geo|g=s' => sub { $self->geo([split ',', $_[1]]) },
        'fresh|f' => sub { $self->fresh(1) },
        'raw|r'   => sub { $self->raw(1) },
    );

    my $base_url     = 'http://krispykreme.com/Locate/Location-Search';
    my $hotlight_url = 'http://services.krispykreme.com/api/locationsearchresult/';

    # user may not provide geo
    $self->geo($self->_geocode_ip) unless $self->geo;

    my $donuts = WWW::KrispyKreme::HotLight->new(where => $self->geo)->locations;

    # pull out the Location key of each store returned
    my @locations =
      grep { $self->fresh ? $_->{Hotlight} : 1 } @$donuts;

    if ($self->raw) {
        say dumper \@locations;
        exit 1;
    }

    # print out some info for each store
    for my $loc (@locations) {
        my $addr = join ', ', grep { s/\s+$//; 1 }    #
          $loc->{Address1}, $loc->{City}, $loc->{Province};

        $addr .= ' [HOTLIGHT ON]' if $loc->{Hotlight};

        say $addr;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Command::donuts - Find fresh donuts with Mojolicious!

=head1 SYNOPSIS

    $ mojo donuts --geo 34.14,-118.40 --fresh
    $ mojo donuts --raw
    $ mojo donuts

=head1 DESCRIPTION

Mojolicious::Command::donuts currently only fetches results
from KrispyKreme. If geo is not specified, this module tries
to geocode your IP and use that for searching.

The fresh option filters results by stores which have their
"Hotlight" on. This means fresh donuts.

The raw option prints out the raw data structure returned from
the site (currently KripsyKreme). If --raw is not enabled,
The store's address is printed out along with any Hotlight
indicator.

=head1 TODO

This module was written with the intent of supporting
more than one donuts site - e.g. Yum Yum and Dunkin Donuts.
Unfortunately, those sites make it a bit more difficult
to scrape results. However, patches are welcome!

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Curtis Brandt

=head1 LICENSE

The (two-clause) FreeBSD License. See LICENSE for details.

=head1 SEE ALSO

L<WWW::KrispyKreme::HotLight>

=cut
