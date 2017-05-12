use strict;
use warnings;
use Test::More 0.94 tests => 1;#2;
use String::Trim;

my $in = {
    "\none" => undef,
    'two'   => ' two',
    'three' => 'three ',
    ' four' => ' four ',
    'five'  => '  five  ',
};
my $out = {
    'one'   => undef,
    'two'   => 'two',
    'three' => 'three',
    'four'  => 'four',
    'five'  => 'five',
};

# subtest 'return' => sub {
    # plan tests => 1;
    # my %trimmed = trim(%$in);
    # is_deeply(\%trimmed, $out, 'trim(%hash) returns a trimmed hash OK');
# };

subtest 'in-place' => sub {
    TODO: {
        local $TODO = 'unimplemented';
        plan tests => 1;
        use Data::Dumper;
        # print STDERR Dumper $in;
        trim(%$in);
        # print STDERR Dumper $in;
        is_deeply($in, $out, 'trim(%hash) trims a hash in-place OK');
    }
};
