package Module::cpmfile::Util;
use strict;
use warnings;

use CPAN::Meta::Requirements;

use Exporter 'import';
our @EXPORT_OK = qw(merge_version);

my $TEST_PACKAGE = '__TEST_PACKAGE__';

sub merge_version {
    my ($v1, $v2) = @_;
    my $r = CPAN::Meta::Requirements->new;
    $r->add_string_requirement($TEST_PACKAGE, $v1) if defined $v1;
    $r->add_string_requirement($TEST_PACKAGE, $v2) if defined $v2;
    $r->requirements_for_module($TEST_PACKAGE);
}

1;
