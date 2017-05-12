#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

use Test::More qw(no_plan);
#use Test::More tests => 42;

my $class;

BEGIN {
    $class = 'Rsync::Config::Module';
    use_ok($class) or BAIL_OUT('RIP.');
}

for my $method (
    qw[atoms atoms_no add_atom_obj add_atom add_blank add_comment name to_string]
    )
{
    eval { $class->$method };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
    eval {
        no strict 'refs';    ## no critic
        &{"${class}::${method}"}( bless {}, 'Foobar' );
    };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
}

for my $name ( undef, q{}, q{ } ) {
    eval { $class->new( name => $name ) };
    like( $EVAL_ERROR->error, qr/Invalid name/, 'no name?' );
}

my $module = $class->new( name => 'foo' );
isa_ok( $module, $class );
isa_ok( $module, 'Rsync::Config::Renderer' );

eval { $module->add_atom_obj(1); };
like( $EVAL_ERROR->error, qr/atom/, 'not an atom object');
eval { $module->add_atom_obj($module); };
like( $EVAL_ERROR->error, qr/atom/, 'not an atom object');

is( $module->name, 'foo', 'name: accessor' );
is( $module->name('bar'), 'bar', 'name: mutator' );

is( $module->atoms_no, 0, 'no atoms defined yet' );

my $blank = $module->add_blank();
is( $module->atoms_no, 1, 'blank added' );
isa_ok( $blank, 'Rsync::Config::Blank' );

my $comment = $module->add_comment(q{foo});
is( $module->atoms_no, 2, 'comment added' );
isa_ok( $comment, 'Rsync::Config::Comment' );

my $atom = $module->add_atom( foo => 100 );
is( $module->atoms_no, 3, 'atom added' );
isa_ok( $atom, 'Rsync::Config::Atom' );

$atom = $module->add_atom_obj(new Rsync::Config::Atom(name => 'uid', value => 'root'));
is( $module->atoms_no, 4, 'atom added' );
isa_ok( $atom, 'Rsync::Config::Atom' );

my $atoms = $module->atoms;
isa_ok( $atoms, 'ARRAY', 'atoms list' );
is( scalar @{$atoms}, $module->atoms_no, 'atoms number' );
for ( @{$atoms} ) {
    isa_ok( $_, 'Rsync::Config::Blank' );
}
my @atoms = $module->atoms;
is_deeply( \@atoms, $atoms, 'atoms in list context' );

is( $module, qq{[bar]\n\n# foo\nfoo = 100\nuid = root\n}, 'stringification' );

is( $class->indent_step, 1, '"indent_step" as class method' );
is( $module->indent_step(2)->indent_step, 2, 'changing "indent_step"' );
for my $step ( undef, q{}, q{ }, -1 ) {
    eval { $module->indent_step($step) };
    isnt( $EVAL_ERROR, q{}, 'invalid indent_step' );
}
