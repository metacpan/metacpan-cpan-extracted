package Pg::SQL::PrettyPrinter::Node::BoolExpr;

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

    $self->objectify( 'args' );

    return $self;
}

sub as_text {
    my $self    = shift;
    my $this_op = $self->{ 'boolop' };
    $this_op =~ s/_EXPR\z// or croak( "Unknown boolean operation: ${this_op}!" );
    my @nice_args;
    for my $arg ( @{ $self->{ 'args' } } ) {
        my $x = $arg->as_text;
        if ( 'Pg::SQL::PrettyPrinter::Node::BoolExpr' eq ref $arg ) {
            push @nice_args, "( ${x} )";
        }
        else {
            push @nice_args, $x;
        }
    }

    if ( 1 == scalar @nice_args ) {
        return sprintf "%s %s", $this_op, $nice_args[ 0 ];
    }
    return join( " ${this_op} ", @nice_args );
}

sub pretty_print {
    my $self    = shift;
    my $this_op = $self->{ 'boolop' };
    $this_op =~ s/_EXPR\z// or croak( "Unknown boolean operation: ${this_op}!" );
    my @nice_args;

    for my $arg ( @{ $self->{ 'args' } } ) {
        my $x = $arg->pretty_print;
        if ( 'Pg::SQL::PrettyPrinter::Node::BoolExpr' eq ref $arg ) {
            if ( $x =~ m{\n} ) {
                push @nice_args, join( "\n", "(", $self->increase_indent( $x ), ")" );
            }
            else {
                push @nice_args, "( ${x} )";
            }
        }
        else {
            push @nice_args, $x;
        }
    }

    if ( 1 == scalar @nice_args ) {
        return sprintf "%s %s", $this_op, $nice_args[ 0 ];
    }
    my $out = '';
    for my $i ( 0 .. $#nice_args ) {
        $out .= $nice_args[ $i ];
        if ( $i < $#nice_args ) {
            $out .= " ${this_op}\n";
        }
    }
    return $out;
}

1;
