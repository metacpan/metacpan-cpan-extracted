#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Client;
{
  $Net::Gandi::Client::VERSION = '1.122180';
}

# ABSTRACT: A Perl interface for gandi api

use Moose;
use MooseX::Types::URI qw(Uri);
use namespace::autoclean;

use Net::Gandi::Types qw(Apikey);

use Module::Load;

with 'MooseX::Traits';


has 'apikey' => (
    is       => 'rw',
    required => 0,
    isa      => Apikey,
);


has 'apiurl' => (
    is      => 'rw',
    isa     => Uri,
    coerce  => 1,
    default => 'https://rpc.gandi.net/xmlrpc/2.0/',
);


has 'useragent' => (
    is      => 'rw',
    isa     => 'Str',
    default => "Net::Gandi/1.0",
);


has 'timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => 5,
);


has 'err' => (
    is      => 'rw',
    isa     => 'Int',
);


has 'errstr' => (
    is      => 'rw',
    isa     => 'Str',
);


has 'date_to_datetime' => (
    is      => 'rw',
    default => 0,
    isa     => 'Bool',
);

sub _date_to_datetime {
    my ( $self, $object ) = @_;

    ref($object) or return $object;

    load 'DateTime::Format::HTTP';
    my $array        = ref($object) ne 'ARRAY' ? [ $object ] : $object;
    my $dt           = 'DateTime::Format::HTTP';
    my @special_keys = ('ips', 'disks', 'ifaces');

    foreach my $obj (@{$array}) {
        while ( my ($key, $value) = each %{$obj} ) {
            if ( $key ~~ @special_keys ) {
                $self->_date_to_datetime($value);
            }
            $obj->{$key} = $dt->parse_datetime($value) if $key =~ m/date_/;
        }
    }

    return $object;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Gandi::Client - A Perl interface for gandi api

=head1 VERSION

version 1.122180

=head1 ATTRIBUTES

=head2 apikey

rw, Apikey. Api key of your Gandi account

=head2 apikey

rw, Uri. Url of gandi api, default value is current api version

=head2 useragent

rw, Str. Specified a useragent. The default value is Net::Gandi with the version.

=head2 timeout

rw, Int. Timeout in secondes, default to 5.

=head2 err

rw, Int. Returns the numeric code of last error.

=head2 errstr

rw, Str. Returns the human readable text for last error.

=head2 date_to_datetime

rw, Bool. To transform the string date in a DateTime object. Use
DateTime::Format::HTTP

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

