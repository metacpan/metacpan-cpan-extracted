use strict;
use warnings;
use MooseX::Storage;
use Test::More;
use Storable qw//;
use JSON::MaybeXS qw//;
use File::Temp qw/tempfile/;

package Foo;
use strict;
use warnings;
use Moose;
use MooseX::Storage::MaybeDeferred;

with 'MooseX::Storage::MaybeDeferred' => {
    default_format => 'Storable',
    default_io     => 'File'
};

has attribute => (is => 'ro', isa => 'Int', default => 42);

package main;

my $foo = Foo->new();
ok $foo, 'could create a Foo instance';

# freeze/thaw with with default
my $storable = $foo->freeze();
ok $storable, 'default freeze result';
my $is_storable = eval {
    Storable::thaw($storable);
    1;
};
is $is_storable, 1, 'frozen result was storable';

my $cloned_foo = Foo->thaw($storable);
ok $cloned_foo, 'default thawing';


# freeze/thaw with json
my $json = $foo->freeze({format => 'JSON'});
ok $json, 'json freeze result';
my $is_json = eval {
    JSON::MaybeXS->new({utf8 => 1})->decode($json);
    1;
};
is $is_json, 1, 'json result was json';
my $another_foo = Foo->thaw($json, {format => 'JSON'});
ok $another_foo, 'json thawing';

my (undef, $filename) = tempfile(OPEN => 0);
ok not -e $filename;

$foo->store($filename);
ok -e $filename, "Foo written to $filename";

my $is_loaded = eval {
    Foo->load($filename);
    1;
};
is $is_loaded, 1, "Foo loaded from $filename with default settings";

unlink $filename if $filename;

$foo->store($filename, {format => 'JSON', io => 'AtomicFile'});
ok -e $filename, "Foo written to $filename";

my $is_loaded_json_atomic = eval {
    Foo->load($filename, {format => 'JSON', io => 'AtomicFile'});
    1;
};
is $is_loaded_json_atomic, 1, "Foo loaded from $filename with JSON and AtomicFile";

unlink $filename if $filename;

done_testing();
