package Pg::Explain::Hinter::Hint;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.18;
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Unicode::Normalize qw( NFC );
use Unicode::Collate;
use Encode qw( decode );

if ( grep /\P{ASCII}/ => @ARGV ) {
    @ARGV = map { decode( 'UTF-8', $_ ) } @ARGV;
}

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

use Carp;

=head1 NAME

Pg::Explain::Hinter::Hint - Single hint for Pg::Explain plan

=head1 VERSION

Version 2.2

=cut

our $VERSION = '2.2';

=head1 SYNOPSIS

These should be returned by Pg::Explain::Hinter, using:

    my $hinter = Pg::Explain::Hinter->new( $plan );
    if ( $hinter->any_hints ) {
        for my $hint ( @{ $hinter->hints } ) {
            ...
            printf "Hint for node #%d (%s) : %s\n", $hint->node->id, $hint->node_type, $hint->type;
            if ( $hint->details ) {
                print Dumper($hint->details);
            }
        }
    }

Read "HINT TYPES" part for more description of what hint types there can be, and what is the meaning of details for them.

=head1 FUNCTIONS

=head2 new

Object constructor.

=cut

sub new {
    my $class = shift;
    my %args  = @_;
    croak( 'There is no node arg!' )                       unless $args{ 'node' };
    croak( 'Given node is not Pg::Explain::Node object!' ) unless 'Pg::Explain::Node' eq ref $args{ 'node' };
    croak( 'There is no type arg!' )                       unless $args{ 'type' };
    my $self = bless {}, $class;
    $self->type( $args{ 'type' } );
    $self->node( $args{ 'node' } );
    $self->details( $args{ 'details' } ) if $args{ 'details' };
    return $self;
}

=head2 type

Accessor for type inside hint.

=cut

sub type {
    my $self = shift;
    $self->{ 'type' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'type' };
}

=head2 node

Accessor for node inside hint.

=cut

sub node {
    my $self = shift;
    $self->{ 'node' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'node' };
}

=head2 details

Accessor for details inside hint.

=cut

sub details {
    my $self = shift;
    $self->{ 'details' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'details' };
}

=head1 HINT TYPES

There are various types of hints, and each have their own meaning of ->details:

=head2 DISK_SORT

Node that the hint is for is using sorting that is spilling to disk. It's possible that increasing work_mem would help.

Details:

=over

=item * Used disk space in kB

=back

=head2 INDEXABLE_SEQSCAN_SIMPLE

Node that the hint is for is using sequential scan, but it should be possible to add simple index (on one column) that will make it faster.

Details:

=over

=item * Column name that the index should be made on

=back

=head2 INDEXABLE_SEQSCAN_MULTI_EQUAL_AND

Node that the hint is for us using sequential scan, and it should be possible to add index(es) to make it go faster.

This happens only for scans that have multiple equality checks joined with AND operator, like:

=over

=item * a = 1 and b = 2

=item * x = 'abc' and z = 12

=back

Details are arrayref where each element is hashref with two keys:

=over

=item * column : column name that was checked

=item * value : the value that the check was using

=back

=head1 AUTHOR

hubert depesz lubaczewski, C<< <depesz at depesz.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<depesz at depesz.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::Explain::Node

=head1 COPYRIGHT & LICENSE

Copyright 2008-2021 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::Hinter
