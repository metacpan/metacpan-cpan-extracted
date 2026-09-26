#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
require 5.010;
use feature 'say';
use Test::More;
use Test::Exception;
use File::Spec;
use FindBin ();
use lib File::Spec->catdir($FindBin::Bin, 'lib'); # t/lib: CaptureStd, the tests' capture {}
use CaptureStd 'capture';
use File::Temp 'tempfile';
use SimpleFlow qw(task say2);

# Portability setup consistent with 01.t
my $PERL = qq{"$^X"};
sub perl_cmd { my $code = shift; return qq{$PERL -e "$code"} }

# task() prints the result record, and dumps its arguments with "p" before it
# dies on a bad one -- by design, and on the terminal. Captured here so that a
# passing run of this file prints TAP and nothing else; see the fuller note in
# t/01.t. An exception still propagates, so dies_ok works through it.
sub quietly (&) {
  my $code = shift;
  my (undef, undef, @result) = capture { $code->() };
  return wantarray ? @result : $result[0];
}

# --- 1. say2: Invalid Filehandle --------------------------------------------
dies_ok {
  say2('This should die', 'not_a_valid_filehandle');
} 'say2 dies when provided an invalid filehandle';

# --- 2. task(): Argument Parsing Branches -----------------------------------
# Test the elsif (@_ % 2 == 0) branch
my $t = quietly { task(cmd => perl_cmd('exit 0'), 'dry.run' => 1) };
is($t->{'dry.run'}, 1, 'task() successfully parses a flat key/value list');

# Test the else (odd-length list) branch
dies_ok {
  task('cmd', perl_cmd('exit 0'), 'odd_arg_without_value');
} 'task() dies when given an odd-length flat list';

# --- 3. task(): Invalid Reference Types for Files ---------------------------
# input.files else { die ... } branch
dies_ok {
  quietly { task({ cmd => perl_cmd('exit 0'), 'input.files' => { bad => 'hash' } }) };
} 'task() dies when input.files is an unsupported reference type (HASH)';

# output.files else { die ... } branch
dies_ok {
  quietly { task({ cmd => perl_cmd('exit 0'), 'output.files' => { bad => 'hash' } }) };
} 'task() dies when output.files is an unsupported reference type (HASH)';

# --- 4. task(): Missing Scalar Input File -----------------------------------
# (01.t covered the ARRAY branch for missing input files, this hits the scalar branch)
dies_ok {
  quietly { task({ cmd => perl_cmd('exit 0'), 'input.files' => 'definitely_does_not_exist.txt' }) };
} 'task() dies when a scalar input.files does not exist';

# --- 5. task(): 0-Byte Output File Warning ----------------------------------
my (undef, $empty_out) = tempfile(UNLINK => 1, SUFFIX => '.empty');
my $warn_caught = 0;

# Temporarily trap warnings to verify the exact text is emitted
local $SIG{__WARN__} = sub {
  my $msg = shift;
  $warn_caught = 1 if $msg =~ /the above output files have 0 size/i;
};

$t = quietly { task(# Touch a file without writing data to it
  cmd            => qq{$PERL -e "open(my \\\$fh, '>', '$empty_out'); close \\\$fh;"},
  'output.files' => [$empty_out],
  overwrite      => 1,
  die            => 0
) };

ok($warn_caught, 'task() triggers a warning when an output file is exactly 0 bytes');

# --- 6. task(): a caller who had closed STDIN keeps it closed ---------------
# The command is run with fd 0 on the null device, which means saving the
# caller's STDIN and putting it back afterwards. A caller may legitimately have
# closed it, and there is then nothing to save: that branch closes fd 0 again
# rather than leaving the command's null device open behind it.
{
  my $saved;
  open $saved, '<&', \*STDIN or die "cannot save STDIN: $!"
    if defined fileno STDIN; # a smoker may already run us without one
  close STDIN if defined fileno STDIN; # closing a closed handle is a fatal warning here
  my $closed = quietly { task(cmd => perl_cmd('exit 0'), die => 0) };
  my $fd0_after = fileno STDIN;
  if (defined $saved) {
    open STDIN, '<&', $saved or die "cannot restore STDIN: $!";
    close $saved;
  }
  # the positive half first: an assertion about fd 0 afterwards would pass
  # just as well if the command had never run at all
  is($closed->{'exit'}, 0, 'a command still runs when the caller has closed STDIN');
  ok(!defined $fd0_after, 'STDIN is left closed, not holding the null device open');
}


done_testing();
