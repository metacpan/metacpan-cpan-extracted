package Pg::SQL::PrettyPrinter::Node::RangeSubselect;

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

    $self->objectify( 'subquery', [ 'alias', 'colnames' ] );

    return $self;
}

sub as_text {
    my $self = shift;

    # Shortcut
    my $A = $self->{ 'alias' };

    my $base_with_alias = sprintf( '( %s ) AS %s', $self->{ 'subquery' }->as_text, $self->quote_ident( $A->{ 'aliasname' } ) );
    $base_with_alias = 'LATERAL ' . $base_with_alias if $self->{ 'lateral' };
    return $base_with_alias unless $A->{ 'colnames' };

    return sprintf( '%s ( %s )', $base_with_alias, join( ', ', map { $_->as_ident } @{ $A->{ 'colnames' } } ) );
}

sub pretty_print {
    my $self  = shift;
    my @lines = ();
    if ( $self->{ 'lateral' } ) {
        push @lines, 'LATERAL (';
    }
    else {
        push @lines, '(';
    }
    push @lines, $self->increase_indent( $self->{ 'subquery' }->pretty_print );
    push @lines, ') AS ' . $self->{ 'alias' }->{ 'aliasname' };
    if ( $self->{ 'alias' }->{ 'colnames' } ) {
        $lines[ -1 ] .= sprintf ' ( %s )', join( ', ', map { $_->as_ident } @{ $self->{ 'alias' }->{ 'colnames' } } );
    }
    return join( "\n", @lines );
}

1;
