use Test::More;
BEGIN { use_ok('NewRelic::Agent') }

SCOPE: {
    my $o = NewRelic::Agent->new;
    is $o->get_license_key => '',
        'Defaulted license key to ""';
    is $o->get_app_name => 'AppName',
        'Defaulted app name to "AppName"';
    is $o->get_app_language => 'perl',
        'Defaulted app language to "perl"';
    is $o->get_app_language_version => $],
        'Defaulted app version to "$]"';

    $o = NewRelic::Agent->new(
       license_key          => 'asdf1234',
       app_name             => 'REST API',
       app_language         => 'perl5',
       app_language_version => 'v5.14',
    );
    is $o->get_license_key => 'asdf1234',
        'Correctly set license key to "asdf1234"';
    is $o->get_app_name => 'REST API',
        'Correctly set app name to "REST API"';
    is $o->get_app_language => 'perl5',
        'Correctly set app language to "perl5"';
    is $o->get_app_language_version => 'v5.14',
        'Correctly set app version to "v5.14"';
}

done_testing;
