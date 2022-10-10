package Pg::SQL::PrettyPrinter::Node::InsertStmt;

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

    $self->objectify(
        qw( selectStmt cols returningList ),
        [ 'withClause', 'ctes' ],
    );

    if ( exists $self->{ 'onConflictClause' } ) {
        croak( 'Unsupported conflict action: ' . $self->{ 'onConflictClause' }->{ 'action' } ) unless $self->{ 'onConflictClause' }->{ 'action' } =~ m{\AONCONFLICT_(?:NOTHING|UPDATE)\z};
        $self->objectify(
            [ qw{ onConflictClause infer indexElems } ],
            [ qw{ onConflictClause targetList } ],
            [ qw{ onConflictClause whereClause } ],
        );
        $self->build_set_array();
    }

    return $self;
}

sub relname {
    my $self = shift;
    if ( !$self->{ '_relname' } ) {
        my $R = $self->{ 'relation' };
        my @elements = map { $self->quote_ident( $R->{ $_ } ) }
            grep { exists $R->{ $_ } } qw{ catalogname schemaname relname };
        $self->{ '_relname' } = join( '.', @elements );
    }
    return $self->{ '_relname' };
}

sub as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'INSERT INTO';
    push @elements, $self->relname;
    if ( exists $self->{ 'cols' } ) {
        push @elements, '(';
        push @elements, join( ', ', map { $_->as_text } @{ $self->{ 'cols' } } );
        push @elements, ')';
    }
    push @elements, $self->{ 'selectStmt' }->as_text;
    my $prefix = '';
    if ( exists $self->{ 'withClause' } ) {
        $prefix = 'WITH ';
        $prefix .= 'RECURSIVE ' if $self->{ 'withClause' }->{ 'recursive' };
        $prefix .= join( ', ', map { $_->as_text } @{ $self->{ 'withClause' }->{ 'ctes' } } ) . ' ';
    }
    push @elements, $self->conflict_handling();
    if ( exists $self->{ 'returningList' } ) {
        push @elements, 'RETURNING';
        push @elements, join( ', ', map { $_->as_text } @{ $self->{ 'returningList' } } );
    }
    return $prefix . join( ' ', @elements );
}

sub pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'INSERT INTO ' . $self->relname;
    if ( exists $self->{ 'cols' } ) {
        $lines[ -1 ] .= ' ( ';
        $lines[ -1 ] .= join( ', ', map { $_->as_text } @{ $self->{ 'cols' } } );
        $lines[ -1 ] .= ' )';
    }
    push @lines, $self->increase_indent( $self->{ 'selectStmt' }->pretty_print );

    if ( exists $self->{ 'withClause' } ) {

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

        unshift @lines, join( ' ', @cte_def );
    }

    push @lines, map { $self->increase_indent( $_ ) } $self->conflict_handling( 1 );

    if ( exists $self->{ 'returningList' } ) {
        push @lines, $self->increase_indent( 'RETURNING ' );
        $lines[ -1 ] .= join( ', ', map { $_->as_text } @{ $self->{ 'returningList' } } );
    }

    return join( "\n", @lines );
}

sub conflict_handling {
    my $self   = shift;
    my $indent = shift // '';
    return unless exists $self->{ 'onConflictClause' };

    my @lines = ();
    my $C     = $self->{ 'onConflictClause' };
    my $A     = $self->{ 'onConflictClause' }->{ 'action' };
    push @lines, 'ON CONFLICT';
    if ( $C->{ 'infer' } ) {
        my $I = $C->{ 'infer' };
        if ( exists $I->{ 'conname' } ) {
            $lines[ -1 ] .= ' ON CONSTRAINT ' . $self->quote_ident( $I->{ 'conname' } );
        }
        elsif ( exists $I->{ 'indexElems' } ) {
            $lines[ -1 ] .= sprintf ' ( %s )', join( ', ', map { $_->as_text } @{ $I->{ 'indexElems' } } );
        }
    }
    if ( $A eq 'ONCONFLICT_NOTHING' ) {
        $lines[ -1 ] .= ' DO NOTHING';
    }
    elsif ( $A eq 'ONCONFLICT_UPDATE' ) {
        $lines[ -1 ] .= ' DO UPDATE';
        push @lines, 'SET';
        for my $item ( @{ $C->{ '_set' } } ) {
            if ( exists $item->{ 'col' } ) {
                push @lines, sprintf(
                    '%s = %s,',
                    $self->quote_ident( $item->{ 'col' } ),
                    $item->{ 'val' }->pretty_print
                );
            }
            else {
                push @lines, sprintf(
                    '( %s ) = %s,',
                    join( ', ', @{ $item->{ 'cols' } } ),
                    $item->{ 'val' }->pretty_print
                );
            }
            $lines[ -1 ] = $self->increase_indent( $lines[ -1 ] ) if $indent;
        }

        # Remove tailing ,
        $lines[ -1 ] =~ s/,\z//;

        if ( exists $C->{ 'whereClause' } ) {
            push @lines, 'WHERE';
            if ( $indent ) {
                push @lines, $self->increase_indent( $C->{ 'whereClause' }->pretty_print() );
            }
            else {
                push @lines, $C->{ 'whereClause' }->as_text;
            }
        }
    }
    return @lines;
}

sub build_set_array {
    my $self = shift;
    my $C    = $self->{ 'onConflictClause' };
    return unless exists $C->{ 'targetList' };

    my @set        = ();
    my $multi_join = 0;

    for my $item ( @{ $C->{ 'targetList' } } ) {
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
    $C->{ '_set' } = \@set;
}

1;

# vim: set ft=perl:
