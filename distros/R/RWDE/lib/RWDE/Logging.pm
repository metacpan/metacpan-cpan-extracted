package RWDE::Logging;

use strict;
use warnings;

use RWDE::Logger;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::Logging

=cut

=head2 syslog_msg()

=cut

sub syslog_msg {
  my ($self, $type, $info) = @_;
                                 
  return RWDE::Logger->syslog_msg($type, $info);
}

=head2 debug_info()

=cut

sub debug_info {
  my ($self, $type, $info) = @_;

  return RWDE::Logger->debug_info($type, $info);
}

=head2 is_debug()

=cut

sub is_debug {
  return RWDE::Logger->is_debug;
}


1;
