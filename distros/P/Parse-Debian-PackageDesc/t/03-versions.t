use strict;
use warnings;

use Test::More tests => 18;
use Parse::Debian::PackageDesc;

sub is_upstream_version {
    my ($v, $expected_upstream, $msg) = @_;
    my $actual = Parse::Debian::PackageDesc->extract_upstream_version($v);
    $msg ||= "Upstream version for '$v' should be " .
                "'$expected_upstream', was '$actual'";
    is($actual, $expected_upstream, $msg);
}

sub is_debian_revision {
    my ($v, $expected_revision, $msg) = @_;
    my $actual = Parse::Debian::PackageDesc->extract_debian_revision($v);
    $msg ||= "Debian revision for '$v' should be " .
                "'$expected_revision', was '$actual'";
    is($actual, $expected_revision, $msg);
}

my @test_cases = (
    [ qw(1.0 1) ],
    [ qw(1.0 1.1) ],
    [ qw(1.0 0.1) ],
    [ qw(1.0~beta1 0ubuntu1) ],
    [ qw(40) ],
    [ qw(1.0+git20100604 1) ],
    [ qw(4:3.5.10 0ubuntu1~hardy2) ],
    [ qw(4:3.5.10-2 0ubuntu1~beta1.1+b1) ],
    [ qw(1.0+Git20100604 4) ],
);

foreach my $case (@test_cases) {
    my ($upstream, $revision) = @$case;
    my $full_version = join("-", @$case);
    is_upstream_version($full_version, $upstream);
    is_debian_revision ($full_version, $revision || "");
}

__END__

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
