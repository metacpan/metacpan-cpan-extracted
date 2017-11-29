use 5.012;
use warnings;
use Test::More;
use Panda::Lib qw/clone fclone/;
use Test::Deep;
use Storable qw/dclone/;

my ($val, $copy);

#number IV
$val = 10;
$copy = clone($val);
$val++;
is($val, 11);
is($copy, 10);

#number NV
$val = 0.333;
$copy = clone($val);
$val++;
is($val, 1.333);
is($copy, 0.333);

#string
$val = "abcd";
$copy = clone($val);
substr($val, 0, 2, '');
is($val, 'cd');
is($copy, 'abcd');

#string + number IV
$val = 10;
$copy = "$val";
$copy = clone($val);
$val++;
is($val, 11);
is($copy, 10);

#string + number NV
$val = 0.333;
$copy = "$val";
$copy = clone($val);
$val++;
is($val, 1.333);
is($copy, 0.333);

#reference to scalar
my $tmp = 10;
$val = \$tmp;
$copy = clone($val);
$$val++;
is($$val, 11);
is($$copy, 10);

# reference to reference
$val = \\$tmp;
$copy = clone($val);
$$$val++;
is($$$val, 12);
is($$$copy, 11);

# reference to array
$val = [1,2,3];
$copy = clone($val);
shift @$val;
cmp_deeply($copy, [1,2,3]);

#reference to hash
$val = {a => 1, b => 2};
$copy = clone($val);
$val->{b} = 3;
cmp_deeply($copy, {a => 1, b => 2});

#object
package main;
$val = bless {a => 1, b => 2}, 'MySimple';
$copy = clone($val);
$val->{b} = 3;
cmp_deeply($copy, bless {a => 1, b => 2}, 'MySimple');
is(ref $copy, 'MySimple');

# object with clone logic
{
    package MyComplex;
    sub HOOK_CLONE { my %new = %{$_[0]}; delete $new{b}; return bless \%new, 'MyComplex'; }
}
$val = bless {a => 1, b => 2}, 'MyComplex';
$copy = clone($val);
$val->{b} = 3;
cmp_deeply($copy, bless {a => 1}, 'MyComplex');
is(ref $copy, 'MyComplex');

# object with clone logic using clone function again recursively
{
    package MyMoreComplex;
    sub HOOK_CLONE { my $self = shift; delete local $self->{b}; return Panda::Lib::clone($self); }
}
$val = bless {a => 1, b => 2}, 'MyMoreComplex';
$copy = clone($val); # should not enter inifinite loop
is($val->{b}, 2);
cmp_deeply($copy, bless {a => 1}, 'MyMoreComplex');
$val->{b} = 3;
cmp_deeply($copy, bless {a => 1}, 'MyMoreComplex');
is(ref $copy, 'MyMoreComplex');

#mixed
$val = {a => 1, b => [1,2,3], c => bless {a => 1, b => 2}, 'MySimple'};
$copy = clone($val);
shift @{$val->{b}};
cmp_deeply($copy, {a => 1, b => [1,2,3], c => bless {a => 1, b => 2}, 'MySimple'});

#same references - all are different copies
$tmp = [1,2,3];
$val = {a => $tmp, b => $tmp};
$copy = clone($val);
shift @{$val->{a}};
cmp_deeply($copy, {a => [1,2,3], b => [1,2,3]});
ok($copy->{a} ne $copy->{b});
shift @{$copy->{a}};
cmp_deeply($copy, {a => [2,3], b => [1,2,3]});

#same references - all are references to the same data
$tmp = [1,2,3];
$val = {a => $tmp, b => $tmp};
$copy = fclone($val);
shift @{$val->{a}};
cmp_deeply($copy, {a => [1,2,3], b => [1,2,3]});
is($copy->{a}, $copy->{b});
shift @{$copy->{a}};
cmp_deeply($copy, {a => [2,3], b => [2,3]});

#cycled structure
$val = bless {a => 1, b => [1,2,3]}, 'MySimple';
$val->{c} = $val;
$val = [$val];
ok(!eval { $copy = clone($val); 1 }); # should die
ok(!eval { $copy = lclone($val); 1 }); # lclone must behave just like clone without second arg
ok(!eval { $copy = clone($val, 0); 1 }); # false second arg should behave as without it
$copy = fclone($val);
$tmp = shift @{$val->[0]{b}};
cmp_deeply($copy->[0]{c}{c}{c}{c}{c}{c}{c}{c}{b}, [1,2,3]);
unshift @{$val->[0]{b}}, $tmp;
$copy = clone($val, 1); # should behave like fclone
shift @{$val->[0]{b}};
cmp_deeply($copy->[0]{c}{c}{c}{c}{c}{c}{c}{c}{b}, [1,2,3]);

# fclone with HOOK_CLONE and again clone inside - MUST NOT loose object dictionary inside
{
    package MyObj;
    use Data::Dumper;
    sub HOOK_CLONE { my $self = shift; my $ret = Panda::Lib::fclone($self); $ret->{copied} = 1; return $ret; }
}
$val = {obj => bless({a => 1}, 'MyObj')};
$val->{obj}{top} = $val;
$copy = fclone($val);
$copy->{obj}{a}++;
is($val->{obj}{a}, 1);
cmp_deeply([$copy->{obj}{a}, $copy->{obj}{copied}], [2, 1]);
isnt($val, $copy);
isnt($val->{obj}, $copy->{obj});
is($copy->{obj}{top}, $copy, 'same dictionary used');

# code reference
$val = sub { return 25 };
$copy = clone($val);
is(ref($copy), 'CODE');
is($val->(), $copy->());

# regexp
$val = qr/asdf/;
$copy = clone($val);
is(ref($copy), 'Regexp');
ok("123asdf321" =~ $copy);

# typeglob
sub suka { return 10 }
$val = *suka;
$copy = clone($val);
is(ref(\$copy), 'GLOB');
is($copy->(), 10);

# IO
$val = *STDERR{IO};
$copy = clone($val);
is(ref($copy), 'IO::File');
is(fileno($copy), fileno($val));

done_testing();
