#!/usr/bin/env perl

use strict;
use warnings;

use PYX::XMLSchema::List;

# Example data.
my $pyx = <<'END';
(foo
Axmlns:bar http://bar.foo
Axmlns:foo http://foo.bar
Afoo:bar baz
(foo:bar
Axml:lang en
Abar:foo baz
)foo:bar
)foo
END

# PYX::XMLSchema::List object.
my $obj = PYX::XMLSchema::List->new;

# Parse.
$obj->parse($pyx);

# Output:
# [ bar ] (E: 0000, A: 0001) http://bar.foo
# [ foo ] (E: 0001, A: 0001) http://foo.bar
# [ xml ] (E: 0000, A: 0001)