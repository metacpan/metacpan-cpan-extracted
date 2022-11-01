package Pg::SQL::PrettyPrinter::Node::XmlSerialize;

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
use Carp         qw( carp croak confess cluck );
use English      qw( -no_match_vars );
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

    croak( 'Unknown XML option: ' . $self->{ 'xmloption' } ) unless $self->{ 'xmloption' } =~ m{\AXMLOPTION_(DOCUMENT|CONTENT)\z};

    $self->objectify( 'expr', [ qw( typeName names ) ], [ qw( typeName typmods ) ], [ qw( typeName arrayBounds ) ] );

    return $self;
}

sub as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLSERIALIZE(';
    push @elements, $self->{ 'xmloption' };
    $elements[ -1 ] =~ s/^XMLOPTION_//;
    push @elements, $self->{ 'expr' }->as_text;
    push @elements, 'AS';
    push @elements, $self->expr_type;
    push @elements, ')';
    return join( ' ', @elements );
}

sub pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLSERIALIZE(';
    push @lines, $self->increase_indent( $self->{ 'xmloption' } );
    $lines[ -1 ] =~ s/^(\s+)XMLOPTION_/$1/;
    push @lines, $self->increase_indent( $self->{ 'expr' }->pretty_print );
    $lines[ -1 ] .= ' AS ' . $self->expr_type;
    push @lines, ')';
    return join( "\n", @lines );
}

sub expr_type {
    my $self = shift;

    my $typname = join( '.', map { $_->as_ident } @{ $self->{ 'typeName' }->{ 'names' } } );
    $typname = 'char' if $typname eq 'pg_catalog.bpchar';

    my $typmods = '';
    if ( exists $self->{ 'typeName' }->{ 'typmods' } ) {
        $typmods = '( ' . join( ', ', map { $_->as_text } @{ $self->{ 'typeName' }->{ 'typmods' } } ) . ' )';
    }
    if ( exists $self->{ 'typeName' }->{ 'arrayBounds' } ) {
        my @bounds_as_text = map { $_->as_text } @{ $self->{ 'typeName' }->{ 'arrayBounds' } };
        my $array_def      = sprintf '[%s]', join( ', ', @bounds_as_text );
        $array_def = '[]' if $array_def eq '[-1]';
        $typmods .= $array_def;
    }
    return $typname . $typmods;
}

1;

# vim: set ft=perl:
