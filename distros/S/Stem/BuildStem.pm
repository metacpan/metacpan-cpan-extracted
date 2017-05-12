package BuildStem ;

use strict;
use warnings qw( all );

use Carp ;
use Config;
use File::Path ;
use File::Spec ;

use lib 'lib' ;
use base 'Module::Build' ;

$ENV{HARNESS_DEBUG} = 1 ;
$ENV{HARNESS_VERBOSE} = 1 ;

# this is the common env values to control running stem stuff in the
# build directory.

my $env =
	'PATH=blib/bin:blib/demo:$PATH PERL5LIB=blib/lib STEM_CONF_PATH=conf' ;

my %env = (
	PATH	=> "blib/bin:blib/demo:$ENV{PATH}",
	PERL5LIB => 'blib/lib',
	STEM_CONF_PATH	=> 'conf',
) ;

local( @ENV{ keys %env } ) = values %env ;


my ( @manifest_lines ) ;

eval {
	require Stem::InstallConfig
} ;
my $conf = \%Stem::InstallConfig::Config ;

my $is_win32 = ( $^O =~ /Win32/) ? 1 : 0 ;

my $default_stem_path = $is_win32 ?
		'/stem' :
		File::Spec->catfile(
			File::Spec->rootdir, qw( usr local stem ) ) ;

my $default_conf_path = File::Spec->catfile( $default_stem_path, 'conf' ) ;
#my $default_tail_dir = File::Spec->catfile( File::Spec->tmpdir, 'stem_tail' );

my %defaults = (
	bin_path	=> $Config{bin},
	run_stem_path	=> File::Spec->catfile( $Config{bin}, 'run_stem' ),
	perl_path	=> $Config{perlpath},
	conf_path	=> $default_conf_path,
	prefix		=> $Config{prefix},
#	tail_dir	=> $default_tail_dir,
	build_demos 	=> ! $is_win32,
	install_demos	=> ! $is_win32,
	install_ssfe	=> ! $is_win32,
	%{$conf}
);

################
# these are the top level action handlers. ACTION_foo gets called when you do
# 'Build foo' on the command line
################

sub ACTION_build {

	my ( $self ) = @_ ;

	$self->query_for_config() ;

	$self->SUPER::ACTION_build() ;

#	$self->build_bin() ;
}

sub ACTION_test {

	my ( $self ) = @_ ;

	local( @ENV{ keys %env } ) = values %env ;

	$self->depends_on('build');

	$self->SUPER::ACTION_test() ;
}

sub ACTION_install {

	my ( $self ) = @_ ;

	$self->install_config_files() ;
#	$self->install_ssfe() ;

	$self->SUPER::ACTION_install() ;
}

sub ACTION_run { 

	my ( $self ) = @_ ;

	$self->depends_on('build');

	my $run_cmd = $self->{'args'}{'cmd'} || '' ;

	$run_cmd or die "Missing cmd=name argument" ;

	my $cmd = "$env $run_cmd" ;
#	print "CMD: $cmd\n" ;

	system $cmd ;
}

sub ACTION_run_stem { 

	my ( $self ) = @_ ;

	$self->depends_on('build');

	my $conf = $self->{'args'}{'conf'} || '' ;

	$conf or die "Missing conf=name argument" ;

	my $cmd = "$env run_stem $conf" ;
#	print "DEMO: $cmd\n" ;

	system $cmd ;
}


sub run_demo { 

	my ( $self ) = @_ ;

	$self->depends_on('build');

	my $cmd = "$env $self->{action}_demo" ;
	print "DEMO: $cmd\n" ;
	system $cmd ;
}


sub ACTION_tail {

	mkdir 'tail' ;
	
	unlink <tail/*> ;

	goto &run_demo ;
}

*ACTION_chat = \&run_demo ;
*ACTION_chat2 = \&run_demo ;
*ACTION_inetd = \&run_demo ;

sub ACTION_update_pod {

	my( $self ) = @_ ;

	my @manifest_sublist = $self->grep_manifest( qr/\.pm$/ ) ;

	@manifest_sublist = grep /Codec/, @manifest_sublist ;

print join( "\n", @manifest_sublist ), "\n" ;
	
	system( "bin/spec2pod.pl @manifest_sublist" ) ;

	return;
}

# grep through all matched files
# command line args:
#	files=<regex> (default is all .pm files)
#	re=<regex>

sub ACTION_grep {

	my( $self ) = @_ ;

	my $args = $self->{'args'} ;

	my $file_regex = $args->{ files } || qr/\.pm$/ ;
	my $grep_regex = $args->{ re } or die "need grep regex" ; 

	my @manifest_sublist = $self->grep_manifest( $file_regex ) ;

	local( @ARGV ) = @manifest_sublist ;

	while( <> ) {

		next unless /$grep_regex/ ;

		print "$ARGV:$. $_"
	}
	continue {

		close ARGV if eof ;
	}

	return;
}

# ACTION: grep through MANIFEST
# command line args:
#	files=<regex>
#
# do we need this action?
# 

sub ACTION_grep_manifest {

	my( $self ) = @_ ;

	my @manifest_sublist = $self->grep_manifest() ;

	print join( "\n", @manifest_sublist ), "\n" ;
	return;
}

# ACTION: count source lines
# command line args:
#	files=<regex> (defaults to all .pm and bin files
#
# do we need this action?

sub ACTION_lines {

	my( $self ) = @_ ;

	my $args = $self->{'args'} ;
	my $file_regex = $args->{ files } || qr/\.pm$|^bin/ ;

	my @manifest_sublist = $self->grep_manifest( $file_regex ) ;

	system( "./util/lines @manifest_sublist" ) ;

	return;
}

# build a distro and scp to stemsystems.com

sub ACTION_ftp {

	my ( $self ) = @_ ;

	my $dist_tar = $self->dist_dir() . '.tar.gz' ;

	unlink $dist_tar ;

	$self->ACTION_dist() ;

	system "scp $dist_tar stemsystems.com:www/" ;
}


# this sub overrides the find_test_files method in Module::Build

sub find_test_files {

	my ($self) = @_;

	my $test_args = $self->{ args }{ tests } ;

	my @tests = $test_args ? split( ':', $test_args ) :
 		    $self->grep_manifest( qr/\.t$/ ) ;

	return \@tests ;
}

sub process_script_files {
	my( $self ) = @_ ;

	my @scripts = $self->grep_manifest( qr{^bin/} ) ;

#print "SCR @scripts\n" ;
	foreach my $file ( @scripts ) {

		my $bin_dir = File::Spec->catdir(
				$self->blib,
				$file =~ /_demo$/ ? 'demo' : 'bin' ) ;

		File::Path::mkpath( $bin_dir );
  
		my $result = $self->copy_if_modified(
			$file, $bin_dir, 'flatten') or next;

#print "COPY $file\n" ;
		$self->fix_run_stem($result);
		$self->fix_demos($result);
		$self->fix_shebang_line($result);
		$self->make_executable($result);
	}
}

sub fix_run_stem {

	my( $self, $file ) = @_ ;

	return unless $file =~ m{/run_stem$} ;

	my $text = read_file( $file ) ;

	$text =~ s/'conf:.'/'$conf->{'conf_path'}'/ if $conf->{'conf_path'} ;

	write_file( $file, $text ) ;
}

sub fix_demos {

	my( $self, $file ) = @_ ;

	return unless $file =~ /_demo$/ ;

	my $text = read_file( $file ) ;

	$conf->{xterm_path} ||= 'NOT FOUND' ;
	$conf->{telnet_path} ||= 'NOT FOUND' ;

	$text =~ s[xterm][$conf->{xterm_path}]g;
	$text =~ s[telnet][$conf->{telnet_path}]g;

	write_file( $file, $text ) ;
}

# MANIFEST helper subs

sub grep_manifest {

	my( $self, $file_regex ) = @_ ;

	$file_regex ||= $self->{ args }{ files } || qr/.*/ ;

	manifest_load() ;

	return grep( /$file_regex/, @manifest_lines ) ;
}

sub manifest_load {

	return if @manifest_lines ;

	@manifest_lines = grep ! /^\s*$|^\s*#/, read_file( 'MANIFEST' ) ;

	chomp @manifest_lines ;

	return ;
}

#################################

sub query_for_config {

	my( $self ) = @_ ;

	return if $defaults{ 'config_done' } ;

	print <<'EOT';

Building Stem

This script will ask you various questions in order to properly
configure, build and install Stem on your system.  Whenever a question
is asked, the default answer will be shown inside [brackets].
Pressing enter will accept the default answer. If a choice needs to be
made from a list of values, that list will be inside (parentheses).

If you have already configured Stem in a previous build, you can put
use_defaults=1 on the Build command line and you won't be prompted for
any answers and the previous settings will be used.

If you want to force a new build, run Build clean.

EOT

	$self->get_path_config() ;
	$self->get_demo_config() ;

	$defaults{ 'config_done' } = 1 ;

	$self->write_config_pm() ;
}


my $package = 'Stem::InstallConfig' ;

sub config_pm_path {

	return File::Spec->catfile(
		File::Spec->curdir, 'lib', split( /::/, $package) ) . '.pm' ;

}

sub write_config_pm {

	my ( $self ) = @_ ;

	my $config = Data::Dumper->Dump(
		[\%defaults],
		["*${package}::Config"]
	);

	my $conf_pm_file = $self->config_pm_path() ;

	$self->add_to_cleanup( $conf_pm_file ) ;

	write_file( $conf_pm_file, <<EOT ) ;

# DO NOT EDIT
# this file is generated by running Build build

package $package ;

$config
1 ;
EOT

}


sub get_path_config {

	my( $self ) = @_ ;

# 	$self->query_config_value( <<'EOT', 'perl_path' );

# Stem has several executable Perl programs and demonstration scripts
# and they need to have the correct path to your perl binary.

# What is the path to perl?
# EOT

# 	$self->query_config_value( <<'EOT', 'bin_path' );

# Those Stem executables need to be installed in a directory that is in your
# shell $PATH variable.

# What directory will have the Stem executables?
# EOT

 	$self->query_config_value( <<'EOT', 'conf_path' );

Stem configuration files are used to create and initialize Stem Cells
(objects). Stem needs to know the list of directories to search to
find its configurations files.

Note that the default has a single absolute path. You can test Stem
configurations easily setting this path when executing run_stem. You
can override or modify the path time with either a shell environment
variable or on the command line of run_stem. See the documentation on
run_stem for how so do this.

The first directory in the list is where the standard Stem
configuration files will be installed.

Enter a list of absolute directory paths separated by ':'.

What directories do you want to search for Stem configuration files?
EOT

	return ;
}

sub get_demo_config {

	my( $self ) = @_ ;

# don't even bother if win32

	return if $is_win32 ;

# 	$self->get_config_boolean( <<'EOT', 'build_demos' );

# Stem comes with several demonstration scripts. After building them,
# they can be run from the main directory by the Build script: ./Build
# chat, Build inetd, etc.  Do you want to build the demos?
# EOT

# 	return unless $defaults{build_demos};

# all the demos need xterm

	$self->get_xterm_path();
	$self->get_telnet_path();
	return unless -x $defaults{xterm_path} && -x $defaults{telnet_path};

# 	$self->query_config_value( <<'EOT', 'tail_dir' );

# The tail demo script needs a temporary working directory.  Enter the
# path to a directory to use for this purpose.  If it does not exist,
# this directory will be created.
# EOT

	$self->get_config_boolean( <<'EOT', 'install_ssfe' );

ssfe (Split Screen Front End) is a compiled program optionally used by
the Stem demonstration scripts that provides a full screen interface
with command line editing and history. It is not required to run Stem
but it makes the demonstrations easier to work with and they look much
nicer. To use ssfe add the '-s' option when you run any demonstration
script. You can also use ssfe for your own programs.  Install ssfe in
some place in your \$PATH ($conf->{'bin_path'} is where Stem executables
are being installed) so it can be used by the demo scripts. The ssfe
install script will do this for you or you can do it manually after
building it.

Do you want to install ssfe?
EOT

}

sub get_xterm_path {

	my( $self ) = @_ ;

	my $xterm_path;

# 	unless ( $xterm_path = which_exec( 'xterm' ) ) {

# 		foreach my $path ( qw(
# 			/usr/openwin/bin/xterm
# 			/usr/bin/X11/xterm
# 			/usr/X11R6/bin/xterm ) ) {

# 			next unless -x $path;
# 			$xterm_path = $path ;
# 			last;
# 		}
# 	}

# 	if ( $xterm_path ) {

# 		$defaults{'xterm_path'} = $xterm_path ;
# 		print "xterm was found at '$xterm_path'\n";
# 		return ;
# 	}

	$self->query_config_value( <<"EOT", 'xterm_path' );

xterm was not found on this system. you can't run the demo programs
without xterm.  Make sure you enter a valid path to xterm or some other
terminal emulator.

NOTE: If you don't have an xterm, you can still run the demo scripts
by hand. Run a *_demo script and see what commands it issues. Take the
part after the -e and run that command in its own terminal window.

Enter the path to xterm (or another compatible terminal emulator)
EOT

}

sub get_telnet_path {

	my( $self ) = @_ ;

	my $telnet_path;

	unless ( $telnet_path = which_exec( 'telnet' ) ) {

# enter a list of common places to find telnet. or delete this as it
# will almost always be in the path

		foreach my $path ( qw( ) ) {

			next unless -x $path;
			$telnet_path = $path ;
			last;
		}
	}

	if ( $telnet_path ) {

		$defaults{'telnet_path'} = $telnet_path ;
		print "telnet was found at '$telnet_path'\n";
		return ;
	}

	$self->query_config_value( <<"EOT", 'telnet_path' );

telnet was not found on this system. you can't run the demo programs
without telnet.  Make sure you enter a valid path to telnet or some other
terminal emulator.

NOTE: If you don't have an telnet, you can still run the demo scripts
by hand. Run a *_demo script and see what telnet commands it
issues. The run those telnet commands using your telnet or another
similar program.

Enter the path to telnet (or another compatible terminal emulator)
EOT

}

sub install_config_files {

	my ( $self ) = @_ ;

	my ( $conf_path ) = split /:/, $conf->{conf_path} ;

	mkpath( $conf_path, 1, 0755 ) unless -d $conf_path ;

	my @config_files = $self->grep_manifest( qr{^conf/.+\.stem$} ) ;

	foreach my $conf_file (@config_files) {

		$conf_file =~ s{conf/}{} ;

		my $out_file = File::Spec->catfile( $conf_path, $conf_file );

		print "Installing config file: $out_file\n";

		my $in_file = File::Spec->catfile(
			    File::Spec->curdir(), 'conf', $conf_file );

		my $conf_text = read_file($in_file);

		if ( $conf_file eq 'inetd.stem' ) {

			my $quote_serve = File::Spec->catfile(
				$conf->{bin_path}, 'quote_serve' );

			$conf_text =~ s[path\s+=>\s+'bin/quote_serve',]
				       [path\t\t=> '$quote_serve',];
		}
# 		elsif ( $conf eq 'monitor.stem' || $conf eq 'archive.stem' ) {

# 			$conf_text =~ s[path'\s+=>\s+'tail]
# 				       [path'\t\t=> '$conf->{tail_dir}]g ;
# 		}

		write_file( $out_file, $conf_text );
	}
}


sub install_ssfe {

	my ( $self ) = @_ ;

	return unless $conf->{install_stem_demos} &&
		      $conf->{install_ssfe} ;

	print <<'EOT';

Installing ssfe.

This is not a Stem install script and it will ask its own
questions. It will execute in its own xterm (whatever was configured
earlier) to keep this install's output clean. The xterm is kept open
with a long sleep call and can be exited by typing ^C.

EOT

#########
# UGLY
#########

    system <<'EOT';
xterm -e /bin/sh -c 'chdir extras ;
tar zxvf sirc-2.211.tar.gz ;
chdir sirc-2.211 ;
./install ;
sleep 1000 ;'
EOT

    print "\nInstallation of ssfe is done\n\n";
}

#########################################################
# this sub builds the exec scripts in bin and puts them into blib/bin
# for local running or later installation

# sub build_bin {

# 	my ( $self ) = @_ ;

# 	my @bin_scripts = $self->grep_manifest( qr{^bin/} ) ;

# 	foreach my $bin_file ( @bin_scripts ) {

# #print "BIN $bin_file\n" ;

# 		my $bin_text = read_file( $bin_file ) ;

# 		$bin_file =~ s{bin/}{} ;

# # fix the shebang line

# 		$bin_text =~ s{/usr/local/bin/perl}{$conf->{'perl_path'}} ;

# 		my $bin_dir ;

# 		if ( $bin_file =~ /_demo$/ ) {

# 			next unless $conf->{build_demos} ;

# 			$bin_dir = 'demo' ;

# # fix the location of xterms in the demo scripts

# 			$bin_text =~ s[xterm][$conf->{xterm_path}]g;
# 			$bin_text =~ s[telnet][$conf->{telnet_path}]g;

# # fix the default config search path in run_stem
# 		}
# 		else {

# 			$bin_dir = 'bin' ;

# # fix the default config search path in run_stem

# 			if ( $bin_file eq 'run_stem' ) {
# 				$bin_text =~
# 					s/'conf:.'/'$conf->{'conf_path'}'/ ;
# 			}
# 		}

# # 		elsif ( $bin_file eq 'tail_demo' ) {
# # 			$bin_text =~ s['tail']['$conf->{tail_dir}'];
# # 		}

# # write the built script into the blib/ dir

# 		my $out_file = File::Spec->catfile( 'blib',
# 						    $bin_dir,
# 						    $bin_file
# 		);

# 		mkdir "blib/$bin_dir" ;
# 		print "Building executable script: $out_file\n";
# 		write_file( $out_file, $bin_text );
# 		chmod 0755, $out_file;
# 	}
# }

#############################################################

# this sub searches the path for the locations of an executable

sub which_exec {

	my ( $exec ) = @_;

	foreach my $path_dir ( split /[:;]/, $ENV{PATH} ) {

		my $exec_path = File::Spec->catfile( $path_dir, $exec );
		return $exec_path if -x $exec_path ;
	}

	return;
}

# the sub searches a list of dir paths to find the first one that
# exists with a prefix dir

# UNUSED FOR THE MOMENT

# sub which_dir {

# 	my ( $prefix, @dirs ) = @_;

# 	foreach my $subdir ( @dirs ) {

# 		my $dir = File::Spec->catfile( $prefix, $subdir );
# 		return $dir if -x $dir;
# 	}

# 	return;
# }

#############################################################

# these subs handle querying for a user answer. it uses the key to
# find a current value in the defaults and prompt for another value
# if 'use_defaults' is set on the command line, then no prompting will be done

sub query_config_value {

	my( $self, $query, $key ) = @_ ;

	my $default = $self->{args}{$key} ;

	$default = $defaults{ $key } unless defined $default ;

	$defaults{ $key } = ( $self->{args}{use_defaults} ) ?
		$default :
		$self->prompt( edit_query( $query, $default ), $default ) ;
}

sub get_config_boolean {

	my( $self, $query, $key ) = @_ ;

	my $default = $self->{args}{$key} ;

	$default = $defaults{ $key } unless defined $default ;
	$default =~ tr/01/ny/ ;

	$defaults{ $key } = ( $self->{args}{use_defaults} ) ?
		$default :
		$self->y_n( edit_query( $query, $default ), $default ) ;
}

sub edit_query {

	my ( $query, $default ) = @_ ;

	chomp $query ;

	$default ||= '' ;

	my $last_line = (split /\n/, $query)[-1] ;

	if ( length( $last_line ) + 2 * length( $default ) > 70 ) {

		$query .= "\n\t" ;
	}

	return $query ;
}

# low level file i/o subs. should be replaced with File::Slurp. stem
# should depend on it


sub read_file {

	my ( $file_name ) = @_ ;

	local( *FH );

	open( FH, $file_name ) || croak "Can't open $file_name $!";

	return <FH> if wantarray;

	read FH, my $buf, -s FH;
	return $buf;
}

sub write_file {

	my( $file_name ) = shift ;

	local( *FH ) ;

	open( FH, ">$file_name" ) || croak "can't create $file_name $!" ;

	print FH @_ ;
}

1 ;
