use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
}
else {
    plan 'no_plan';
}


pod_coverage_ok("Palm::Progect");
pod_coverage_ok("Palm::Progect::DB_orig");
pod_coverage_ok("Palm::Progect::Date");
pod_coverage_ok("Palm::Progect::Prefs");

pod_coverage_ok(
          "Palm::Progect::Converter",
        { also_private => [ qr/^new$/ ], },
        "Palm::Progect::Converter POD coverage",
);

pod_coverage_ok(
          "Palm::Progect::Record",
        { also_private => [ qr/^(Accessors)|(category_id)$/ ], },
        "Palm::Progect::Record POD coverage",
);

pod_coverage_ok(
          "Palm::Progect::VersionDelegator",
        { also_private => [ qr/^new$/ ], },
        "Palm::Progect::VersionDelegator POD coverage",
);

pod_coverage_ok(
          "Palm::Progect::Converter::Text",
        { also_private => [ qr/^(accepted_extensions)|(dummy)|(load_prefs)|(options_spec)|(provides_export)|(provides_import)|(save_prefs)$/ ], },
        "Palm::Progect::Converter::Text POD coverage",
);

pod_coverage_ok(
          "Palm::Progect::Converter::CSV",
        { also_private => [ qr/^(accepted_extensions)|(options_spec)|(provides_export)|(provides_import)$/ ], },
        "Palm::Progect::Converter::CSV POD coverage",
);
