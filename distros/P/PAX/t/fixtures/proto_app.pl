use strict;
use warnings;

use lib 't/fixtures/app_lib';
use ProtoOps ();

print ProtoOps::constant_one(41, 99), "\n";

=pod

=head1 NAME

t/fixtures/proto_app.pl - fixture for fixture that exercises subroutine prototypes in application code

=head1 DESCRIPTION

This fixture exists to provide fixture that exercises subroutine prototypes in application code. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
