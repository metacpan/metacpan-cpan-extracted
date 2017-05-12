package RDF::AllegroGraph::Catalog4;

use strict;
use warnings;

require Exporter;
use base qw(RDF::AllegroGraph::Catalog);

=pod

=head1 NAME

RDF::AllegroGraph::Catalog4 - AllegroGraph catalog handle for AGv4

=cut

use RDF::AllegroGraph::Repository4;
use RDF::AllegroGraph::Utils;

use JSON;
use HTTP::Status;
use Fcntl;
use Data::Dumper;

=pod

=head1 INTERFACE

=head2 Constructor

The constructor will try to connect to the server and will C<die> if fetching the repositories (even
the empty list) fails.

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    die "no NAME"   unless $options{NAME};
    die "no SERVER" unless $options{SERVER};
    my $self = bless \%options, $class;
    eval {                                                          # test whether it exists, by probing the repositories (could be anything else for that matter)
	$self->repositories unless $self->{NAME} eq '/';            # for non-root catalogs we check whether they exist
    }; if ($@) {                                                    # if something weird happened here
	die "catalog '".$self->{NAME}."' does not exist on the server";
    }
    return $self;                                                   # otherwise we continue with normal business
} 

=pod


=head2 Methods

=over

=item B<disband>

Removes the named catalog from the server.

B<NOTE>: I have no idea what happens with any repositories in there.

=cut

sub disband {
    my $self = shift;
    my $requ = HTTP::Request->new (DELETE => $self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME});
    my $resp = $self->{SERVER}->{ua}->request ($requ);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
}

=pod

=item B<repositories>

I<@repos> = I<$cat>->repositories

This method returns a list of L<RDF::AllegroGraph::Repository> objects of this catalog.

=cut

sub repositories {
    my $self = shift;
    my $resp = $self->{SERVER}->{ua}->get ($self->{SERVER}->{ADDRESS} . ($self->{NAME} eq '/' 
                                                                            ? '' 
                                                                            : '/catalogs' . $self->{NAME} ) . '/repositories');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    my $repo = from_json ($resp->content);
    return
	map { RDF::AllegroGraph::Repository4->new (%$_, CATALOG => $self) }
	map { RDF::AllegroGraph::Utils::_hash_to_perl ($_) }
        @$repo;
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
    my $self = shift;
    my $id   = shift;
    my $mode = shift || O_RDONLY;

    if (my ($repo) = grep { $_->id eq $id } $self->repositories) {
	return $repo;
    } elsif ($mode == O_CREAT) {
	my $uri;
	if ($id =~ m{^(/[^/]+)$}) {  # root catalog repo
	    my $repoid = $1;
	    die "do not want to open root catalog repository within non-root catalog" unless $self->{NAME} eq '/'; # we are not inside the root catalog?
	    $uri = $self->{SERVER}->{ADDRESS} . '/repositories' . $repoid;                                   # create the uri for below
	} elsif ($id =~ m{^(/[^/]+?)(/.+)$}) {
	    my $catid  = $1;
	    my $repoid = $2;
	    die "do not want to open non-root repository in named catalog" unless $self->{NAME} eq $1;
	    $uri = $self->{SERVER}->{ADDRESS} . '/catalogs' . $catid . '/repositories' . $repoid;
	} else {
	    die "cannot handle repository id '$id'";
	}
        use HTTP::Request;
	my $requ = HTTP::Request->new (PUT => $uri);
	my $resp = $self->{SERVER}->{ua}->request ($requ);
	die "protocol error: ".$resp->status_line unless $resp->code == RC_NO_CONTENT;
	return $self->repository ($id);                                                    # recursive, but without forced create
    } else {
	die "cannot open repository '$id'";
    }
}

=pod

=item B<protocol>

This method returns the protocol version the catalog supports.

=cut

sub protocol {
    my $self = shift;
    my $resp = $self->{SERVER}->{ua}->get ($self->{SERVER}->{ADDRESS} . ($self->{NAME} eq '/' 
                                                                            ? '/protocol' 
                                                                            : '/catalogs' . $self->{NAME} . '/protocol'));
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    return $resp->content =~ m/^"?(.*?)"?$/ && $1;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(09|10|11) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

our $VERSION  = '0.04';

1;

__END__

