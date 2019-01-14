package PMLTQ::Command::printtrees;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::printtrees::VERSION = '1.0.1';
# ABSTRACT: generate svg trees for given treebank

use PMLTQ::Base 'PMLTQ::Command';
use PMLTQ;
use File::Which;
use File::Path qw( make_path );
use File::Basename qw/fileparse dirname/;
use File::ShareDir 'dist_dir';
use File::Spec;
use Hash::Merge 'merge';
use Parallel::ForkManager;

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
    extensions => $extensions,
    parallel => {
      job_size => 50,
      forks => 8
    }
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

  unless($printtrees_config->{parallel}->{forks} || $printtrees_config->{parallel}->{forks} > 0) {
    print STDERR "invalid --printtrees-parallel-forks value ". ($printtrees_config->{parallel}->{forks}//'undef');
    return 1;
  }

  unless($printtrees_config->{parallel}->{job_size} || $printtrees_config->{parallel}->{job_size} > 0) {
    print STDERR "invalid --printtrees-parallel-job_size value ". ($printtrees_config->{parallel}->{job_size}//'undef');
    return 1;
  }

  my @layer_files;
  my $pm = Parallel::ForkManager->new($printtrees_config->{parallel}->{forks});
  my $maxlen = 0;

  for my $layer ( @{ $config->{layers} } ) {
    my @layerf = $self->files_for_layer($layer);
    $maxlen = scalar @layerf > $maxlen ? scalar @layerf : $maxlen;
    push @layer_files, [@layerf];
  }

  my @all_layer_files = map {my $idx = $_; map {defined $_->[$idx] ? $_->[$idx] : ()} @layer_files}  (0 .. ($maxlen-1)); # schuffle files - balancing job difficultness
  my @all_files = ();
  push @all_files, [ splice @all_layer_files, 0, $printtrees_config->{parallel}->{job_size} ] while @all_layer_files;
  foreach my $files (@all_files){
    $pm->start and next;
    system($printtrees_config->{btred},
      '--config-file', $printtrees_config->{btred_rc},
      '-Z',$self->config->{resources},
      '-m', File::Spec->catdir(shared_dir(),'print_trees.btred'),
      '--enable-extensions', $printtrees_config->{extensions},
      '-o',
        '--data-dir', $data_dir,
        '--output-dir', $tree_dir,
        @$files,
        '--');
    $pm->finish;
  }

  $pm->wait_all_children;
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

=item B<printtrees-parallel-job_size>

Size of one job, default is 50.

=item B<printtrees-parallel-forks>

Maximum number of parallel jobs, default is 8.

=back

=cut

1;
