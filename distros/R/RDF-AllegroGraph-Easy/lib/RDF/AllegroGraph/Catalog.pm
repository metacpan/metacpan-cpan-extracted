package RDF::AllegroGraph::Catalog;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

=pod

=head1 NAME

RDF::AllegroGraph::Catalog - AllegroGraph catalog handle (abstract)

=head1 SYNOPSIS

   my $server = new RDF::AllegroGraph::Server (ADDRESS => 'http://localhost:8080');
   my $vienna = new RDF::AllegroGraph::Catalog (NAME => '/vienna', SERVER => $server);

   warn "all repositories in vienna: ".Dumper $vienna->repositories;

   # open an existing
   my $air   = $vienna->repository ('/vienna/air-quality');
   # create one if it does not exist
   use Fcntl;
   my $water = $vienna->repository ('/vienna/water', mode => O_CREAT);

=head1 DESCRIPTION

AllegroGraph catalogs are containers for individual repositories
(L<RDF::AllegrGraph::Repository>). The latter roughly correspond to what the RDF folks call a
I<model>. You can get a catalog handle from the AG server (L<RDF::AllegroGraph::Server>).

=head2 Naming

AllegroGraph understands I<catalogs> and I<repositories>. While the latter are mostly what RDF model
are called elsewhere, catalogs are containers for a set of repositories. I<Named catalogs> are
supported by this interface, you will have to configure them either in the C<agraph.cfg>
configuration file, or create them with the web interface (since AGv4). Since AGv4 there is also the
I<root container>. It always exists.

To provide a consistent naming, this interface uses a simple path language:

=over

=item C</>

This specifies the root container. Any repository (such as, say, C<catlitter>) is
addressable via C</catlitter>.

=item C</[named]>

Named catalogs (such as, say, C<scratch>) are addressed as C</scratch> and, yes, without further
context it is now not decidable whether C</scratch> is a repository inside the root catalog or a
catalog on it own.

Anyways, .... repositories B<inside> one named catalog are again unambigously addressable, such as
C</scratch/catlitter>.

=back

=head2 AG version 3 and 4

This is interface supports AGv3 (3.3 onwards) and AGv4 (4.2 onwards), even though many features will
be missing (until I really need them). Still, the overall interface tries to be as version agnostic
as possible. When this fails, you should consult the proper subclass for the version, such as
L<RDF::AllegroGraph::Server4> for example.

=head1 INTERFACE

=head2 Constructor

The constructor expects the following options:

=over

=item C<NAME> (mandatory, string)

This is a string of the form C</mycatalog> and it identifies that very catalog on the server.

=item C<SERVER> (mandatory, L<RDF::AllegroGraph::Server> object)

This is the handle to the server.

=back

Example:

   my $server = new RDF::AllegroGraph::Server (...);
   my $vienna = new RDF::AllegroGraph::Catalog (NAME => '/vienna', SERVER => $server);


=head2 Methods

=over

=item B<repositories>

I<@repos> = I<$cat>->repositories

This method returns a list of L<RDF::AllegroGraph::Repository> objects of this catalog.

=cut

sub repositories {
    die;
}

=pod

=item B<repository>

I<$repo> = I<$cat>->repository (I<$repo_id> [, I<$mode> ])

This method returns an L<RDF::AllegroGraph::Repository> object for the repository with
the provided id. That id always has the form C</somerepository>.

If that repository does not exist in the catalog, then an exception C<cannot open> will be
raised. That is, unless the optional I<mode> is provided having the POSIX value C<O_CREAT>. Then the
repository will be created.

=cut

sub repository {
    die;
}

=pod

=item B<version>

This method simply returns the version supported by the protocol, in the form of C<3.3>, or similar.

=cut

sub version {
    die;
}

=pod

=item B<protocol>

This method returns the protocol version the catalog supports.

=cut

sub protocol {
    die;
}


=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(09|1[01]) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

our $VERSION  = '0.06';

1;

__END__

