#!perl
use strict;
use warnings;

use English;

my %required_modules = (
    'DBIx::Simple' => { cat => 'databases', port => 'p5-DBIx-Simple' },
    'Date::Calc'   => { cat => 'devel',     port => 'p5-Date-Calc'   },
    'Config::Std'  => { cat => 'devel',     port => 'p5-Config-Std'  },
    'MIME::Lite'   => { cat => 'mail',      port => 'p5-MIME-Lite'   },
    'MIME::Lite'   => { cat => 'mail',      port => 'p5-MIME-Lite'   },
    'Text::CSV'    => { cat => 'textproc',  port => 'p5-Text-CSV'    },
);


if ( lc($OSNAME) eq "freebsd" ) {

    foreach my $module ( keys %required_modules ) {

        my $category = $required_modules{$module}->{'cat'};
        my $portdir  = $required_modules{$module}->{'port'};
        die "cat/port not set" if (!$category || !$portdir);

        my ($registered_name) = $portdir =~ /^p5-(.*)$/;

        my $checkcmd = "/usr/sbin/pkg_info | /usr/bin/grep $registered_name";
        #print "$checkcmd\t";
        my $installed = `$checkcmd`;
        if ($installed) {
            print "$module is installed.\n";
            next;
        };

        print "installing $module\n";
        chdir "/usr/ports/$category/$portdir";
        system "make install distclean";
    }
    exit;
};

use CPAN; 
CPAN::install Date::Calc;
CPAN::install DBIx::Simple;
CPAN::install MIME::Lite;
CPAN::install Text::CSV;
CPAN::install Config::Std;

