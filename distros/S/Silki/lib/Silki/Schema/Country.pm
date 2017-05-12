package Silki::Schema::Country;
{
  $Silki::Schema::Country::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema;

use Fey::ORM::Table;

my $Schema = Silki::Schema->Schema();

{
    has_policy 'Silki::Schema::Policy';

    has_table( $Schema->table('Country') );

    has_one( $Schema->table('Locale') );

    has_many time_zones => (
        table => $Schema->table('TimeZone'),
        order_by =>
            [ $Schema->table('TimeZone')->column('display_order'), 'ASC' ],
    );
}

sub CreateDefaultCountries {
    my $class = shift;

    my @countries = (
        [ 'us', 'United States', 'en_US' ],
        [ 'ca', 'Canada',        'en_CA' ],
    );

    for my $country (@countries) {
        next if $class->new( iso_code => $country->[0] );

        $class->insert(
            iso_code    => $country->[0],
            name        => $country->[1],
            locale_code => $country->[2],
        );
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a country

__END__
=pod

=head1 NAME

Silki::Schema::Country - Represents a country

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

