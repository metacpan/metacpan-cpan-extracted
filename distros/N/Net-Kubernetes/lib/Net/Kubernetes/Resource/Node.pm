package Net::Kubernetes::Resource::Node;
# ABSTRACT: Object representatioon of a Kubernetes Pod
$Net::Kubernetes::Resource::Node::VERSION = '1.03';
use Moose;
use URI;
extends 'Net::Kubernetes::Resource';

with 'Net::Kubernetes::Resource::Role::State';
with 'Net::Kubernetes::Resource::Role::Spec';

sub get_pods {
    my($self) = shift;
    my $uri = URI->new($self->url.'/api/'.$self->api_version.'/pods');
    my $selector = {};
    if($self->api_version eq 'v1'){
        $selector->{'spec.nodeName'} = $self->metadata->{name};
    }else{
        $selector->{'spec.host'} = $self->metadata->{name};
    }
    $uri->query_form(fieldSelector=>$self->_build_selector_from_hash($selector));
    print "Query with $uri\n";
    my $res = $self->ua->request($self->create_request(GET => $uri));
    if ($res->is_success) {
        my $pod_list = $self->json->decode($res->content);
        my(@pods)=();
        foreach my $pod (@{ $pod_list->{items}}){
            $pod->{apiVersion} = $pod_list->{apiVersion};
            my(%create_args) = %$pod;
            $create_args{api_version} = $pod->{apiVersion};
            $create_args{username} = $self->username if($self->username);
            $create_args{password} = $self->password if($self->password);
            $create_args{url} = $self->url;
            $create_args{base_path} = $pod->{metadata}{selfLink};
            push @pods, Net::Kubernetes::Resource::Pod->new(%create_args);
        }
        return wantarray ? @pods : \@pods;
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
	return join(",", @selectors);
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Node - Object representatioon of a Kubernetes Pod

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

=head1 CONSUMES

=over 4

=item * L<Net::Kubernetes::Resource::Role::Spec>

=item * L<Net::Kubernetes::Resource::Role::State>

=back

=cut
