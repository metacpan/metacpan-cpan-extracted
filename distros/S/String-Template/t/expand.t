use strict;
use warnings;
use Test::More;
use String::Template;
use Time::Piece 1.17;

$ENV{TZ} = 'EST5EDT'; # override so test in local TZ will succeed

if($^O eq 'MSWin32') {
  # it would be nice to use POSIX for this
  # instead since that is a public interface
  # but of course Strawberry has borked it.
  Time::Piece::_tzset();
}

my @TestCases =
(
    {
        Name     => 'Simple, nothing replaced',
        Template => 'foo',
        Fields   => {},
        Correct  => 'foo'
    },
    {
        Name     => '1 replace',
        Template => '<foo>',
        Fields   => { foo => 12 },
        Correct  => '12'
    },
    {
        Name     => '1 replace, with whitespace',
        Template => '  <foo> ',
        Fields   => { foo => 12, ignored => 72},
        Correct  => '  12 '
    },
    {
        Name     => '2 replaces',
        Template => '  <foo>  <bar>',
        Fields   => { foo => 12, bar => 72},
        Correct  => '  12  72'
    },
    {
        Name     => 'Missing field',
        Template => '  <foo>  <bar>',
        Fields   => { foo => 12, ignored => 72},
        Correct  => '  12  '
    },
    {
        Name     => '2 replaces with sprintf format',
        Template => '  <foo>  <bar%04d>',
        Fields   => { foo => 12, bar => 72},
        Correct  => '  12  0072'
    },
    {
        Name     => '2 replaces with date format',
        Template => '  <foo>  <date:%Y-%m-%d> ',
        Fields   => { foo => 12, date => 'May 17, 2008'},
        Correct  => '  12  2008-05-17 '
    },
    {
        Name     => 'date format with :(local) and !(utc)',
        Template => 'local: <date:%Y-%m-%d %H:%M> utc: <date!%Y-%m-%d %H:%M>',
        Fields   => { date => '2008-02-27T17:57:00Z' },
        Correct  => 'local: 2008-02-27 12:57 utc: 2008-02-27 17:57'
    }
);

plan tests => scalar @TestCases;

foreach my $t (@TestCases)
{
    my $exp = expand_string($t->{Template}, $t->{Fields});

    is($exp, $t->{Correct}, $t->{Name});
}
