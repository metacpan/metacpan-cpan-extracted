use 5.010;
use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI;

subtest 'basic' => sub {
  my $nr = NewRelic::Agent::FFI->new;
  is $nr->get_license_key => '',
    'Defaulted license key to ""';
  is $nr->get_app_name => 'AppName',
    'Defaulted app name to "AppName"';
  is $nr->get_app_language => 'perl',
    'Defaulted app language to "perl"';
  is $nr->get_app_language_version => $],
    'Defaulted app version to "$]"';

  $nr = NewRelic::Agent::FFI->new(
     license_key          => 'asdf1234',
     app_name             => 'REST API',
     app_language         => 'perl5',
     app_language_version => 'v5.14',
  );
  is $nr->get_license_key => 'asdf1234',
    'Correctly set license key to "asdf1234"';
  is $nr->get_app_name => 'REST API',
    'Correctly set app name to "REST API"';
  is $nr->get_app_language => 'perl5',
    'Correctly set app language to "perl5"';
  is $nr->get_app_language_version => 'v5.14',
    'Correctly set app version to "v5.14"';
};

subtest 'init' => sub {
  my $nr = NewRelic::Agent::FFI->new;
  $nr->init;
  pass 'init did not crash';
};

done_testing

