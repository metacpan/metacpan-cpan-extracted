package Solstice::IconService;

# $Id: IconService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::IconService - Gives access to a library of icons.

=head1 SYNOPSIS

  use Solstice::IconService;
  
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use constant OBJECT_IMAGES => 'images/icons/';
use constant ACTION_IMAGES => 'images/actions/';
use constant EXTENSION     => '.gif';
use constant DEFAULT_COLOR => 'blue';

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new([\%params])

Creates a new Solstice::IconService object.

=cut

sub new {
    my $class = shift;
    my $params = shift;
    
    my $self = $class->SUPER::new(@_);
    
    if (defined $params) {
        $self->setSize($params->{'size'});
        $self->setLocked($params->{'locked'});
        $self->setColor($params->{'color'});
    }
    
    return $self;
}

=item setSize($int)

Set the size attribute, in pixels. Available values are 16, 20 and 32.

=cut

sub setSize {
    my $self = shift;
    my $size = shift;
    $self->set('size', $size);
}

=item getSize()

Return the size attribute.

=cut

sub getSize {
    my $self = shift;
    return $self->get('size');
}

=item setLocked($bool)

Set the locked boolean attribute. Specifies a "locked" version of the icon if set.

=cut

sub setLocked {
    my $self = shift;
    my $locked = shift;
    $self->set('locked', $locked);
}

=item getLocked()

Return the locked attribute.

=cut

sub getLocked {
    my $self = shift;
    return $self->get('locked');
}

=item setColor($string)

=cut

sub setColor {
    my $self = shift;
    my $color = shift;
    $self->set('color', $color);
}

=item getColor()

=cut

sub getColor {
    my $self = shift;
    return $self->get('color');
}

=item getIconByType($type) {

Return the icon path for the passed file content-type.
Returns the path for a generic icon if the type is unknown.

=cut

sub getIconByType {
    my $self = shift;
    my $type = shift;
    
    return undef unless defined $type;

    my $size = $self->getSize() || 16;

    return OBJECT_IMAGES .
        ($size < 17 ? '16/' : '32/') .
        ($self->getLocked() ? 'locked/' : 'unlocked/') .
        $self->getContentTypeService()->getIconByContentType($type);
}    

=item getIconByName($name)

Return an icon path for the passed icon name.

=cut

sub getIconByName {
    my $self = shift;
    my $name = shift;

    return undef unless defined $name;
    
    return $self->_getObjectIconPath($name);
}

=item getIconByAction($name)

Return an icon path for the passed icon name.

=cut

sub getIconByAction {
    my $self = shift;
    my $name = shift;

    return undef unless defined $name;
    
    return $self->_getActionIconPath($name);
}

=back

=head2 Private Methods

=over 4

=cut

=item _getObjectIconPath($icon)

Return a file path for an icon file.

=cut

sub _getObjectIconPath {
    my $self = shift;
    my $icon = shift;

    my $size   = $self->getSize() || 16;
    my $locked = $self->getLocked();

    return OBJECT_IMAGES . 
        ($size < 17 ? '16/'     : '32/') .
        ($locked    ? 'locked/' : 'unlocked/') .
        $icon . EXTENSION;
}

=item _getActionIconPath($icon)

Return a file path for an icon file.

=cut

sub _getActionIconPath {
    my $self = shift;
    my $icon = shift;

    my $size  = $self->getSize()  || 20;

    return ACTION_IMAGES .
        $size . '/' .
        ($self->getColor || DEFAULT_COLOR) . '/' .
        $icon . EXTENSION;
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::IconService';
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



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
