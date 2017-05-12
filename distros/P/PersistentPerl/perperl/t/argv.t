
# Bug in 2.11 - argv is split on whitespace when it shouldn't be
# Also do a basic argv test

print "1..4\n";

my $cmd = "$ENV{PERPERL} t/scripts/basic.1";
my @list;

sub evaluate {
    if ($_[0]) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
}

# Basic test
@list = `$cmd 1 2`;
chomp @list;
&evaluate($list[0] eq '1' && $list[1] eq '2');

# Test for split failure
@list = `$cmd "1 2"`;
chomp @list;
&evaluate($list[0] eq '1 2');

# Test for an argv starting with "-" just in case that triggers a bug
@list = `$cmd "-x"`;
chomp @list;
&evaluate($list[0] eq '-x');

# Test for complicated options
@list = `$ENV{PERPERL} -w -- -t5 -r300 t/scripts/basic.1 -x 1`;
chomp @list;
&evaluate($list[0] eq '-x' && $list[1] eq '1');
