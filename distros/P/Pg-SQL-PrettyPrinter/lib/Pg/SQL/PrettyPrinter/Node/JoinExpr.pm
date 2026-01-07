package Pg::SQL::PrettyPrinter::Node::JoinExpr;

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

    $self->objectify( 'larg' );
    $self->objectify( 'rarg' );
    if ( $self->{ 'quals' } ) {
        $self->objectify( 'quals' );
    }
    if ( $self->{ 'usingClause' } ) {
        $self->objectify( 'usingClause' );
    }
    return $self;
}

sub join_type {
    my $self = shift;
    if ( !exists $self->{ '_join_type' } ) {
        my $join_type = $self->{ 'jointype' };
        $join_type =~ s/^JOIN_(.*)$/$1 JOIN/;
        $join_type              = 'JOIN'               if $join_type eq 'INNER JOIN';
        $join_type              = "CROSS ${join_type}" if ( !exists $self->{ 'quals' } ) && ( !exists $self->{ 'usingClause' } );
        $self->{ '_join_type' } = $join_type;
    }
    return $self->{ '_join_type' };
}

sub as_text {
    my $self = shift;

    my $join_cond = '';
    if ( $self->{ 'usingClause' } ) {
        $join_cond = 'USING ( ' . join( ', ', map { $_->as_ident } @{ $self->{ 'usingClause' } } ) . ' )';
    }
    elsif ( $self->{ 'quals' } ) {
        $join_cond = 'ON ' . $self->{ 'quals' }->as_text;
    }
    return sprintf '%s %s %s %s', $self->{ 'larg' }->as_text, $self->join_type, $self->{ 'rarg' }->as_text, $join_cond;
}

sub pretty_print {
    my $self = shift;

    my $join_cond = '';
    if ( $self->{ 'usingClause' } ) {
        $join_cond = 'USING ( ' . join( ', ', map { $_->as_ident } @{ $self->{ 'usingClause' } } ) . ' )';
    }
    elsif ( $self->{ 'quals' } ) {
        my $Q        = $self->{ 'quals' };
        my $q_text   = $Q->as_text;
        my $q_pretty = $Q->pretty_print;

        # If join condition is multiline, indent it in nicer way.
        if ( $q_pretty =~ /\n/ ) {
            $join_cond = sprintf( "ON\n%s", $self->increase_indent( $q_pretty ) );
        }
        else {
            $join_cond = 'ON ' . $q_pretty if $q_pretty !~ /\n/;
        }
    }
    return sprintf "%s\n%s %s %s", $self->{ 'larg' }->pretty_print, $self->join_type, $self->{ 'rarg' }->pretty_print, $join_cond;
}

1;
