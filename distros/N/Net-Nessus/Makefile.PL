# -*- perl -*-
#
#   Net::Nessus - a set of Perl modules for working with the
#                 nessus program
#
#
#   The Net::Nessus package is
#
#	Copyright (C) 1998	Jochen Wiedmann
#               		Am Eisteich 9
#				72555 Metzingen
#				Germany
#
#				Phone: +49 7123 14887
#				Email: joe@ispsoft.de
#
#
#   All rights reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#
#   $Id: Makefile.PL,v 1.4 1999/01/29 20:15:39 joe Exp $
#
############################################################################

require 5.004;
use strict;

use Getopt::Long;
use ExtUtils::MakeMaker;

use vars qw($opt_config);
my %prereq;



sub CheckModule ($;$$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereq{$module} = $version || 0;
    if ($version) {
        print "Checking for $package, $version or later ... ";
        eval "use $module $version";
        if ($@) {
            print("\nYou don't have installed the $package package,",
                  " version $version or later.\n");
            return 0;
        }
    } else {
        print "Checking for $package ... ";
        eval "use $module";
        if ($@) {
            print("\nYou don't have installed the $package package.\n");
            return 0;
        }
    }
    print "ok\n";
    return 1;
}


my $ok = 1;
$ok &&= CheckModule("Data::Dumper");
$ok &&= CheckModule("Term::ReadKey");
$ok &&= CheckModule("Net::Telnet", 3.01);


if (!$ok) {
    print q{

Missing modules are available from any CPAN mirror, for example
        ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module

};
    exit 1;
}

my $cfg = eval { require ".status" };
if (!$cfg  or  $opt_config) {
    print "\nModule configuration:\n\n";
    if (!exists($cfg->{'path_nessusd'})) {
	foreach my $dir (split(/:/, $ENV{'PATH'})) {
	    if (-f "$dir/nessusd") { # No -x, because the current user
		                     # won't have x permissions in all cases
		$cfg->{'path_nessusd'} = "$dir/nessusd";
	    }
	}
    }
    $cfg->{'path_nessusd'} =
	prompt("Path of the nessusd binary, if any ",
	       ($cfg->{'path_nessusd'} || 'none'));
    $cfg->{'path_nessusd'} = '' if $cfg->{'path_nessusd'} eq 'none';

    $cfg->{'nessus_host'} = 
	prompt("Host name of Nessus server: ",
	       ($cfg->{'nessus_host'} or 'localhost'));
    $cfg->{'nessus_port'} =
	prompt("Port number of Nessus server: ",
	       ($cfg->{'nessus_port'} or '1241'));
    $cfg->{'nessus_user'} =
	prompt("Nessus user name: ",
	       ($cfg->{'nessus_user'} or 'none'));
    die "Nessus user name must be set" if $cfg->{'nessus_user'} eq 'none';
    $cfg->{'nessus_password'} =
	prompt("Nessus password: ",
	       ($cfg->{'nessus_password'} or 'none'));
    die "Nessus password must be set" if $cfg->{'nessus_password'} eq 'none';

    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    my $dump = Data::Dumper->Dump([$cfg], [qw(config)]);

    require Symbol;
    my $fh = Symbol::gensym();
    die "Error while writing config file: $!"
	unless (open($fh, ">.status")  and
		(print $fh "package Net::Nessus::Config;\n$dump\n")  and
		close($fh));
}


my %opts = ('NAME'         => 'Net::Nessus',
	    'VERSION_FROM' => 'lib/Net/Nessus/Client.pm',
	    'EXE_FILES'    => ['nessusc'],
	    'dist'         => { 'SUFFIX'       => ".gz",
				'DIST_DEFAULT' => 'all tardist',
				'COMPRESS'     => "gzip -9vf" },
	    'realclean'    => { 'FILES' => '.status' },
	    'clean'        => { 'nessusc' }
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'ABSTRACT'} = 'A Nessus Client implementation';
    $opts{'AUTHOR'} = 'Jochen Wiedmann <joe@ispsoft.de>';
    $opts{'PREREQ_PM'} = \%prereq;
}

WriteMakefile(%opts);


package MY;

sub postamble {
    qq{

pm_to_blib: README

README: lib/Net/Nessus/Client.pm
\tperldoc -t lib/Net/Nessus/Client.pm >README

}
}

sub libscan {
    my($self, $path) = @_;
    if ($path =~ /\~$/) {
        undef;
    } else {
        $path;
    }
}
