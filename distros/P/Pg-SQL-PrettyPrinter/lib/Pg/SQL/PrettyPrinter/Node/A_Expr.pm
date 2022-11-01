package Pg::SQL::PrettyPrinter::Node::A_Expr;

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

use parent     qw( Pg::SQL::PrettyPrinter::Node );
use List::Util qw( any );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    bless $self, $class;

    my @types_ok   = map { 'AEXPR_' . $_ } qw( BETWEEN IN OP OP_ALL OP_ANY NOT_BETWEEN BETWEEN_SYM NOT_BETWEEN_SYM DISTINCT NOT_DISTINCT LIKE ILIKE NULLIF SIMILAR );
    my %type_is_ok = map { $_ => 1 } @types_ok;
    if ( !$type_is_ok{ $self->{ 'kind' } } ) {
        croak( "Unsupported A_Expr kind: " . $self->{ 'kind' } );
    }

    $self->objectify( 'name', 'rexpr', 'lexpr' );
    return $self;
}

sub operator {
    my $self = shift;
    if ( 1 == scalar @{ $self->{ 'name' } } ) {
        return $self->{ 'name' }->[ 0 ]->{ 'str' };
    }
    my @elements = map { $_->as_ident() } @{ $self->{ 'name' } };
    $elements[ -1 ] = $self->{ 'name' }->[ -1 ]->{ 'str' };
    return sprintf( "OPERATOR( %s )", join( '.', @elements ) );
}

sub as_text {
    my $self = shift;

    if ( $self->{ 'kind' } eq 'AEXPR_IN' ) {
        return sprintf(
            '%s IN %s',
            $self->{ 'lexpr' }->as_text,
            $self->{ 'rexpr' }->as_text
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_OP_ANY' ) {
        return sprintf(
            '%s %s ANY( %s )',
            $self->{ 'lexpr' }->as_text,
            $self->operator,
            $self->{ 'rexpr' }->as_text
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_OP_ALL' ) {
        return sprintf(
            '%s %s ALL( %s )',
            $self->{ 'lexpr' }->as_text,
            $self->operator,
            $self->{ 'rexpr' }->as_text
        );
    }
    elsif ( any { $_ eq $self->{ 'kind' } } qw( AEXPR_BETWEEN AEXPR_NOT_BETWEEN AEXPR_BETWEEN_SYM AEXPR_NOT_BETWEEN_SYM ) ) {
        return sprintf(
            '%s %s %s AND %s',
            $self->{ 'lexpr' }->as_text,
            $self->operator,
            $self->{ 'rexpr' }->{ 'items' }->[ 0 ]->as_text,
            $self->{ 'rexpr' }->{ 'items' }->[ 1 ]->as_text,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_DISTINCT' ) {
        return sprintf(
            '%s IS DISTINCT FROM %s',
            $self->{ 'lexpr' }->as_text,
            $self->{ 'rexpr' }->as_text,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_NOT_DISTINCT' ) {
        return sprintf(
            '%s IS NOT DISTINCT FROM %s',
            $self->{ 'lexpr' }->as_text,
            $self->{ 'rexpr' }->as_text,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_LIKE' ) {
        return sprintf(
            '%s LIKE %s',
            $self->{ 'lexpr' }->as_text,
            $self->{ 'rexpr' }->as_text,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_NULLIF' ) {
        return sprintf(
            'NULLIF( %s, %s )',
            $self->{ 'lexpr' }->as_text,
            $self->{ 'rexpr' }->as_text,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_ILIKE' ) {
        return sprintf(
            '%s ILIKE %s',
            $self->{ 'lexpr' }->as_text,
            $self->{ 'rexpr' }->as_text,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_SIMILAR' ) {
        my $right_side;
        if (   ( $self->{ 'rexpr' }->isa( 'Pg::SQL::PrettyPrinter::Node::FuncCall' ) )
            && ( $self->{ 'rexpr' }->func_name eq 'pg_catalog.similar_to_escape' )
            && ( 1 == scalar @{ $self->{ 'rexpr' }->{ 'args' } } ) )
        {
            $right_side = $self->{ 'rexpr' }->{ 'args' }->[ 0 ]->as_text;
        }
        else {
            $right_side = $self->{ 'rexpr' }->as_text;
        }
        return sprintf(
            '%s SIMILAR TO %s',
            $self->{ 'lexpr' }->as_text,
            $right_side,
        );
    }

    my @parts = ();
    if ( exists $self->{ 'lexpr' } ) {
        my $this_expr  = '';
        my $add_parens = 0;
        if ( $self->{ 'lexpr' }->isa( 'Pg::SQL::PrettyPrinter::Node::A_Expr' ) ) {
            $add_parens = 1 if $self->{ 'lexpr' }->operator ne $self->operator;
        }
        $this_expr .= '( ' if $add_parens;
        $this_expr .= $self->{ 'lexpr' }->as_text;
        $this_expr .= ' )' if $add_parens;
        push @parts, $this_expr;
    }

    push @parts, $self->operator;

    if ( exists $self->{ 'rexpr' } ) {
        my $this_expr  = '';
        my $add_parens = 0;
        if ( $self->{ 'rexpr' }->isa( 'Pg::SQL::PrettyPrinter::Node::A_Expr' ) ) {
            $add_parens = 1 if $self->{ 'rexpr' }->operator ne $self->operator;
        }
        $this_expr .= '( ' if $add_parens;
        $this_expr .= $self->{ 'rexpr' }->as_text;
        $this_expr .= ' )' if $add_parens;
        push @parts, $this_expr;
    }

    return join( ' ', @parts );
}

sub pretty_print {
    my $self = shift;
    if ( $self->{ 'kind' } eq 'AEXPR_IN' ) {
        return sprintf(
            '%s IN %s',
            $self->{ 'lexpr' }->pretty_print,
            $self->{ 'rexpr' }->pretty_print
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_OP_ANY' ) {
        return sprintf(
            '%s %s ANY( %s )',
            $self->{ 'lexpr' }->pretty_print,
            $self->operator,
            $self->{ 'rexpr' }->pretty_print
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_OP_ALL' ) {
        return sprintf(
            '%s %s ALL( %s )',
            $self->{ 'lexpr' }->pretty_print,
            $self->operator,
            $self->{ 'rexpr' }->pretty_print
        );
    }
    elsif ( any { $_ eq $self->{ 'kind' } } qw( AEXPR_BETWEEN AEXPR_NOT_BETWEEN AEXPR_BETWEEN_SYM AEXPR_NOT_BETWEEN_SYM ) ) {
        return sprintf(
            '%s %s %s AND %s',
            $self->{ 'lexpr' }->pretty_print,
            $self->operator,
            $self->{ 'rexpr' }->{ 'items' }->[ 0 ]->pretty_print,
            $self->{ 'rexpr' }->{ 'items' }->[ 1 ]->pretty_print,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_DISTINCT' ) {
        return sprintf(
            '%s IS DISTINCT FROM %s',
            $self->{ 'lexpr' }->pretty_print,
            $self->{ 'rexpr' }->pretty_print,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_NOT_DISTINCT' ) {
        return sprintf(
            '%s IS NOT DISTINCT FROM %s',
            $self->{ 'lexpr' }->pretty_print,
            $self->{ 'rexpr' }->pretty_print,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_LIKE' ) {
        return sprintf(
            '%s LIKE %s',
            $self->{ 'lexpr' }->pretty_print,
            $self->{ 'rexpr' }->pretty_print,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_NULLIF' ) {
        return sprintf(
            'NULLIF( %s, %s )',
            $self->{ 'lexpr' }->pretty_print,
            $self->{ 'rexpr' }->pretty_print,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_ILIKE' ) {
        return sprintf(
            '%s ILIKE %s',
            $self->{ 'lexpr' }->pretty_print,
            $self->{ 'rexpr' }->pretty_print,
        );
    }
    elsif ( $self->{ 'kind' } eq 'AEXPR_SIMILAR' ) {
        my $right_side;
        if (   ( $self->{ 'rexpr' }->isa( 'Pg::SQL::PrettyPrinter::Node::FuncCall' ) )
            && ( $self->{ 'rexpr' }->func_name eq 'pg_catalog.similar_to_escape' )
            && ( 1 == scalar @{ $self->{ 'rexpr' }->{ 'args' } } ) )
        {
            $right_side = $self->{ 'rexpr' }->{ 'args' }->[ 0 ]->pretty_print;
        }
        else {
            $right_side = $self->{ 'rexpr' }->pretty_print;
        }
        return sprintf(
            '%s SIMILAR TO %s',
            $self->{ 'lexpr' }->pretty_print,
            $right_side,
        );
    }

    my @parts = ();
    if ( exists $self->{ 'lexpr' } ) {
        my $this_expr  = '';
        my $add_parens = 0;
        if ( $self->{ 'lexpr' }->isa( 'Pg::SQL::PrettyPrinter::Node::A_Expr' ) ) {
            $add_parens = 1 if $self->{ 'lexpr' }->operator ne $self->operator;
        }
        $this_expr .= '( ' if $add_parens;
        $this_expr .= $self->{ 'lexpr' }->pretty_print;
        $this_expr .= ' )' if $add_parens;
        push @parts, $this_expr;
    }

    push @parts, $self->operator;

    if ( exists $self->{ 'rexpr' } ) {
        my $this_expr  = '';
        my $add_parens = 0;
        if ( $self->{ 'rexpr' }->isa( 'Pg::SQL::PrettyPrinter::Node::A_Expr' ) ) {
            $add_parens = 1 if $self->{ 'rexpr' }->operator ne $self->operator;
        }
        $this_expr .= '( ' if $add_parens;
        $this_expr .= $self->{ 'rexpr' }->pretty_print;
        $this_expr .= ' )' if $add_parens;
        push @parts, $this_expr;
    }

    return join( ' ', @parts );
}

1;
