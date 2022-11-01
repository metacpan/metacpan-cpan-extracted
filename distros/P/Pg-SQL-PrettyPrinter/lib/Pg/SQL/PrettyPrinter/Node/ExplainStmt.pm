package Pg::SQL::PrettyPrinter::Node::ExplainStmt;

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

    $self->objectify( qw( query options ) );

    if ( exists $self->{ 'options' } ) {
        $self->{ '_options' } = [ map { $_->as_text } @{ $self->{ 'options' } } ];
    }
    return $self;
}

sub as_text {
    my $self = shift;
    return 'EXPLAIN ' . $self->{ 'query' }->as_text unless exists $self->{ 'options' };
    my @elements = ();
    push @elements, 'EXPLAIN';
    if ( $self->has_complex_opts ) {
        push @elements, '(';
        push @elements, join( ', ', @{ $self->{ '_options' } } );
        push @elements, ')';
    }
    else {
        push @elements, map { uc $_ } @{ $self->{ '_options' } };
    }
    push @elements, $self->{ 'query' }->as_text;
    return join( ' ', @elements );
}

sub has_complex_opts {
    my $self = shift;
    return unless exists $self->{ '_options' };
    for my $key ( @{ $self->{ '_options' } } ) {
        return 1 unless $key =~ m{\A(?:analyze|verbose)\z};
    }
    return;
}

sub pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'EXPLAIN';
    if ( exists $self->{ 'options' } ) {
        if ( $self->has_complex_opts ) {
            $lines[ -1 ] .= ' (';
            push @lines, map { $self->increase_indent( $_ ) . ',' } @{ $self->{ '_options' } };

            # Remove unnecessary trailing , in last element
            $lines[ -1 ] =~ s/,\z//;
            push @lines, ')';
        }
        else {
            $lines[ -1 ] .= ' ' . join( ' ', map { uc $_ } @{ $self->{ '_options' } } );
        }
    }
    push @lines, $self->{ 'query' }->pretty_print;
    return join( "\n", @lines );
}

1;

# vim: set ft=perl:
