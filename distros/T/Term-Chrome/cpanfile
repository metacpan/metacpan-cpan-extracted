# vim:set ft=perl:

requires 'perl', '5.008005';

requires 'Exporter', '5.57';
requires 'Scalar::Util'; # In core since 5.7.3

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Is', '20140823';
    requires 'Test::Requires' => '0.05';
    suggests 'Test::Synopsis' => '0.14';
};

on develop => sub {
    requires 'Dist::Zilla' => '5.043'; # Required for extended testing with 'dzil test --all'
    requires 'Dist::Milla' => 'v1.0.15';

    requires 'Test::Requires' => '0.07'; # Features RELEASE_TESTING
    requires 'Test::Synopsis' => '0.14';

    # https://github.com/miyagawa/Dist-Zilla-Plugin-LicenseFromModule/pull/3
    requires 'Dist::Zilla::Plugin::LicenseFromModule' => '0.05';
    # https://rt.cpan.org/Ticket/Display.html?id=96692
    requires 'Dist::Zilla::Plugin::ReadmeAnyFromPod' => '0.142470';
}
