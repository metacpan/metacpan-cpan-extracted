package PkgForge::BuildCommand::Submitter::PkgSubmit;    # -*-perl-*-
use strict;
use warnings;

# $Id: PkgSubmit.pm.in 16799 2011-04-22 11:52:09Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16799 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildCommand/Submitter/PkgSubmit.pm.in $
# $Date: 2011-04-22 12:52:09 +0100 (Fri, 22 Apr 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use IPC::Run ();
use Readonly;

Readonly my $PKGSUBMIT => '/usr/sbin/pkgsubmit';

use overload q{""} => sub { shift->stringify };

use Moose;
use MooseX::Types::Moose qw(Str);

with 'PkgForge::BuildCommand::Submitter';

has '+tools' => (
  default => sub { [$PKGSUBMIT] },
);

has '+architecture' => (
  required => 1,
);

has 'config' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  builder  => 'build_config',
  lazy     => 1,
  documentation => 'The pkgsubmit configuration file which should be used',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub build_config {
  my $self = shift;
  my $platform = $self->platform;
  my $arch     = $self->architecture;
  my $config   = $platform . q{-} . $arch . '.conf';
  return $config;
}

sub run {
  my ( $self, $job, $buildinfo, $buildlog ) = @_;

  my $logger = $buildlog->logger;

  my $config = $self->config;
  my $bucket = $job->bucket;

  my @files = $buildinfo->products_list;

  # Should not be necessary but just in case...
  @files = grep { m/\.rpm$/ } @files;

  my $id = join q{/}, $self->platform, $self->architecture, $bucket;
  my $files_count = scalar @files;

  my $success = 1;
  if ( $files_count > 0 ) {
    my @cmd = ( $PKGSUBMIT, '-x', '-f', $config, '-B', $bucket, @files );

    $logger->debug("Will run command '@cmd'");

    my $pkgsubmit_out;
    my $ok = eval { IPC::Run::run( \@cmd, \undef, '>&', \$pkgsubmit_out ) };

    if ( !$ok || $EVAL_ERROR ) {
      $logger->error($EVAL_ERROR) if $EVAL_ERROR;
      $logger->error("Failed to run pkgsubmit: $pkgsubmit_out");
      $success = 0;
    } else {
      $logger->info("Successfully submitted $files_count packages for '$id'");
    }

  }

  return $success;
}

1;
__END__
