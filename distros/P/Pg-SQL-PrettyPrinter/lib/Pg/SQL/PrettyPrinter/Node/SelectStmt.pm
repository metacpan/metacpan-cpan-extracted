package Pg::SQL::PrettyPrinter::Node::SelectStmt;

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

    $self->objectify(
        'valuesLists',
        [ 'withClause', 'ctes' ],
    );
    if ( $self->setop ) {
        $self->init_setop;
    }
    else {
        $self->init_plain;
    }

    return $self;
}

sub setop {
    my $self = shift;
    return if $self->{ 'op' } eq 'SETOP_NONE';
    my $op = $self->{ 'op' };
    $op =~ s/^SETOP_//;
    $op .= ' ALL' if $self->{ 'all' };
    return $op;
}

sub init_setop {
    my $self = shift;
    for my $element ( qw( rarg larg ) ) {
        $self->{ $element } = $self->make_from( { 'SelectStmt' => $self->{ $element } } );
    }
}

sub init_plain {
    my $self = shift;

    $self->objectify( qw( targetList fromClause whereClause groupClause havingClause sortClause limitCount limitOffset distinctClause lockingClause ) );
}

sub as_text {
    my $self = shift;
    if ( exists $self->{ 'valuesLists' } ) {
        return sprintf( 'VALUES %s', join( ', ', map { $_->as_text } @{ $self->{ 'valuesLists' } } ) );
    }
    my $prefix = '';
    if ( exists $self->{ 'withClause' } ) {
        $prefix = 'WITH ';
        $prefix .= 'RECURSIVE ' if $self->{ 'withClause' }->{ 'recursive' };
        $prefix .= join( ', ', map { $_->as_text } @{ $self->{ 'withClause' }->{ 'ctes' } } ) . ' ';
    }
    return $prefix . ( $self->{ 'op' } eq 'SETOP_NONE' ? $self->as_text_plain : $self->as_text_setop );
}

sub as_text_setop {
    my $self     = shift;
    my @elements = ();
    if ( ( $self->{ 'larg' }->setop // '' ) eq $self->setop ) {
        push @elements, $self->{ 'larg' }->as_text;
    }
    else {
        push @elements, '(', $self->{ 'larg' }->as_text, ')';
    }
    push @elements, $self->setop;
    if ( ( $self->{ 'rarg' }->setop // '' ) eq $self->setop ) {
        push @elements, $self->{ 'rarg' }->as_text;
    }
    else {
        push @elements, '(', $self->{ 'rarg' }->as_text, ')';
    }
    return join( " ", @elements );
}

sub as_text_plain {
    my $self  = shift;
    my $query = 'SELECT ';
    if ( exists $self->{ 'distinctClause' } ) {
        if ( 0 == scalar @{ $self->{ 'distinctClause' } } ) {
            $query .= 'DISTINCT ';
        }
        else {
            $query .= sprintf(
                'DISTINCT ON ( %s ) ',
                join( ', ', map { $_->as_text } @{ $self->{ 'distinctClause' } } )
            );
        }
    }
    $query .= join( ', ', map { $_->as_text } @{ $self->{ 'targetList' } } );
    if ( exists $self->{ 'fromClause' } ) {
        $query .= ' FROM ' . join( ', ', map { $_->as_text } @{ $self->{ 'fromClause' } } );
    }
    if ( exists $self->{ 'whereClause' } ) {
        $query .= ' WHERE ' . $self->{ 'whereClause' }->as_text;
    }
    if ( exists $self->{ 'groupClause' } ) {
        $query .= ' GROUP BY ' . join( ', ', map { $_->as_text } @{ $self->{ 'groupClause' } } );
    }
    if ( exists $self->{ 'havingClause' } ) {
        $query .= ' HAVING ' . $self->{ 'havingClause' }->as_text;
    }
    if ( exists $self->{ 'sortClause' } ) {
        $query .= ' ORDER BY ' . join( ', ', map { $_->as_text } @{ $self->{ 'sortClause' } } );
    }
    if ( exists $self->{ 'limitCount' } ) {
        $query .= ' LIMIT ' . $self->{ 'limitCount' }->as_text;
    }
    if ( exists $self->{ 'limitOffset' } ) {
        $query .= ' OFFSET ' . $self->{ 'limitOffset' }->as_text;
    }
    if ( exists $self->{ 'lockingClause' } ) {
        $query .= ' ' . join(
            ' ',
            map { $_->as_text } @{ $self->{ 'lockingClause' } }
        );
    }
    return $query;
}

sub pretty_print {
    my $self = shift;
    if ( exists $self->{ 'valuesLists' } ) {
        my @lines = ();
        push @lines, 'VALUES';
        push @lines, map { $self->increase_indent( $_->as_text ) . ',' } @{ $self->{ 'valuesLists' } };

        # Remove unnecessary trailing , in last element
        $lines[ -1 ] =~ s/,\z//;
        return join( "\n", @lines );
    }

    my $main_body = $self->{ 'op' } eq 'SETOP_NONE' ? $self->pretty_print_plain : $self->pretty_print_setop;
    return $main_body unless exists $self->{ 'withClause' };

    my @cte_def = ();

    push @cte_def, map { $_->pretty_print . ',' } @{ $self->{ 'withClause' }->{ 'ctes' } };

    # Remove unnecessary trailing , in last element
    $cte_def[ -1 ] =~ s/,\z//;
    if ( $self->{ 'withClause' }->{ 'recursive' } ) {
        $cte_def[ 0 ] = 'WITH RECURSIVE ' . $cte_def[ 0 ];
    }
    else {
        $cte_def[ 0 ] = 'WITH ' . $cte_def[ 0 ];
    }

    my @lines = ();
    push @lines, join( ' ', @cte_def );
    push @lines, $main_body;
    return join( "\n", @lines );
}

sub pretty_print_setop {
    my $self     = shift;
    my @elements = ();
    if ( ( $self->{ 'larg' }->setop // '' ) eq $self->setop ) {
        push @elements, $self->{ 'larg' }->pretty_print;
    }
    else {
        push @elements, '(';
        push @elements, $self->increase_indent( $self->{ 'larg' }->pretty_print );
        push @elements, ')';
    }
    push @elements, $self->setop;
    if ( ( $self->{ 'rarg' }->setop // '' ) eq $self->setop ) {
        push @elements, $self->{ 'rarg' }->pretty_print;
    }
    else {
        push @elements, '(';
        push @elements, $self->increase_indent( $self->{ 'rarg' }->pretty_print );
        push @elements, ')';
    }
    return join( "\n", @elements );
}

sub pretty_print_plain {
    my $self  = shift;
    my @lines = ( 'SELECT' );

    if ( exists $self->{ 'distinctClause' } ) {
        if ( 0 == scalar @{ $self->{ 'distinctClause' } } ) {
            $lines[ 0 ] .= ' DISTINCT';
        }
        else {
            push @lines, sprintf(
                $self->increase_indent( 'DISTINCT ON ( %s )' ),
                join( ', ', map { $_->pretty_print } @{ $self->{ 'distinctClause' } } )
            );
        }
    }

    for my $i ( 0 .. $#{ $self->{ 'targetList' } } ) {
        my $is_last = $i == $#{ $self->{ 'targetList' } };
        my $target  = $self->{ 'targetList' }->[ $i ];
        my $pretty  = $self->increase_indent( $target->pretty_print() );
        $pretty .= ',' unless $is_last;
        push @lines, $pretty;
    }
    if ( exists $self->{ 'fromClause' } ) {
        push @lines, 'FROM';
        push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'fromClause' } };

        # Remove unnecessary trailing , in last element
        $lines[ -1 ] =~ s/,\z//;
    }
    if ( exists $self->{ 'whereClause' } ) {
        push @lines, 'WHERE';
        push @lines, $self->increase_indent( $self->{ 'whereClause' }->pretty_print );
    }
    if ( exists $self->{ 'groupClause' } ) {
        push @lines, 'GROUP BY';
        push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'groupClause' } };

        # Remove unnecessary trailing , in last element
        $lines[ -1 ] =~ s/,\z//;
    }
    if ( exists $self->{ 'havingClause' } ) {
        push @lines, 'HAVING';
        push @lines, $self->increase_indent( $self->{ 'havingClause' }->pretty_print );
    }
    if ( exists $self->{ 'sortClause' } ) {
        push @lines, 'ORDER BY';
        push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'sortClause' } };

        # Remove unnecessary trailing , in last element
        $lines[ -1 ] =~ s/,\z//;
    }

    if ( exists $self->{ 'limitCount' } ) {
        push @lines, 'LIMIT ' . $self->{ 'limitCount' }->pretty_print;
    }
    if ( exists $self->{ 'limitOffset' } ) {
        push @lines, 'OFFSET ' . $self->{ 'limitOffset' }->pretty_print;
    }
    if ( exists $self->{ 'lockingClause' } ) {
        push @lines, map { $_->pretty_print } @{ $self->{ 'lockingClause' } };
    }

    return join( "\n", @lines );
}

1;
