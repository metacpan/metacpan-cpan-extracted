#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for Pangloss

=head1 SYNOPSIS

 perl Build.PL install_base=/path/to/install/pangloss
 ./Build test
 ./Build install

=cut

use lib 'lib';
use strict;
use warnings;

use Module::Build;
use File::Spec::Functions qw( catfile catdir rel2abs );

$| = 1;
my $install_base = catdir(File::Spec->rootdir, qw( usr local pangloss ));

my @args;
do { $_ =~ /^install_base=(.+)$/ ? $install_base = $1 : push @args, $_ } for (@ARGV);

$install_base = rel2abs( $install_base );

print " + Using installation prefix: $install_base\n";
print <<END_OF_NOTE unless $ENV{PG_TEST_STORE};
 i Note: to use an alternative test Pixie store set PG_TEST_STORE in your
   environment to a valid DBI datasource name such as:
	'dbi:mysql:dbname=pangloss;user=pangloss'
   Otherwise I will try to use BerkeleyDB or memory (which may be slower).
END_OF_NOTE

my $SUBCLASS_CODE = join( '', <DATA> );

my $class = Module::Build->subclass
  (
   class => 'Pangloss::Builder',
   code  => $SUBCLASS_CODE,
  );

my $build = $class->new
  (
   module_name        => 'Pangloss',
   dist_version_from  => catfile(qw( lib Pangloss Version.pm)),
   create_readme      => 1,

   install_base       => $install_base,
   install_types      => [qw( lib arch script bindoc libdoc web conf )],
   # can't override install_base :-/
   #  install_path       => { script => catdir($install_base, 'bin') },

   create_makefile_pl => 'passthrough',
   script_files       => [ catfile(qw( bin pg_test_server )), catfile(qw( bin pg_admin )) ],
   license            => 'perl',
   build_requires     => {
			  'Test::More'    => '0.47',
			  'Data::Random'  => '0.05',
			  'Module::Build' => '0.20',
		      },
   requires           => {
			  'perl'              => '5.8.0',
			  'accessors'         => '0.02',
			  'Storable'          => '2.0',
			  'YAML'              => '0.35',
			  'Date::Format'      => '2.0',
			  'Pod::Usage'        => '1.0',
			  'MIME::Types'       => '1.06',
			  'HTML::Parser'      => '3.00',
			  'LWP::Simple'       => '1.0',
			  'URI'               => '1.0',
			  'Cache::Cache'      => '1.0',
			  'Term::ReadKey'     => '2.0',
			  'Error'             => '0.15',
			  'Petal'             => '1.06',
			  'Petal::Utils'      => '0.05',
			  'Pixie'             => '2.06',
			  'Pipeline'          => '3.04',
			  'Pipeline::Config'  => '0.03',
			  'OpenFrame'         => '3.03',
			  'OpenFrame::WebApp' => '0.04',
		      },
   recommends         => {
			  'Apache'            => '1.0',
			  'Apache::Cookie'    => '0.1',
			  'HTTP::Daemon'      => '1.0',
			  'HTTP::Headers'     => '1.47',
			  'OpenFrame::Segment::Apache' => '1.05',
		      },
  );

$build->create_build_script;


=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=cut


__DATA__

# Pangloss::Builder - custom Module::Build extension
# Auto-generated from Build.PL

use strict;
use File::Spec::Functions;

sub do_create_readme {
  my $self = shift;
  require Pod::Text;
  my $parser = Pod::Text->new;
  $parser->parse_from_file(catfile(qw( lib Pangloss.pm )), 'README', @_);
}

sub install_base_relative {
    my ($self, $type) = @_;
    my %map = (
	       script => ['bin'],
	       web    => ['web'],
	       conf   => ['conf'],
	      );
    return $self->SUPER::install_base_relative($type) unless exists $map{$type};
    return catdir(@{$map{$type}});
}

sub ACTION_install {
    my $self = shift;
    my $base = $self->{properties}{install_base};

    print "\nInstalling Pangloss to $base...\n";
    my $ret  = $self->SUPER::ACTION_install( @_ );

    # worry about creating these dynamically if we ever include XS, etc:
    my $lib_dir = File::Spec->catdir( $base, 'lib' );
    my $man_dir = File::Spec->catdir( $base, 'man' );
    my $bin_dir = File::Spec->catdir( $base, 'bin' );

    print(
	  "\nInstallation Complete\n",
	  "---------------------\n\n",
	  "You should set the following environment variables:\n\n",
	  "\tPG_HOME  = $base\n",
	  "\tPERL5LIB = $lib_dir\n",
	  (-e $man_dir) ?
	  "\tMANPATH  = $man_dir\t[optional]\n" : (),
	  "\tPATH     = $bin_dir\t[optional]\n",
	  "\n",
	  "See the Pangloss::Install and Pangloss::Config pages for\n",
	  "more details on how to get your server up and running\n\n",
	 );

    return $ret;
}

sub ACTION_cover {
    my $self = shift;
    die "test coverage action not yet written!";
}

sub ACTION_test {
    my $self = shift;
    $self->add_to_cleanup( catfile(qw( t tmp )) );
    $self->SUPER::ACTION_test;
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;
    $self->process_web_files
         ->process_conf_files;
}

sub process_web_files {
    my $self = shift;
    my $files = $self->find_web_files;
    while (my ($from, $to) = each %$files) {
	$to = catfile('blib', $to);
	$self->copy_if_modified(from => $from, to => $to );
    }
    return $self;
}

sub process_conf_files {
    my $self = shift;
    my $files = $self->find_conf_files;
    while (my ($from, $to) = each %$files) {
	$to = catfile('blib', $to);
	$self->copy_if_modified(from => $from, to => $to );
    }
    return $self;
}

sub find_web_files { shift->find_all_files_no_cvs( 'web' ) }

sub find_conf_files { shift->find_all_files_no_cvs( 'conf' ) }

sub find_all_files_no_cvs {
    my ($self, $dir) = @_;
    my $sub = sub {
	return 1 if ($File::Find::dir !~ /CVS/i and -f $File::Find::name);
    };
    return { map {$_, $_} @{ $self->rscan_dir($dir, $sub) } };
}

