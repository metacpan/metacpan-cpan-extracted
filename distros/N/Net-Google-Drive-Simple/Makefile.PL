######################################################################
# Makefile.PL for Net::Google::Drive::Simple
# 2019, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository => 'http://github.com/mschilli/net-google-drive-simple.git',
            bugtracker => 'https://github.com/mschilli/net-google-drive-simple/issues',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Net::Google::Drive::Simple',
    'VERSION_FROM' => 'lib/Net/Google/Drive/Simple.pm', # finds $VERSION
    'PREREQ_PM'    => {
      'Crypt::SSLeay'        => '0.72',
      'File::MMagic'         => '1.29',
      'JSON'                 => '2.53',
      'Log::Log4perl'        => '1',
      'LWP::Protocol::https' => '6.04',
      'LWP::UserAgent'       => '6.02',
      'Mojolicious'          => '4.13',
      'OAuth::Cmdline'       => '0.04',
      'Pod::Usage'           => '1.36',
      'Sysadm::Install'      => '0.43',
      'YAML'                 => '0.71',
    }, # e.g., Module::Name => 1.1
    'TEST_REQUIRES' => {
      "Test2::Bundle::Extended"   => "0",
      "Test2::Tools::Explain"     => "0",
      "Test2::Plugin::NoWarnings" => "0",
      "File::Temp"                => "0",
      "Test::MockModule"          => "v0.171.0",
    },
    EXE_FILES                => ["eg/google-drive-init"],
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/Google/Drive/Simple.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
