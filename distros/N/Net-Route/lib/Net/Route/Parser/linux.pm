package Net::Route::Parser::linux;
use 5.008;
use strict;
use warnings;
use version; our ( $VERSION ) = '$Revision: 363 $' =~ m{(\d+)}xms;
use Moose;
use Net::Route;

extends 'Net::Route::Parser';

sub command_line
{
    return [qw(/sbin/route -n )];
}

sub parse_routes
{
    my ( $self, $text_lines_ref ) = @_;

    splice @{$text_lines_ref}, 0, 2;

    my @routes;
    foreach my $line ( @{$text_lines_ref} )
    {
        chomp $line;

        my @values = split /\s+/xms, $line;

        # These values will be stored in a configuration hash
        my ( $dest, $gateway, $dest_mask, $flags, $metric, $ref, $use, $interface ) = @values;

        my $is_active  = $flags =~ /U/xms;
        my $is_dynamic = $flags =~ /[RDM]/xms;
        my $route_ref = Net::Route->new( {
               'destination' => $self->create_ip_object( $dest, $dest_mask ),
               'gateway'     => $self->create_ip_object( $gateway ),
               'is_active'   => $is_active,
               'is_dynamic'  => $is_dynamic,
               'metric'      => $metric,
               'interface'   => $interface,

            } );
        push @routes, $route_ref;
    }

    return \@routes;
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

Net::Route::Parser::linux - Internal class


=head1 SYNOPSIS

Internal.


=head1 VERSION

Revision $Revision: 363 $.


=head1 DESCRIPTION

This class parses Linux' C<route> output. It implements
L<Net::Route::Parser>.


=head1 INTERFACE

See L<Net::Route::Parser>.

=head2 Object Methods

=head3 command_line()

=head3 parse_routes()


=head1 AUTHOR

Created by Alexandre Storoz, C<< <astoroz@straton-it.fr> >>

Maintained by Thomas Equeter, C<< <tequeter@straton-it.fr> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Straton IT.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

