#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject 'as_list';

diag "--- Loading object functionality into repl\n";

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => [qw[debug]],
        use_queue => 1,
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 30;
};

# create a nested object
sub genObj {
    my ($repl,$val) = @_;
    my $rn = $repl->name;
    my $obj = $repl->expr(<<JS)
(function(repl, val) {
    return { bar: [ 'baz', { value: val } ] };
})($rn, "$val")
JS
}

my $foo = genObj($repl, 'deep');
isa_ok $foo, 'MozRepl::RemoteObject::Instance';

my $bar = $foo->{bar};
isa_ok $bar, 'MozRepl::RemoteObject::Instance';

my @elements = @{ $bar };
is 0+@elements, 2, 'We have two elements';

is 0+@{ $bar }, 2, 'We have two elements (scalar context)';

#diag $_ for @$bar;

my $baz = $bar->[0];
is $baz, 'baz', 'First array element retrieved';

my $baz2 = $bar->{0};
is $baz2, 'baz', 'First array element retrieved via hash key';

my $val = $bar->[1];
isa_ok $val, 'MozRepl::RemoteObject::Instance', 'Object retrieval from array';
is $val->{value}, 'deep', '... and the object contains our value';

push @{ $bar }, 'asdf';
is 0+@{ $bar }, 3, '... even pushing an element works';
is $bar->[-1], 'asdf', '... and the value is actually stored';

my $elt = pop @{ $bar };
is $elt, 'asdf', 'We can pop the value back';
is 0+@{ $bar }, 2, '... and that reduces the element count by one';

my @arr = @$bar;
is 0+@arr, 2, 'Fetching all array elements returns the right count';
is $arr[0], 'baz', 'First element is correct';
isa_ok $arr[1], 'MozRepl::RemoteObject::Instance', 'Second element is of correct type';

# Fetch in one go:
@arr = as_list $bar;
#use Data::Dumper;
#diag Dumper \@arr;
is 0+@$bar, 2, 'Fetching leaves the array as is';
is 0+@arr, 2, 'Fetching all array elements returns the right count';
is $arr[0], 'baz', 'First element is correct';
isa_ok $arr[1], 'MozRepl::RemoteObject::Instance', 'Second element is of correct type';

# Fetch in one go, destructively:
@arr = splice @$bar;
is 0+@$bar, 0, 'Splice empties the array';
is 0+@arr, 2, 'Fetching all array elements returns the right count';
is $arr[0], 'baz', 'First element is correct';
isa_ok $arr[1], 'MozRepl::RemoteObject::Instance', 'Second element is of correct type';

@arr = $repl->expr(<<JS,'list');
      [1,2,3,4]
JS
is_deeply \@arr, [1,2,3,4], "List-expressions also work";

# Check array assignment:
$bar = genObj($repl,'tmp')->{bar};
@$bar = ();
is 0+@$bar, 0, "We can clear an array";

$ok = eval {
    @$bar = (1,2,3,4);
    1;
};
ok $ok, "We can assign lists to arrays";
is_deeply [as_list $bar], [1,2,3,4], "And we assign the right values";

# Check that 4-arg splice is unsupported:
@arr = splice @$bar, 1,2, 'b', 'c';
is 0+@$bar, 4, 'We still have four elements';
is_deeply \@arr, [2,3], "We spliced out the right values";
is_deeply [as_list $bar], [1,'b','c',4], "We spliced in the right values";
