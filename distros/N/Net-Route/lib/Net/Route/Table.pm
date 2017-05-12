package Net::Route::Table;
use 5.008;
use strict;
use warnings;
use version; our ( $VERSION ) = '$Revision: 363 $' =~ m{(\d+)}xms;
use Moose;
use NetAddr::IP;
use English qw( -no_match_vars );

has 'routes' => ( is => 'ro', reader => 'all_routes' );

sub default_route
{
    my ( $self ) = @_;
    foreach my $route_ref ( @{ $self->all_routes() } )
    {
        if ( $route_ref->destination->addr eq '0.0.0.0' )
        {
            return $route_ref;
        }
    }
    return;

}

sub from_system
{
    require "Net/Route/Parser/$OSNAME.pm";    ## no critic (Modules::RequireBareWordIncludes)

    my $parser_ref = "Net::Route::Parser::$OSNAME"->new();
    my @routes     = sort _up_routes_by_metric @{ $parser_ref->from_system() };

    return Net::Route::Table->new( { 'routes' => \@routes } );
}

sub _up_routes_by_metric
{
    my $is_up_sort = ( $a->is_active() <=> $b->is_active() );
    if ( $is_up_sort == 0 )
    {
        return ( $a->metric() <=> $b->metric() );
    }
    else
    {
        return $is_up_sort;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

Net::Route::Table - A routing table, such as your system's.

=head1 SYNOPSIS

    use Net::Route::Table;
    $table_ref = Net::Route::Table->from_system();
    my $default_route_ref = $table_ref->default_route();
    my $routes_ref = $table_ref->all_routes();


=head1 VERSION 

Revision $Revision: 363 $.

=head1 DESCRIPTION 

This class represents a routing table. It can be read from the system and gives
access to appropriate selections of routes.

=head1 INTERFACE

=head2 Class Methods

=head3 from_system()

Returns the system's routing table as a L<Net::Route::Table> object.


=head2 Object Methods

=head2 default_route()

Returns the current default route of the system as a L<Net::Route> object.

=head2 all_routes()

Returns the complete routing table as an arrayref of L<Net::Route> objects. The
active routes are listed first, then the results are sorted by increasing
metric.


=head1 AUTHOR

Created by Alexandre Storoz, C<< <astoroz@straton-it.fr> >>

Maintained by Thomas Equeter, C<< <tequeter@straton-it.fr> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Straton IT.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

