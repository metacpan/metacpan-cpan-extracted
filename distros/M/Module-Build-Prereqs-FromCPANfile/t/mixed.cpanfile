
requires perl => "5.14.0";
requires "NoVersion";
requires "WithVersion", "1.100";
requires "WithDottedVersion", "v2.9.0";
requires "WithExactVersion", "== 3.000";

recommends "RuntimeRecommends" => "2";
suggests   "RuntimeSuggests";
conflicts  "RuntimeConflicts" => 10;

on test => sub {
    requires "TestRequires" => "1.10";
    recommends "TestRecommends" => "1.20";
    suggests "TestSuggests";
    conflicts "TestConflicts" => "1.40";
};

on build => sub {
    requires "BuildRequires" => "2.10";
    recommends "BuildRecommends";
    suggests "BuildSuggests" => "2.30";
    conflicts "BuildConflicts" => "2.40";
};

on develop => sub {
    requires "DevelopRequires";
    recommends "DevelopRecommends" => "3.20";
    suggests "DevelopSuggests" => "3.30";
    conflicts "DevelopConflicts";
};

on configure => sub {
    requires "ConfigureRequires" => "4.10";
    recommends "ConfigureRecommends";
    suggests "ConfigureSuggests" => "4.30";
    conflicts "ConfigureConflicsts" => "4.40";
};

feature "awesome-feature", sub {
    requires "FeatureRequires" => "5.10";
    recommends "FeatureRecommends";
    suggests "FeatureSuggests";
    conflicts "FeatureConflicts";
};
