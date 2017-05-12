=head1 NAME

 Prospect::SoapServer -- execute Prospect locally
 $Id: SoapServer.pm,v 1.9 2003/11/04 01:01:32 cavs Exp $

=head1 SYNOPSIS

 use Prospect::SoapServer;
 use Prospect::Options;
 my $p2options = new Prospect::Options;
 my $p2factory = new Prospect::SoapServer( {options=>$p2options} );
 my $xmlout = $p2factory->thread( $sequence );

=head1 DESCRIPTION

B<Prospect::SoapServer> is runs Prospect remotely using SOAP as the
protocol.  Utilize a LocalClient object to actually run Prospect.

=head1 ROUTINES & METHODS

=cut


package Prospect::SoapServer;

use base Prospect::Client;

use warnings;
use strict;
use Data::Dumper;
use Prospect::Exceptions;
use Prospect::LocalClient;
use Prospect::Options;
use Bio::Seq;
use SOAP::Lite;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/ );


sub new() {
  my $type = shift;
  my $self = {};
  return (bless $self,$type);
}


#-------------------------------------------------------------------------------
# thread_summary()
#-------------------------------------------------------------------------------

=head2 thread_summary()

 Name:      thread_summary()
 Purpose:   thread a sequence using Prospect::LocalClient
 Arguments: comma-separated list:
    0 - string containing sequence id
    1 - string, contains protein sequence (or '' if secondary structure is
        defined in #2)
    2 - string, contains secondary structure information in phd format
        (or '' if sequence is defined in #1)
    3 - string, one of 'scop', 'fssp', 'all' (or '' if templates is defined in #4)
        to define a template set
    4 - string, contains a space-separated list of templates (or '' if
        template set is defined in #3)
    5 - string, one of 'global' or 'global_local' for alignment type
    6 - string, either '0' (false) or '1' (true) for calculating zscores
 Returns:   XML string containing prospect results

=cut

sub thread_summary($$) {
  my ($self,$seqID,$s,$secondaryStructure,$templateSet,$templates,$alignmentType,$calculateZscores) = @_;

  my $opts = &_parseOptions($templateSet,$templates,$alignmentType,$calculateZscores);

  # use LocalClient to do the work
  my $LocalClient = new Prospect::LocalClient( {options=>$opts} );
  my $seq = new Bio::Seq( -display_id => $seqID, -seq => $s );
  my @threads = $LocalClient->thread_summary( $seq );

  return( \@threads );
}


#-------------------------------------------------------------------------------
# xml()
#-------------------------------------------------------------------------------

=head2 thread()

 Name:      xml()
 Purpose:   thread a sequence using Prospect::LocalClient
 Arguments: comma-separated list:
    0 - string containing sequence id
    1 - string, contains protein sequence (or '' if secondary structure is
        defined in #2)
    2 - string, contains secondary structure information in phd format
        (or '' if sequence is defined in #1)
    3 - string, one of 'scop', 'fssp', 'all' (or '' if templates is defined in #4)
        to define a template set
    4 - string, contains a space-separated list of templates (or '' if
        template set is defined in #3)
    5 - string, one of 'global' or 'global_local' for alignment type
    6 - string, either '0' (false) or '1' (true) for calculating zscores
 Returns:   XML string containing prospect results

=cut

sub xml($$) {
  my ($self,$seqID,$s,$secondaryStructure,$templateSet,$templates,$alignmentType,$calculateZscores) = @_;

  my $opts = &_parseOptions($templateSet,$templates,$alignmentType,$calculateZscores);

  # use LocalClient to do the work
  my $LocalClient = new Prospect::LocalClient( {options=>$opts} );
  my $seq = new Bio::Seq( -display_id => $seqID, -seq => $s );
  my $xml = $LocalClient->xml( $seq );

  return( $xml );
}


#-------------------------------------------------------------------------------
# ping()
#-------------------------------------------------------------------------------

=head2 ping()

 Name:      ping()
 Purpose:   return whether alive or not
 Arguments: none
 Returns:   0 - dead, 1 - alive

=cut

sub ping {
  return 1;
}


#-------------------------------------------------------------------------------
# INTERNAL METHODS: not intended for use outside this module
#-------------------------------------------------------------------------------

=pod

=head1 INTERNAL METHODS & ROUTINES

The following functions are documented for developers' benefit.  THESE
SHOULD NOT BE CALLED OUTSIDE OF THIS MODULE.  YOU'VE BEEN WARNED.

=cut

#-------------------------------------------------------------------------------
# _parseOption()
#-------------------------------------------------------------------------------

=head2 _parseOption()

 Name:      _parseOption()
 Purpose:   parse arguments to the thread, thread_summary, and xml() methods
 Arguments: comma-separated list:
    1 - string, one of 'scop', 'fssp', 'all' (or '' if templates is defined in #4)
        to define a template set
    2 - string, contains a space-separated list of templates (or '' if
        template set is defined in #3)
    3 - string, one of 'global' or 'global_local' for alignment type
    4 - string, either '0' (false) or '1' (true) for calculating zscores
 Returns:   Prospect::Options object

=cut

sub _parseOptions {
  my ($templateSet,$templates,$alignmentType,$calculateZscores) = @_;

  # build Prospect::Options.  howto handle caching???
  my $opts = new Prospect::Options;

  $opts->{'templates'} = [ split /,/,$templates ] if defined $templates;
  $opts->{'zscore'} = $calculateZscores if defined $calculateZscores;
  $opts->{'global_local'} = ( defined $alignmentType ) ?  $alignmentType : '-global';
  $opts->{'svm'} = 1;
  $opts->{'seq'} = 1;

  return( $opts );
}


1;
