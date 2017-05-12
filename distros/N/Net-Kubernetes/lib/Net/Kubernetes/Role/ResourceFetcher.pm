package Net::Kubernetes::Role::ResourceFetcher;
# ABSTRACT: Role to give access to list_* methods.
$Net::Kubernetes::Role::ResourceFetcher::VERSION = '1.03';
use Moose::Role;
use MooseX::Aliases;
use syntax "try";
require Net::Kubernetes::Resource::Service;
require Net::Kubernetes::Resource::Pod;
require Net::Kubernetes::Resource::ReplicationController;

with 'Net::Kubernetes::Role::ResourceFactory';

sub get_resource_by_name {
	my($self, $name, $type) = @_;
	my($res) = $self->ua->request($self->create_request(GET => $self->path.'/'.$type.'/'.$name));
	if ($res->is_success) {
		return $self->create_resource_object($self->json->decode($res->content));
	}
	else {
		my $message;
		try{
			my $obj = $self->json->decode($res->content);
			$message = $obj->{message};
		}
		catch($e) {
			$message = $res->message;
		}
		Net::Kubernetes::Exception->throw(code=>$res->code, message=>$message);
	}
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Role::ResourceFetcher - Role to give access to list_* methods.

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

=item * L<Net::Kubernetes::Role::ResourceFactory>

=back

=cut
