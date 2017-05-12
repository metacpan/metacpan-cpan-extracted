package Solstice::Controller::FormInput::TextArea;

# $Id: TextArea.pm 25 2006-01-14 00:50:12Z jlaney $

=head1 NAME

Solstice::Controller::FormInput::TextArea - Collects form input from a <textarea>

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::FormInput);

use Solstice::View::FormInput::TextArea;

use Solstice::CGI;
use Solstice::StringLibrary qw(trimstr);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant PARAM => 'htmltextarea';

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=item new($model)

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_setControl($self->getModel());
    
    return $self;
}

=item getView()

Creates the view object for the home page.

=cut

sub getView {
    my $self = shift;

    my $view = Solstice::View::FormInput::TextArea->new($self->getModel());
    $view->setName($self->getName() || PARAM);
    
    return $view;
}

=item update()

=cut

sub update { 
    my $self = shift;

    $self->setModel(trimstr(param($self->getName() || PARAM)));
    
    return TRUE;
}

=item validate()

=cut

sub validate { 
    my $self = shift;

    my $name = $self->getName() || PARAM;

    my $param = $self->getIsRequired()
        ? $self->createRequiredParam($name)
        : $self->createOptionalParam($name);

    return $self->processConstraints();
}

=item isModelTainted()

=cut

sub isModelTainted {
    my $self = shift;

    my $old_content = $self->_getControl() || '';
    my $new_content = $self->getModel()    || '';
    #warn "\nOld: ".$old_content."\n";
    #warn "\nNew: ".$new_content."\n\n";
    return ($old_content ne $new_content) ? TRUE : FALSE;
}

sub _setControl {
    my $self = shift;
    $self->{'_control'} = shift;
}

sub _getControl {
    my $self = shift;
    return $self->{'_control'};
}

sub setFocusEditor {
    my $self = shift;
    $self->{'_focus_editor'} = shift;
}

sub getFocusEditor {
    my $self = shift;
    return $self->{'_focus_editor'};
}

1;
__END__

=back

=head1 AUTHOR

Educational Technology Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 25 $

=head1 SEE ALSO

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
