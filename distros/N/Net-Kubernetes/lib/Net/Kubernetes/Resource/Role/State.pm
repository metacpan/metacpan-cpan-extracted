package Net::Kubernetes::Resource::Role::State;
# ABSTRACT: Resource role for types that have a status
$Net::Kubernetes::Resource::Role::State::VERSION = '1.03';
use Moose::Role;

has status => (
	is       => 'rw',
	isa      => 'HashRef',
	required => 1
);


sub refresh {
	my($self) = @_;
	my($res) = $self->ua->request($self->create_request(GET => $self->path));
	if ($res->is_success) {
		my($data) = $self->json->decode($res->content);
		$self->status($data->{status});
		return 1;
	}
	return 0;
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Role::State - Resource role for types that have a status

=head1 VERSION

version 1.03

=head1 METHODS

=head2 refresh

Retrieve current state information from kubernetes.

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

=cut
