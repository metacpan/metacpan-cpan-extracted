use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::StandaloneImage;

my $have_plack = eval {
    require Plack::Middleware::FixMissingBodyInRedirect;
    1;
};

SKIP: {
    skip 'Plack web stack not installed', 3 if !$have_plack;

    my @inc_dirs = PAX::StandaloneImage::_runtime_inc_dirs([]);
    my @loaded = PAX::StandaloneImage::_probe_loaded_runtime_files(
        modules => ['Plack::Middleware::FixMissingBodyInRedirect'],
        lib_dirs => [],
    );

    my ($html_parser_pm) = grep { /HTML\/Parser\.pm$/ } @loaded;
    ok($html_parser_pm, 'runtime probe loads HTML::Parser wrapper');

    my @xs = PAX::StandaloneImage::_related_xs_files_for_source($html_parser_pm, \@inc_dirs);
    ok((grep { /auto\/HTML\/Parser\/Parser\.(?:so|bundle|dll)$/ } @xs) >= 1, 'runtime payload discovery includes matching HTML::Parser XS binary');

    my %selected = map { $_ => 1 } PAX::StandaloneImage::_runtime_selected_files(
        inc_dirs => \@inc_dirs,
        dependencies => [],
        lib_dirs => [],
        exclude_files => [],
    );
    ok($selected{$html_parser_pm}, 'runtime selection includes probe-discovered HTML::Parser wrapper without needing an explicit dependency entry');
}

done_testing;

=pod

=head1 NAME

t/runtime_payload_selection.t - regression coverage for standalone runtime payload selection logic

=head1 DESCRIPTION

This test exercises standalone runtime payload selection logic. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for standalone runtime payload selection logic. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/runtime_payload_selection.t

=head1 WHY IT EXISTS

PAX uses this test to keep standalone runtime payload selection logic from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
