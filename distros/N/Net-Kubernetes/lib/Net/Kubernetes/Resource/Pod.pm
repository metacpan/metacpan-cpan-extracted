package Net::Kubernetes::Resource::Pod;
# ABSTRACT: Object representatioon of a Kubernetes Pod
$Net::Kubernetes::Resource::Pod::VERSION = '1.03';
use Moose;

extends 'Net::Kubernetes::Resource';

with 'Net::Kubernetes::Resource::Role::State';
with 'Net::Kubernetes::Resource::Role::Spec';


sub logs {
	my($self, %options) = @_;
	if (scalar(@{ $self->spec->{containers} }) > 1 && ! exists($options{container})) {
		Net::Kunbernetes::Exception::ClientException->throw(code=>499,  message=>'Must provide container to get logs from a multi-container pod');
	}
	
	my $uri = URI->new($self->path.'/log');
	$uri->query_form(\%options);	
	my $res = $self->ua->request($self->create_request(GET => $uri));
	if ($res->is_success) {
		return $res->content;
	}
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Pod - Object representatioon of a Kubernetes Pod

=head1 VERSION

version 1.03

=head1 METHODS

=head2 logs([container=>'foo'])

This method will return the logs from STDERR on for containers in a pod.  If the pod has more than one container,
the container argument become manditory, however for single container pods it may be ommited.

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
