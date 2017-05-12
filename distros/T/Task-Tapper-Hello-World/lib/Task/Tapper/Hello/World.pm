use strict;
use warnings;
package Task::Tapper::Hello::World;
# git description: v0.002-1-gb7a3b9e

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Tapper - The easiest start without hassle (hopefully)
$Task::Tapper::Hello::World::VERSION = '0.003';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::Tapper::Hello::World - Tapper - The easiest start without hassle (hopefully)

=head1 VERSION

version 0.003

=head1 TASK CONTENTS

=head2 Explicit troublemaker deps

=head3 L<File::Slurp>

=head3 L<File::Copy::Recursive>

=head3 L<Test::WWW::Mechanize>

=head3 L<IO::Interactive>

=head3 L<DBI>

=head3 L<DBD::SQLite>

=head3 L<Template::Plugin::Autoformat>

=head3 L<Module::Install::Catalyst>

=head2 Tapper

=head3 L<Tapper::Config>

=head3 L<Tapper::CLI>

=head3 L<Tapper::TAP::Harness>

=head3 L<Tapper::Reports::Receiver>

=head3 L<Tapper::Reports::API>

=head3 L<Tapper::Reports::Web>

=head3 L<Tapper::TestSuite::AutoTest>

=head3 L<Tapper::TestSuite::HWTrack>

=head3 L<Tapper::MCP>

=head3 L<Tapper::MCP::MessageReceiver>

=head3 L<Task::Tapper::Client>

=head3 L<Tapper::Reports::Receiver::Level2::BenchmarkAnything>

1;

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Steffen Schwigon.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
