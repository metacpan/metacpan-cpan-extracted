package Solstice::View::MessageService;

# $Id: MessageService.pm 2543 2005-08-30 22:24:50Z mcrawfor $

=head1 NAME

Solstice::View::MessageService - A banner view of messages. 

=head1 SYNOPSIS

  use Solstice::View::MessageService;

  my $msg_view = Solstice::View::MessageService->new();

=head1 DESCRIPTION

An error view for the Solstice Web Tools.  This view takes no model, rather it
gets its data automatically from the Solstice::MessageService.

=cut

use 5.006_000;
use strict;
use warnings;
no  warnings qw(redefine);
use Solstice::MessageService;
use Solstice::View;

use constant ERROR_TEMPLATE => "error.html";
use constant WARNING_TEMPLATE => "warning.html";
use constant INFO_TEMPLATE    => 'info.html';
use constant SYSTEM_TEMPLATE    => 'system.html';
use constant SUCCESS_TEMPLATE    => 'success.html';
use constant NONE                => 'none.html';

use constant ERROR        => 'error';
use constant WARNING    => 'warning';
use constant INFO        => 'information';
use constant SYSTEM        => 'system';
use constant SUCCESS    => 'success';


our @ISA = qw(Solstice::View);
our ($VERSION) = ('$Revision: 2543 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View|Solstice::View>

=head2 Export

No symbols exported.

=head2 Methods

=over 4


=cut

=item new()

Creates a new Solstice::View::MessageService object.

=cut

sub new {
    my $obj = shift;
    
    my $self = $obj->SUPER::new(@_);
    my $messaging_service = Solstice::MessageService->new();
    my $message_type = $messaging_service->getMessageType();
    $self->setPossibleTemplates(NONE, ERROR_TEMPLATE, INFO_TEMPLATE, WARNING_TEMPLATE, SUCCESS_TEMPLATE, SYSTEM_TEMPLATE);

    $self->_setTemplate(NONE);
    switch: {
        if(defined $message_type && $message_type eq ERROR) { $self->_setTemplate(ERROR_TEMPLATE); }
        if(defined $message_type && $message_type eq INFO)  { $self->_setTemplate(INFO_TEMPLATE);  }
        if(defined $message_type && $message_type eq WARNING){$self->_setTemplate(WARNING_TEMPLATE);}
        if(defined $message_type && $message_type eq SUCCESS){$self->_setTemplate(SUCCESS_TEMPLATE);}
        if(defined $message_type && $message_type eq SYSTEM){ $self->_setTemplate(SYSTEM_TEMPLATE); }
    }
    $self->_setTemplatePath('templates/message_service');
    
    return $self;
}

=back

=head2 Private Methods

=over 4

=item _getTemplateParams()

=cut

sub _getTemplateParams {
    my $self = shift;

    my $messaging_service = Solstice::MessageService->new();
    my @messages = map { msg => $_ }, $messaging_service->getMessages();

    return {
        alert_image => 'images/alert.gif',
        messages      => \@messages,
    };
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>,
L<Solstice::MessageService|Solstice::MessageService>.

=head1 SEE ALSO

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2543 $



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
