package Net::Kubernetes::Role::ResourceFactory;
# ABSTRACT: Role to allow easy construction of Net::Kubernetes::Resouce::* objects
$Net::Kubernetes::Role::ResourceFactory::VERSION = '1.03';
use Moose::Role;
use MooseX::Aliases;
require Net::Kubernetes::Resource::Endpoint;
require Net::Kubernetes::Resource::Event;
require Net::Kubernetes::Resource::Node;
require Net::Kubernetes::Resource::Pod;
require Net::Kubernetes::Resource::ReplicationController;
require Net::Kubernetes::Resource::Secret;
require Net::Kubernetes::Resource::Service;
require Net::Kubernetes::Resource::ServiceAccount;

sub create_resource_object {
	my($self, $object, $kind) = @_;
	$kind ||= $object->{kind};
	$object->{kind} ||= $kind;
	my(%create_args) = %$object;
	$create_args{api_version} = $object->{apiVersion};
	$create_args{username} = $self->username if($self->username);
	$create_args{password} = $self->password if($self->password);
	$create_args{url} = $self->url;
	$create_args{base_path} = $object->{metadata}{selfLink};
	$create_args{ssl_cert_file} = $self->ssl_cert_file if($self->ssl_cert_file);
	$create_args{ssl_key_file} = $self->ssl_key_file if($self->ssl_key_file);
	$create_args{ssl_ca_file} = $self->ssl_ca_file if($self->ssl_ca_file);
	my $class = "Net::Kubernetes::Resource::".$kind;
	return $class->new(%create_args);
}


return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Role::ResourceFactory - Role to allow easy construction of Net::Kubernetes::Resouce::* objects

=head1 VERSION

version 1.03

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
