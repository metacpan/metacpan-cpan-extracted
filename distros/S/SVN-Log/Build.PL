# $Id: Build.PL 729 2006-01-11 08:20:09Z nik $

use strict;

use Module::Build;
use Config;
use File::Spec;

sub have_exe {
  my $name = shift;

  my @dirs = split ':', $ENV{PATH};

  my $found_exe = 0;

  for (@dirs) {
    $found_exe = 1 if (-x File::Spec->catdir ($_, "$name$Config{_exe}"));
  }

  return $found_exe;
}

eval {
  require SVN::Core;
  require SVN::Ra;
};

if ($@) {
  unless (have_exe ('svn')) {
    print <<EOM;
SVN::Log::Index requires either the SVN perl bindings or the 'svn' executable
to function.

You can obtain both at http://subversion.tigris.org/.
EOM
    exit 1;
  }
}

unless (have_exe ('svnadmin')) {
  print <<EOM;
SVN::Log::Index requires the 'svnadmin' executable to run it's tests.

You don't seem to have it, so don't be too surprised when they fail.
EOM
};

my $class = Module::Build->subclass(code => <<'EOF');
  sub ACTION_test {
    my $self = shift;
    use File::Copy;
    copy('t/02basics.t', 't/03commandline.t') or die "Copy failed: $!\n";
    $self->SUPER::ACTION_test(@_);
  }
EOF

my $build = $class->new(
			module_name => 'SVN::Log',
			license => 'perl',
			create_readme => 1,
			sign => 1,
			requires => {
				     'perl' => 5.006,
				    },
			build_requires => {
					   'Test::More' => 0,
					  },
			recommends => {
				       'SVN::Core' => 0,
				      },

			create_makefile_pl => 'passthrough',
			add_to_cleanup => ['t/03commandline.t'],
)->create_build_script;
