use strict;
use warnings;
use Module::Build;
use PDL::Core::Dev;

# This is lifted from PDL::Core::Dev, but use a less redundant style:
my $inc = PDL_INCLUDE;
$inc =~ s/-I//g;
$inc =~ s/"//g;

my $class = Module::Build->subclass(
	class => "Module::Build::Custom",
	code => q{
		sub ACTION_install {
			my $self = shift;
			
			# Install the files first
			$self->SUPER::ACTION_install;
			
			##################################
			# Twiddle with the docs database #
			##################################
			
			use PDL::Doc;
			use File::Copy qw(copy);

			# Find the pdl documentation
			my ($dir,$file,$pdldoc);

			DIRECTORY:
			for my $dir (@INC) {
				$file = "$dir/PDL/pdldoc.db";
				if (-f $file) {
					if (not -w "$dir/PDL") {
						die "No write permission at $dir/PDL! Not updating docs database.\n";
					}
					print "Found docs database $file\n";
					$pdldoc = new PDL::Doc ($file);
					last DIRECTORY;
				}
			}

			die ("Unable to find docs database! Not updating docs database.\n") unless $pdldoc;

			for my $basedir(@INC) {
				$dir = "$basedir/PDL/Parallel";
				if (-d $dir) {
					$pdldoc->ensuredb();
					$pdldoc->scantree($dir);
					eval { $pdldoc->savedb(); };
					warn $@ if $@;

					print "PDL docs database updated.\n";
					last;
				}
			}
		}
	},
);

my $build = $class->new(
	module_name => 'PDL::Parallel::threads',
	license  => 'perl',
	configure_requires => {
		PDL             => '2.4.0',
		'Module::Build' => 0.28,   # meta_merge
	},
	build_requires => {
		# working here - I need to check the smoke reports to hone in on a
		# minimum required version:
		'ExtUtils::ParseXS'	=> '3.0',
		'Test::Warn' => 0,
		'Test::Exception' => 0,
	},
	requires => {
		'perl'            => '5.8.0',  # PerlIO
		'PDL'             => '2.4.10', # Windows mmapping
		'threads::shared' => '1.21',   # shared_clone
	},
	needs_compiler => 1,
	include_dirs => [$inc],
	meta_merge => {
		resources => {
			repository
				=> 'http://github.com/run4flat/PDL-Parallel-threads',
#				=> {
#					web => 'http://github.com/run4flat/PDL-Parallel-threads',
#					url => 'git://github.com/run4flat/PDL-Parallel-threads.git',
#					type => 'git',
#				},
			bugtracker
				=> 'http://github.com/run4flat/PDL-Parallel-threads/issues',
#				=> {
#					web => 'http://github.com/run4flat/PDL-Parallel-threads/issues',
#				},
		},
		no_index => {
			file => ['README.pod'],
			directory => [qw(examples t)],
		},
	},
);

$build->create_build_script;
