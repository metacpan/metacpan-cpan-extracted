package Solstice::View::FormInput::TextInput;

# $Id: TextInput.pm 63 2006-06-19 22:51:42Z jlaney $

=head1 NAME

Solstice::View::FormInput::TextInput - A view of an html <input type="text"> element

=head1 SYNOPSIS

    use Solstice::View::FormInput::TextInput;

    my $content = 'A string containing <i>content</i>.';

    my $view = Solstice::View::FormInput::TextInput->new($content);
    $view->setName('mytextbox');
    $view->setWidth('90%');  # a percentage or an integer representing pixels
    $view->setIsResizable(1);
    
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View::FormInput);

use constant TRUE  => 1;
use constant FALSE => 0;
use constant WIDTH => '100%';

our $template = 'form_input/textinput.html';

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

=item setWidth($int)

=cut

sub setWidth {
    my $self = shift;
    $self->{'_width'} = shift;
}

=item getWidth()

=cut

sub getWidth {
    my $self = shift;
    return $self->{'_width'};
}

=item setCharLimit($int)

=cut

sub setCharLimit {
    my $self = shift;
    $self->{'_char_limit'} = shift;
}

=item getCharLimit()

=cut

sub getCharLimit {
    my $self = shift;
    return $self->{'_char_limit'};
}

=item generateParams()

=cut

sub generateParams {
    my $self = shift;

    my $width = $self->getWidth() || WIDTH;
    
    $self->setParam('name', $self->getName());    
    $self->setParam('width', ($width =~ /^\d+%$/) ? $width : $width.'px');
    $self->setParam('char_limit', $self->getCharLimit()); 
    $self->setParam('content', $self->getModel());
    $self->setParam('error', '');
    
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
