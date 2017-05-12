perl -MMath::Combinatorics=combine -MData::Dumper -e my @data = (qw(Moose::Object Point Point3D)); warn Dumper(map { combine($_, @data) } 0 .. @data)

test is a subclass of MX::Compile::Test


setup {
    make a tempdir

    compile next combination into the tempdir

    verify that things have actually been compiled
}

sub run {
    $^X -I tmpdir $actual_test_file @compiled_classes; # the list of compiled classes is used in the test file to check whether or not Moose has been loaded
    renunmber tap
}

teardown {
    remove tempdir;
}


