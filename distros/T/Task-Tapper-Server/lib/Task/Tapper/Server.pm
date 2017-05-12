use strict;
use warnings;
package Task::Tapper::Server;
# git description: 389cfe0de3368ba6fc9972cf950a0c8b0310ac5f

BEGIN {
  $Task::Tapper::Server::AUTHORITY = 'cpan:AMD';
}
{
  $Task::Tapper::Server::VERSION = '0.001';
}
# ABSTRACT: Tapper - dependencies for central server




__END__
=pod

=head1 NAME

Task::Tapper::Server - Tapper - dependencies for central server

=head1 VERSION

version 0.001

=head1 TASK CONTENTS

=head2 Explicit troublemaker deps

=head3 L<File::Slurp>

=head3 L<File::Copy::Recursive>

=head3 L<Test::WWW::Mechanize>

=head3 L<IO::Interactive>

=head3 L<DBI>

=head3 L<DBD::mysql>

=head3 L<DBD::Pg>

=head3 L<DBD::SQLite>

=head3 L<Template::Plugin::Autoformat>

=head3 L<Module::Install::Catalyst>

=head2 Tapper

=head3 L<Tapper::Config>

=head3 L<Tapper::CLI>

=head3 L<Tapper::TAP::Harness>

=head3 L<Tapper::Testplan>

=head3 L<Tapper::Reports::Receiver>

=head3 L<Tapper::Reports::API>

=head3 L<Tapper::Reports::Web>

1;

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

