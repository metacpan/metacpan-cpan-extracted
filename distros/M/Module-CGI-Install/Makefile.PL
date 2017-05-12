use inc::Module::Install 0.77;

all_from       'lib/Module/CGI/Install.pm';
requires       'Carp'                => 0;
requires       'Config'              => 0;
requires       'ExtUtils::Packlist'  => 0;
requires       'File::Copy'          => 0;
requires       'File::Path'          => 0;
requires       'File::Spec'          => '0.80';
requires       'File::chmod'         => '0.31';
requires       'File::Remove'        => '0.36';
requires       'File::Basename'      => 0;
requires       'Scalar::Util'        => '1.17';
requires       'Params::Util'        => '0.25';
requires       'Term::Prompt'        => '1.03';
requires       'URI::ToDisk'         => '1.09';
requires       'LWP::Simple'         => '1.41';
requires       'CGI::Capture'        => '1.08';
requires       'Object::Tiny'        => '1.02';
test_requires  'Test::More'          => '0.42';
test_requires  'Test::Script'        => '1.02';
test_requires  'Test::File::Cleaner' => '0.03';
test_requires  'URI'                 => '1.35';
install_script 'cgi_install';

WriteAll;
