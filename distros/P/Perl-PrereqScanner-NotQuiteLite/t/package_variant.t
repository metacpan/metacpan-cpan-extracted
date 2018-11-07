use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/..";
use Test::More;
use t::Util;

test('no importing', <<'END', {'Package::Variant' => 0}); # MSTROUT/Package-Variant-1.003002/t/01simple.t
  use Package::Variant ();
END

test('importing with a scalar', <<'END', {'Package::Variant' => 0, 'TestImportableA' => 0}); # MSTROUT/Package-Variant-1.003002/t/01simple.t
use Package::Variant importing => 'TestImportableA';
END

test('importing with an arrayref', <<'END', {'Package::Variant' => 0, 'Data::Record::Serialize::Role::Base' => 0, 'Moo' => 0}); # DJERIUS/Data-Record-Serialize-0.07/lib/Data/Record/Serialize.pm
use Package::Variant
  importing => ['Moo'],
  subs      => [qw( with has )];

...

with 'Data::Record::Serialize::Role::Base';
END

test('importing with extra arg', <<'END', {'Package::Variant' => 0, 'MooX::Role' => 0}); # SHLOMIF/XML-GrammarBase-0.2.6/lib/XML/GrammarBase/Role/XSLT.pm
use Package::Variant
    importing => [ 'MooX::Role' => ['late'], ],
    subs      => [qw(has with)];
END

test('importing with a hashref', <<'END', {'Package::Variant' => 0, 'Moo::Role' => 0}); # ILMARI/SQL-Translator-0.11024/lib/SQL/Translator/Role/ListAttr.pm
use Package::Variant (
    importing => {
        'Moo::Role' => [],
    },
    subs => [qw(has around)],
);
END

test('version and importing', <<'END', {'Package::Variant' => '1.002000', 'Moo' => 0, 'MooX::StrictConstructor' => 0}); # RJBS/HTTP-Throwable-0.026/lib/HTTP/Throwable/Variant.pm
use Package::Variant 1.002000
  importing => ['Moo', 'MooX::StrictConstructor'],
  subs      => [ qw(extends with) ];
END

done_testing;
