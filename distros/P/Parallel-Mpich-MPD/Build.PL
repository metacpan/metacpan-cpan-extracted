use strict;
#use warnings;
use Module::Build;

my @scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  push @scripts, $_ if /^(scripts)\//;
}
my %cgi_scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  $cgi_scripts{$_}=$_ if /^(cgi)\//;
}
close fd;

#my $MyBuild = Module::Build->subclass(code => <<'EOF');
#sub process_cgi_files {
#  my $self = shift;
#  ... locate and process *.dat files,
#    ... and create something in blib/lib/
#  }
#EOF


# get deps 
# find . \( -name "*.pm" -or -name "*.pl" \) -exec grep -E "use +\S+;" {} \;|sort -u

my $builder = Module::Build->new(
				 module_name         => 'Parallel::Mpich::MPD',
				 license             => 'lgpl',
				 dist_author         => 'Olivier Evalet, Alexandre Masselot <alexandre.masselot@genebio.com>',
				 dist_version_from   => 'lib/Parallel/Mpich/MPD.pm',
				 create_makefile_pl => 'traditional',
				 create_readme => 'README',
				 build_requires => {
						    'Carp'=>0,
						    'CGI'=>0,
						    'Cwd'=>0,
						    'Data::Dumper'=>0,
						    'File::Basename'=>0,
						    'File::Spec'=>0,
						    'File::Temp'=>0,
						    'IO::All' => 0,
						    'Object::InsideOut'=>0,
						    'Test::More' => 0,
						    'Time::HiRes'=>0,
						    'Mail::Sendmail' =>0,
						    'Sys::Hostname'=>0,
						    'Getopt::Long'=>0,
						    'Proc::ProcessTable'=>0

						   },
				 script_files=>\@scripts,
				 cgi_files=>\%cgi_scripts,
				 install_path => { cgi => "cgi/"},
				 add_to_cleanup      => [ 'Parallel-Mpich-MPD-*' ],
			   );
$builder->add_build_element('cgi') || die "cannot add build element [cgi]";
$builder->prereq_failures() && $builder->prereq_failures()->{requires}  && die "conflicts (missing requirem\ents?)";
$builder->create_build_script;

