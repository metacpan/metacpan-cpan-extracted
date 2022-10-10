package Pg::SQL::PrettyPrinter::Node::SubLink;

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
    my @known_types_array = qw( ALL_SUBLINK ANY_SUBLINK EXPR_SUBLINK ARRAY_SUBLINK EXISTS_SUBLINK );
    my %known_types;

    # Builds %known_types, where each key is elements form @known_types_array, and the value is the same as key.
    @known_types{ @known_types_array } = @known_types_array;

    croak( 'Unknown subselect type: ' . $self->{ 'subLinkType' } ) unless exists $known_types{ $self->{ 'subLinkType' } };

    $self->objectify( 'subselect' );
    if ( $self->{ 'subLinkType' } =~ m{\A(?:ALL|ANY)_SUBLINK\z} ) {
        $self->objectify( 'testexpr', 'operName' );
    }
    if ( exists $self->{ 'operName' } ) {
        croak( "Can't handle operName with more than 1 element: " . Dumper( $self ) ) if 1 != scalar @{ $self->{ 'operName' } };
    }

    return $self;
}

sub as_text {
    my $self           = shift;
    my $subselect_text = $self->{ 'subselect' }->as_text;

    if ( $self->{ 'subLinkType' } =~ m{\A(ANY|ALL)_SUBLINK\z} ) {
        my $type = $1;
        if ( exists $self->{ 'operName' } ) {
            my $opname = $self->{ 'operName' }->[ 0 ]->{ 'str' };
            return sprintf( '%s %s %s( %s )', $self->{ 'testexpr' }->as_text, $opname, $type, $subselect_text );
        }
        else {
            return sprintf( '%s IN ( %s )', $self->{ 'testexpr' }->as_text, $subselect_text );
        }
    }
    elsif ( $self->{ 'subLinkType' } eq 'ARRAY_SUBLINK' ) {
        return sprintf( 'ARRAY( %s )', $subselect_text );
    }
    elsif ( $self->{ 'subLinkType' } eq 'EXISTS_SUBLINK' ) {
        return sprintf( 'EXISTS ( %s )', $subselect_text );
    }
    return sprintf( '( %s )', $self->{ 'subselect' }->as_text );
}

sub pretty_print {
    my $self           = shift;
    my $subselect_text = $self->increase_indent( $self->{ 'subselect' }->pretty_print );

    my @lines = ();
    if ( $self->{ 'subLinkType' } =~ m{\A(ANY|ALL)_SUBLINK\z} ) {
        my $type = $1;
        if ( exists $self->{ 'operName' } ) {
            my $opname = $self->{ 'operName' }->[ 0 ]->{ 'str' };
            push @lines, sprintf( '%s %s %s(', $self->{ 'testexpr' }->pretty_print, $opname, $type );
            push @lines, $subselect_text;
            push @lines, ')';
        }
        else {
            push @lines, $self->{ 'testexpr' }->pretty_print . ' IN (';
            push @lines, $subselect_text;
            push @lines, ')';
        }
    }
    elsif ( $self->{ 'subLinkType' } eq 'ARRAY_SUBLINK' ) {
        push @lines, 'ARRAY(';
        push @lines, $subselect_text;
        push @lines, ')';
    }
    elsif ( $self->{ 'subLinkType' } eq 'EXISTS_SUBLINK' ) {
        push @lines, 'EXISTS (';
        push @lines, $subselect_text;
        push @lines, ')';
    }
    else {
        push @lines, '(';
        push @lines, $subselect_text;
        push @lines, ')';
    }
    return join( "\n", @lines );
}

1;
