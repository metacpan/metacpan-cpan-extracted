package Pg::SQL::PrettyPrinter::Node::MinMaxExpr;

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

    croak( "Unknown MinMaxExpr op: " . $self->{ 'op' } ) unless $self->{ 'op' } =~ m{\A(?:IS_LEAST|IS_GREATEST)\z};

    $self->objectify( 'args' );

    return $self;
}

sub as_text {
    my $self = shift;
    my $op   = $self->{ 'op' };
    $op =~ s/^IS_//;
    return sprintf( '%s( %s )', $op, join( ", ", map { $_->as_text } @{ $self->{ 'args' } } ) );
}

sub pretty_print {
    my $self = shift;
    my $text = $self->as_text;
    return $text if length( $text ) < 40;
    my $op = $self->{ 'op' };
    $op =~ s/^IS_//;
    my @lines = ();
    push @lines, $op . "(";

    push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'args' } };
    $lines[ -1 ] =~ s/,\z//;
    push @lines, ')';
    return join( "\n", @lines );
}

1;

# vim: set ft=perl:
