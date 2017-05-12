use inc::Module::Install 0.91;

all_from       'lib/Perl/Metrics2.pm';
requires       'Time::HiRes'            => '1.9718';
requires       'Time::Elapsed'          => '0.24';
requires       'File::Spec'             => '0.80';
requires       'File::Next'             => '1.04';
requires       'File::HomeDir'          => '0.82';
requires       'File::ShareDir'         => '1.00';
requires       'File::Find::Rule'       => '0.30';
requires       'File::Find::Rule::VCS'  => '1.06';
requires       'File::Find::Rule::Perl' => '1.09';
requires       'Class::Inspector'       => '1.23';
requires       'Params::Util'           => '1.00';
requires       'Process'                => '0.27';
requires       'Process::Storable'      => '0.27';
requires       'Process::Delegatable'   => '0.27';
requires       'ORLite'                 => '1.21';
requires       'ORLite::Migrate'        => '0.02';
requires       'CPAN::Mini::Visit'      => '0.02';
test_requires  'Test::More'             => '0.42';
install_script 'pm2dist';
install_script 'pm2cache';
install_script 'pm2precache';
install_script 'pm2preparse';
install_script 'pm2minicpan';
install_share;

WriteAll;
