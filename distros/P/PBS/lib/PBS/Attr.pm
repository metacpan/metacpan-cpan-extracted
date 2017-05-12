package PBS::Attr;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PBS::Attr ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
	MAXNAMLEN
	MAXPATHLEN
	MAX_ENCODE_BFR
	MGR_CMD_ACTIVE
	MGR_CMD_CREATE
	MGR_CMD_DELETE
	MGR_CMD_LIST
	MGR_CMD_PRINT
	MGR_CMD_SET
	MGR_CMD_UNSET
	MGR_OBJ_JOB
	MGR_OBJ_NODE
	MGR_OBJ_NONE
	MGR_OBJ_QUEUE
	MGR_OBJ_SERVER
	MSG_ERR
	MSG_OUT
	PBS_BATCH_SERVICE_PORT
	PBS_BATCH_SERVICE_PORT_DIS
	PBS_INTERACTIVE
	PBS_MANAGER_SERVICE_PORT
	PBS_MAXCLTJOBID
	PBS_MAXDEST
	PBS_MAXGRPN
	PBS_MAXHOSTNAME
	PBS_MAXPORTNUM
	PBS_MAXQUEUENAME
	PBS_MAXROUTEDEST
	PBS_MAXSEQNUM
	PBS_MAXSERVERNAME
	PBS_MAXSVRJOBID
	PBS_MAXUSER
	PBS_MOM_SERVICE_PORT
	PBS_SCHEDULER_SERVICE_PORT
	PBS_TERM_BUF_SZ
	PBS_TERM_CCA
	PBS_USE_IFF
	RESOURCE_T_ALL
	RESOURCE_T_NULL
	SHUT_DELAY
	SHUT_IMMEDIATE
	SHUT_QUICK
	SHUT_SIG
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
	MAXNAMLEN
	MAXPATHLEN
	MAX_ENCODE_BFR
	MGR_CMD_ACTIVE
	MGR_CMD_CREATE
	MGR_CMD_DELETE
	MGR_CMD_LIST
	MGR_CMD_PRINT
	MGR_CMD_SET
	MGR_CMD_UNSET
	MGR_OBJ_JOB
	MGR_OBJ_NODE
	MGR_OBJ_NONE
	MGR_OBJ_QUEUE
	MGR_OBJ_SERVER
	MSG_ERR
	MSG_OUT
	PBS_BATCH_SERVICE_PORT
	PBS_BATCH_SERVICE_PORT_DIS
	PBS_INTERACTIVE
	PBS_MANAGER_SERVICE_PORT
	PBS_MAXCLTJOBID
	PBS_MAXDEST
	PBS_MAXGRPN
	PBS_MAXHOSTNAME
	PBS_MAXPORTNUM
	PBS_MAXQUEUENAME
	PBS_MAXROUTEDEST
	PBS_MAXSEQNUM
	PBS_MAXSERVERNAME
	PBS_MAXSVRJOBID
	PBS_MAXUSER
	PBS_MOM_SERVICE_PORT
	PBS_SCHEDULER_SERVICE_PORT
	PBS_TERM_BUF_SZ
	PBS_TERM_CCA
	PBS_USE_IFF
	RESOURCE_T_ALL
	RESOURCE_T_NULL
	SHUT_DELAY
	SHUT_IMMEDIATE
	SHUT_QUICK
	SHUT_SIG
);

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&PBS::Attr::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('PBS::Attr', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

PBS::Attr - Perl extension for PBS

=head1 SYNOPSIS

  use strict;
  use PBS;
  use PBS::Status;
  use PBS::Attr();

  my $pbs = PBS->new();
  $pbs->connect() || die $pbs->error(), "\n";

  my $stat = $pbs->stat_queue("queue_name");
          or
  my $stat = $pbs->stat_node("node_name");
          or
  my $stat = $pbs->stat_job("job_id");
       
  foreach my $s (@$stat) {
      print $s->{'name'}, " ", $s->{'text'}, "\n";
      my $attrs = $s->{'attributes'};
      my $attr_list = $attrs->get();
      foreach my $a (@$attr_list) {
          print $a->{'name'}, "=", $a->{'value'}, "\n";
      }
  }    
      
  $pbs->disconnect();

=head1 DESCRIPTION

Perl interface to the PBS attrl data structures.

=head2 EXPORT

None by default.

=head2 Exportable constants

  
  MAXNAMLEN
  MAXPATHLEN
  MAX_ENCODE_BFR
  MGR_CMD_ACTIVE
  MGR_CMD_CREATE
  MGR_CMD_DELETE
  MGR_CMD_LIST
  MGR_CMD_PRINT
  MGR_CMD_SET
  MGR_CMD_UNSET
  MGR_OBJ_JOB
  MGR_OBJ_NODE
  MGR_OBJ_NONE
  MGR_OBJ_QUEUE
  MGR_OBJ_SERVER
  MSG_ERR
  MSG_OUT
  PBS_BATCH_SERVICE_PORT
  PBS_BATCH_SERVICE_PORT_DIS
  PBS_INTERACTIVE
  PBS_MANAGER_SERVICE_PORT
  PBS_MAXCLTJOBID
  PBS_MAXDEST
  PBS_MAXGRPN
  PBS_MAXHOSTNAME
  PBS_MAXPORTNUM
  PBS_MAXQUEUENAME
  PBS_MAXROUTEDEST
  PBS_MAXSEQNUM
  PBS_MAXSERVERNAME
  PBS_MAXSVRJOBID
  PBS_MAXUSER
  PBS_MOM_SERVICE_PORT
  PBS_SCHEDULER_SERVICE_PORT
  PBS_TERM_BUF_SZ
  PBS_TERM_CCA
  PBS_USE_IFF
  RESOURCE_T_ALL
  RESOURCE_T_NULL
  SHUT_DELAY
  SHUT_IMMEDIATE
  SHUT_QUICK
  SHUT_SIG



=head1 SEE ALSO

See the documentation for PBS and PBS::Status

=head1 AUTHOR

Todd Merritt, E<lt>tmerritt@email.arizona.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Todd Merritt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
