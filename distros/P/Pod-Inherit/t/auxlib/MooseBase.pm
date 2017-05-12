package MooseBase;

use strict;
use warnings;

use Moose;

has anattribute => ( isa => 'Str', is => 'rw' );

no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

MooseBase - Base Moose class

=head1 SYNOPSIS

Blah

=head1 DESCRIPTION

=head2 anattribute

Blah

=head1 AUTHOR

James Mastros <james@mastros.biz>

=head1 LICENSE

Stuff


