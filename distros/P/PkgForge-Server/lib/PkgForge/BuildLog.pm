package PkgForge::BuildLog;    # -*-perl-*-
use strict;
use warnings;

# $Id: BuildLog.pm.in 16584 2011-04-05 10:09:34Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16584 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildLog.pm.in $
# $Date: 2011-04-05 11:09:34 +0100 (Tue, 05 Apr 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Spec ();

use Moose;
use MooseX::Types::Moose qw(Bool Str);

with 'MooseX::LogDispatch';

has 'debug' => (
  is      => 'rw',
  isa     => Bool,
  default => 0,
  documentation => 'Controls whether or not to log debugging messages'
);

has 'logfile' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  lazy     => 1,
  default  => sub {
    my $self = shift @_;
    my $logfile = File::Spec->catfile( $self->logdir,
                                       'pkgforge-build.log' );
  },
  documentation => 'The PkgForge build log file',
);

has 'logdir' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  default  => '.',
  documentation => 'Where the pkgforge build log will be stored'
);

has 'log_dispatch_conf' => (
  is       => 'ro',
  isa      => 'HashRef',
  lazy     => 1,
  required => 1,
  default  => sub {
    my $self = shift;

    return {
      class          => 'Log::Dispatch::File',
      min_level      => ( $self->debug ? 'debug' : 'info' ),
      filename       => $self->logfile,
      mode           => 'append',
      format         => '[%d] [%p] %m%n',
      close_on_write => 1,
    };
  },
  documentation => 'The configuration for Log::Dispatch',
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
