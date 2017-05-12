package POE::Component::Client::opentick::Util;
#
#   opentick.com POE client
#
#   Low-level utility routines
#
#   infi/2008
#
#   $Id: Util.pm 56 2009-01-08 16:51:14Z infidel $
#
#   Full POD documentation after __END__
#

use strict;
use warnings;
use Carp qw( carp );
use Data::Dumper;

use POE::Component::Client::opentick::Error;

use vars qw( $VERSION $TRUE $FALSE );

BEGIN {
    require Exporter;
    our @ISA    = qw( Exporter );
    our @EXPORT = qw( pack_binary unpack_binary count_fields check_fields
                      dump_hex    pack_macaddr  is_error     pack_bytes
                      asc2longlong  );
    ($VERSION)  = q$Revision: 56 $ =~ /(\d+)/;
}

###
### Variables
###

*TRUE  = \1;
*FALSE = \0;

# NOTE: This is not complete, nor is it intended to be.
# Probably not platform-safe, either.
my $pack_bytes = {
    x   => 1,   a   => 1,   A   => 1,   c   => 1,
    C   => 1,   s   => 2,   S   => 2,   i   => 4,
    I   => 4,   l   => 4,   L   => 4,   n   => 2,
    N   => 4,   v   => 2,   V   => 4,   f   => 4,
    d   => 8,   p   => 4,   P   => 4,
};

###
### Functions
###

sub pack_binary
{
    my( $pack_tmpl, @fields ) = @_;

    my $field_count = count_fields( $pack_tmpl );
    throw( "Require $field_count fields for template '$pack_tmpl', but " .
           "received " . scalar( @fields ) )
        unless( check_fields( $field_count, @fields ) );
    my $string = pack( $pack_tmpl, @fields );

    return( $string );
}

sub unpack_binary
{
    my( $pack_tmpl, $string ) = @_;

    my $field_count = count_fields( $pack_tmpl );
    my( @fields ) = unpack( $pack_tmpl, $string );

# NOTE: Some incoming packets are of variable length, so this is bogus.
#    throw( "Should expand $field_count fields from template '$pack_tmpl', " .
#           "but got " . scalar( @fields ) )
#        unless( check_fields( $field_count, @fields ) );

    return( wantarray ? @fields : $fields[0] );
}

# NOTE: Not complete for all pack templates.
sub count_fields
{
    my( $pack_tmpl ) = @_;

    my $count = grep { ! /^x/ } split( /\s+/, $pack_tmpl );

    return( $count );
}

sub check_fields
{
    my( $count, @fields ) = @_;

    my $field_count = grep { defined } @fields;

    return( $count == $field_count ? $TRUE : $FALSE );
}

sub dump_hex
{
    my( $data ) = @_;

    # Stolen from perlpacktut.pod, because I'm lazy.
    my $i;
    my $hex = join( '', map( ++$i % 16 ? "$_ " : "$_\n",
                   unpack( 'H2' x length( $data ), $data ) ),
                   length( $data ) % 16 ? "\n" : '' );

    return( $hex );
}

sub pack_macaddr
{
    my ( $macaddr ) = @_;

    # FIXME: ensure validity
    check_fields( 6, $macaddr =~ m/([0-9a-f]{2})[:-]?/ig )
         or throw( "Invalid MAC address: $macaddr; expected in " .
                   "xx:xx:xx:xx:xx:xx format." );

    $macaddr =~ s/[:-]//g;

    return( pack( 'H*', $macaddr ) );
}

sub is_error
{
    my( $object ) = @_;

    return( ref( $object ) eq 'POE::Component::Client::opentick::Error'
            ? $TRUE
            : $FALSE );
}

# NOTE: This is not complete, nor is it intended to be.
sub pack_bytes
{
    my( $template, $input ) = @_;
    return 0 unless( $template );

    my @tokens = $template =~ m#([A-Za-z]\d*)+\s*#g;

    my $count = 0;
    for( @tokens )
    {
        my( $digit, $repeat ) = m#(.)(\d*)#;
        $repeat ||= 1;
        $count += $pack_bytes->{$digit} * $repeat;
    }

    return( $count );
}

sub asc2longlong
{
    my( $string ) = @_;

    my( $i1, $i2 ) = unpack( 'VV', pack( 'a8', $string ) );
    my $ll         = ( $i2 * ( 2**32 )) + $i1;

    return( $ll );
}

1;

__END__

=pod

=head1 NAME

POE::Component::Client::opentick::Util - Utility routines for the opentick POE Component.

=head1 SYNOPSIS

 use POE::Component::Client::opentick::Util;

=head1 DESCRIPTION

This module contains utility routines used by the rest of
POE::Component::Client::opentick, and thus is of no use to anything else.

It also rudely exports a bunch of junk into your namespace.  This is
desirable for the POE component, but why would you want that in your own
module?

Don't fiddle with it.  Ist easy schnappen der Springenwerk, blowen-fusen
und poppen corken mit spitzensparken.

=head1 FUNCTIONS

=over 4

=item B<$string = pack_binary( $pack_tmpl, @args )>

Pack @args using $pack_tmpl into $string.

=item B<@fields = unpack_binary( $pack_tmpl, $string )>

Unpack $string using $pack_tmpl into corresponding @fields.

=item B<$count  = count_fields( $template )>

Return the field $count from a pack() $template.

=item B<$bool   = check_fields( $count, @fields )>

Verify that number of @fields match $count and all are defined.

=item B<$hex    = dump_hex( $data )>

Reformat $data into a standard hexdump format and store in $hex.

=item B<$string = pack_macaddr( 'xx:xx:xx:xx:xx:xx' )>

Pack a human-readable MAC address into its 6 byte binary representation.

=item B<$bool   = is_error( $object )>

Given an argument, returns TRUE if it is of class ::Error.

=item B<$bytes  = pack_bytes( $pack_tmpl )>

Given a pack() template, returns the number of bytes it will compact into.

=item B<$value  = asc2longlong( $string )>

Given a value unpacked as an ascii string, convert it to its numeric
counterpart.

=back

=head1 SEE ALSO

POE, POE::Component::Client::opentick

L<http://poe.perl.org>

L<http://www.opentick.com/>

perldoc lib

perldoc -q "include path"

=head1 AUTHOR

Jason McManus (INFIDEL) - C<< infidel AT cpan.org >>

=head1 LICENSE

Copyright (c) Jason McManus

This module may be used, modified, and distributed under the same terms
as Perl itself.  Please see the license that came with your Perl
distribution for details.

The data from opentick.com are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the opentick.com and exchange license agreements with the data.

Further details are available on L<http://www.opentick.com/>.

=cut

