#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

use Test::More qw(no_plan);
#use Test::More tests => 44;

my $class;

BEGIN {
    $class = 'Rsync::Config';
    use_ok($class) or BAIL_OUT('RIP.');
}

for my $method (
    qw[modules modules_no add_module add_module_obj module_exists to_string to_file])
{
    eval { $class->$method };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
    eval {
        no strict 'refs';    ## no critic
        &{"${class}::${method}"}( bless {}, 'Foobar' );
    };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
}

my $rsync = Rsync::Config->new;
isa_ok( $rsync, $class );
isa_ok( $rsync, 'Rsync::Config::Module' );

eval { $rsync->add_module_obj(1); };
like ( $EVAL_ERROR->error, qr/module/, 'not a module obj' );
eval { $rsync->add_module_obj(new Rsync::Config::Atom(name => 'test', value => 1)); };
like ( $EVAL_ERROR->error, qr/module/, 'not a module obj' );

is( $rsync->atoms_no, 0, 'no atoms defined yet' );

my $main_atom = $rsync->add_atom( uid => 99 );
is( $rsync->atoms_no, 1, 'atom added' );
isa_ok( $main_atom, 'Rsync::Config::Atom' );

is( $rsync->modules_no, 0, 'no modules defined yet' );

my $module = $rsync->add_module(q{foo});
is( $rsync->modules_no, 1, 'module added' );
isa_ok( $module, 'Rsync::Config::Module' );

eval { $rsync->add_module_obj(new Rsync::Config::Module(name => 'foo')); };
like ( $EVAL_ERROR->error, qr/Already/, 'module already added');

my $module2 = $rsync->add_module(q{bar});
is( $rsync->modules_no, 2, 'module added' );
isa_ok( $module2, 'Rsync::Config::Module' );

my $atom = $module->add_atom( bar => 100 );
is( $module->atoms_no, 1, 'atom added' );
isa_ok( $atom, 'Rsync::Config::Atom' );

my $modules = $rsync->modules;
isa_ok( $modules, 'ARRAY', 'modules list' );
is( scalar @{$modules}, $rsync->modules_no, 'modules number' );
for ( @{$modules} ) {
    isa_ok( $_, 'Rsync::Config::Module' );
}
my @modules = $rsync->modules;
is_deeply( \@modules, $modules, 'modules in list context' );

eval { $rsync->add_module(q{foo}) };
isa_ok( $EVAL_ERROR, 'Rsync::Config::Exception' );
like( $EVAL_ERROR->error, qr/already have/i, 'proper exception' );

my $module3 = $rsync->add_module_obj(new Rsync::Config::Module(name => 'zaz'));
isa_ok($module3, 'Rsync::Config::Module');

is( $rsync, qq{uid = 99\n\t[foo]\n\t\tbar = 100\n\t[bar]\n[zaz]\n},
    'stringification' );

for ( undef, qw(x 1 2 main) ) {
    is( $rsync->module_exists($_), undef, 'module exists? no' );
}

eval { $rsync->to_file };
isa_ok( $EVAL_ERROR, 'Rsync::Config::Exception' );
like( $EVAL_ERROR->error, qr/filename/i, 'proper exception' );

eval { $rsync->to_file( rand(1999) . qq{/tmp/$$/} . time ) };
isa_ok( $EVAL_ERROR, 'Rsync::Config::Exception' );
like( $EVAL_ERROR->error, qr/cannot open/i, 'proper exception' );

my $tmpfile = q{foo.tmp};
is( $rsync->to_file($tmpfile), 1, 'file saved' );
is( -s $tmpfile, length $rsync->to_string, 'file saved successfully' );
unlink $tmpfile;
