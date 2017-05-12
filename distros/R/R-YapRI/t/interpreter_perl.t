#!/usr/bin/perl

=head1 NAME

  interpreter_perl.t
  A piece of code to test the R::YapRI::Interpreter::Perl

=cut

=head1 SYNOPSIS

 perl interpreter_perl.t
 prove interpreter_perl.t

=head1 DESCRIPTION

 Test R::YapRI::Interpreter::Perl

=cut

=head1 AUTHORS

 Aureliano Bombarely
 (aurebg@vt.edu)

=cut

use strict;
use warnings;
use autodie;

use Data::Dumper;
use Test::More;
use Test::Exception tests => 29;
use Test::Warn;

use Math::BigInt;

use FindBin;
use lib "$FindBin::Bin/../lib";


## TEST 1

BEGIN {
    use_ok('R::YapRI::Interpreter::Perl', 'r_var');
}


## Check interpreter function, r_var, TEST 2 to 28

my %r_p_vars = (
    '1'                          => 1,
    '-1.23'                      => '-1.23',
    '"word"'                     => 'word',
    '"mix%(4)"'                  => 'mix%(4)',
    'c(2, 4)'                    => [2, 4],
    'c(-1.2, -4)'                => ['-1.2', '-4'],
    'TRUE'                       => 'TRUE',
    'FALSE'                      => 'FALSE', 
    'NULL'                       => undef, 
    'NA'                         => '',
    'c(TRUE, FALSE)'             => ['TRUE', 'FALSE'],
    'c(NA, NULL)'                => ['', undef],
    'x'                          => { x => undef },
    'z'                          => { z => '' },
    'mx = 2'                     => { '' => { mx => 2 } },
    'tx = c(2, 3)'               => { '' => { tx => [2, 3] } },
    'log(2)'                     => { log => 2 },
    'log(2, base = 10)'          => { log => [2, { base => 10 }]},
    't(x)'                       => { t => {x => '' } },
    'plot(x, main = "A")'        => { plot => [ { x => ''}, { main => "A" } ] },
    'rnorm(b, mean = 0, sd = 1)' => 
       { rnorm => { b => undef, mean => 0, sd => 1 } },
    'pie(c(10, 2, 3), labels = c("A", "B", "C"))' => 
       { pie => [ [10, 2, 3], { labels => ['A', 'B', 'C'] } ] },
    'bmp(filename = "test"); plot(x)' =>
       { bmp => { filename => 'test' }, plot => { x => '' } },

    );

foreach my $rvar (keys %r_p_vars) {
    is(r_var($r_p_vars{$rvar}), $rvar, 
	"testing r_var function for $rvar, checking R string")
	or diag("Looks like this has failed");
}


## Check the croak for this functions:

## Create a simple object to test that it is not hash ref

my $tobj = Math::BigInt->new('text');

throws_ok  { r_var($tobj) } qr/ERROR: NaN/, 
    'TESTING DIE ERROR when var supplied isnt scalar or ref. for r_var()';

throws_ok  { r_var({ b => $tobj }) } qr/ERROR: NaN/, 
    'TESTING DIE ERROR when var arg. supplied isnt scalar or ref. for r_var() ';

throws_ok  { R::YapRI::Interpreter::Perl::_rvar_arg({ b => $tobj }) } qr/No p/, 
    'TESTING DIE ERROR when arg. supplied isnt scalar or ref. for rvar_arg() ';

throws_ok  { R::YapRI::Interpreter::Perl::_rvar_vector('fake') } qr/ERROR: fa/, 
    'TESTING DIE ERROR when arg. supplied to _rvar_vector isnt ARRAYREF.';

throws_ok  { R::YapRI::Interpreter::Perl::_rvar_noref({}) } qr/ERROR: HASH/, 
    'TESTING DIE ERROR when arg. supplied to _rvar_noref is a REF.';



  
####
1; #
####
