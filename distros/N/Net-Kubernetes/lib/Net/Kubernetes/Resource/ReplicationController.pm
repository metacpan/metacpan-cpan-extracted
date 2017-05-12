package Net::Kubernetes::Resource::ReplicationController;
# ABSTRACT: Object representatioon of a Kubernetes Replication Controller
$Net::Kubernetes::Resource::ReplicationController::VERSION = '1.03';
use Moose;
use URI;
use Time::HiRes;


extends 'Net::Kubernetes::Resource';
with 'Net::Kubernetes::Resource::Role::State';
with 'Net::Kubernetes::Resource::Role::Spec';
with 'Net::Kubernetes::Resource::Role::HasPods';



sub scale {
    my($self, $replicas, $timeout) = @_;
    $timeout ||= 5;
    $self->spec->{replicas} = $replicas;
    $self->update;
    my $st = time;
    while((time - $st) < $timeout){
        my $pods = $self->get_pods;
        if(scalar(@$pods) == $replicas){
            return "scaled";
        }
        sleep(0.3);
    }
    return 0;
}

return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Resource::ReplicationController - Object representatioon of a Kubernetes Replication Controller

=head1 VERSION

version 1.03

=head1 METHODS

=head2 my(@pods) = $rc->get_pods()

Fetch a list off all pods belonging to this replication controller.

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
