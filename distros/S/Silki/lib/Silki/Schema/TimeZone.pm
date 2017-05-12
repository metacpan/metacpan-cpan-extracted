package Silki::Schema::TimeZone;
{
  $Silki::Schema::TimeZone::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Fey::Object::Iterator::FromSelect;
use Silki::Schema;

use Fey::ORM::Table;

my $Schema = Silki::Schema->Schema();

{
    has_policy 'Silki::Schema::Policy';

    has_table( $Schema->table('TimeZone') );

    has_one( $Schema->table('Country') );
}

sub CreateDefaultZones {
    my $class = shift;

    my %zones = (
        us => [
            [ 'America/New_York',      'East Coast' ],
            [ 'America/Chicago',       'Central' ],
            [ 'America/Denver',        'Mountain' ],
            [ 'America/Los_Angeles',   'West Coast' ],
            [ 'America/Anchorage',     'Alaska' ],
            [ 'Pacific/Honolulu',      'Hawaii' ],
            [ 'America/Santo_Domingo', 'Puerto Rico' ],
        ],

        ca => [
            [ 'America/Halifax',   'Halifax and New Brunswick' ],
            [ 'America/Toronto',   'Ontario and Quebec' ],
            [ 'America/Winnipeg',  'Manitoba' ],
            [ 'America/Regina',    'Saskatchewan' ],
            [ 'America/Edmonton',  'Alberta' ],
            [ 'America/Vancouver', 'British Columbia' ],
            [ 'America/St_Johns',  q{St. John's} ],
        ],
    );

    for my $iso_code ( keys %zones ) {
        my $order = 1;

        for my $zone ( @{ $zones{$iso_code} } ) {
            next if $class->new( olson_name => $zone->[0] );

            $class->insert(
                olson_name    => $zone->[0],
                iso_code      => $iso_code,
                description   => $zone->[1],
                display_order => $order++,
            );
        }
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a time zone

__END__
=pod

=head1 NAME

Silki::Schema::TimeZone - Represents a time zone

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

