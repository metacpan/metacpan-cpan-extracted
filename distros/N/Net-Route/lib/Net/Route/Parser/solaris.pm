package Net::Route::Parser::solaris;
use 5.008;
use strict;
use warnings;
use version; our ( $VERSION ) = '$Revision: 363 $' =~ m{(\d+)}xms;
use Moose;
use Net::Route;
use Net::Route::Parser qw(:ip_re);
use Readonly;

extends 'Net::Route::Parser';

# /m is broken in <5.10
## no critic (RegularExpressions::RequireLineBoundaryMatching)
Readonly my $netstat_ipv4_line_re => qr{
    ($IPV4_RE | default) \s+ # destination
    ($IPV4_RE) \s+           # mask
    ($IPV4_RE) \s+           # gateway
    (?: ( [\w:]+ ) \s+ )?    # interface   
    (\d+\*?) \s+             # mxfrg
    (\d+) \s+                # rtt
    (\d+) \s+                # metric
    ([A-Z]+) \s+             # flags
    (\d+) \s+                # out
    (\d+)}xs;    # in_fwd

Readonly my $netstat_ipv6_line_re => qr{
    ($IPV6_RE | default) \s+ # destination
    ($IPV6_RE) \s+           # gateway
    (?: (\w+) \s+ )?         # interface   
    (\d+) \s+                # rtt
    (\d+) \s+                # metric
    ([A-Z]+) \s+             # flags
    (\d+) \s+                # out
    (\d+)}xs;    # in_fwd
## use critic

sub command_line
{
    return [qw( /bin/netstat -rnv )];
}

sub parse_routes
{
    my ( $self, $text_lines_ref ) = @_;
    my @routes;
    my ( $dest, $mask, $gateway, $interface, $mxfrg, $rtt, $metric, $flags, $out, $in_fwd );
    foreach my $line ( @{$text_lines_ref} )
    {

        # These values will be stored in a configuration hash
        if ( ( $dest, $gateway, $interface, $rtt, $metric, $flags, $out, $in_fwd )
             = ( $line =~ $netstat_ipv6_line_re ) )
        {
            my $is_active  = $flags =~ /U/xms;
            my $is_dynamic = $flags =~ /[RDM]/xms;
            my $route_ref = Net::Route->new( { 'destination' => NetAddr::IP->new( $dest ),
                                               'gateway'     => NetAddr::IP->new( $gateway ),
                                               'is_active'   => $is_active,
                                               'is_dynamic'  => $is_dynamic,
                                               'metric'      => $metric,
                                               'interface'   => $interface,
                                             } );
            push @routes, $route_ref;
        }
        elsif ( ( $dest, $mask, $gateway, $interface, $mxfrg, $rtt, $metric, $flags, $out, $in_fwd )
                = ( $line =~ $netstat_ipv4_line_re ) )
        {
            if ( $dest eq 'default' )
            {
                $dest = '0.0.0.0';
            }

            if ( !defined $interface )
            {
                $interface = '';
            }

            my $is_active  = $flags =~ /U/xms;
            my $is_dynamic = $flags =~ /[RDM]/xms;
            my $route_ref = Net::Route->new( {
                   'destination' => $self->create_ip_object( $dest, $mask ),
                   'gateway'     => $self->create_ip_object( $gateway ),
                   'is_active'   => $is_active,
                   'is_dynamic'  => $is_dynamic,
                   'metric'      => $metric,
                   'interface'   => $interface,

                } );
            push @routes, $route_ref;
        }
    }

    return \@routes;
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

Net::Route::Parser::solaris - Internal class


=head1 SYNOPSIS

Internal.


=head1 VERSION

Revision $Revision: 363 $.


=head1 DESCRIPTION

This class parses Solaris' C<netstat> output. It implements
L<Net::Route::Parser>.


=head1 INTERFACE

See L<Net::Route::Parser>.

=head2 Object Methods

=head3 command_line()

=head3 parse_routes()


=head1 AUTHOR

Created by Alexandre Storoz, C<< <astoroz@straton-it.fr> >>

Maintained by Thomas Equeter, C<< <tequeter@straton-it.fr> >>


=head1  LICENSE AND COPYRIGHT

Copyright 2009 Straton IT, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

