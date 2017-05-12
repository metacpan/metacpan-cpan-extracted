package Mojolicious::Plugin::Leafletjs;

use Mojo::Base 'Mojolicious::Plugin';
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use File::ShareDir ':ALL';

our $VERSION = '0.004';

my %defaults = (
    name      => 'map',
    cssid     => 'map',
    longitude => undef,
    latitude  => undef,
    zoomLevel => 13,
    tileLayer =>
      'http://{s}.tile.cloudmade.com/BC9A493B41014CAABB98F0471D759707/997/256/{z}/{x}/{y}.png',
    maxZoom => 18,
    attribution =>
      'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, '
      . '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, '
      . 'Imagery &copy; <a href="http://cloudmade.com">CloudMade</a>',
    markers => [

        # Example
        # {   name      => 'Stubby',
        #     longitude => undef,
        #     latitude  => undef,
        #     popup     => 'A new message here.',
        # }
    ],
    circles => [

        # Example:
        # {   name        => 'circly',
        #     longitude   => undef,
        #     latitude    => undef,
        #     color       => 'red',
        #     fillColor   => '#f03',
        #     fillOpacity => 0.5,
        #     radius      => 500,
        # }

    ],
);




sub register {
    my ($plugin, $app) = @_;
    my (%conf) = (%defaults, %{$_[2] || {}});
    push @{$app->static->paths},
      catdir(dist_dir('Mojolicious-Plugin-Leafletjs'), 'public');
    push @{$app->renderer->classes}, __PACKAGE__;
    $app->helper(
        leaflet => sub {
            my $self = shift;
            %conf = (%conf, %{shift()});
            $self->render(
                template => 'leaflet_template',
                partial  => 1,
                attrs    => \%conf,
            );
        }
    );

    $app->helper(
        leaflet_include => sub {
            my $self = shift;
            $self->render(
                template => 'leaflet_include',
                partial  => 1,
            );
        }
    );
    $app->hook(
        after_dispatch => sub {
            my $c    = shift;
            my $dom  = $c->res->dom;
            my $head = $dom->at('head') or return;

            my $append = $c->leaflet_include;
            $head->append_content($append);
            $c->tx->res->body($dom->to_xml);
        }
    );
}

1;

__DATA__

@@ leaflet_include.html.ep
%= stylesheet '/leaflet.css'
%= javascript '/leaflet.js'

@@ leaflet_template.html.ep
%= javascript begin
  var <%= $attrs->{name} %> = L.map('<%= $attrs->{cssid} %>').setView([<%= $attrs->{latitude} %>, <%= $attrs->{longitude} %>], <%= $attrs->{zoomLevel} %>);
  L.tileLayer('<%= $attrs->{tileLayer} %>', {
      maxZoom: <%= $attrs->{maxZoom} %>,
      attribution: '<%== $attrs->{attribution} %>'
  }).addTo(<%= $attrs->{name} %>);

% if (scalar @{$attrs->{markers}} > 0) {
  % foreach my $marker (@{$attrs->{markers}}) {
    var <%= $marker->{name} %> = L.marker([<%= $marker->{latitude} %>, <%= $marker->{longitude} %>]).addTo(<%= $attrs->{name} %>);
    % if ($marker->{popup}) {
      <%= $marker->{name} %>.bindPopup("<%== $marker->{popup} %>");
    % }
  % }
% }

% if (scalar @{$attrs->{circles}} > 0) {
  % foreach my $circle (@{$attrs->{circles}}) {
    var <%= $circle->{name} %> = L.circle([<%= $circle->{latitude} %>, <%= $circle->{longitude} %>], <%= $circle->{radius} %>, {
      color: '<%= $circle->{color} %>',
      fillColor: '<%= $circle->{fillColor} %>',
      fillOpacity: <%= $circle->{fillOpacity} %>
    }).addTo(<%= $attrs->{name} %>);
  % }
% }
%= end

__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Leafletjs - A Mojolicious Plugin

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Leafletjs');

    # Mojolicious::Lite
    plugin 'Leafletjs';

    # In your template
    <%= leaflet {
      name      => 'map1',
      latitude => '35.9239',
      longitude  => '-78.4611',
      zoomLevel => 18,
      markers   => [
        {   name      => 'marker1',
            latitude => '35.9239',
            longitude  => '-78.4611',
            popup     => 'A new message tada!',
        },
        {   name      => 'marker2',
            latitude => '35.9235',
            longitude  => '-78.4610',
            popup     => 'A second popup here!',
        }
      ],
    }
    %>

=head1 DESCRIPTION

Mojolicious::Plugin::Leafletjs is helpers for integrating simple maps via leafletjs

=head1 HELPERS

=head2 B<leaflet>

Accepts the following options:

=over

=item name

Name of map variable

=item longitude

Longitude

=item latitude

Latidude

=item cssid

CSS id of map

=item zoomLevel

Map zoomlevel

=item tileLayer

URL of map tile layer, defaults to a cloudmade.com tile

=item maxZoom

Max zoom into the map

=item attribution

Show some love for the leaflet team, openmap, and cloudmade map tiles

=item markers

Array of hashes containing the following key/value:

=over

=item name

Marker name

=item longitude

Longitude

=item latitude

Latitude

=item popup

A popup message

=back

=item circles

Array of hashes containing the following key/value

=over

=item name

Name of circle variable

=item longitude

longitude

=item latitude

latitude

=item color

circle color

=item fillColor

circle fill color

=item fillOpacity

circle opacity

=item radius

radius of circle in meters

=back

=back

=head1 TODO

=over

=item Add polygons

=back

=head1 CONTRIBUTIONS

Always welcomed! L<https://github.com/battlemidget/Mojolicious-Plugin-Leafletjs>

=head1 AUTHOR

Adam Stokes E<lt>adamjs@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Adam Stokes

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
