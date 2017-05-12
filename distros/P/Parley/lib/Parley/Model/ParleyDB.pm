package Parley::Model::ParleyDB;

use strict;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Model::DBIC::Schema';

#__PACKAGE__->config(
#    schema_class => 'Parley::Schema',
#    connect_info => [
#        'dbi:Pg:dbname=parley',
#        'parley',
#        
#    ],
#);

# CONFIG COMES FROM parley.conf

=head1 NAME

Parley::Model::ParleyDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Parley>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Parley::Schema>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
