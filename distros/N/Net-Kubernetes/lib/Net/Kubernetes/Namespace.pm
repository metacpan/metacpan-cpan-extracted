package Net::Kubernetes::Namespace;
# ABSTRACT: Provides access to kubernetes respources within a single namespace.
$Net::Kubernetes::Namespace::VERSION = '1.03';
use Moose;
use MooseX::Aliases;
use syntax 'try';

has namespace => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);

has _namespace_data => (
	is       => 'ro',
	isa      => 'HashRef',
	required => 0,
);

with 'Net::Kubernetes::Role::APIAccess';
with 'Net::Kubernetes::Role::ResourceLister';
with 'Net::Kubernetes::Role::ResourceCreator';
with 'Net::Kubernetes::Role::ResourceFactory';
with 'Net::Kubernetes::Role::ResourceFetcher';
with 'Net::Kubernetes::Role::SecretBuilder';


sub get_secret {
	my($self, $name) = @_;
	Net::Kubernetes::Exception->throw(message=>"Missing required parameter 'name'") if(! defined $name || ! length $name);
	return $self->get_resource_by_name($name, 'secrets');
}

sub get_pod {
	my($self, $name) = @_;
	Net::Kubernetes::Exception->throw(message=>"Missing required parameter 'name'") if(! defined $name || ! length $name);
	return $self->get_resource_by_name($name, 'pods');
}

sub get_service {
	my($self, $name) = @_;
	Net::Kubernetes::Exception->throw(message=>"Missing required parameter 'name'") if(! defined $name || ! length $name);
	return $self->get_resource_by_name($name, 'services');
}

sub get_replication_controller {
	my($self, $name) = @_;
	Net::Kubernetes::Exception->throw(message=>"Missing required parameter 'name'") if(! defined $name || ! length $name);
	return $self->get_resource_by_name($name, 'replicationcontrollers');
}
alias get_rc => 'get_replication_controller';

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Namespace - Provides access to kubernetes respources within a single namespace.

=head1 VERSION

version 1.03

=head1 METHODS

=head2 $ns->get_pod('my-pod-name')

=head2 $ns->get_repllcation_controller('my-rc-name') (aliased as $ns->get_rc('my-rc-name'))

=head2 $ns->get_service('my-servce-name')

=head2 $ns->get_secret('my-secret-name')

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

=item * L<Net::Kubernetes::Role::ResourceCreator>

=item * L<Net::Kubernetes::Role::ResourceFactory>

=item * L<Net::Kubernetes::Role::ResourceFetcher>

=item * L<Net::Kubernetes::Role::ResourceLister>

=item * L<Net::Kubernetes::Role::SecretBuilder>

=back

=cut
