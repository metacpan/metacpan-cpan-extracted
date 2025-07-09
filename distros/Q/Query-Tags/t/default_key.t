use v5.16;
use Test::More;
use Query::Tags;

sub t {
    my ($q, $arg, $opts) = @_;
    Query::Tags->new($q, $opts)->test($arg)
}

# Default string key
my $defkey = { default_key => 'xuz' };
ok  t(q[bare] => { bare => 0, xuz => 'bare' }, $defkey);
ok  t(q[bare] => { bare => 1, xuz => 'bare' }, $defkey);
ok !t(q[bare] => { bare => 0, xuz => 'barefoot' }, $defkey);
ok !t(q[bare] => { bare => 1, xuz => 'barefoot' }, $defkey);
ok  t(q[/bare/] => { bare => 0, xuz => 'barefoot' }, $defkey);
ok  t(q[/bare/] => { bare => 1, xuz => 'barefoot' }, $defkey);

# Test side effects from coderef
my $i = 0;
my $side_effect = { default_key => sub{ $i++ } };
ok !t(q[bare] => { }, $side_effect);
is $i, 1;
ok  t(q[bare] => { }, $side_effect);
is $i, 2;

# Options should also be passed to coderef
my $opts = {
    default_key => sub {
        my ($obj, $val, $opts) = @_;
        $opts->{retval}
    },
    retval => 0,
};
ok !t(q[bare] => { }, $opts);
$opts->{retval}++;
ok  t(q[bare] => { }, $opts);

done_testing;
