package RDF::Trine::Store::AllegroGraph;

use strict;
use warnings;
use base qw(RDF::Trine::Store);

use Data::Dumper;

our $VERSION;
BEGIN {
    $VERSION        = "0.1";
    my $class       = __PACKAGE__;
    $RDF::Trine::Store::STORE_CLASSES{ $class }     = $VERSION;
}

=head1 NAME

RDF::Trine::Store::AllegroGraph - Triple store implementation based on AGv4

=head1 SYNOPSIS

    use RDF::Trine::Store::AllegroGraph;
    my $trine = RDF::Trine::Store->new_with_string( "AllegroGraph;http://ag_server:10035/scratch/catlitter" );

    # use the RDF::Trine::Store API

=head1 DESCRIPTION

This package implements the RDF::Trine::Store API on the basis of the AllegroGraph v4 Perl client.

You will almost never invoke any of the functions/methods here directly, but will peruse the Trine
invocation stack. The only exception for that are those things which an AGv4 repository offers, but
are not covered by the Trine API. These are, among other things:

=over

=item 

I<Prolog> rule based querying

=item 

I<sessions> and I<transactions>

=item 

I<geo-spatial> support

=item 

I<social network analysis>

=back

For these I suggest that you pull out the AGv4 repository from the trine store like this:

   my $repo = $store->{model};
   my $result = $repo->prolog ("....");

B<NOTE>: This will probably change as L<RDF::Trine> evolves.

=head2 Restrictions/Shortcomings

=over

=item For the time being this will not be fast, and that for a number of reasons.

=item This store has native support for SPQARL 1.0. You should be able to use SPARQL 1.1 as that
will be intercepted by the Trine framework. It will be slow, though, as it will be pulling
statements individually. To handle this properly will be future work.

=back


=head1 INTERFACE

=head2 Constructor(s)

Are essentially those from L<RDF::Trine::Store> with the following flavor:

=over

=item C<_new_with_object> accepts one RDF::AllegroGraph::Repository4 object.

That will be wrapped into the store and used from then on.

=item C<_new_with_string> accepts a string of the following form:

   AllegroGraph;<HTTP-address-of-server>/<catalog-name>/<repository-name>

such as

   AllegroGraph;http://super:super@127.0.0.1:10035/test/experiment

B<NOTE>: If the repository does not exist, it will be generated (that usually takes a bit of time
with AG).

=item C<_new_with_config> accepts a hash with the following fields:

=over

=item C<storetype>

must be C<AllegroGraph>

=item C<server> 

must be an HTTP URL of the server (excluding trailing slash), defaults to C<http://127.0.0.1:10035>

=item C<catalog> 

must be an identifier of the form /something

=item C<repository>

must be an identifier of the form /somethingelse

=item C<username> 

is used for authentication

=item C<password>

ditto

=back

=back

=cut

sub _new_with_object {
    my $class = shift;
    my $obj   = shift;
    die "no valid AllegroGraph repository" unless $obj->isa ('RDF::AllegroGraph::Repository4');
    return bless { model => $obj }, $class;
}

sub _new_with_config {
    my $class = shift;
    my $config = shift;
    $config->{server}   ||= 'http://127.0.0.1:10035';
    $config->{catalog}    =~ m{^/\w+} or die "catalog identifier should be of the form /something";
    $config->{repository} =~ m{^/\w+} or die "repository identifier should be of the form /something";

    my $server = $config->{server};
    $server =~ s{http://}{http://$config->{username}:$config->{password}\@} if $config->{username};
    my $url = $server . $config->{catalog} . $config->{repository};
    return $class->_new_with_string ($url);
}

sub _new_with_string {
    my $class  = shift;
    my $config = shift;
    use URI;
    my $uri    = new URI ($config);
    my $server = sprintf "%s://%s", $uri->scheme, $uri->authority;

    use RDF::AllegroGraph::Easy;
    my $storage = new RDF::AllegroGraph::Easy ($server);                                # we get hold of the backend server
    use Fcntl;
    my $model = $storage->model ($uri->path, mode => O_CREAT);                          # and break out one model
    return bless { model => $model }, $class;
}

=pod

=head2 Methods

=over

=item B<temporary_store>

This is not implemented as we need serious information to actually create a repository (and to get
rid of it eventually).

TODO: As additional parameters could provide this information, one could use that.

=cut

sub temporary_store {
    my $class = shift;
    die "cannot create a temporary store without information about the AG server";
}

=pod

=item B<supports>

Currently this store supports the following features:

=over

=item http://www.w3.org/ns/sparql-service-description#SPARQL10Query

I.e. SPARQL 1.0 queries can be directly funneled into here.

=back

=cut

my %features = map { $_ => 1 } (
			       'http://www.w3.org/ns/sparql-service-description#SPARQL10Query',
			       );
sub supports {
    my $self = shift;
    if (@_) {
	my $f = shift;
	return $features{ $f };
    } else {
	return keys %features;
    }
}

=pod

=item B<get_sparql>

If you pass in a string holding a SPARQL query, then you will get back an
L<RDF::Trine::Iterator::Bindings> iterator.

=cut

sub get_sparql {
    my $self = shift;
    my $sparql = shift;

    my $results = $self->{model}->sparql ($sparql, RETURN => 'NAMED_TUPLE_LIST');
#warn "my sparql ".Dumper $results;
    my @bs;
    foreach my $vs (@{ $results->{values} }) {                   # reformatting results for the iterator
	my @vs = map { RDF::Trine::Node::Resource->new ($_) }
	             map { /<(.+)>/ and $1}
	             @$vs;
	use List::MoreUtils qw(zip);
	my @vss = zip @{ $results->{names} }, @vs;
	push @bs, { @vss };
    }

    use RDF::Trine::Iterator::Bindings;
    return RDF::Trine::Iterator::Bindings->new(\@bs, $results->{names} );
}

=pod

=item B<count_statements>

As the mother class commands.

=cut

sub count_statements {
    my $self = shift;
    die "count: not in bulk mode please" if $self->{bulky};
    my @stms = $self->{model}->match ([ map { defined $_ ? $_->as_string : undef } @_ ]);
#    warn Dumper \@stms;
    return scalar @stms;
}

=pod

=item B<add_statement>

As the mother class, but:

=over

=item

We do not check for duplicates here. I.e. you can add any number of identical triples. They will not
show up in your SPARQL results, but with C<get_statements> they will.

=item

Quads are not (yet) supported.

=back

=cut

sub add_statement {
    my $self = shift;
    my $stm  = shift;

    my @stms = $self->{model}->match ( [ map { $_->as_string } $stm->nodes ] );
    return if @stms;                                      # do not add a statement already existing

    if ($self->{bulky}) {
	push @{ $self->{'+updates'} }, $stm;
    } else { # do it immediately
	$self->{model}->add ( [ map { $_->as_string } $stm->nodes ] );
    }
}

=pod

=item B<remove_statement>

Same as mother class.

B<NOTE>: No quads yet. And this does not work within bulk mode (yet).

=cut

sub remove_statement {
    my $self = shift;
    my $stm  = shift;

    die "remove statement: not in bulk mode please" if $self->{bulky};
    $self->{model}->delete ( [ map { $_->as_string } $stm->nodes ] );
}

=pod

=item B<remove_statements>

See C<remove_statement>

=cut


sub remove_statements {
    my $self = shift;
    die "remove statements: not in bulk mode please" if $self->{bulky};
    $self->{model}->delete ( [ map { $_->is_variable ? undef : $_->as_string } @_ ] );
}

=pod

=item B<get_statements>

As the mother class.

=cut

sub get_statements {
    my $self = shift;
    my @nodes = @_;
    die "get statements: not in bulk mode please" if $self->{bulky};
    my @stms = $self->{model}->match ( [ map { $_->is_variable ? undef : $_->as_string } @nodes ] );

    use RDF::Trine::Iterator::Graph;
    return RDF::Trine::Iterator::Graph->new( [
					       map { RDF::Trine::Statement->new ( map { RDF::Trine::Node::Resource->new ($_) }
										  map { /<(.+)>/ and $1}
										  @$_) }
					      @stms
					      ] );
}

=pod

=item B<get_contexts>

For now, this always will return an empty list.

TODO: When Perl AG supports more context features this will change.

=cut

sub get_contexts {
    return RDF::Trine::Iterator->new( [] );
}

=pod

=item B<size>

As for the mother class, but remember that AG allows you to hold duplicates.

=cut

sub size {
	my $self	= shift;
	return $self->{model}->size;
}

=pod

=item B<etag>

Not implemented. Will die.

=cut

# TODO: what is the intention MD5 over everything?
sub etag {
    my $self	= shift;
    die "not yet implemented as I am unsure what it exactly means";
}


=pod

=item B<_begin_bulk_ops>, B<_end_bulk_ops>

Currently bulk operation is only supporting I<adding> statements. Not I<deleting> them.

=cut

sub _begin_bulk_ops {
    my $self                        = shift;
#    warn "start bulk";
    $self->{bulky}++;
    $self->{'+updates'} = [];                               # we will collect statements to add (and later remove)
}


# at the moment only for adding
sub _end_bulk_ops {
    my $self                        = shift;
#    warn "end bulk";
    return unless $self->{bulky};                           # if we never have been touched, forget it
    $self->{bulky}--;                                       # reduce bulking
    if ($self->{bulky} == 0) {                              # if we are out of bulk mode, then
	$self->{model}->add ( map {                         # we all add it in one go
                                    [ map { $_->as_string } $_->nodes ]
                                  } @{ $self->{'+updates'} } );
	$self->{'+updates'} = [];
    }
}


sub _nuke {
    my $self = shift;
    $self->{model}->disband;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-trine-allegrograph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Trine-AllegroGraph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<RDF::Trine::AllegroGraph>

=head1 ACKNOWLEDGEMENTS

The development of this package was supported by Franz Inc.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut



1;

__END__

