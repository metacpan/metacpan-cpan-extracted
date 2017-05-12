package PkgForge::BuildCommand::Check::RPMLint;    # -*-perl-*-
use strict;
use warnings;

# $Id: RPMLint.pm.in 16798 2011-04-22 11:50:05Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16798 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildCommand/Check/RPMLint.pm.in $
# $Date: 2011-04-22 12:50:05 +0100 (Fri, 22 Apr 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Spec ();
use IO::File ();
use IPC::Run ();

use Readonly;

Readonly my $RPMLINT           => '/usr/bin/rpmlint';
Readonly my $ERRORS_FOUND_CODE => 64;

use overload q{""} => sub { shift->stringify };

use Moose;

with 'PkgForge::BuildCommand::Check';

has '+tools' => (
  default => sub { [$RPMLINT] },
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub run {
  my ( $self, $job, $buildinfo, $buildlog ) = @_;

  my $logger = $buildlog->logger;

  my $logdir = $buildlog->logdir;

  my $rpmlint_log = File::Spec->catfile( $logdir, 'check-rpmlint.log' );
  my $logfh = IO::File->new( $rpmlint_log, 'w' )
    or $logger->log_and_die(
        level   => 'error',
        message => "Could not open '$rpmlint_log' for writing: $OS_ERROR",
      );

  $logfh->autoflush(1);

  $buildinfo->add_logs($rpmlint_log);

  my $errors = 0;
  for my $pkg ($buildinfo->products_list) {
    if ( $pkg !~ m/\.rpm$/ || $pkg =~ m/\.src\.rpm$/ ) {
      next;
    }

    $logger->info("Running rpmlint on $pkg");
    $logfh->print("Running rpmlint on $pkg\n");

    my @cmd = ( $RPMLINT, $pkg );

    $logger->debug("Will run command '@cmd'");

    my $rpmlint_out;
    my $ok = eval { IPC::Run::run( \@cmd, \undef, '>&', \$rpmlint_out ) };
    my $err_msg   = $EVAL_ERROR;
    my $exit_code = $CHILD_ERROR >> 8;
    my $errors_found = $exit_code & $ERRORS_FOUND_CODE;

    $logfh->print($rpmlint_out);
    $logfh->print("\n\n");

    if ( $err_msg || ( !$ok && !$errors_found ) ) {
      $logger->log_and_die(
        level   => 'error',
        message => "Failed to run rpmlint: $err_msg",
      );
    }

    if ($errors_found) {
      $errors++;
      $logger->error("Package '$pkg' failed the rpmlint check");
    } else {
      $logger->info("Package '$pkg' passed the rpmlint check");
    }

  }

  $logfh->close();

  # For now we are not requiring the passing of rpmlint checks
  #return ( $errors == 0 ? 1 : 0 );
  return 1;
}

1;
__END__
