
BEGIN {
    use FindBin qw($Bin);
    require "$Bin/test.pl";
    plan(tests => 8);
}

use Regexp::Fields;

#
# keys
#

my $rx = qr/(?<x>.)(?<y>.)(?<z>.)/;

"xyz" =~ /$rx/;
is keys %{&}, 3, 'keys %{&} == 3';


#
# each
#
$k = each %{&};
ok $k, 'each works';

"xyz" =~ /^$/;
ok $k, '$k valid after intervening failed regex';

"xyz" =~ /$rx/;
while (each %{&}) { $count++ }

is $count, 2, 'new match doesn\'t reset the iterator';

#
# read-only
#

my @a = 1..3;

readonly sub{ %{&} = @a },   '%{&} = @a       [read-only]';
readonly sub{ @&{@a} = @a }, '@&{@a} = @a     [read-only]';
readonly sub{ $&{bar}++ },   '$&{bar}++ fails [read-only]';
readonly sub{ undef %{&} },  'undef %{&}      [read-only]';

