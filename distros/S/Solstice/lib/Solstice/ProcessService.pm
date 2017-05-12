package Solstice::ProcessService;

# $Id: Service.pm 2263 2005-05-20 17:58:55Z mcrawfor $

=head1 NAME

Solstice::ProcessService - Manages the input and output of embedded pageflows.

=head1 SYNOPSIS

  my $service = Solstice::ProcessService->new();

  my $output_value = $service->getOutputValue();
  my $input_value  = $service->getInputValue();
  my $is_entrance  = $service->getIsPageFlowEntrance();
  my $is_exit      = $service->getIsPageFlowExit();

  $service->setInputValue('value');
  $service->SetOutputValue('value');

=head1 DESCRIPTION

A service interface to values that allow a service process to communicate with the application it is embedded in.  Most of the time you should only need to use the get/set value functions.  If you have several possible services that you are getting data from, you can use the input/output names to help distinguish them.
  
=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

our ($VERSION) = ('$Revision: 2263 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export 

No symbols exported.

=head2 Methods

=over 4

=item new()

Constructor.

=cut

sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
}

=item setInputName('name');

=cut

sub setInputName {
    my $self = shift;
    my $name = shift;
    warn "setInputName is depricated.  Caller: ".join(' ', caller)."\n"; 
    $self->set('input_name', $name);
}

=item getInputName()
=cut

sub getInputName {
    my $self = shift;
    warn "getInputName is depricated.  Caller: ".join(' ', caller)."\n"; 
    return $self->get('input_name');
}

=item setOutputName('name')
=cut

sub setOutputName {
    my $self = shift;
    my $name = shift;
    warn "setOutputName is depricated.  Caller: ".join(' ', caller)."\n"; 
    $self->set('output_name', $name);
}

=item getOutputName()
=cut

sub getOutputName {
    my $self = shift;
    warn "getOutputName is depricated.  Caller: ".join(' ', caller)."\n"; 
    return $self->get('output_name');
}

=item setInputValue('value')
=cut

sub setInputValue {
    my $self = shift;
    my $value = shift;
    $self->set('input_value', $value);
}

=item getInputValue()
=cut

sub getInputValue {
    my $self = shift;
    return $self->get('input_value');
}

=item setOutputValue('value')
=cut

sub setOutputValue {
    my $self = shift;
    my $value = shift;
    $self->set('output_value', $value);
}

=item getOutputValue()
=cut

sub getOutputValue {
    my $self = shift;
    return $self->get('output_value');
}

=item getIsPageFlowEntrance()
=cut

sub getIsPageFlowEntrance {
    my $self = shift;
    return $self->get('is_pageflow_entrance');
}

=item getIsPageFlowExit()
=cut

sub getIsPageFlowExit {
    my $self = shift;
    return $self->get('is_pageflow_exit');
}


=item setIsPageFlowEntrance()
=cut

sub setIsPageFlowEntrance {
    my $self = shift;
    my $value = shift;
    $self->set('is_pageflow_entrance', $value);
}

=item setIsPageFlowExit()
=cut

sub setIsPageFlowExit {
    my $self = shift;
    my $value = shift;
    $self->set('is_pageflow_exit', $value);
}

=back

=head2 Private Methods

=over 4

=cut

=item _getClassName()

=cut

sub _getClassName {
    return 'Solstice::ProcessService';
}

1;
__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2263 $



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
