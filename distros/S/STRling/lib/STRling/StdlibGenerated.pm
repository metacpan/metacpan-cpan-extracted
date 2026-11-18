package STRling::StdlibGenerated;

use 5.010;
use strict;
use warnings;
use STRling::Requests ();

# Generated from the canonical standard-library registry. Do not edit.
# These lexical helpers record Simply recipes; they do not validate semantics.
use constant SURFACE_SOURCE_SHA256 => '94f28b16873abd0b57b324b76e236cbe17706f5310758e066a88a776e4930a3d';
use constant REGISTRY_VERSION => '1.0.0';

# STRling-public-arity: helper_ids=0
sub helper_ids { return ['stdlib.date_time', 'stdlib.email', 'stdlib.ip', 'stdlib.url', 'stdlib.uuid']; }
# STRling-public-arity: date_time=1
sub date_time { return STRling::Requests::stdlib_helper($_[0], 'stdlib.date_time', {}); }
# STRling-public-arity: email=1
sub email { return STRling::Requests::stdlib_helper($_[0], 'stdlib.email', {}); }
# STRling-public-arity: ip=1..2
sub ip { return STRling::Requests::stdlib_helper($_[0], 'stdlib.ip', { version => $_[1] }); }
# STRling-public-arity: url=1
sub url { return STRling::Requests::stdlib_helper($_[0], 'stdlib.url', {}); }
# STRling-public-arity: uuid=1..2
sub uuid { return STRling::Requests::stdlib_helper($_[0], 'stdlib.uuid', { version => $_[1] }); }

1;
