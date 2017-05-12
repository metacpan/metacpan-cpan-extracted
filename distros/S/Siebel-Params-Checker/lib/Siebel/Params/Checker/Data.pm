package Siebel::Params::Checker::Data;
use warnings;
use strict;
use Exporter qw(import);
our $VERSION = '0.002'; # VERSION
our @EXPORT_OK = qw(has_more_servers by_param by_server);

=pod

=head1 NAME

Siebel::Params::Checker::Data - functions to rearrange data returned from Siebel::Srvrmgr

=head1 DESCRIPTION

This module has exportable functions to rearrange data generated from L<Siebel::Srvrmgr>.

These functions are pretty specific for Siebel::Params::Checker, this module was created to simplify maintance and tests.

Unless you're going to hack this distribution, you shouldn't be using those functions directly.

=head1 FUNCTIONS

The subs C<has_more_servers>, C<by_param> and C<by_server> are exported on demand.

=head2 has_more_servers

Tests if data returned from L<Siebel::Srvrmgr> has more servers or parameters, returning true or false (as Perl understands it).

Expects as parameter a hash reference.

=cut

sub has_more_servers {

    my $data_ref = shift;
    my @servers  = ( keys( %{$data_ref} ) );
    my @params   = ( keys( %{ $data_ref->{ $servers[0] } } ) );
    if ( scalar(@servers) > scalar(@params) ) {
        return 1;
    }
    else {
        return 0;
    }

}

=head2 by_param

Expects as parameters the data returned from L<Siebel::Srvrmgr>.

Returns data structured by the parameters (they will be used as the table headers in the report).

=cut

sub by_param {

    my $ref = shift;
    my @rows;
    my @servers = sort( keys( %{$ref} ) );
    my @params  = sort( keys( %{ $ref->{ $servers[0] } } ) );

    foreach my $server (@servers) {
        my @row = ($server);
        foreach my $param (@params) {
            push( @row, $ref->{$server}->{$param} );
        }
        push( @rows, \@row );
    }

    unshift( @params, ' ' );
    return \@params, \@rows;

}

=head2 by_server

Expects as parameters the data returned from L<Siebel::Srvrmgr>.

Returns data structured by the Siebel servers names (they will be used as the table headers in the report).

=cut

sub by_server {

    my $ref = shift;
    my @rows;
    my @servers = sort( keys( %{$ref} ) );
    my @params  = sort( keys( %{ $ref->{ $servers[0] } } ) );

    foreach my $param (@params) {
        my @row = ($param);
        foreach my $server (@servers) {
            push( @row, $ref->{$server}->{$param} );
        }
        push( @rows, \@row );
    }

    unshift( @servers, ' ' );
    return \@servers, \@rows;

}

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

The command line utility scpc.pl uses this module.

=item *

L<Siebel::Params::Checker::ListComp>

=item *

L<Siebel::Params::Checker::ListParams>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
