#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Test::Exception;
use File::Temp 'tempfile';
use SimpleFlow qw(task say2);

# Portability setup consistent with 01.t
my $PERL = qq{"$^X"};
sub perl_cmd { my $code = shift; return qq{$PERL -e "$code"} }

# --- 1. say2: Invalid Filehandle --------------------------------------------
dies_ok {
  say2('This should die', 'not_a_valid_filehandle');
} 'say2 dies when provided an invalid filehandle';

# --- 2. task(): Argument Parsing Branches -----------------------------------
# Test the elsif (@_ % 2 == 0) branch
my $t = task(cmd => perl_cmd('exit 0'), 'dry.run' => 1);
is($t->{'dry.run'}, 1, 'task() successfully parses a flat key/value list');

# Test the else (odd-length list) branch
dies_ok {
  task('cmd', perl_cmd('exit 0'), 'odd_arg_without_value');
} 'task() dies when given an odd-length flat list';

# --- 3. task(): Invalid Reference Types for Files ---------------------------
# input.files else { die ... } branch
dies_ok {
  task({ cmd => perl_cmd('exit 0'), 'input.files' => { bad => 'hash' } });
} 'task() dies when input.files is an unsupported reference type (HASH)';

# output.files else { die ... } branch
dies_ok {
  task({ cmd => perl_cmd('exit 0'), 'output.files' => { bad => 'hash' } });
} 'task() dies when output.files is an unsupported reference type (HASH)';

# --- 4. task(): Missing Scalar Input File -----------------------------------
# (01.t covered the ARRAY branch for missing input files, this hits the scalar branch)
dies_ok {
  task({ cmd => perl_cmd('exit 0'), 'input.files' => 'definitely_does_not_exist.txt' });
} 'task() dies when a scalar input.files does not exist';

# --- 5. task(): 0-Byte Output File Warning ----------------------------------
my (undef, $empty_out) = tempfile(UNLINK => 1, SUFFIX => '.empty');
my $warn_caught = 0;

# Temporarily trap warnings to verify the exact text is emitted
local $SIG{__WARN__} = sub {
  my $msg = shift;
  $warn_caught = 1 if $msg =~ /the above output files have 0 size/i;
};

$t = task(# Touch a file without writing data to it
  cmd            => qq{$PERL -e "open(my \\\$fh, '>', '$empty_out'); close \\\$fh;"},
  'output.files' => [$empty_out],
  overwrite      => 1,
  die            => 0
);

ok($warn_caught, 'task() triggers a warning when an output file is exactly 0 bytes');

done_testing();
