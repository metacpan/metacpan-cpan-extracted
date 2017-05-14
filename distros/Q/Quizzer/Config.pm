#!/usr/bin/perl -w

=head1 NAME

Quizzer::Config - Quizzer meta-configuration module

=cut

=head1 DESCRIPTION

This package holds configuration values for debconf. It supplies defaults,
and allows them to be overridden by values pulled right out of the debconf
database itself.

=cut

package Quizzer::Config;
use strict;

my $VERSION='0.01';

=head1 METHODS

=cut

=head2 configfile

Where to store the config file

=cut

sub configfile {
	"/etc/Quizzer.conf" # CHANGE THIS AT INSTALL TIME
}

=head2 dbdir

Where to store the database. 

=cut

sub dbdir {
	"./" # CHANGE THIS AT INSTALL TIME
}

=head2 tmpdir

Where to put temporary files. /tmp isn't used because I don't bother
opening these files safely, since that requires the use of Fcntl, which
isn't in perl-base

=cut

sub tmpdir {
	"./" # CHANGE THIS AT INSTALL TIME
}

=head2 getconfoption

Given an option name as parameter returns the option value.

=cut

sub getconfoption {
	
	my $wanted = shift;

	open CONFIGFILE, configfile();
	while (<CONFIGFILE>) {
		my $line = $_;
		my ($option, $value) = split(/=/, $line);
		if ($option eq $wanted) {
			return $value;
		}
	}
	close CONFIGFILE;
	
}

=head2 frontend

The frontend to use. A value is pulled out of the database if possible,
otherwise a default is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

If DEBIAN_FRONTEND is set in the environment, it overrides all this.

=cut

{
	my $override_frontend='';

	sub frontend {
		return ucfirst($ENV{DEBIAN_FRONTEND})
			if exists $ENV{DEBIAN_FRONTEND};
		
		if (@_) {
			$override_frontend=ucfirst(shift);
		}
	
		return $override_frontend if ($override_frontend);
		
		my $ret=getconfoption('frontend');
		return $ret;
	}
}

=head2 level

The lowest level of questions you want to see. A value is pulled out of the
database if possible, otherwise a default is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

=cut

{
	my $override_level='';

	sub level {
		if (@_) {
			$override_level=shift;
		}
	
		if ($override_level) {
			return $override_level;
		}
	
		my $ret=getconfoption('level');
		return $ret;
	}
}

=head2 showold

If true, then old questions the user has already seen are shown to them again.
A value is pulled out of the database if possible, otherwise a default of
false is used.

If a value is passed to this function, it changes it temporarily (for
the lifetime of the program) to override what's in the database.

=cut

{
	my $override_showold;
	
	sub showold {
		if (@_) {
			$override_showold=shift;
		}
		
		if (defined $override_showold) {
			return $override_showold;
		}
		
		my $ret='true';
		return $ret;
	}
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
