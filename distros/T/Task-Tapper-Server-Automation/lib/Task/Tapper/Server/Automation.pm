use strict;
use warnings;
package Task::Tapper::Server::Automation;
# git description: caec9eb085e3a752c42522a38c4dc3805ce6920c

BEGIN {
  $Task::Tapper::Server::Automation::AUTHORITY = 'cpan:AMD';
}
{
  $Task::Tapper::Server::Automation::VERSION = '0.001';
}
# ABSTRACT: Tapper - dependencies for automation layer




__END__
=pod

=head1 NAME

Task::Tapper::Server::Automation - Tapper - dependencies for automation layer

=head1 VERSION

version 0.001

=head1 TASK CONTENTS

=head2 Explicit troublemaker deps

=head3 L<Proc::ProcessTable>

=head3 L<App::Daemon>

=head2 Tapper

=head3 L<Tapper::Action>

=head3 L<Tapper::Producer>

=head3 L<Tapper::MCP>

=head3 L<Tapper::Notification>

=head3 L<Tapper::MCP::MessageReceiver>

1;

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

