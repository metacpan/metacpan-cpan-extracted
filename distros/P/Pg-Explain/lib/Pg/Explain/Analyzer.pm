package Pg::Explain::Analyzer;

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

use autodie;
use Carp;

=head1 NAME

Pg::Explain::Analyzer - Some helper methods to analyze explains

=head1 VERSION

Version 1.11

=cut

our $VERSION = '1.11';

=head1 SYNOPSIS

This is to be used in analysis/statistical tools. Sample usage:

    use Pg::Explain;
    use Pg::Explain::Analyzer;
    use Data::Dumper;

    my $explain = Pg::Explain->new('source_file' => 'some_file.out');
    my $analyzer = Pg::Explain::Analyzer->new( $explain );

    print Dumper($analyzer->all_node_types);

=head1 FUNCTIONS

=head2 new

Object constructor.

Takes one argument - Pg::Explain object.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    croak( 'You have to provide explain object.' )                 if 0 == scalar @_;
    croak( 'Too many arguments to Pg::Explain::Analyzer->new().' ) if 1 < scalar @_;
    $self->explain( shift );
    croak( 'Given explain is not an object.' )   unless ref( $self->explain );
    croak( 'Given explain is not Pg::Explain.' ) unless $self->explain->isa( 'Pg::Explain' );
    return $self;
}

=head2 explain

Getter/setter of explain object.

=cut

sub explain {
    my $self = shift;
    $self->{ 'explain' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'explain' };
}

=head2 all_node_types

Returns list (arrayref) with names of all nodes in analyzed explain.

=cut

sub all_node_types {
    my $self   = shift;
    my %seen   = ();
    my @return = ();
    my @nodes  = ( $self->explain->top_node );
    while ( my $node = shift @nodes ) {
        my $type = $node->type;
        push @return, $type unless $seen{ $type }++;
        push @nodes,  $node->all_subnodes;
    }
    return \@return;
}

=head2 all_node_paths

Returns list (arrayref) where each element is array of node types from top level to "current".

Elements in final arrays are node types.

=cut

sub all_node_paths {
    my $self   = shift;
    my %seen   = ();
    my @return = ();
    my @nodes  = ( [ [], $self->explain->top_node ] );
    while ( my $data = shift @nodes ) {
        my ( $prefix, $node ) = @{ $data };
        my $node_type        = $node->type;
        my $current_path     = [ @{ $prefix }, $node_type ];
        my $current_path_str = join ' :: ', @{ $current_path };
        push @return, $current_path unless $seen{ $current_path_str }++;
        push @nodes,  map { [ $current_path, $_ ] } $node->all_subnodes;
    }
    return \@return;
}

=head1 AUTHOR

hubert depesz lubaczewski, C<< <depesz at depesz.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<depesz at depesz.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::Explain

=head1 COPYRIGHT & LICENSE

Copyright 2008-2021 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::Analyzer
