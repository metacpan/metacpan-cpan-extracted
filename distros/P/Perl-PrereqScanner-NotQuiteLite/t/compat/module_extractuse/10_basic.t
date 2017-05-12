use strict;
use warnings;
use Test::More;
use t::Util;

# compatibility test with Module::ExtractUse

test('useSome::Module', <<'END', used());
useSome::Module1;
END

test('use Some::Module2', <<'END', used(qw/Some::Module2/));
use Some::Module2;
END

test('useless stuff', <<'END', used(qw/Some::Module3/));
yadda yadda useless stuff;
use Some::Module3 qw/$VERSION @EXPORT @EXPORT_OK/;
END

# base is not listed in as of M::EU 0.33
test('use base', <<'END', used(qw/base Class::DBI4 Foo::Bar5/));
use base qw(Class::DBI4 Foo::Bar5);
END

test('use in if block', <<'END', used(qw/Foo::Bar6/));
if ($foo) { use Foo::Bar6; }
END

test('use constant', <<'END', used(qw/constant/));
use constant dl_ext => $Config{dlext};
END

test('use strict', <<'END', used(qw/strict/));
use strict;
END

test('use Foo args', <<'END', used(qw/Foo8/));
use Foo8 qw/asdfsdf/;
END

test('$use', <<'END', used());
$use=stuff;
END

test('abuse', <<'END', used());
abuse Stuff;
END

test('package', <<'END', used());
package Module::ScanDeps;
END

# XXX: incompatibility
# M::EU 0.33 returns Bar7
test('require in if block', <<'END', used());
if ($foo) { require "Bar7"; }
END

test('require file', <<'END', used());
require "some/stuff.pl";
END

# XXX: incompatibility
# M::EU 0.33 returns Foo::Bar9, which seems a bug, but it may be (or
# may not be) nice to have Foo/Bar.pm => Foo::Bar conversion here.
test('require .pm file', <<'END', used());
require "Foo/Bar.pm9";
END

test('require namespace', <<'END', used(qw/Foo10/));
require Foo10;
END

test('two uses in a line', <<'END', used(qw/Some::Module11 Some::Other::Module12/));
use Some::Module11;use Some::Other::Module12;
END

test('two uses', <<'END', used(qw/Some::Module Some::Other::Module/));
use Some::Module;
use Some::Other::Module;
END

test('use vars', <<'END', used(qw/vars/));
use vars qw/$VERSION @EXPORT @EXPORT_OK/;
END

test('use in comment', <<'END', used());
unless ref $obj;  # use ref as $obj
END

test('use in string', <<'END', used());
$self->_carp("$name trigger deprecated: use before_$name or after_$name instead");
END

test('use base', <<'END', used(qw/base Exporter1/));
use base 'Exporter1';
END

test('use base with parentheses', <<'END', used(qw/base Class::DBI2/));
use base ("Class::DBI2");
END

test('use base with string', <<'END', used(qw/base Class::DBI3/));
use base "Class::DBI3";
END

test('use base with qw', <<'END', used(qw/base Class::DBI4 Foo::Bar5/));
use base qw/Class::DBI4 Foo::Bar5/;
END

test('use base with parentheses (2)', <<'END', used(qw/base Class::DBI6 Foo::Bar7/));
use base ("Class::DBI6","Foo::Bar7");
END

test('use base with strings', <<'END', used(qw/base Class::DBI8 Foo::Bar9/));
use base "Class::DBI8","Foo::Bar9";
END

test('use parent', <<'END', used(qw/parent Exporter1/));
use parent 'Exporter1';
END

test('use parent with parentheses', <<'END', used(qw/parent Class::DBI2/));
use parent ("Class::DBI2");
END

test('use parent with string', <<'END', used(qw/parent Class::DBI3/));
use parent "Class::DBI3";
END

test('use parent with qw', <<'END', used(qw/parent Class::DBI4 Foo::Bar5/));
use parent qw/Class::DBI4 Foo::Bar5/;
END

test('use parent with parentheses (2)', <<'END', used(qw/parent Class::DBI6 Foo::Bar7/));
use parent ("Class::DBI6","Foo::Bar7");
END

test('use parent with strings', <<'END', used(qw/parent Class::DBI8 Foo::Bar9/));
use parent "Class::DBI8","Foo::Bar9";
END

test('use parent -norequire string', <<'END', used(qw/parent/));
use parent -norequire, 'Exporter1';
END

test('use parent -norequire in parentheses', <<'END', used(qw/parent/));
use parent (-norequire, "Class::DBI2");
END

test('use parent "-norequire" string', <<'END', used(qw/parent/));
use parent "-norequire", "Class::DBI3";
END

test('use parent -norequire in qw', <<'END', used(qw/parent/));
use parent qw/-norequire Class::DBI4 Foo::Bar5/;
END

test('use parent -norequire in parentheses', <<'END', used(qw/parent/));
use parent (-norequire,"Class::DBI6","Foo::Bar7");
END

test('use parent -norequire strings', <<'END', used(qw/parent/));
use parent -norequire,"Class::DBI8","Foo::Bar9";
END

test('use in eval', <<'END', used(), {'Test::Pod' => 1.06});
eval "use Test::Pod 1.06";
END

test('uses in two evals', <<'END', used(qw/strict Test::More/), {'Test::Pod' => 1.06, 'Test::Pod::Coverage' => 1.06});
#!/usr/bin/perl -w
use strict;
use Test::More;
eval "use Test::Pod 1.06";
eval 'use Test::Pod::Coverage 1.06;';
plan skip_all => "Test::Pod 1.06 required for testing POD" if $@;
all_pod_files_ok();
END

test('use base with qw and whitespaces', <<'END', used(qw/base Data::Phrasebook::Loader::Base Data::Phrasebook::Debug/));
use base qw( Data::Phrasebook::Loader::Base Data::Phrasebook::Debug );
END

test('RT #83569', <<'END', used(qw/warnings strict Test::More lib DBIx::Class DBICTest Test::Pod/));
use warnings;
use strict;

use Test::More;
use lib qw(t/lib);
use DBICTest;

require DBIx::Class;
unless ( DBIx::Class::Optional::Dependencies->req_ok_for ('test_pod') ) {
  my $missing = DBIx::Class::Optional::Dependencies->req_missing_for ('test_pod');
  $ENV{RELEASE_TESTING}
    ? die ("Failed to load release-testing module requirements: $missing")
    : plan skip_all => "Test needs: $missing"
}

# this has already been required but leave it here for CPANTS static analysis
require Test::Pod;

my $generated_pod_dir = 'maint/.Generated_Pod';
Test::Pod::all_pod_files_ok( 'lib', -d $generated_pod_dir ? $generated_pod_dir : () );
END

test('require in string', <<'END', used(qw/Foo/));
use Foo;say "Failed to load the release-testing modules we require: Bar;"
END

test('require in string', <<'END', used(qw/Foo/));
use Foo;say "Failed to load the release-testing modules we require: Bar";
END

# dup
test('require in string', <<'END', used(qw/Foo/));
use Foo;say "Failed to load the release-testing modules we require: Bar;"
END

test('use Data::Section -setup', <<'END', used(qw/Data::Section/));
use Data::Section -setup;
END

test('use Data::Section with hashref', <<'END', used(qw/Data::Section/));
use Data::Section { installer => method_installer }, -setup;
END

test('use Data::Section -setup hashref', <<'END', used(qw/Data::Section/));
use Data::Section -setup => { header_re => qr/^\@\@\s*(\S+)/ };
END

test('use Module ()', <<'END', used(qw/Foo::Bar29/));
use Foo::Bar29 ();
END

test('use Module version ()', <<'END', {'Min::Version30' => 1.2});
use Min::Version30 1.2 ();
END

test('use MooseX::Types -declare', <<'END', used(qw/MooseX::Types/));
use MooseX::Types -declare => [qw(BorderStyle Component Container)];
END

test('require in eval block', <<'END', {}, used(qw/Foo::Bar32/));
eval { require Foo::Bar32 };
END

test('use in do block', <<'END', used(qw/Foo::Bar33/));
do { use Foo::Bar33 };
END

test('use version', <<'END', used(qw/version/));
use version;
END

test('use version VERSION', <<'END', {version => '0.77'});
use version 0.77;
END

done_testing;
