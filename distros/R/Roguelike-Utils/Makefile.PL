use strict;
use ExtUtils::MakeMaker;
use 5.006; 

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# extract version from Utils file
# this is basically the Maj.Min.subversion number ... for all files

my $ver = 0;

# if VERSION_FROM took an array ref, it would be nice

for (qw(Games/Roguelike/Utils.pm 
	Games/Roguelike/World.pm 
	Games/Roguelike/World/Daemon.pm 
	Games/Roguelike/Area.pm 
	Games/Roguelike/Console.pm)) {
	my $ver2 = getver($_);
	die "Can't get version from $_" unless $ver2;
	$ver = $ver2 if ($ver2 gt $ver);  # stringwise compare...works for me ... for now
}

die "Can't get version from files" unless $ver;

my @exe_files = qw(scripts/example scripts/netgame scripts/tictactoe);


WriteMakefile(
    NAME         => 'Roguelike-Utils',
    PMLIBDIRS    => ['Games'],
    VERSION      => "$ver",
    AUTHOR       => 'Erik Aronesty <earonesty@cpan.org>',
    ABSTRACT     => 'Roguelike Utilities for Perl',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Term::ReadKey' => 0,
		     'Time::HiRes' => 0,
                    },
    EXE_FILES    => \@exe_files,
);


# since it's my module, i'd prefer not to use Safe & eval 
sub getver {
	my ($f) = @_;
	open(IN, $f);
	my ($ver, $rev);
	while (my $in=<IN>) {
		if (my @v = ($in =~ /VERSION[\s='"]*([\d.]+)\.[\s.'"\[]*qw\$Revision: (\d+)/s)) {
			return join '.', @v;
		}
	}
	close IN;
	return undef;
}
