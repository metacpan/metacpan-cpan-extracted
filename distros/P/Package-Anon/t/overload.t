use strict;
use warnings;
use Test::More;

use Package::Anon;
use overload ();

my $stash = Package::Anon->new('Foo');

{
    my $gv = $stash->create_glob('OVERLOAD');
    *$gv = {};
    $stash->{OVERLOAD} = $gv;
}

{
    my $gv = $stash->create_glob('()');
    *$gv = \&overload::nil;
    *$gv = \undef;
    $stash->{'()'} = $gv;
}

$stash->add_method('(""' => sub { "overloaded!" });

*{ $stash->{OVERLOAD} }{HASH}->{dummy}++;

my $foo = $stash->bless({});
is "$foo", "overloaded!";

done_testing;
