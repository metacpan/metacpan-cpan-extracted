#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

#use Test::More qw(no_plan);
use Test::More tests => 99;

my $class;

BEGIN {
    $class = 'Rsync::Config::Renderer';
    use_ok($class) or BAIL_OUT('RIP.');
}

# default options
my %defaults = $class->_default_options;
is_deeply(
    \%defaults,
    { indent => 0, indent_char => "\t" },
    'default options'
);

# valid indent values
for my $indent ( 0, 9, 99, 999, 9999 ) {
    is( $class->_valid_indent($indent), $indent, 'valid indent value' );
}

# invalid indent values
for my $indent ( undef, q{}, q{foo}, 1.1, -1 ) {
    my $ret = eval { $class->_valid_indent($indent) };
    is( $ret, undef, 'invalid indent value' );
}

# valid indent char values
for my $indent_char ( 0, q{ }, q{a}, q{foo} ) {
    is( $class->_valid_indent_char($indent_char),
        $indent_char, 'valid indent_char value' );
}

# invalid indent_char values
for my $indent_char ( undef, q{} ) {
    my $ret = eval { $class->_valid_indent_char($indent_char) };
    is( $ret, undef, 'invalid indent_char value' );
}

# default renderer object
my $render = eval { $class->new };
isa_ok( $render, $class )
    or BAIL_OUT("Cannot create $class object: $EVAL_ERROR");
while ( my ( $opt, $value ) = each %defaults ) {
    is( $render->$opt, $value, "default options applied ($opt)" );
}

# custom renderer object
my %custom = map { $_ => q{1} . $defaults{$_} } keys %defaults;
my $custom = eval { $class->new(%custom) };
isa_ok( $custom, $class )
    or BAIL_OUT("Cannot create $class object: $EVAL_ERROR");
while ( my ( $opt, $value ) = each %custom ) {
    is( $custom->$opt, $value, "custom options applied ($opt)" );
}

# accessors as class methods
while ( my ( $opt, $value ) = each %defaults ) {
    is( $class->$opt, $value, "class method: $opt (accessor)" );
    is( $class->$opt( q{1} . $value ),
        $value, "class method: $opt (mutator - silent deny)" );
}

# chaining mutators
while ( my ( $opt, $value ) = each %defaults ) {
    is( ref $render->$opt($value), $class, "$opt mutator" );
}

# indent string
for my $args ( [], [0], [3], [ 2, 'a' ], [ 12, q{#} ] ) {
    for my $renderer ( $render, $custom, $class ) {
        my @args = ();
        my ( $mult, $char ) = @{$args};
        if ( defined $mult ) {
            push @args, $mult;
        }
        else {
            $mult = $renderer->indent;
        }
        if ( defined $char ) {
            push @args, $char;
        }
        else {
            $char = $renderer->indent_char;
        }
        is( $renderer->indent_string(@args), $char x $mult, 'indent_string' );
    }
}

# rendering
my @lines = ( 'foo bar', q{}, 123 );
for my $opt (
    {},
    { indent => 0 },
    { indent => 0, prefix => q{[} },
    { indent => 0, suffix => q{]} },
    { indent => 0, prefix => q{[}, suffix => q{]} },
    { indent => 3, indent_char => q{#} },
    { indent => 3, indent_char => q{#}, prefix => q{[} },
    { indent => 3, indent_char => q{#}, suffix => q{]} },
    { indent => 3, indent_char => q{#}, prefix => q{[}, suffix => q{]} },
    )
{
    my $prefix = exists $opt->{prefix} ? $opt->{prefix} : q{};
    my $suffix = exists $opt->{suffix} ? $opt->{suffix} : "\n";
    for my $renderer ( $render, $custom, $class ) {
        my @iargs = ();
        for my $iarg (qw(indent indent_char)) {
            next if !exists $opt->{$iarg};
            push @iargs, $opt->{$iarg};
        }
        my $istr = $renderer->indent_string(@iargs);
        my $to_get = join q{}, map { $istr . $prefix . $_ . $suffix } @lines;
        my @got_list = $renderer->render( @lines, $opt );
        my $got_scalar = $renderer->render( @lines, $opt );
        is( join( q{}, @got_list ), $to_get, 'rendering (list)' );
        is( $got_scalar, $to_get, 'rendering (scalar)' );
    }
}
