package Net::Kubernetes::Resource;
# ABSTRACT: Base class for all Net::Kubernetes::Resource objects.
$Net::Kubernetes::Resource::VERSION = '1.03';
use Moose;
use Clone qw(clone);

with 'Net::Kubernetes::Role::APIAccess';


has kind     => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);

has api_version => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);

has metadata => (
	is       => 'rw',
	isa      => 'HashRef',
	required => 1
);


sub delete {
	my($self) = @_;
	my($res) = $self->ua->request($self->create_request(DELETE => $self->path));
	if ($res->is_success) {
		return 1;
	}
	return 0;
}

sub update {
	my($self) = @_;
	my($res) = $self->ua->request($self->create_request(PUT => $self->path, undef, $self->json->encode($self->as_hashref)));
	if ($res->is_success) {
		return 1;
	}
	return 0;
}

sub as_hashref
{
	my($self) = @_;

        # It is possible for kuberentes to churn the resource version higher even if
        # you just refresh it and then attempt an update operation. Let's ignore it for now.
        my $metadata = $self->metadata;
        delete $metadata->{resourceVersion};

	return clone({
		inner(),
		apiVersion=>$self->api_version,
		kind=>$self->kind,
		metadata=>$self->metadata
	});
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource - Base class for all Net::Kubernetes::Resource objects.

=head1 VERSION

version 1.03

=head1 METHODS

=head2 $resource->delete

Delete this rsource.

=head2 $resource->update (send local changes to api server)

Saves any changes made to metadata, or spec or any other resource type specific changes
made since this item was last pulled from the server.

=head2 $resource->refresh

Update status information from server.  This is only available for reosurce types which have
a status field (Currently that is everything other than 'Secret' objects)

=head1 AUTHOR

Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Mueller.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::Kubernetes|Net::Kubernetes>

=back

=head1 CONSUMES

=over 4

=item * L<Net::Kubernetes::Role::APIAccess>

=back

=cut
