#!/usr/bin/perl

package Task::KiokuDB;

use strict;
use warnings;

use 5.008;

our $VERSION = "0.07";

__PACKAGE__

__END__

=pod

=head1 NAME

Task::KiokuDB - Install L<KiokuDB> and related modules.

=head1 DESCRIPTION

This bundle installs L<KiokuDB> and depending on the environment several
additional components.

=head1 MODULES

All of these are considered optional.

=over 4

=item L<KiokuDB::Cmd>

Commands for the C<kioku> command line program.

=item L<KiokuDB::Backend::BDB>

L<BerkeleyDB> backend. Requires an installed BerkeleyDB, preferably linked
against 4.7.

Defaults false to unless BDB seems to be installed.

=item L<KiokuDB::Backend::DBI>

The L<DBI> backend.

Defaults to true if you have one of the tested DBDs (SQLite, Pg, or mysql)

=item L<KiokuDB::Backend::CouchDB>

Defaults to true if you have L<AnyEvent::CouchDB>.

=item L<Data::UUID::LibUUID>

Better UUID generation than L<Data::UUID> (not time based). Requires C<libuuid>
which is available by default on Mac OS X, and easy to install on most Linux
distributions.

Defaults to false, unless C<uuid.h> can be found and you have a compiler.

=item L<JSON::XS>

Provides faster JSON performance.

Defaults to true if you have a compiler.

=item L<YAML::XS>

Allows dumping/loading DBs as YAML, using YAML serialization, and importing to
a DB using L<MooseX::YAML> with modern/up to spec YAML files.

Defaults to true if you have a compiler.

=item L<KiokuX::User>

A reusable role for user objects with L<Authen::Passphrase> based
authentication

=item L<KiokuX::Model>

A wrapper for integrating L<KiokuDB> plus per app convenience methods into
frameworks.

=item L<Catalyst::Model::KiokuDB>

L<Catalyst> integration using L<KiokuX::Model>.

=back

=head1 LICENSE

MIT

=head1 AUTHOR

Yuval Kogman

=cut
