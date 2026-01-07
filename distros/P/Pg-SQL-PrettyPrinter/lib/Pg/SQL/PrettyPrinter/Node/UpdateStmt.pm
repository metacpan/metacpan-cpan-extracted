package Pg::SQL::PrettyPrinter::Node::UpdateStmt;

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
        qw( targetList whereClause fromClause returningList ),
        [ 'withClause', 'ctes' ],
    );

    $self->build_set_array();

    return $self;
}

sub build_set_array {
    my $self       = shift;
    my @set        = ();
    my $multi_join = 0;

    for my $item ( @{ $self->{ 'targetList' } } ) {
        my $column = $item->{ 'name' };
        if ( $multi_join > 0 ) {
            push @{ $set[ -1 ]->{ 'cols' } }, $column;
            $multi_join--;
            next;
        }
        my $val = $item->{ 'val' };
        if ( 'Pg::SQL::PrettyPrinter::Node::MultiAssignRef' eq ref $val ) {
            push @set, { 'cols' => [ $column ], 'val' => $val->{ 'source' } };
            $multi_join = $val->{ 'ncolumns' } - 1;
        }
        else {
            push @set, { 'col' => $column, 'val' => $val };
        }
    }
    $self->{ '_set' } = \@set;
}

sub as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'UPDATE';
    push @elements, $self->relname;
    push @elements, 'SET';
    my @set_elements = ();
    for my $item ( @{ $self->{ '_set' } } ) {
        if ( exists $item->{ 'col' } ) {
            push @set_elements, sprintf '%s = %s', $self->quote_ident( $item->{ 'col' } ), $item->{ 'val' }->as_text;
        }
        else {
            push @set_elements, sprintf(
                '( %s ) = %s',
                join( ', ', @{ $item->{ 'cols' } } ),
                $item->{ 'val' }->as_text
            );
        }
    }
    push @elements, join( ', ', @set_elements );
    if ( exists $self->{ 'fromClause' } ) {
        push @elements, 'FROM';
        push @elements, join( ', ', map { $_->as_text } @{ $self->{ 'fromClause' } } );
    }
    if ( exists $self->{ 'whereClause' } ) {
        push @elements, 'WHERE';
        push @elements, $self->{ 'whereClause' }->as_text;
    }
    if ( exists $self->{ 'returningList' } ) {
        push @elements, 'RETURNING';
        push @elements, join( ', ', map { $_->as_text } @{ $self->{ 'returningList' } } );
    }
    my $prefix = '';
    if ( exists $self->{ 'withClause' } ) {
        $prefix = 'WITH ';
        $prefix .= 'RECURSIVE ' if $self->{ 'withClause' }->{ 'recursive' };
        $prefix .= join( ', ', map { $_->as_text } @{ $self->{ 'withClause' }->{ 'ctes' } } ) . ' ';
    }
    return $prefix . join( ' ', @elements );
}

sub pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'UPDATE ' . $self->relname;
    push @lines, 'SET';
    for my $item ( @{ $self->{ '_set' } } ) {
        if ( exists $item->{ 'col' } ) {
            push @lines, $self->increase_indent(
                sprintf(
                    '%s = %s,',
                    $self->quote_ident( $item->{ 'col' } ),
                    $item->{ 'val' }->pretty_print
                )
            );
        }
        else {
            push @lines, $self->increase_indent(
                sprintf(
                    '( %s ) = %s,',
                    join( ', ', @{ $item->{ 'cols' } } ),
                    $item->{ 'val' }->pretty_print
                )
            );
        }
    }

    # Remove unnecessary trailing , in last element
    $lines[ -1 ] =~ s/,\z//;

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

    if ( exists $self->{ 'returningList' } ) {
        push @lines, 'RETURNING ';
        $lines[ -1 ] .= join( ', ', map { $_->pretty_print } @{ $self->{ 'returningList' } } );
    }

    my $main_body = join( "\n", @lines );
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

    @lines = ();
    push @lines, join( ' ', @cte_def );
    push @lines, $main_body;
    return join( "\n", @lines );
}

sub relname {
    my $self = shift;
    if ( !$self->{ '_relname' } ) {
        my $R        = $self->{ 'relation' };
        my @elements = map { $self->quote_ident( $R->{ $_ } ) }
            grep { exists $R->{ $_ } } qw{ catalogname schemaname relname };
        $self->{ '_relname' } = join( '.', @elements );
        if ( $R->{ 'alias' }->{ 'aliasname' } ) {
            $self->{ '_relname' } .= ' AS ' . $self->quote_ident( $R->{ 'alias' }->{ 'aliasname' } );
        }
    }
    return $self->{ '_relname' };
}

1;

# vim: set ft=perl:
