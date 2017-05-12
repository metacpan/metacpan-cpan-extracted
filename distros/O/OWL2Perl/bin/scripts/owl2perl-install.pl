#!/usr/bin/perl -w
#
# Prepare the stage...
#
# $Id: owl2perl-install.pl,v 1.7 2010-03-09 16:39:14 ubuntu Exp $
# Contact: Edward Kawas <edward.kawas+owl2perl@gmail.com>
# -----------------------------------------------------------

BEGIN {
	use Getopt::Std;
	use vars qw/ $opt_h $opt_F /;
	getopt;

	# usage
	if ($opt_h) {
		print STDOUT <<'END_OF_USAGE';
Preparing stage for generating Perl modules from owl ontologies.
Usage: [-F]

    It creates necessary files (some of them by copying from
    their templates):
       owl2perl-config.cfg
       log4perl.properties
       generator.log
    The existing files are not overwritten - unless an option -F
    has been used.

END_OF_USAGE
		exit(0);
	}

	my $errors_found = 0;

	sub say { print @_, "\n"; }

	sub check_module {
		eval "require $_[0]";
		if ($@) {
			$errors_found = 1;
			say "Module $_[0] not installed.";
		} else {
			say "OK. Module $_[0] is installed.";
		}
	}

	use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

	say 'Welcome! Preparing stage for OWL2Perl ...';
	say '------------------------------------------------------';

	# check needed modules
	foreach $module (
					  qw (
					  Carp
					  File::Spec
					  Config::Simple
					  File::HomeDir
					  File::ShareDir
					  Log::Log4perl
					  HTTP::Date
					  Template
					  Params::Util
					  Class::Inspector
					  Unicode::String
					  IO::String
					  RDF::Core
					  )
	  )
	{
		check_module($module);
	}

	if (MSWIN) {
		check_module('Term::ReadLine');
		{
			local $^W = 0;
			$SimplePrompt::Terminal = Term::ReadLine->new('Installation');
		}
	} else {
		check_module('IO::Prompt');
		require IO::Prompt;
		import IO::Prompt;
	}
	if ($errors_found) {
		say "\nSorry, some needed modules were not found.";
		say "Please install them and run 'owl2perl-install.pl' again.";
		exit(1);
	}
	say;
}
use File::HomeDir;
use File::ShareDir;
use File::Spec;
use OWL::Base;
use File::HomeDir;
use English qw( -no_match_vars );
use strict;

# different prompt modules used for different OSs
# ('pprompt' as 'proxy_prompt')
sub pprompt {
	return prompt(@_) unless MSWIN;
	return SimplePrompt::prompt(@_);
}

# $prompt ... a prompt asking for a directory
# $prompted_dir ... suggested directory
sub prompt_for_directory {
	my ( $prompt, $prompted_dir ) = @_;
	while (1) {
		my $dir = pprompt("$prompt [$prompted_dir] ");
		$dir =~ s/^\s*//;
		$dir =~ s/\s*$//;
		$dir = $prompted_dir unless $dir;
		return $dir if -d $dir and -w $dir;    # okay: writable directory
		$prompted_dir = $dir;
		next if -e $dir and say "'$dir' is not a writable directory. Try again please.";
		next unless pprompt( "Directory '$dir' does not exists. Create? ", -yn );

		# okay, we agreed to create it
		mkdir $dir and return $dir;
		say "'$dir' not created: $!";
	}
}

# create a file from a template
#  - from $file_template to $file,
#  - $file_desc used in messages,
#  - hashref $filters tells what to change in template
sub file_from_template {
	my ( $file, $file_template, $file_desc, $filters ) = @_;
	eval {
		open FILETEMPL, "<$file_template"
		  or die "Cannot read template file '$file_template': $!\n";
		open FILEOUT, ">$file"
		  or die "Cannot open '$file' for writing: $!\n";
		while (<FILETEMPL>) {
			foreach my $token ( keys %$filters ) {
				if ( $^O eq 'MSWin32' ) {
					$filters->{$token} =~ s|\\|\/|;
				}
				s/\Q$token\E/$filters->{$token}/ge;
			}
			print FILEOUT
			  or die "Cannot write into '$file': $!\n";
		}
		close FILEOUT;
		close FILETEMPL
		  or die "Cannot close '$file': $!\n";
	};
	if ($@) {
		say "ERROR: $file_desc was (probably) not created.\n$@";
	} else {
		say "\n$file_desc created: '$file'\n";
	}
}

# --- main ---
no warnings 'once';

my $owl2perl_home = File::Spec->catdir( File::HomeDir->my_home, "Perl-OWL2Perl" );
my $samples_home =
  File::Spec->catdir( File::HomeDir->my_home, "Perl-OWL2Perl", "sample-resources" );
say "Installing in $owl2perl_home\n";

# create install directory if necessary
eval {
	my ( $v, $d, $f ) = File::Spec->splitpath($owl2perl_home);
	my $dir = File::Spec->catdir($v);
	foreach my $part ( File::Spec->splitdir( ( $d . $f ) ) ) {
		$dir = File::Spec->catdir( $dir, $part );
		next if -d $dir or -e $dir;
		mkdir($dir)
		  || die(
				"Error creating installation directory directory '" . $dir . "':\n$!" );
	}
};
say $@ ? $@ : "Created install directory '$owl2perl_home'.";

# log files (create, or just change their write permissions)
my $log_file1 = $OWLCFG::LOG_FILE
  || File::Spec->catfile( "$owl2perl_home", "generator.log" );
foreach my $file ( $log_file1 ) {
	unless ( -e $file ) {
		eval {
			open LOGFILE, ">$file" or die "Cannot create file '$file': $!\n";
			close LOGFILE or die "Cannot create file '$file': $!\n";
		};
		say $@ ? $@ : "Created log file '$file'.";
	}
	chmod 0666, $file;    # just in case a web server will be writing here
}

# log4perl property file (will be found and used, or created)
my $log4perl_file = $OWLCFG::LOG_CONFIG
  || File::Spec->catfile( "$owl2perl_home", "log4perl.properties" );
if ( -e $log4perl_file and !$opt_F ) {
	say "\nLogging property file '$log4perl_file' exists.";
	say "It will not be overwritten unless you start 'install.pl -F'.\n";
} else {
	file_from_template(
						$log4perl_file,
						File::ShareDir::dist_file(
												  'OWL2Perl', 'log4perl.properties.template'
						),
						'Log properties file',
						{
						   '@LOGFILE@'  => $log_file1,
						}
	);
}

# define some directories
my $generated_dir = $OWLCFG::GENERATORS_OUTDIR
  || "$owl2perl_home/generated";

eval {
    my ( $v, $d, $f ) = File::Spec->splitpath( $generated_dir );
    my $dir = File::Spec->catdir($v);
    foreach my $part ( File::Spec->splitdir( ( $d . $f ) ) ) {
        $dir = File::Spec->catdir( $dir, $part );
        next if -d $dir or -e $dir;
        mkdir($dir)
          || die( "Error creating generated_dir directory '" . $dir . "':\n$!" );
    }
    open (FHO,">$generated_dir/README") 
       and print FHO 'This directory will contain any generated OWL2Perl modules.';
    close(FHO);
};
say $@ ? $@ : "Created generated '$generated_dir'.";

# configuration file (will be found and used, or created)
my $config_file =
  File::Spec->catfile( $ENV{$OWL::Config::ENV_CONFIG_DIR} || $owl2perl_home,
					   $OWL::Config::DEFAULT_CONFIG_FILE );
if ( -e $config_file and !$opt_F ) {
	say "Configuration file $config_file exists.";
	say "It will be used and not overwritten unless you start 'owl2perl-install.pl -F'.\n";
} else {
	file_from_template(
						$config_file,
						File::ShareDir::dist_file(
												   'OWL2Perl', 'owl2perl-config.cfg.template'
						),
						'Configuration file',
						{
						   '@GENERATED_DIR@'    => $generated_dir,
						   '@HOME_DIR@'         => $owl2perl_home,
						   '@LOG4PERL_FILE@'    => $log4perl_file,
						   '@LOGFILE@'          => $log_file1,
						}
	);
}

say 'Done.';

package SimplePrompt;

use vars qw/ $Terminal /;

sub prompt {
	my ( $msg, $flags, $others ) = @_;

	# simple prompt
	return get_input($msg)
	  unless $flags;

	$flags =~ s/^-//o;    # ignore leading dash

	# 'waiting for yes/no' prompt, possibly with a default value
	if ( $flags =~ /^yn(d)?/i ) {
		return yes_no( $msg, $others );
	}

	# prompt with a menu of possible answers
	if ( $flags =~ /^m/i ) {
		return menu( $msg, $others );
	}

	# default: again a simple prompt
	return get_input($msg);
}

sub yes_no {
	my ( $msg, $default_answer ) = @_;
	while (1) {
		my $answer = get_input($msg);
		return $default_answer if $default_answer and $answer =~ /^\s*$/o;
		return 'y' if $answer =~ /^(1|y|yes|ano)$/;
		return 'n' if $answer =~ /^(0|n|no|ne)$/;
	}
}

sub get_input {
	my ($msg) = @_;
	local $^W = 0;
	my $line = $Terminal->readline($msg);
	chomp $line;    # remove newline
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;    # trim whitespaces
	$Terminal->addhistory($line) if $line;
	return $line;
}

sub menu {
	my ( $msg, $ra_menu ) = @_;
	my @data = @$ra_menu;

	my $count = @data;

	#    die "Too many -menu items" if $count > 26;
	#    die "Too few -menu items"  if $count < 1;

	my $max_char = chr( ord('a') + $count - 1 );
	my $menu     = '';

	my $next = 'a';
	foreach my $item (@data) {
		$menu .= '     ' . $next++ . '.' . $item . "\n";
	}
	while (1) {
		print STDOUT $msg . "\n$menu";
		my $answer = get_input(">");

		# blank and escape answer accepted as undef
		return undef if $answer =~ /^\s*$/o;
		return undef
		  if length $answer == 1 && $answer eq "\e";

		# invalid answer not accepted
		if ( length $answer > 1 || ( $answer lt 'a' || $answer gt $max_char ) ) {
			print STDOUT "(Please enter a-$max_char)\n";
			next;
		}

		# valid answer
		return $data[ ord($answer) - ord('a') ];
	}
}

__END__
