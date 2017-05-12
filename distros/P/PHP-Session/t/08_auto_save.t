use PHP::Session;
use Test::More tests => 4;

local $^W = 1; # for 5.8 MakeMaker bug

my $warn;
$SIG{__WARN__} = sub { $warn .= "@_" };

{
    my $sess = PHP::Session->new("foobar", {
	save_path => 't', create => 1,
    });
    $sess->set(foo => 'foo');
}

like $warn, qr/PHP::Session: some keys are changed but not saved/, 'warnings';
undef $warn;


{
    my $sess = PHP::Session->new("foobar", {
	save_path => 't', create => 1,
    });
    $sess->set(foo => 'foo');
    $sess->save;
}

is $warn, undef, 'no warnings';

{
    my $sess = PHP::Session->new("foobar", {
	save_path => 't',
	auto_save => 1,
    });
    $sess->set(bar => 'baz');
}

is $warn, undef, 'no warnings here';

{
    my $sess = PHP::Session->new("foobar", {
	save_path => 't',
	auto_save => 1,
    });
    is $sess->get('bar'), 'baz', 'bar is baz: saved';
    $sess->destroy();
}
