use Test::More;
use Protocol::Star::Linemode;

{
    my $p = Protocol::Star::Linemode->new();
    $p->select_font(0);
    my $r = $p->result;
    is_deeply([unpack('CCCC', $r)], [0x1B, 0x1E, 0x46, 0]);
}

{
    my $p = Protocol::Star::Linemode->new();
    $p->text('hello world');
    my $r = $p->result;
    is($r, 'hello world');
}

done_testing();
