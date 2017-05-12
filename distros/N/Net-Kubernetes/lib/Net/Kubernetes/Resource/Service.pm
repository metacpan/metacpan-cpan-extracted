package Net::Kubernetes::Resource::Service;
# ABSTRACT: Object representatioon of a Kubernetes Service
$Net::Kubernetes::Resource::Service::VERSION = '1.03';
use Moose;


extends 'Net::Kubernetes::Resource';

with 'Net::Kubernetes::Resource::Role::State';
with 'Net::Kubernetes::Resource::Role::Spec';
with 'Net::Kubernetes::Resource::Role::HasPods';




return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::Service - Object representatioon of a Kubernetes Service

=head1 VERSION

version 1.03

=head1 METHODS

=head2 my(@pods) = $service->get_pods()

Fetch a list off all pods belonging to this service.

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

=item * L<Net::Kubernetes::Resource::Role::HasPods>

=item * L<Net::Kubernetes::Resource::Role::Spec>

=item * L<Net::Kubernetes::Resource::Role::State>

=item * L<Net::Kubernetes::Role::APIAccess>

=back

=cut
