use 5.006001;
use ExtUtils::MakeMaker;
use Data::Dumper;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub initialize {
	my @scripts = map { "scripts/$_" } qw(
		snap_charge
		snapback_loop
		snapback2
		snapcopy
	);

	my $clink = `cp --help`;
	$clink =~ /--link/ 
		or print <<EOF;
###############

	WARNING
		This module will not work properly until it has access to the GNU cp command.
		It is required for the --link option, which is central to the functionality.
		If you install GNU cp in a non-standard place which is not first in your
		path, add this to snapback.conf:

			cp  /path/to/gnu/cp

##############
EOF
	my %X;
	$X{INSTALLDIRS}	= "perl";
	$X{clean} = {
		FILES => join(" ", 'scripts/initp.pl', @scripts, 'b_target', 'b_source', 'b_source2'),
	};
	$X{EXE_FILES}	= [ @scripts ];
	$X{PL_FILES}	= { 'relocate.util' => [ @scripts ] };
	for(%MV::Default) {
		$X{$_} = $MV::Default{$_}
			unless defined $X{$_};
	}
	mk_initp(\%X);
	return \%X;
}

sub mk_initp {
	my ($ref) = @_;
	local($Data::Dumper::Terse);
	$Data::Dumper::Terse = 1;
	open (INITP, ">scripts/initp.pl")
		or die "Can't write initp.pl: $!\n";
	print INITP '$MV::Self = ';
	print INITP Dumper($ref);
	print INITP ";\n1;";
	close INITP;
}


my %mv_specific = qw/
	CP            1
	RM            1
	SENDMAIL      1
	MV            1
	RSYNC         1
	RSYNCSHELL    1
/;

my %delete;
use Getopt::Long;
my @saveargs = @ARGV;
my %optctl = (
	'junk'			=> sub { 1 },
	'<>'			=> sub {
							my ($arg) = @_;
	warn "checking option $arg\n";
							my ($opt, $val);
							if($arg !~ /=/) {
								$opt = $arg;
								$val = 1;
							}
							else {
								($opt, $val) = split /=/, $arg, 2;
							}

							if ($mv_specific{uc $opt}) {
								$delete{$arg} = 1;
								$delete{$opt} = 1;
								$delete{$val} = 1;
								warn "It was specific arg=$arg\n";
							}

							$MV::Default{$opt} = $val;
							return;
						},
);

my @options = ( qw/
	junk
	<>
/ );

Getopt::Long::config(qw/permute/);
GetOptions(\%optctl, @options)
	or die "Bad option get\n";

#use Data::Dumper;
#$Data::Dumper::Terse = $Data::Dumper::Indent = 2;
#print "ARGV: " . Dumper(\@ARGV);
#print "OPT: " . Dumper(\%MV::Default);

@ARGV = grep ! $delete{$_}, @saveargs;

#warn "ARGV now=" . Dumper(\@ARGV)  . "\n";

WriteMakefile(
    NAME		    => 'Snapback2',
    VERSION_FROM	=> 'scripts/snapback2.PL', # finds $VERSION
	'MAN1PODS' => {
		'scripts/snapcopy'    => '$(INST_MAN1DIR)/snapcopy.$(MAN1EXT)',
		'scripts/snapback2'    => '$(INST_MAN1DIR)/snapback2.$(MAN1EXT)',
		'scripts/snapback_loop'    => '$(INST_MAN1DIR)/snapback_loop.$(MAN1EXT)',
		'scripts/snap_charge'    => '$(INST_MAN1DIR)/snap_charge.$(MAN1EXT)',
    },
	EXE_FILES => [],
	PL_FILES => {},
	PM => { 'Backup/Snapback.pm' => '$(INST_LIBDIR)/Backup/Snapback.pm'},
	CONFIGURE => \&initialize,
    PREREQ_PM		=> { Config::ApacheFormat => 1.2 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Snapback2 -- automated rsync backup',
       AUTHOR     => 'Mike Heins <snapback2@perusion.org>') : ()),
);
