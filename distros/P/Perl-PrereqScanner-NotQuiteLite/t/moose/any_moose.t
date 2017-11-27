use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test('with names that look like a part of a module, and imports', <<'END', {'Any::Moose' => 0}, {}, {'Mouse::Util' => 0, 'Mouse::Util::TypeConstraints' => 0});
use Any::Moose (
    '::Util::TypeConstraints' => ['subtype'],
    '::Util' => ['does_role'],
);
END

test('only with names that look like a part of a module', <<'END', {'Any::Moose' => 0}, {}, {'Mouse::Util' => 0, 'Mouse::Util::TypeConstraints' => 0});
use Any::Moose qw(
    ::Util::TypeConstraints
    ::Util
);
END

test('with a name that looks like a module', <<'END', {'Any::Moose' => 0}, {}, {'MouseX::Types' => 0});
use Any::Moose 'X::Types';
END

test('both extends and with', <<'END', {'Any::Moose' => 0, 'Test::More' => 0, 'Exporter' => 0});
use Any::Moose;
extends 'Test::More';
with 'Exporter';
END

test('extends with any_moose with a name that looks like a part of a module', <<'END', {'Any::Moose' => 0}, {}, {'Mouse::Meta::Class' => 0});
use Any::Moose;
extends any_moose('::Meta::Class');
END

test('extends with any_moose with a name that looks like a module', <<'END', {'Any::Moose' => 0}, {}, {'MouseX::Types' => 0});
use Any::Moose;
extends any_moose(qw/X::Types/);
END

test('extends with any_moose without ()', <<'END', {'Any::Moose' => 0}, {}, {'Mouse::Meta::Class' => 0, 'Mouse::Util' => 0});
use Any::Moose;
extends any_moose '::Meta::Class', '::Util';
END

done_testing;
