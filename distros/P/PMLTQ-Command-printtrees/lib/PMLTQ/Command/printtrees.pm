package PMLTQ::Command::printtrees;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::printtrees::VERSION = '0.1.1';
# ABSTRACT: generate svg trees for given treebank

use PMLTQ::Base 'PMLTQ::Command';
use PMLTQ;
use File::Which;
use File::Path qw( make_path );
use File::Basename qw/fileparse dirname/;
use File::ShareDir 'dist_dir';
use File::Spec;
use Hash::Merge 'merge';

has usage => sub { shift->extract_usage };

my $local_shared_dir = File::Spec->catdir(dirname(__FILE__), File::Spec->updir, File::Spec->updir, File::Spec->updir, 'share');
my $shared_dir = eval {  dist_dir('PMLTQ-Command-printtrees') };

# Assume installation
if (-d $local_shared_dir or !$shared_dir) {
  $shared_dir = $local_shared_dir;
}

sub DEFAULT_CONFIG {
  my $btred = shift || $ENV{BTRED};
  ($btred && -f $btred ) || which('btred') || die 'path to btred is not in --printserver-btred option nor in BTRED variable nor in PATH';
  my $extensions = join(',', grep {! m/^!/} split("\n",`$btred --very-quiet --list-extensions`));
  return {
    btred_rc => File::Spec->catdir(shared_dir(),'btred.rc'),
    tree_dir => 'svg',
    btred => $btred || which('btred'),
    extensions => $extensions
  };
}

my %opts;

sub run {
  my $self = shift;
  my @args = @_;
  my $config =  $self->config;

  my $printtrees_config = merge( $config->{'printtrees'}||{}, DEFAULT_CONFIG(($config->{'printtrees'}||{})->{btred} ));
  my $tree_dir =  $printtrees_config->{'tree_dir'};

  my $data_dir = $config->{data_dir};

  unless ($self->test_btred_version($printtrees_config->{'btred'})) {
    print STDERR 'Minimum required BTrEd version is not satisfied';
    return;
  }

  unless ( $config->{layers} && @{ $config->{layers} } > 0 ) {
    print STDERR 'Nothing to print, no layers configured';
    return;
  }

  unless ( -d $tree_dir ) {
    make_path($tree_dir) or die "Unable to create directory $tree_dir\n";
    print "Path '$tree_dir' has been created\n";
  }
  print STDERR "WARNING: No extension is loaded !!!" unless $printtrees_config->{extensions};

  for my $layer ( @{ $config->{layers} } ) {
  	  system($printtrees_config->{btred},
    '--config-file', $printtrees_config->{btred_rc},
    '-Z',$self->config->{resources},
    '-m', File::Spec->catdir(shared_dir(),'print_trees.btred'),
    '--enable-extensions', $printtrees_config->{extensions},
    '-o',
      '--data-dir', $data_dir,
      '--output-dir', $tree_dir,
      $self->files_for_layer($layer),
      '--');
  }
  return 1;
}


sub files_for_layer {
  my ( $self, $layer ) = @_;

  if ( $layer->{data} ) {
    return glob( File::Spec->catfile( $self->config->{data_dir}, $layer->{data} ) );
  } elsif ( $layer->{filelist} ) {
    return $self->load_filelist( $layer->{filelist} );
  }
}

sub load_filelist {
  my ( $self, $filelist ) = @_;

  die "Filelist '$filelist' does not exists or is not readable!" unless -r $filelist;

  map { File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->catfile( $self->config->{data_dir}, $_ ) }
    grep { $_ !~ m/^\s*$/ } read_file( $filelist, chomp => 1, binmode => ':utf8' );
}

sub shared_dir { $shared_dir }

sub minimum_btred_version { 2.5157 }

sub test_btred_version {
  my $self = shift;
  my $btred = shift;
  my $version = `$btred --version`;
  $version =~ s/^.*BTrEd\s*([0-9\.]*)\n.*$/$1/ms;
  return $version >= $self->minimum_btred_version;
}
=head1 SYNOPSIS

  pmltq printtrees

=head1 DESCRIPTION

Generate svg trees for given treebank. It works on local PML files.

=head1 OPTIONS

=over 5

=item B<--printtrees-btred>

Path to btred script. If not set path in $BTRED variable is used. If neither of previous is set script seeks for btred in $PATH.

=item B<--printtrees-btred_rc>

Path to btred configuration. The most important settings is path to extensions.

=item B<--printtrees-extensions>

Comma separated list with extensions. Defaultly are used the same ones as in TrEd (list in extensions.lst optained with `btred --very-quiet --list-extensions`).

=item B<--printtrees-tree_dir>

Directory where sould be images stored. Default value is 'svg'.

=back

=cut

1;
