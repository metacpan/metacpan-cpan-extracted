#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 10;
use Test::Builder;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

my $output;
ok my $php = PHP::Interpreter->new({
    OUTPUT => \$output,
    hash  => { one => 1, two => 2 },
    array => [1, 2, 3],
    code  => sub { 'hello' },
    fh    => *DATA,
}), 'Create new PHP interpreter with various symbols';

ok $php->eval(q/echo $hash['one'], ', ', $hash['two'];/), 'Access the hash';

is $output, '1, 2', 'Check the hash output';
$php->clear_output;

ok $php->eval(q/echo implode(', ', $array);/), 'Access the array';

is $output, '1, 2, 3', 'Check the array output';
$php->clear_output;

ok $php->eval(q/echo fread($fh, 100);/), 'Access the file handle';
TODO: {
    local $TODO = 'Globs not supported; use file handle objects instead';
    is $output, 'File handle output.', 'Check the file handle output';
    $php->clear_output;
}

ok $php->eval(q/echo $code->call();/), 'Execute the code'; # Maybe $code()?
is $output, 'hello', 'Check the code output';
$php->clear_output;

__DATA__
File handle output.
