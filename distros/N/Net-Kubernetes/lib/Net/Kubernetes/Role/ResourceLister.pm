package Net::Kubernetes::Role::ResourceLister;
# ABSTRACT: Role to give access to list_* methods.
$Net::Kubernetes::Role::ResourceLister::VERSION = '1.03';
use Moose::Role;
use MooseX::Aliases;
require Net::Kubernetes::Resource::Service;
require Net::Kubernetes::Resource::Pod;
require Net::Kubernetes::Resource::ReplicationController;

with 'Net::Kubernetes::Role::ResourceFactory';

requires 'ua';
requires 'create_request';
requires 'json';


sub list_pods {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/pods');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $pod_list = $self->json->decode($res->content);
		my(@pods)=();
		foreach my $pod (@{ $pod_list->{items}}){
			$pod->{apiVersion} = $pod_list->{apiVersion};
			push @pods, $self->create_resource_object($pod, 'Pod');
		}
		return wantarray ? @pods : \@pods;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}


sub list_replication_controllers {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/replicationcontrollers');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $pod_list = $self->json->decode($res->content);
		my(@rcs)=();
		foreach my $rc (@{ $pod_list->{items}}){
			$rc->{apiVersion} = $pod_list->{apiVersion};
			push @rcs, $self->create_resource_object($rc, 'ReplicationController');;
		}
		return wantarray ? @rcs : \@rcs;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}

alias list_rc => 'list_replication_controllers';


sub list_services {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/services');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $pod_list = $self->json->decode($res->content);
		my(@services)=();
		foreach my $service (@{ $pod_list->{items}}){
			$service->{apiVersion} = $pod_list->{apiVersion};
			push @services, $self->create_resource_object($service, 'Service');
		}
		return wantarray ? @services : \@services;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}


sub list_events {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/events');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $event_list = $self->json->decode($res->content);
		my(@events)=();
		foreach my $service (@{ $event_list->{items}}){
			$service->{apiVersion} = $event_list->{apiVersion};
			push @events, $self->create_resource_object($service, 'Event');
		}
		return wantarray ? @events : \@events;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}


sub list_secrets {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/secrets');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $pod_list = $self->json->decode($res->content);
		my(@secrets)=();
		foreach my $secret (@{ $pod_list->{items}}){
			$secret->{apiVersion} = $pod_list->{apiVersion};
			push @secrets, $self->create_resource_object($secret, 'Secret');
		}
		return wantarray ? @secrets : \@secrets;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}


sub list_endpoints {
	my $self = shift;
	my(%options);
	if (ref($_[0])) {
		%options = %{ $_[0] };
	}else{
		%options = @_;
	}

	my $uri = URI->new($self->path.'/endpoints');
	my(%form) = ();
	$form{labelSelector}=$self->_build_selector_from_hash($options{labels}) if (exists $options{labels});
	$form{fieldSelector}=$self->_build_selector_from_hash($options{fields}) if (exists $options{fields});
	$uri->query_form(%form);

	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		my $point_list = $self->json->decode($res->content);
		my(@points)=();
		foreach my $point (@{ $point_list->{items} }){
			$point->{apiVersion} = $point_list->{apiVersion};
			push @points, $self->create_resource_object($point, 'Endpoint');
		}
		return wantarray ? @points : \@points;
	}else{
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$res->message);
	}
}

sub _build_selector_from_hash {
	my($self, $select_hash) = @_;
	my(@selectors);
	foreach my $label (keys %{ $select_hash }){
		push @selectors, $label.'='.$select_hash->{$label};
	}
	return \@selectors;
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Role::ResourceLister - Role to give access to list_* methods.

=head1 VERSION

version 1.03

=head1 METHODS

=head2 list_pods([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Pod>s

=head2 list_rc([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::ReplicationController>s

=head2 list_replication_controllers([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::ReplicationController>s

=head2 list_services([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Service>s

=head2 list_events([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Event>s

=head2 list_secrets([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Secret>s

=head2 list_endpoints([label=>{label=>value}], [fields=>{field=>value}])

returns a list of L<Net::Kubernetes::Resource::Endpoint>s

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

=item * L<Net::Kubernetes::Role::ResourceFactory>

=back

=cut
