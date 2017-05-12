package Net::Kubernetes;
# ABSTRACT: An object oriented interface to the REST API's provided by kubernetes
$Net::Kubernetes::VERSION = '1.03';
use Moose;
require Net::Kubernetes::Namespace;
require LWP::UserAgent;
require HTTP::Request;
require URI;;
require Throwable::Error;
use MIME::Base64;
require Net::Kubernetes::Exception;


with 'Net::Kubernetes::Role::APIAccess';
with 'Net::Kubernetes::Role::ResourceLister';
with 'Net::Kubernetes::Role::ResourceFetcher';


has 'default_namespace' => (
	is         => 'rw',
	isa        => 'Net::Kubernetes::Namespace',
	required   => 0,
	lazy       => 1,
	handles    => [qw(get_pod get_rc get_replication_controller get_secret get_service create create_from_file build_secret)],
	builder    => '_get_default_namespace',
);

sub get_namespace {
	my($self, $namespace) = @_;
	if (! defined $namespace || ! length $namespace) {
		Throwable::Error->throw(message=>'$namespace cannot be null');
	}
	my $res = $self->ua->request($self->create_request(GET => $self->path.'/namespaces/'.$namespace));
	if ($res->is_success) {
		my $ns = $self->json->decode($res->content);
		my(%create_args) = (url => $self->url, base_path=>$ns->{metadata}{selfLink}, api_version=>$self->api_version, namespace=> $namespace, _namespace_data=>$ns);
		$create_args{username} = $self->username if(defined $self->username);
		$create_args{password} = $self->password if(defined $self->password);
		$create_args{ssl_cert_file} = $self->ssl_cert_file if(defined $self->ssl_cert_file);
		$create_args{ssl_key_file} = $self->ssl_key_file if(defined $self->ssl_key_file);
		$create_args{ssl_ca_file} = $self->ssl_ca_file if(defined $self->ssl_ca_file);
		return Net::Kubernetes::Namespace->new(%create_args);
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>"Error getting namespace $namespace:\n".$res->message);
	}
}


sub list_nodes {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/nodes');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $node_list = $self->json->decode($res->content);
		my(@nodes)=();
		foreach my $node (@{ $node_list->{items}}){
			$node->{apiVersion} = $node_list->{apiVersion};
			push @nodes, $self->create_resource_object($node, 'Node');
		}
		return wantarray ? @nodes : \@nodes;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}

sub get_node {
	my($self, $name) = @_;
	Net::Kubernetes::Exception->throw(message=>"Missing required parameter 'name'") if(! defined $name || ! length $name);
	return $self->get_resource_by_name($name, 'nodes');
}


sub list_service_accounts {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/serviceaccounts');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $sa_list = $self->json->decode($res->content);
		my(@saccs)=();
		foreach my $sacc (@{ $sa_list->{items}}){
			$sacc->{apiVersion} = $sa_list->{apiVersion};
			push @saccs, $self->create_resource_object($sacc, 'ServiceAccount');
		}
		return wantarray ? @saccs : \@saccs;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}


sub _get_default_namespace {
	my($self) = @_;
	return $self->get_namespace('default');
}

# SEEALSO: Net::Kubernetes::Namespace, Net::Kubernetes::Resource

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes - An object oriented interface to the REST API's provided by kubernetes

=head1 VERSION

version 1.03

=head1 SYNOPSIS

  my $kube = Net::Kubernetes->new(url=>'http://127.0.0.1:8080', username=>'dave', password=>'davespassword');
  my $pod_list = $kube->list_pods();

  my $nginx_pod = $kube->create_from_file('kubernetes/examples/pod.yaml');

  my $ns = $kube->get_namespace('default');

  my $services = $ns->list_services;

  my $pod = $ns->get_pod('my-pod');

  $pod->delete;

  my $other_pod = $ns->create_from_file('./my-pod.yaml');

=head1 METHODS

=head2 new - Create a new $kube object

All parameters are optional and have some basic default values (where appropriate).

=over 1

=item url ['http://localhost:8080']

The base url for the kubernetes. This should include the protocal (http or https) but not "/api/v1beta3" (see base_path).

=item base_path ['/api/v1beta3']

The entry point for api calls, this may be used to set the api version with which to interact.

=item username

Username to use with basic authentication. If either username or password are not provided, basic authentication will not
be used.

=item password

Password to use with basic authentication. If either username or password are not provided, basic authentication will not
be used.

=item token

An authentication token to be used to access the apiserver.  This may be provided as a plain string, a path to a file
from which to read the token (like /var/run/secrets/kubernetes.io/serviceaccount/token from within a pod), or a reference
to a file handle (from which to read the token).

=item ssl_cert_file, ssl_key_file, ssl_ca_file

This there options passed into new will cause Net::Kubernetes in inlcude SSL client certs to requests to the kuberernetes
API server for authentication.  There are basically just a passthrough to the underlying LWP::UserAgent used to handle the 
api requests.

=back

=head2 get_namespace("myNamespace");

This method returns a "Namespace" object on which many methods can be called implicitly
limited to the specified namespace.

=head2 get_pod('my-pod-name')

Delegates automatically to L<Net::Kubernetes::Namespace> via $self->get_namespace('default')

=head2 get_repllcation_controller('my-rc-name') (aliased as $ns->get_rc('my-rc-name'))

Delegates automatically to L<Net::Kubernetes::Namespace> via $self->get_namespace('default')

=head2 get_service('my-servce-name')

Delegates automatically to L<Net::Kubernetes::Namespace> via $self->get_namespace('default')

=head2 get_secret('my-secret-name')

Delegates automatically to L<Net::Kubernetes::Namespace> via $self->get_namespace('default')

=head2 list_nodes([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Node>s

=head2 list_service_accounts([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Service>s

=begin html

<h2>Build Status</h2>

<img src="https://travis-ci.org/perljedi/net-kubernetes.svg?branch=release-0.21" />

=end html

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

L<Net::Kubernetes::Namespace|Net::Kubernetes::Namespace>

=item *

L<Net::Kubernetes::Resource|Net::Kubernetes::Resource>

=back

=head1 CONSUMES

=over 4

=item * L<Net::Kubernetes::Role::APIAccess>

=item * L<Net::Kubernetes::Role::ResourceFactory>

=item * L<Net::Kubernetes::Role::ResourceFetcher>

=item * L<Net::Kubernetes::Role::ResourceLister>

=back

=head1 CONTRIBUTORS

=for stopwords Christopher Pruden Dave Mueller Kevin Johnson

=over 4

=item *

Christopher Pruden <cdpruden@liquidweb.com>

=item *

Dave <dave@perljedi.com>

=item *

Dave Mueller <dmueller@liquidweb.com>

=item *

Kevin Johnson <kcavemanj@gmail.com>

=back

=cut
