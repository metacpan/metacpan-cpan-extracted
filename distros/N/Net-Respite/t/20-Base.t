#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 40;
use Cwd qw(abs_path);
use File::Path qw(rmtree);
use Test::Deep;
use Throw qw(throw);
use Net::Respite::Base;
use Data::Debug qw(debug);
use End;

my $file = __FILE__;
my $dir = abs_path "$file.testlib";
my $end = end { rmtree $dir if -e $dir };
mkdir $dir, or warn "Could not mkdir $dir: $!";
open my $fh, '>', "$dir/MyMod.pm" or throw "Could not write $dir/MyMod.pm: $!";
print $fh "package MyMod; use base 'Net::Respite::Base'; sub __voom { return {VOOM => 1} }\n1;\n";
mkdir "$dir/MyMod", or warn "Could not mkdir $dir/MyMod: $!";
open $fh, '>', "$dir/MyMod/MySub.pm" or throw "Could not write $dir/MyMod/MySub.pm: $!";
print $fh "package MyMod::MySub; use base 'MyMod'; our \$api_meta = {methods => {voom2 => 'voom2'}}; sub voom2 { return {VOOM2 => 1} }\n";
close $fh;

###----------------------------------------------------------------###

{
    package Bam;
    use strict;
    use Throw qw(throw);
    use base qw(Net::Respite::Base);
    sub api_meta {
        return shift->{'api_meta'} ||= {
            dispatch_type => 'cache',
            methods => {
                foo => 'bar',
            },
            namespaces => {
                foo_child  => 1,
                bar_child  => 1,
                baz_child  => 1,
                bing_child => 1,
                bang_child => 1,
            },
            lib_dirs => {
                $dir => '__',
            },
        };
    }

    sub bar { {BAR => 1} }
    sub bar__meta {} # { {desc => 'Bar desc'} }

    sub val__meta {
        return {desc => 'Bob', args => {foo => {required => 1, desc => 'Foo'}}};
    }

    our $val_line = __LINE__ + 3;
    sub val {
        my ($self, $args) = @_;
        $self->validate_args($args);
        return {ok => 1};
    }
}

{
    package FooChild;
    sub new { bless $_[1] || {}, $_[0] }
    sub one { {FOO_CHILD => 1} }
    sub one__meta { {desc => ''} }
}

{
    package BarChild;
    sub new { bless $_[1] || {}, $_[0] }
    sub two { {BAR_CHILD => 1} }
    sub two__meta { return {desc => "Hey", args => {}, resp => {}} }
}

{
    package BazChild;
    sub new { bless $_[1] || {}, $_[0] }
    sub three { {BAZ_CHILD => 1} }
    sub three__meta { {desc => '3m'} }
    sub __hey_non { {HEY_NON => 1} }
    sub other {}
}

{
    package BingChild;
    use base qw(Net::Respite::Base);
    sub new { bless $_[1] || {}, $_[0] }
#    sub api_meta { {methods => {bing_child => 'bing_child'}} }
    sub __four { {BING_CHILD => 1} }
}

{
    package BangChild;
    sub new { bless $_[1] || {}, $_[0] }
    sub __five { {BANG_CHILD => 1, self => "$_[0]", base => "".($_[0]->{'base'}||'')} }
}

###----------------------------------------------------------------###

my $json = Bam->json;
ok($json, "JSON loaded");

my $obj = eval { Net::Respite::Base->new({api_meta => {}}) };
my $out = eval { $obj->find_method } or diag "$@";
is_deeply([sort keys %$out], [qw(--load-- hello hello__meta methods methods__meta)], 'Base lookup');
is($out->{'hello'}, 'Net::Respite::Base::__hello', "Correct lookup for hello");


$obj = eval { Net::Respite::Base->new({api_meta => {methods => {foo => 1, bar => 'bar', hello => 'myhello'}}}) };
$out = eval { $obj->find_method } or diag "$@";
is_deeply([sort keys %$out], [qw(--load-- bar foo hello hello__meta methods methods__meta)], 'Base lookup');
is($out->{'bar'}, 'bar', "Correct lookup for bar");
is($out->{'foo'}, 1, "Correct lookup for foo");
is($out->{'hello'}, 'myhello', "Correct lookup for hello");

$obj = eval { Net::Respite::Base->new({
    api_meta => {
        methods => {
            foo => 1,
            bar => 'bar',
            hello => 'myhello',
        },
        namespaces => {
            bang_child => 1,
        },
    },
}) };
$out = eval { $obj->find_method } or diag "$@";
is_deeply([sort keys %$out], [qw(--load-- bang_child_five bar foo hello hello__meta methods methods__meta)], 'Base lookup');
like($out->{'bang_child_five'}, qr/^CODE/, "Correct lookup for bang_child_five");


$obj = eval { Net::Respite::Base->new({api_meta => {namespaces => {bang_child => {dispatch_type => 'new'}}}}) };
my $data = eval { $obj->bang_child_five };
is($data->{'base'}, "$obj", 'Correct parent');
my $id = $data->{'self'};
ok(!$obj->{'BangChild'}, "No cached child");
$data = eval{ $obj->bang_child_five };
isnt($data->{'self'}, $id, 'New child each time');

$obj = eval { Net::Respite::Base->new({api_meta => {namespaces => {bang_child => {dispatch_type => 'cache'}}}}) };
$data = eval{ $obj->bang_child_five };
is_deeply($data, {BANG_CHILD => 1, self => "$obj->{'BangChild'}", base => "$obj"}, 'Correct caching');
ok($obj->{'BangChild'}, "Has cached child");
$data = eval{ $obj->bang_child_five };
is_deeply($data, {BANG_CHILD => 1, self => "$obj->{'BangChild'}", base => "$obj"}, 'Correct caching');

$obj = eval { Net::Respite::Base->new({api_meta => {namespaces => {bang_child => {dispatch_type => 'morph'}}}}) };
$data = eval{ $obj->bang_child_five };
(my $morph = "$obj") =~ s/^Net::Respite::Base=/BangChild=/;
is_deeply($data, {BANG_CHILD => 1, self => $morph, base => $morph}, 'Correct caching');
ok(!$obj->{'BangChild'}, "No cached child");


$obj = eval { Net::Respite::Base->new({
    api_meta => {
        methods => {
            foo => 1,
            bar => 'bar',
            hello => 'myhello',
        },
        lib_dirs => {
            $dir => 1,
        },
    },
}) };
$out = eval { $obj->find_method } or diag "$@";
#debug $out;
is_deeply([sort keys %$out], [qw(--load-- bar foo hello hello__meta methods methods__meta my_mod_voom)], 'Base lookup');

$obj = eval { Bam->new };
$out = eval { $obj->find_method } or diag "$@";
#debug $out;
is_deeply([sort keys %$out], [qw(
--load--
bang_child_five
bar
bar__meta
bar_child_two
bar_child_two__meta
baz_child_hey_non
baz_child_three
baz_child_three__meta
bing_child_four
foo
foo_child_one
foo_child_one__meta
hello
hello__meta
methods
methods__meta
my_mod_voom
val
val__meta)], 'Base lookup');

###----------------------------------------------------------------###

$obj = eval { Bam->new } || diag "$@";
ok($obj, "Created Net::Respite::Base object");

$out = eval { local $obj->api_meta->{'dispatch_type'} = 'cache'; $obj->methods } || diag "$@";
is_deeply($out, {
    methods => {
        bar_child_two => "Hey",
        bar => 'Not documented', # message from methods method call
        baz_child_three => '3m',
        foo_child_one => '',
        hello => "Basic call to test connection",
        methods => "Return a list of all known Bam methods.  Optionally return all meta information as well",
        val => "Bob",
    },
}, "Check for proper methods listing") || do { debug $out;  };


ok($obj->can('run_method'), "Can dispatch");
my $sub_line = __LINE__ + 3;
my $test = sub {
    my ($method, $args, $resp) = @_;
    my $data = eval { $obj->$method($args) };
    $data ||= ref($@) ? $@->TO_JSON : diag "Trouble running $method: $@";

    is_deeply($data, $resp, "$method(".$json->encode($args).")  ==> ".$json->encode($resp)) || do { debug $data;  };
};
eval { $obj->bang_child_five() }; # make sure a method has been called so the cache will hit and BangChild will be set

$test->(@$_) for (
    [foo => {} => {BAR => 1}],
    [bar => {} => {BAR => 1}],
    [bad => {} => {error => 'Invalid Respite method during AUTOLOAD', method => 'bad', class => 'Bam', trace => "Called from (eval) at $file line $sub_line"}],
    [foo_child_one => {} => {FOO_CHILD => 1}],
    [bar_child_two => {} => {BAR_CHILD => 1}],
    [baz_child_three => {} => {BAZ_CHILD => 1}],
    [baz_child_hey_non => {} => {HEY_NON => 1}],
    [bing_child_four => {} => {BING_CHILD => 1}],
    [bang_child_five => {} => {BANG_CHILD => 1, self => "$obj->{'BangChild'}", base => "$obj"}],

    [val => {_no_trace => 1} => {type => 'validation', error => 'Failed to validate args', errors => {foo => 'foo is required.'}, trace => "Called from Bam::val at $file line $Bam::val_line"}],
    [val => {_no_trace => 1, foo => 2} => {ok => 1}],
    [val => {foo => 2} => {ok => 1}],
    [my_mod_voom => {} => {VOOM => 1}],

    );

###----------------------------------------------------------------###

{
    package Nest;
    use strict;
    use Throw qw(throw);
    use base qw(Net::Respite::Base);
    sub foo__meta {{desc => 'nest foo'}}
    sub foo { {n=>__PACKAGE__} }
    sub api_meta {
        shift->{'api_meta'} ||= {
            allow_nested => 1,
            namespaces => {
                nest_a => 1,
            },
        };
    }

    package NestA;
    use strict;
    use Throw qw(throw);
    use base qw(Nest);
    sub foo__meta {{desc => 'nest_a foo'}}
    sub foo { {n=>__PACKAGE__} }
    sub api_meta {
        shift->{'api_meta'} ||= {
            namespaces => {
                nest_b => 1,
            },
        };
    }

    package NestB;
    use base qw(Net::Respite::Base);
    sub foo__meta {{desc => 'nest_b foo'}}
    sub foo { {n=>__PACKAGE__} }
}

$obj = Nest->new({flat => 1});
is(eval{$obj->foo->{'n'}}||'', 'Nest', "Correct base");
is(eval{$obj->nest_a_foo->{'n'}}||'', 'NestA', "Correct child") || diag "$@";
is(eval{$obj->nest_a_nest_b_foo->{'n'}}||'', 'NestB', "Correct grandchild") || diag "$@";
$out = eval { $obj->methods } || diag "$@";
is_deeply([sort keys %{$out->{'methods'}}], [qw(
foo
hello
methods
nest_a_foo
nest_a_hello
nest_a_methods
nest_a_nest_b_foo
)], "Correct nested setup");


my $ip = '127.0.0.1';
$obj = Bam->new({api_ip => $ip});
$out = eval { $obj->hello } || diag "$@";
Test::Deep::cmp_deeply(
    $out,
    { api_brand => undef, api_ip => $ip, args => { }, server_time => Test::Deep::ignore() },
    'Call hello method'
);
