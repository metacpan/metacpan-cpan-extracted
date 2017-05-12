package Net::Route::Parser::MSWin32;
use 5.008;
use strict;
use warnings;
use version; our ( $VERSION ) = '$Revision: 366 $' =~ m{(\d+)}xms;
use Moose;
use Readonly;
use Net::Route;
use Net::Route::Parser qw(:ip_re :route_re);

extends 'Net::Route::Parser';

sub command_line
{
    return [qw(c:\WINDOWS\system32\route print)];
}

sub parse_routes
{
    my ( $self, $text_lines_ref ) = @_;

    my @routes;
    foreach my $line ( @{$text_lines_ref} )
    {
        chomp $line;

        if ( my @values = ( $line =~ $ROUTE_RE ) )
        {
            my ( $dest, $dest_mask, $gateway, $interface, $metric ) = @values;

            my $route_ref = Net::Route->new( {
                   'destination' => $self->create_ip_object( $dest, $dest_mask ),
                   'gateway'     => $self->create_ip_object( $gateway ),
                   'is_active'   => 1,                              # TODO
                   'is_dynamic' => 0,            # TODO
                   'metric'     => $metric,
                   'interface'  => $interface,

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

Net::Route::Parser::MSWin32 - Internal class


=head1 SYNOPSIS

Internal.


=head1 VERSION

Revision $Revision: 366 $.


=head1 DESCRIPTION

This class parses Windows' C<route print> output. It implements
L<Net::Route::Parser>.

=head2 Object Methods

=head3 command_line()

=head3 parse_routes()


=head1 INTERFACE

See L<Net::Route::Parser>.


=head1 AUTHOR

Created by Alexandre Storoz, C<< <astoroz@straton-it.fr> >>

Maintained by Thomas Equeter, C<< <tequeter@straton-it.fr> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Straton IT.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

