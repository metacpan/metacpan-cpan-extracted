# (c) B.Cornec 2007-2016
# Eric Anderson's changes are (c) Copyright 2012 Hewlett Packard
# Provided under the GPL v2
use 5.006001;
use ExtUtils::MakeMaker;
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME         => 'ProjectBuilder',
	DISTNAME     => 'ProjectBuilder',
	VERSION      => '0.14.1',
	INST_SCRIPT  => 'blib/bin',
	INSTALLDIRS  => 'perl',
	PREREQ_PM    => {
			#HTTP::Headers                    => 1.59,
			#Template                         => 0,
	},    # e.g., Module::Name => 1.1
	#ABSTRACT_FROM => 'bin/pb',   # retrieve abstract from module
	AUTHOR        => 'Bruno Cornec <bruno#project-builder.org>',
	EXE_FILES     => [ qw(bin/pbdistrocheck bin/pbgetparam) ],
	MAN1PODS      => { 
						'bin/pbdistrocheck' => '$(INST_MAN1DIR)/pbdistrocheck.$(MAN1EXT)', 
						'bin/pbgetparam' => '$(INST_MAN1DIR)/pbgetparam.$(MAN1EXT)', 
					},
#	MAN3PODS      => {	'lib/ProjectBuilder/Distribution.pm' => '$(INST_MAN3DIR)/ProjectBuilder::Distribution.$(MAN3EXT)',
						#'lib/ProjectBuilder/Conf.pm' => '$(INST_MAN3DIR)/ProjectBuilder::Conf.$(MAN3EXT)',
						#'lib/ProjectBuilder/Display.pm' => '$(INST_MAN3DIR)/ProjectBuilder::Display.$(MAN3EXT)',
						#'lib/ProjectBuilder/Log.pm' => '$(INST_MAN3DIR)/ProjectBuilder::Log.$(MAN3EXT)',
						#'lib/ProjectBuilder/Log/Item.pm' => '$(INST_MAN3DIR)/ProjectBuilder::Log::Item.$(MAN3EXT)',
						#'lib/ProjectBuilder/Base.pm' => '$(INST_MAN3DIR)/ProjectBuilder::Base.$(MAN3EXT)', },
);

package MY;

sub postamble {

	# Determine location of etc conf files
	my $text ="";

	# Grab out any CONFDIR or MANDIR param
	my $etcdir = undef;
	my $mandir = undef;
	my $prefix = undef;

	while (my $arg = shift @ARGV) {
		my ($key, $value) = split /=/, $arg;
		if ($key =~ /^CONFDIR$/) {
			$etcdir = $value;
		} elsif ($key =~ /^MANDIR$/) {
			$mandir = $value;
		} elsif ($key =~ /^PREFIX$/) {
			$prefix = $value;
		}
	}

	$etcdir ||= "$prefix/etc/pb" if (defined $prefix);
	$mandir ||= "$prefix/share/man" if (defined $prefix);
	$etcdir ||= "/usr/local/etc/pb";
	$mandir ||= "/usr/local/share/man";

	# Use that conf dir info to modify Distribution.pm
	system("perl -pi -e \"s~CCCC~$etcdir~\" lib/ProjectBuilder/Distribution.pm");

	$text .= "install ::\n";
	$text .= "\t".'mkdir -p $(DESTDIR)'."$etcdir\n";
	$text .= "\t".'chmod 755 $(DESTDIR)'."$etcdir\n";
	$text .= "\t".'cp etc/pb.conf $(DESTDIR)'."$etcdir\n";

	# Produce the man page for pb.conf
	$text .= "\t".'mkdir -p $(DESTDIR)'."$mandir/man5\n";
	$text .= "\t".'pod2man --section=5 etc/pb.conf.pod > $(DESTDIR)'."$mandir/man5/pb.conf.5\n";
	return($text);
}
