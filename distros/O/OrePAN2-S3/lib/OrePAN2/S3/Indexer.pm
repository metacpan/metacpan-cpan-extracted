package OrePAN2::S3::Indexer;

use strict;
use warnings;

use Cwd qw(getcwd);
use Log::Log4perl;
use Data::Dumper;
use JSON qw(decode_json);
use English qw(-no_match_vars);

use Role::Tiny::With;

with qw(
  OrePAN2::S3::Role::Inject
  OrePAN2::S3::Role::UploadArtifacts
);

########################################################################
sub new {
########################################################################
  my ( $class, %args ) = @_;

  my $self = bless \%args, $class;

  my $home = $ENV{HOME} ? "$ENV{HOME}/" : getcwd . q{/};

  my $config_file = $ENV{CONFIG} // q{};  # specify the absolute path

  my @candidates = ( "${home}.orepan2-s3.json", '/var/task/orepan2-s3.json', 'orepan2-s3.json', $config_file );

  $self->get_logger->debug( Dumper( [ candidates => \@candidates ] ) );

  my ($config_path) = grep { $_ && -e $_ } @candidates;

  die "ERROR: no config file found.\n"
    if !$config_path;

  my $profile_name = $ENV{OREPAN2_PROFILE_NAME} // 'default';

  eval {
    local $RS = undef;
    open my $fh, '<', $config_file
      or die "ERROR: could not open $config_file for reading: $OS_ERROR\n";

    my $config = decode_json(<$fh>);

    $self->{config} = $config->{$profile_name};

    close $fh;
  };

  die $EVAL_ERROR
    if $EVAL_ERROR;

  return $self;
}

sub get_logger      { return $_[0]->{logger} // Log::Log4perl->get_logger }
sub get_author_path { return $_[0]->{author_path} }
sub get_s3          { return $_[0]->{s3} }
sub get_bucket_name { return $_[0]->{bucket_name} }
sub get_config      { return $_[0]->{config} }

1;
