use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $value = "N";
eval {
   require Net::HTTPTunnel;
   $value = "Y";
};
if ($@) {
   # Only ask if module isn't present! (uses default for smoke testers)
   $value = prompt ("Will you be tunneling through a proxy server?  This requires extra modules.", $value);
}

# My list of required modules for Net::FTPSSL ...
my %req = ( IO::Socket::SSL => 1.26,  IO::Socket::INET => 0.0,
            Net::SSLeay => 0.0,       Net::SSLeay::Handle => 0.0,
            File::Basename => 0.0,    File::Copy => 0.0,
            Time::Local => 0.0,       Sys::Hostname => 0.0 );

# Also required if you need to go through a proxy tunnel ... (the question)
if ($value eq "Y" || $value eq "y") {
   $req{"Net::HTTPTunnel"} = 0.50;
}

# These additional modules are required to run the test scripts ...
$req{"Test::More"} = 0.88;
$req{"File::Spec"} = 0.0;

my %params = ( NAME         => 'Net::FTPSSL',
               VERSION_FROM => 'FTPSSL.pm',      # Finds $VERSION
               PREREQ_PM    => \%req );          # e.g., Module::Name => 1.1

## Add these new keywords supported since 5.005
if ( $] >= 5.005 ) {
   $params{ABSTRACT_FROM} = 'FTPSSL.pm',    # retrieve abstract from module
   $params{AUTHOR} = 'Curtis Leach <cleach at cpan dot org>';
}

## An Extra Kwalitee Metric setting.
if ( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
   $params{LICENSE} = 'perl';
}

## An Extra Kwalitee Metric setting.
## The earliest release of Perl I've personally tested this module with:  5.8.8!
## But the "use 5.006001" line has been in this script forever, so I'm going
## to enforce that as the earliest version of perl for now.
if ( $ExtUtils::MakeMaker::VERSION >= 6.48 ) {
   $params{MIN_PERL_VERSION} = '5.006001';      # Perl Version 5.6.1
}

WriteMakefile ( %params );

