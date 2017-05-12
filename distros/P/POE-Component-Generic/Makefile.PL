#!/usr/bin/perl

use warnings;
use strict;

use ExtUtils::MakeMaker;
use Getopt::Long;
use Data::Dumper;

use 5.006;

# Add in the Ex::MM::Coverage stuff.  But silently ignore failure.
eval q{
    use ExtUtils::MakeMaker::Coverage;
    # I keep some modules outside of /usr/lib/perl5
    my $config = ExtUtils::MakeMaker::Coverage->config;
    $config->ignore( ['site_perl'] ); 
};


###########################################################
my $HELP = 0;
my %config = (
    ssh=>{
        host => 'localhost',
        port => 22,
        user => '',
        password => '',
    }
);
if( $^O =~ /MSWin32/i or $^O =~ /cygwin/ ) {
    warn <<'    WARN';
************************************************************
It has come to our attention that POE::Component::Generic
does not always function correctly on Windows.  We do not
have the skills nor the time to debug this issue.  We would
be very pleased if you would solve this for us.  
    Thank you.
************************************************************
    WARN
    eval q{
        use Win32;  
        $config{ssh}{user} = Win32::LoginName() unless Win32::IsWin95();
    };
}
else {
    $config{ssh}{user} = getpwuid($<);
}


my @args = @ARGV;
my $res = GetOptions ( "ssh-host=s" => \$config{ssh}{host}, 
                       "ssh-port=i" => \$config{ssh}{port}, 
                       "ssh-user=s" => \$config{ssh}{user}, 
                       "ssh-password=s" => \$config{ssh}{password},

                       "help"       => \$HELP
                     );

if( not $res or $HELP ) {
    print <<HELP;
Usage: $0 [options] [MakeMaker-optoins]

    --help          This text

For testing Net::SSH::Perl
    --ssh-host      Host to connect to ($config{ssh}{host})
    --ssh-port      Port to connect to ($config{ssh}{port})
    --ssh-user      User to login as ($config{ssh}{user})
    --ssh-password  Password to use
HELP
}

# @ARGV=@args;

###########################################################
open CONFIG, ">t/Config.pm" or die "Unable to create t/Config.pm: $!";
my $conf = Dumper \%config;
print CONFIG <<CONFIG;
package t::Config;
use vars qw( \$VAR1 );
$conf
1;
CONFIG

close CONFIG;



###########################################################

WriteMakefile(
	NAME          => 'POE::Component::Generic',
	AUTHOR        => 'Philip Gwyn <gwyn -at- cpan.org>',
	ABSTRACT      => 'Generic non-blocking POE interface to any OO-module',
	VERSION_FROM  => 'lib/POE/Component/Generic.pm', # finds $VERSION
    LICENSE       => 'perl',
	PREREQ_PM     => {
		'Test::More'        => 0.32,
		'POE'               => 1.311,
        'Scalar::Util'      => 1,
		'Devel::Symdump'	=> 2,
		'Carp'			    => 0,
	},
	dist        => {
		COMPRESS  => 'gzip -9f',
		SUFFIX    => 'gz',
	},
);


