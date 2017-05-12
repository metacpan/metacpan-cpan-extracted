use strict;
use warnings;
use Test::More;
use Test::Exception;

use String::TT qw/tt strip/;
use utf8;

is a(), 'foobar', 'foobar works';
like b(), qr/SCALAR/, "references aren't dereferenced";
is c(), 'A::foo', 'methods work';
is d(), 'foo foo bar 1', 'arrays and hashes work';
is e(), 'array foo_a', 'nothing overwritten';
is f(), "Foo maps to bar!\n", 'references and strip work';
is random_work_thing(), <<'HERE', 'random work thing works';
AuthType Basic
AuthName "quotes r us preview"
AuthUserFile /path/to/whatever/.htpasswd
Require user jrockway nothingmuch pergirin stevan
HERE
is utf_eight(), "ほげぼげ", 'utf8 works';
is length utf_eight(), 4, 'utf8 works not by coincidence';

throws_ok { fail_and_throw() } qr/parse error/, 'Throws when your TT does not compile';

done_testing;

sub a {
    my $foo = 'foo';
    my $bar = 'bar';
    return tt '[% foo %][% bar %]';
}

sub b {
    my $foo = \'reference';
    return tt '[% foo %]';
}

{
    sub A::foo { return 'A::foo' }
    
    sub c {
        my $a = bless { foo => 'bar' } => 'A';
        return tt '[% a.foo %]';
    }
}

sub d {
    my $foo = 'foo';
    my @bar = qw/bar/;
    my %baz = ( baz => 1 );
    return tt '[% foo %] [% foo_s %] [% bar_a.0 %] [% baz_h.baz %]';
}

sub e {
    my $foo_a = 'foo_a';
    my @foo = qw/array/;
    return tt '[% foo_a.0 %] [% foo_a_s %]'
}

sub f {
    my $ref = { foo => 'bar' };
    return strip tt q{
        Foo maps to [% ref.foo %]!
    };
}

sub fail_and_throw {
    return tt q{
        [% END %]
    };
}

sub random_work_thing {
    my $users = { 
        jrockway    => 'foo',
        stevan      => 'bar',
        nothingmuch => 'baz',
        pergirin    => 'quux',
    };
    my $site = { name => 'quotes "r" us' };
    my $htpasswd_file = '/path/to/whatever/.htpasswd';
    
    return strip tt q{
        AuthType Basic
        AuthName "[% site.name | remove('"') %] preview"
        AuthUserFile [% htpasswd_file %]
        Require user [% users.keys.sort.join(' ') %]
    };
}

sub utf_eight {
    my $hoge = "ほげ";
    return tt "[% hoge %]ぼげ";
}
