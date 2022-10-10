package Pg::SQL::PrettyPrinter::Node::XmlExpr;

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

    our %is_op_ok = map { $_ => 1 } qw(
        IS_DOCUMENT
        IS_XMLELEMENT
        IS_XMLCONCAT
        IS_XMLFOREST
        IS_XMLPARSE
        IS_XMLPI
        IS_XMLROOT
    );

    croak( 'Unknown XML op: ' . $self->{ 'op' } )            unless $is_op_ok{ $self->{ 'op' } };
    croak( 'Unknown XML option: ' . $self->{ 'xmloption' } ) unless $self->{ 'xmloption' } =~ m{\AXMLOPTION_(DOCUMENT|CONTENT)\z};

    $self->objectify( qw( named_args args ) );

    return $self;
}

sub as_text {
    my $self = shift;
    return $self->element_as_text    if $self->{ 'op' } eq 'IS_XMLELEMENT';
    return $self->forest_as_text     if $self->{ 'op' } eq 'IS_XMLFOREST';
    return $self->parse_as_text      if $self->{ 'op' } eq 'IS_XMLPARSE';
    return $self->pi_as_text         if $self->{ 'op' } eq 'IS_XMLPI';
    return $self->root_as_text       if $self->{ 'op' } eq 'IS_XMLROOT';
    return $self->concat_as_text     if $self->{ 'op' } eq 'IS_XMLCONCAT';
    return $self->isdocument_as_text if $self->{ 'op' } eq 'IS_DOCUMENT';
}

sub pretty_print {
    my $self = shift;
    return $self->element_pretty_print    if $self->{ 'op' } eq 'IS_XMLELEMENT';
    return $self->forest_pretty_print     if $self->{ 'op' } eq 'IS_XMLFOREST';
    return $self->parse_pretty_print      if $self->{ 'op' } eq 'IS_XMLPARSE';
    return $self->pi_pretty_print         if $self->{ 'op' } eq 'IS_XMLPI';
    return $self->root_pretty_print       if $self->{ 'op' } eq 'IS_XMLROOT';
    return $self->concat_pretty_print     if $self->{ 'op' } eq 'IS_XMLCONCAT';
    return $self->isdocument_pretty_print if $self->{ 'op' } eq 'IS_DOCUMENT';
}

sub element_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLELEMENT(';
    push @elements, 'NAME', $self->quote_ident( $self->{ 'name' } );
    if ( exists $self->{ 'named_args' } ) {
        $elements[ -1 ] .= ',';
        push @elements, 'XMLATTRIBUTES(';
        push @elements, map { $_->as_text . ',' } @{ $self->{ 'named_args' } };
        $elements[ -1 ] =~ s/,\z//;
        push @elements, ')';
    }
    if ( exists $self->{ 'args' } ) {
        $elements[ -1 ] .= ',';
        push @elements, map { $_->as_text . ',' } @{ $self->{ 'args' } };
        $elements[ -1 ] =~ s/,\z//;
    }
    push @elements, ')';
    return join( ' ', @elements );
}

sub element_pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLELEMENT(';
    push @lines, $self->increase_indent( 'NAME ' . $self->quote_ident( $self->{ 'name' } ) );
    if ( exists $self->{ 'named_args' } ) {
        $lines[ -1 ] .= ',';
        push @lines, $self->increase_indent( 'XMLATTRIBUTES(' );
        push @lines, map { $self->increase_indent_n( 2, $_->pretty_print ) . ',' } @{ $self->{ 'named_args' } };
        $lines[ -1 ] =~ s/,\z//;
        push @lines, $self->increase_indent( ')' );
    }
    if ( exists $self->{ 'args' } ) {
        $lines[ -1 ] .= ',';
        push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'args' } };
        $lines[ -1 ] =~ s/,\z//;
    }
    push @lines, ')';
    return join( "\n", @lines );
}

sub concat_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLCONCAT(';
    push @elements, join( ', ', map { $_->as_text } @{ $self->{ 'args' } } );
    push @elements, ')';
    return join( ' ', @elements );
}

sub concat_pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLCONCAT(';
    push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'args' } };
    $lines[ -1 ] =~ s/,\z//;
    push @lines, ')';
    return join( "\n", @lines );
}

sub forest_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLFOREST(';
    push @elements, join( ', ', map { $_->as_text } @{ $self->{ 'named_args' } } );
    push @elements, ')';
    return join( ' ', @elements );
}

sub forest_pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLFOREST(';
    push @lines, map { $self->increase_indent( $_->pretty_print ) . ',' } @{ $self->{ 'named_args' } };
    $lines[ -1 ] =~ s/,\z//;
    push @lines, ')';
    return join( "\n", @lines );
}

sub parse_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLPARSE(';
    push @elements, $self->{ 'xmloption' };
    $elements[ -1 ] =~ s/^XMLOPTION_//;
    push @elements, $self->{ 'args' }->[ 0 ]->as_text;
    push @elements, ')';
    return join( ' ', @elements );
}

sub parse_pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLPARSE(';
    push @lines, $self->increase_indent( $self->{ 'xmloption' } );
    $lines[ -1 ] =~ s/^(\s+)XMLOPTION_/$1/;
    push @lines, $self->increase_indent( $self->{ 'args' }->[ 0 ]->pretty_print );
    push @lines, ')';
    return join( "\n", @lines );
}

sub pi_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLPI(';
    push @elements, 'NAME', $self->quote_ident( $self->{ 'name' } );
    if ( exists $self->{ 'args' } ) {
        $elements[ -1 ] .= ',';
        push @elements, $self->{ 'args' }->[ 0 ]->as_text;
    }
    push @elements, ')';
    return join( ' ', @elements );
}

sub pi_pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLPI(';
    push @lines, $self->increase_indent( 'NAME ' . $self->quote_ident( $self->{ 'name' } ) );
    if ( exists $self->{ 'args' } ) {
        $lines[ -1 ] .= ',';
        push @lines, $self->increase_indent( $self->{ 'args' }->[ 0 ]->pretty_print );
    }
    push @lines, ')';
    return join( "\n", @lines );
}

sub root_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, 'XMLROOT(';
    push @elements, $self->{ 'args' }->[ 0 ]->as_text . ',';
    my $ver = $self->{ 'args' }->[ 1 ]->as_text;
    $ver = 'NO VALUE' if $ver eq 'NULL';
    push @elements, 'VERSION', $ver;
    if ( $self->{ 'args' }->[ 2 ]->as_text != 3 ) {
        $elements[ -1 ] .= ',';
        my $val = { 2 => 'NO VALUE', 0 => 'YES', 1 => 'NO' };
        push @elements, 'STANDALONE', $val->{ $self->{ 'args' }->[ 2 ]->as_text };
    }
    push @elements, ')';
    return join( ' ', @elements );
}

sub root_pretty_print {
    my $self  = shift;
    my @lines = ();
    push @lines, 'XMLROOT(';
    push @lines, $self->increase_indent( $self->{ 'args' }->[ 0 ]->pretty_print ) . ',';
    my $ver = $self->{ 'args' }->[ 1 ]->pretty_print;
    $ver = 'NO VALUE' if $ver eq 'NULL';
    push @lines, $self->increase_indent( 'VERSION ' . $ver );
    if ( $self->{ 'args' }->[ 2 ]->as_text != 3 ) {
        $lines[ -1 ] .= ',';
        my $val = { 2 => 'NO VALUE', 0 => 'YES', 1 => 'NO' };
        push @lines, $self->increase_indent( 'STANDALONE ' . $val->{ $self->{ 'args' }->[ 2 ]->as_text } );
    }
    push @lines, ')';
    return join( "\n", @lines );
}

sub isdocument_as_text {
    my $self     = shift;
    my @elements = ();
    push @elements, $self->{ 'args' }->[ 0 ]->as_text;
    push @elements, 'IS DOCUMENT';
    return join( ' ', @elements );
}

sub isdocument_pretty_print {
    my $self     = shift;
    my @elements = ();
    push @elements, $self->{ 'args' }->[ 0 ]->pretty_print;
    push @elements, 'IS DOCUMENT';
    return join( ' ', @elements );
}

1;

# vim: set ft=perl:
