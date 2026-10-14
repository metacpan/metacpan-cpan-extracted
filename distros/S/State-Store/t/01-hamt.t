#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# What happens when HAMT is not what is needed. Each case is a child perl
# with a stand-in HAMT.pm ahead of the real one, since the table is resolved
# once, when the library loads, and this process has already loaded it.

my $dir = tempdir(CLEANUP => 1);
my @inc = map { "-I$_" } grep { !ref } @INC;

sub load_with {
    my ($body) = @_;
    open my $fh, '>', "$dir/HAMT.pm" or die "cannot write a stand-in HAMT.pm: $!";
    print {$fh} "package HAMT;\nour \$VERSION = '0.01';\n$body\n1;\n";
    close $fh;
    my $out = `"$^X" "-I$dir" @inc -e "require State::Store; print qq{loaded\\n}" 2>&1`;
    return ($? >> 8, $out);
}

my ($rc, $out) = load_with('die "no such thing\n";');
isnt($rc, 0, 'a HAMT that does not load stops the load');
like($out, qr/no such thing/, 'with HAMT\'s own error')
    or diag $out;
unlike($out, qr/^loaded$/m, 'and nothing after it runs');

($rc, $out) = load_with('sub _abi_ptr { 0 }');
isnt($rc, 0, 'a HAMT with no table stops the load');
like($out, qr/State::Store: HAMT did not hand over its C ABI/, 'saying so') or diag $out;

($rc, $out) = load_with('sub _abi_ptr { undef }');
isnt($rc, 0, 'as does one that hands over nothing');
like($out, qr/State::Store: HAMT did not hand over its C ABI/, 'saying so') or diag $out;

($rc, $out) = load_with('');
isnt($rc, 0, 'and one with no _abi_ptr at all');
like($out, qr/State::Store: cannot load HAMT: .*_abi_ptr/s, 'named in the error') or diag $out;

# A table from before the version this was built against: a block of memory
# whose first int, the version, is zero. Its address is read at the size of a
# pointer, which on a 32-bit perl with 64-bit integers is not the size of one.
($rc, $out) = load_with(<<'PERL');
our $table = pack('i', 0) . ("\0" x 4096);
sub _abi_ptr { unpack(length(pack('P', '')) == 8 ? 'Q' : 'L', pack('P', $table)) }
PERL
isnt($rc, 0, 'a HAMT whose table is too old stops the load');
like($out, qr/State::Store: HAMT's C ABI is version 0 and version \d+ or later is needed/,
     'saying which version it found and which it needs') or diag $out;

# And the control: the same child with no stand-in loads.
unlink "$dir/HAMT.pm";
$out = `"$^X" "-I$dir" @inc -e "require State::Store; print qq{loaded\\n}" 2>&1`;
is($? >> 8, 0, 'with the real HAMT the same child loads');
like($out, qr/^loaded$/m, 'and runs on') or diag $out;

done_testing;
