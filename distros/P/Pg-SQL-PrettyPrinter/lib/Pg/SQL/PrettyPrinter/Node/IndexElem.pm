package Pg::SQL::PrettyPrinter::Node::IndexElem;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.26;
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

# If there is __DATA__,then uncomment next line:
# binmode( DATA, ':encoding(UTF-8)' );
# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

# Useful common code
use autodie;
use Carp qw( carp croak confess cluck );
use English qw( -no_match_vars );
use Data::Dumper qw( Dumper );

# give a full stack dump on any untrapped exceptions
local $SIG{ __DIE__ } = sub {
    confess "Uncaught exception: @_" unless $^S;
};

# now promote run-time warnings into stackdumped exceptions
#   *unless* we're in an try block, in which
#   case just generate a clucking stackdump instead
local $SIG{ __WARN__ } = sub {
    if   ( $^S ) { cluck "Trapped warning: @_" }
    else         { confess "Deadly warning: @_" }
};

# Useful common code

use parent qw( Pg::SQL::PrettyPrinter::Node );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    bless $self, $class;

    $self->objectify( 'expr', 'collation', 'opclass' );

    croak( 'Unknown ordering: ' . $self->{ 'ordering' } )             unless $self->{ 'ordering' }       =~ m{\A(?:SORTBY_DEFAULT)\z};
    croak( 'Unknown nulls_ordering: ' . $self->{ 'nulls_ordering' } ) unless $self->{ 'nulls_ordering' } =~ m{\A(?:SORTBY_NULLS_DEFAULT)\z};

    return $self;
}

sub as_text {
    my $self = shift;
    my $base = '';
    if ( exists $self->{ 'expr' } ) {
        $base = $self->{ 'expr' }->as_text();
    }
    else {
        $base = $self->quote_ident( $self->{ 'name' } );
    }
    if ( exists $self->{ 'collation' } ) {
        $base .= ' COLLATE ' . join( '.', map { $_->as_ident } @{ $self->{ 'collation' } } );
    }
    if ( exists $self->{ 'opclass' } ) {
        $base .= ' ' . join( '.', map { $_->as_ident } @{ $self->{ 'opclass' } } );
    }
    return $base;
}

1;

# vim: set ft=perl:
