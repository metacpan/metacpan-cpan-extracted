use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('load_class', <<'END', {'Class::Load' => 0, 'Test::More' => 0});
use Class::Load 'load_class';
load_class('Test::More');
END

test('conditional load_class', <<'END', {'Class::Load' => 0}, {}, {'Test::More' => 0});
use Class::Load 'load_class';
if (1) { load_class('Test::More'); }
END

test('load_class in a sub', <<'END', {'Class::Load' => 0}, {}, {'Test::More' => 0});
use Class::Load 'load_class';
sub foo { load_class('Test::More'); }
END

test('load_class in BEGIN', <<'END', {'Class::Load' => 0, 'Test::More' => 0});
use Class::Load 'load_class';
BEGIN { load_class('Test::More'); }
END

test('load_class with -version', <<'END', {'Class::Load' => 0, 'Test::More' => '0.01'});
use Class::Load ':all';
load_class('Test::More', {-version => '0.01'});
END

test('try_load_class', <<'END', {'Class::Load' => 0}, {'Test::More' => 0});
use Class::Load 'try_load_class';
try_load_class('Test::More');
END

test('try_load_class with -version', <<'END', {'Class::Load' => 0}, {'Test::More' => '0.01'});
use Class::Load ':all';
try_load_class('Test::More', {-version => '0.01'});
END

test('load_first_existing_class', <<'END', {'Class::Load' => 0}, {strict => 0, warnings => 0});
use Class::Load 'load_first_existing_class';
load_first_existing_class('strict', 'warnings');
END

test('load_first_existing_class with -version', <<'END', {'Class::Load' => 0}, {'strict' => '0.01', warnings => 0, 'Test::More' => '0.02'});
use Class::Load ':all';
load_first_existing_class('strict', {-version => '0.01'}, 'warnings', 'Test::More', {-version => '0.02'});
END

test('Class::Load::load_class', <<'END', {'Class::Load' => 0, 'Test::More' => 0});
use Class::Load;
Class::Load::load_class('Test::More');
END

# ALEXBIO/App-gist-0.16/lib/App/gist.pm
test('try_load_class with if', <<'END', {'Class::Load' => 0}, {'Config::Identity::GitHub' => 0});
use Class::Load 'try_load_class';
    my %identity = Config::Identity::GitHub -> load
        if try_load_class('Config::Identity::GitHub');
END

done_testing;
