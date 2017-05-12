#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

use Test::More qw(no_plan);
#use Test::More tests => 42;

my $class;
my $test_file;

BEGIN {
    $class = 'Rsync::Config::Parser';
    $test_file = '/tmp/rsyncd.conf.test';
    unlink $test_file;
    use_ok($class) or BAIL_OUT('RIP.');
}

eval { $class->parse($test_file); };
like( $EVAL_ERROR->error, qr/Could not open/, 'exception when file does not exists' );

my ($conf, $module);
$conf = new Rsync::Config();
$conf->add_atom('uid', 'nobody');
$conf->add_blank();
$conf->add_comment('test comment');
$module = $conf->add_module('cpan');
$module->add_atom('path', '/var/ftp/pub/cpan.org/');
$module->add_atom('read only', 'yes');
$module->add_atom('test # ', '10');
$conf->to_file($test_file);

my $parser = new $class;
isa_ok($parser, 'Rsync::Config::Parser');
isa_ok($parser->eat_trail_spaces(1), 'Rsync::Config::Parser', '$self returned');

eval { $parser->eat_trail_spaces(-1); };
like( $EVAL_ERROR, qr/eat_trail_spaces/, 'error when using -1' );

eval { $parser->eat_trail_spaces('a'); };
like( $EVAL_ERROR, qr/eat_trail_spaces/, 'error when using "a"' );

eval { $parser->_valid_eat_trail_spaces(undef); };
like( $EVAL_ERROR, qr/eat_trail_spaces/, 'error when using undef' );

eval { $parser->_valid_eat_trail_spaces('a'); };
like( $EVAL_ERROR, qr/eat_trail_spaces/, 'error when using "a"' );


$conf = $parser->parse($test_file);
isa_ok($conf, 'Rsync::Config');

is($conf->atoms_no, 3, '3 atoms');

is($conf->modules_no, 1, 'one module');

isa_ok($conf->module_exists('cpan'), 'Rsync::Config::Module', 'can get a module');

$conf = $class->parse($test_file, { eat_trail_spaces => 1 });
$conf = $class->parse($test_file, { eat_trail_spaces => 0 });

unlink($test_file);
