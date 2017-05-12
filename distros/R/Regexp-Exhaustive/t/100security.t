use Test::More tests => 2 + 2 + 2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

{
    package Regexp::Fake;
    our @ISA = 'Regexp';

    sub new { bless \ do { my $o = $_[1] } => $_[0] }

    use overload
        '""' => sub { ${$_[0]} },
        fallback => 1,
    ;
}
{
    my $str = 'abc';
    my $pat = '.';

    my $fake = Regexp::Fake::->new($pat);
    is("$fake", $pat);

    my @matches = exhaustive($str => $fake);
    is_deeply(\@matches, [qw/ a b c /]);
}
{
    my $str = 'abc';

    my $fake = Regexp::Fake::->new('(?{1})');
    is("$fake", '(?{1})');

    my $msg = "Eval-group not allowed at runtime";
    eval { exhaustive($str => $fake) };
    like($@, qr/\Q$msg/, $msg);
}
