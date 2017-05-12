package RDF::AllegroGraph::Server4;

use strict;
use warnings;

use base qw(RDF::AllegroGraph::Server);

use JSON;
use Data::Dumper;

use RDF::AllegroGraph::Catalog4;
use HTTP::Request::Common;
use HTTP::Status;

=pod

=head1 NAME

RDF::AllegroGraph::Server4 - AllegroGraph server handle for v4 AG servers

=head1 INTERFACE

=head2 Methods

=over

=item B<catalogs>

I<@cats> = I<$server>->catalogs

This method lists the catalogs available on the remote server. The result is a list of relative
paths. 

=cut

sub catalogs {
    my $self = shift;
    my $resp = $self->{ua}->get ($self->{ADDRESS} . '/catalogs');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    my $cats = from_json ($resp->content);
    return 
	map { $_ => RDF::AllegroGraph::Catalog4->new (NAME => $_, SERVER => $self) }
        map { $_ =~ m{/} ? $_ : "/$_" }        # canonicalize everything to look /....
        map { $_->{id} }                       # look only at the id component (the other is the uri)
        @$cats;
}

=pod

=item B<catalog>

This method returns a handle to a named catalog. If it already exists on the
server, the handle is simply returned. Otherwise - if the C<mode> is set to C<O_CREAT> -
a new catalog will be created. Otherwise an exception is raised.

=cut

use Fcntl;

sub catalog {
    my $self = shift;
    my $id   = shift;
    my $mode = shift || O_RDONLY;

    my %cats = $self->catalogs;                                           # let's have a look first, what's there...
    if ($cats{$id}) {
	return $cats{$id};

    } elsif ($mode == O_CREAT) {
	if ($id =~ m{^(/[^/]+)$}) {
	    my $uri = $self->{ADDRESS} . '/catalogs' . $1;
	    use HTTP::Request;
	    my $requ = HTTP::Request->new (PUT => $uri);
	    my $resp = $self->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line unless $resp->code == RC_NO_CONTENT;
	    return RDF::AllegroGraph::Catalog4->new (NAME => $id, SERVER => $self);
	} else {
	    die "cannot handle catalog id '$id'";
	}
	
    } else {
	die "cannot open catalog '$id' (does not exist on the server";
    }
}

=pod

=item B<models>

I<%models> = I<$server>->models

This method lists all models available on the server. Returned is a hash reference. The keys are the
model identifiers, all of the form C</somecatalog/somerepository>. The values are repository objects.

=cut

sub models {
    my $self = shift;
    my %cats = $self->catalogs;                                      # find all catalogs
    return
	map { $_->id => $_ }                                         # generate a hash, because the id is a good key
	map { $_->repositories }                                     # generate from the catalog all its repos
        values %cats;          
}

=pod

=item B<model>

I<$server>->model (I<$mod_id>, I<option1> => I<value1>, ...)

This method tries to find an repository in a certain catalog. This I<model id> is always of the form
C</somecatalog/somerepository>. The following options are understood:

=over

=item C<MODE> (default: C<O_RDONLY>)

This POSIX file mode determines how the model will be opened.

=back

If the model already does exist, then an L<RDF::AllegroGraph::Repository> object will be
returned. If the specified catalog does not exist, then a C<no catalog> exception will be raised.
Otherwise, if the repository there does not exist and the C<MODE> option is C<O_CREAT>, then it will
be generated. Otherwise an exception C<cannot open repository> will be raised.

=cut


sub model {
    my $self = shift;
    my $id   = shift;
    my %options = @_;

    my ($catid, $repoid);                                            # we will have to figure them out
    if (($catid, $repoid) = ($id =~ m|^(/.+?)(/.+)$|)) {
    } elsif ($id =~ m|^/[^/]+$|) {
	($catid, $repoid) = ('/', $id);
    } else {
	die "id must be of the form /somecat/somerep or /somerep";
    }
    my %catalogs = $self->catalogs;
    die "no catalog '$catid'" unless $catalogs{$catid};

    return $catalogs{$catid}->repository ($id, $options{mode});
}

=pod

=item B<reconfigure> (since v0.06)

This method triggers the server to reconsult the configuration. As it is only available to the
I<super> user, lesser accounts will fail at that.

=cut

sub reconfigure {
    my $self = shift;
    my $resp = $self->{ua}->post ($self->{ADDRESS} . '/reconfigure');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
}

=pod

=item B<reopen_log> (since v0.06)

This method triggers the server to reopen the logfile (say for logfile rotation). As it is only available to the
I<super> user, lesser accounts will fail at that.

B<NOTE>: Since you will not be able to move the log file via this API, this is a somewhat strange
function.

=cut

sub reopen_log {
    my $self = shift;
    my $resp = $self->{ua}->post ($self->{ADDRESS} . '/reopenLog');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(09|11) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>, L<RDF::AllegroGraph::Repository4>

=cut

our $VERSION  = '0.03';

1;

__END__


