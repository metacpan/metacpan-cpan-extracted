package Solstice::View::FormInput::FileUpload::Multiple;

# $Id: Multiple.pm 63 2006-06-19 22:51:42Z jlaney $

=head1 NAME

Solstice::View::FormInput::FileUpload::Multiple - A view of an html file upload element

=head1 SYNOPSIS

    use Solstice::View::FormInput::FileUpload::Multiple;

    my $view = Solstice::View::FormInput::FileUpload::Multiple->new();
    
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View::FormInput);

use constant TRUE  => 1;
use constant FALSE => 0;

our $template = 'form_input/file_upload/multiple.html';

our ($VERSION) = ('$Revision: 63 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View::FormInput|Solstice::View::FormInput>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_setTemplatePath('templates');

    return $self;
}

=item setStartCount($int)

=cut

sub setStartCount {
    my $self = shift;
    $self->{'_start_count'} = shift;
}

=item getStartCount()

=cut

sub getStartCount {
    my $self = shift;
    return $self->{'_start_count'};
}

=item setMaxCount($int)

=cut

sub setMaxCount {
    my $self = shift;
    $self->{'_max_count'} = shift;
}

=item getMaxCount()

=cut

sub getMaxCount {
    my $self = shift;
    return $self->{'_max_count'};
}

=item setUploadURL($url)

=cut

sub setUploadURL {
    my $self = shift;
    $self->{'_upload_url'} = shift;
}

=item getUploadURL()

=cut

sub getUploadURL {
    my $self = shift;
    return $self->{'_upload_url'};
}

=item addOnChangeEvent($str)

=cut

sub addOnChangeEvent {
    my $self = shift;
    my $event = shift;
    
    my $events = $self->{'_onchange_events'} || [];
    push @$events, $event;
    $self->{'_onchange_events'} = $events;
}

=item getOnChangeEvents()

=cut

sub getOnChangeEvents {
    my $self = shift;
    return $self->{'_onchange_events'} || [];
}

=item addOnUploadEvent($str)

=cut

sub addOnUploadEvent {
    my $self = shift;
    my $event = shift;

    my $events = $self->{'_onupload_events'} || [];
    push @$events, $event;
    $self->{'_onupload_events'} = $events;
}

=item getOnUploadEvents()

=cut

sub getOnUploadEvents {
    my $self = shift;
    return $self->{'_onupload_events'} || [];
}

=item addOnFormUpdateEvent($str)

=cut

sub addOnFormUpdateEvent {
    my $self = shift;
    my $event = shift;

    my $events = $self->{'_onformupdate_events'} || [];
    push @$events, $event;
    $self->{'_onformupdate_events'} = $events;
}

=item getOnFormUpdateEvents()

=cut

sub getOnFormUpdateEvents {
    my $self = shift;
    return $self->{'_onformupdate_events'} || [];
}

=item setIsDisabled($bool)

=cut

sub setIsDisabled {
    my $self = shift;
    $self->{'_disabled'} = shift;
}

=item getIsDisabled()

=cut

sub getIsDisabled {
    my $self = shift;
    return $self->{'_disabled'};
}

=item setLabels(\%params)

Set a hashref of custom labels. Valid keys are:

add_label, another_label, remove_label

=cut

sub setLabels {
    my $self = shift;
    $self->{'_labels'} = shift;
}

=item getLabels()

=cut

sub getLabels {
    my $self = shift;
    return $self->{'_labels'} || {};
}

=item generateParams()

=cut

sub generateParams {
    my $self = shift;

    my $lang_service = $self->getLangService();
    my $include_service = $self->getIncludeService();

    # File upload javascript
    $include_service->addIncludedFile({
        file => 'javascript/file_upload.js',
        type => 'text/javascript'
    });

    $include_service->addJSFile('javascript/iframe.js');

    # Initialization on body onload is here primarily for the benefit
    # of safari, since IE/Mozilla are happiest with immediate inline
    # initialization. At issue is the readiness of the iframe for 
    # writing the upload document.
    $self->getOnloadService()->addEvent('Solstice.FileUpload.initialize("'.$self->getName().'")');

    $self->setParam('name', $self->getName());
    $self->setParam('base_url', $self->getBaseURL());
    $self->setParam('start_count', $self->getStartCount() || 0);
    $self->setParam('max_count', $self->getMaxCount() || 999); 
    $self->setParam('class_name', $self->getClassName());
    $self->setParam('upload_url', $self->getUploadURL() || 
        ($self->getBaseURL().'file_upload.cgi'));
    $self->setParam('is_disabled', $self->getIsDisabled() ? 'true' : 'false');
    
    # Add any custom handlers
    for my $event (@{$self->getOnChangeEvents()}) {    
        $self->addParam('onchange_handlers', {event => $event});
    }
    for my $event (@{$self->getOnUploadEvents()}) {
        $self->addParam('onupload_handlers', {event => $event});
    }
    for my $event (@{$self->getOnFormUpdateEvents()}) {
        $self->addParam('onformupdate_handlers', {event => $event});
    }

    # Set the default/custom labels
    $self->setParams({
        add_label     => $lang_service->getString('upload_add_label'),
        another_label => $lang_service->getString('upload_another_label'),
        remove_label  => $lang_service->getString('upload_remove_label'),
        %{$self->getLabels()} # Label overrides
    });
    
    return TRUE;
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>.

=head1 AUTHOR

Solstice Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 63 $

=head1 SEE ALSO

L<perl>.

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
