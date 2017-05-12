#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin;
use Pod::Elemental;
use Pod::Weaver;

my $weaver = Pod::Weaver->new_from_config({root => "$FindBin::Bin/01"});

my $doc = Pod::Elemental->read_string(<<'POD');
=head1 BEGINNING

start of pod

=head1 ENDING

end of pod

=cut
POD

my $woven = $weaver->weave_document({pod_document => $doc});

is($woven->as_pod_string, <<'POD', "got the right pod");
=pod

=head1 BEGINNING

start of pod

=head1 TEMPLATE

got template with parameter FOO

=head1 ENDING

end of pod

=cut
POD

done_testing;
