package Solstice::NamespaceService;

=head1 NAME

Solstice::NamespaceService - Used by the framework to discover the configuration namespace of the app it is currently running.

=head1 SYNOPSIS

    #in the main handler, this is initialized:
    my $ns_service = Solstice::NamespaceService->new();
    $ns_service->_setAppNamespace('WEBQ');

    #later, when checking whether the boilerplate/css file is overridden:
    my $ns_service = Solstice::NamespaceService->new();
    my $config = Solstice::Configure->new($ns_service->getAppNamespace());

    if(defined $config->getBoilerplateTemplate()){
        #override the default
    }


=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Service);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::NamespaceService object.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    return $self;
}

=item getNamespace()

synonym for getAppNamespace

=cut

sub getNamespace {
    my $self = shift;
    return $self->get('_app_namespace');
}

=item getAppNamespace()

Return the application namespace.

=cut

sub getAppNamespace {
    my $self = shift;
    return $self->get('_app_namespace');
}

=back

=head2 Private Methods

=over 4

=cut


=item _setAppNamespace($namespace)

=cut

sub _setAppNamespace {
    my $self = shift;
    my $namespace = shift;
    $self->set('_app_namespace', $namespace);
    return 1;
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

#sub _getClassName {
#    return 'Solstice::NamespaceService';
#}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2940 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
