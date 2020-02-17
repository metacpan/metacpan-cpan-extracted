package Net::DNS::Resolver::Mock;

use strict;
use warnings;

our $VERSION = '1.20200215'; # VERSION

use base 'Net::DNS::Resolver';

use Net::DNS::Packet;
use Net::DNS::Question;
use Net::DNS::ZoneFile;

my $die_on = {};
{
    my @_debug_output;
    sub enable_debug {
        my ( $self ) = @_;
        $self->{_mock_debug} = 1;
        $self->_add_debug( "Net::DNS::Resolver::Mock Debugging enabled" );
        return;
    }
    sub disable_debug {
        my ( $self ) = @_;
        $self->clear_debug();
        delete $self->{_mock_debug};
        return;
    }
    sub _add_debug {
        my ( $self, $debug ) = @_;
        push @_debug_output, $debug;
        warn $debug;
        return;
    }
    sub clear_debug {
        my ( $self ) = @_;
        @_debug_output = ();
        return;
    }
    sub get_debug {
        my ( $self ) = @_;
        return @_debug_output;
    }
}

sub die_on {
    my ( $self, $name, $type, $error ) = @_;
    $die_on->{ "$name $type" } = $error;
    return;
}

sub zonefile_read {
    my ( $self, $zonefile ) = @_;
    $self->{ 'zonefile' } = Net::DNS::ZoneFile->read( $zonefile );
    return;
}

sub zonefile_parse {
    my ( $self, $zonefile ) = @_;
    $self->{ 'zonefile' } = Net::DNS::ZoneFile->parse( $zonefile );
    return;
}

sub send {
    my ( $self, $name, $type ) = @_;

    $self->_add_debug( "DNS Lookup '$name' '$type'" ) if $self->{_mock_debug};

    if ( exists ( $die_on->{ "$name $type" } ) ) {
        die $die_on->{ "$name $type" };
    }

    $name =~ s/\.$//;

    my $FakeZone = $self->{ 'zonefile' };

    my $origname = $name;
    if ( lc $type eq 'ptr' ) {
        if ( index( lc $name, '.in-addr.arpa' )  == -1 ) {
            if ( $name =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                $name = join( '.', reverse( split( /\./, $name ) ) );
                $name .= '.in-addr.arpa';
            }
        }
    }
    my $Packet = Net::DNS::Packet->new();
    $Packet->push( 'question' => Net::DNS::Question->new( $origname, $type, 'IN' ) );
    foreach my $Item ( @$FakeZone ) {
        my $itemname = $Item->name();
        my $itemtype = $Item->type();
        if ( ( lc $itemname eq lc $name ) && ( lc $itemtype eq lc $type ) ) {
        $Packet->push( 'answer' => $Item );
        }
        elsif ( ( lc $itemname eq lc $name ) && ( lc $itemtype eq lc 'cname' ) ) {
            $Packet->push( 'answer' => $Item );
        }
    }
    $Packet->{ 'answerfrom' } = '127.0.0.1';
    $Packet->{ 'status' } = 33152;
    return $Packet;
}

1;

__END__

=head1 NAME

Net::DNS::Resolver::Mock - Mock a DNS Resolver object for testing

=head1 DESCRIPTION

A subclass of Net::DNS::Resolver which parses a zonefile for it's data source. Primarily for use in testing.

=for markdown [![Code on GitHub](https://img.shields.io/badge/github-repo-blue.svg)](https://github.com/marcbradshaw/Net-DNS-Resolver-Mock)

=for markdown [![Build Status](https://travis-ci.org/marcbradshaw/Net-DNS-Resolver-Mock.svg?branch=master)](https://travis-ci.org/marcbradshaw/Net-DNS-Resolver-Mock)

=for markdown [![Open Issues](https://img.shields.io/github/issues/marcbradshaw/Net-DNS-Resolver-Mock.svg)](https://github.com/marcbradshaw/Net-DNS-Resolver-Mock/issues)

=for markdown [![Dist on CPAN](https://img.shields.io/cpan/v/Net-DNS-Resolver-Mock.svg)](https://metacpan.org/release/Net-DNS-Resolver-Mock)

=for markdown [![CPANTS](https://img.shields.io/badge/cpants-kwalitee-blue.svg)](http://cpants.cpanauthors.org/dist/Net-DNS-Resolver-Mock)


=head1 SYNOPSIS

    use Net::DNS::Resolver::Mock;

    my $Resolver = Net::DNS::Resolver::Mock-new();

    $Resolver->zonefile_read( $FileName );
    # or
    $Resolver->zonefile_parse( $String );

=head1 PUBLIC METHODS

=over

=item zonefile_read ( $FileName )

Reads specified file for zone data

=item zonefile_parse ( $String )

Reads the zone data from the supplied string

=item die_on ( $Name, $Type, $Error )

Die with $Error for a query of $Name and $Type

=item enable_debug ()

Once set, the resolver will write any lookups received to STDERR
and will be available via the following methods

=item disble_debug ()

Disable debugging

=item clear_debug ()

Clear the debugging list

=item get_debug ()

Returns a list of debugging entries

=back

=head1 DEPENDENCIES

  Net::DNS::Resolver
  Net::DNS::Packet
  Net::DNS::Question
  Net::DNS::ZoneFile

=head1 BUGS

Please report bugs via the github tracker.

https://github.com/marcbradshaw/Net-DNS-Resolver-Mock/issues

=head1 AUTHORS

Marc Bradshaw, E<lt>marc@marcbradshaw.netE<gt>

=head1 COPYRIGHT

Copyright (c) 2017, Marc Bradshaw.

=head1 LICENCE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

