package Solstice::Resource::Directory;

# $Id: Directory.pm 747 2005-09-30 19:38:37Z jlaney $

=head1 NAME

Solstice::Resource::Directory - A model representing a directory

=head1 SYNOPSIS

  package Solstice::Resource::Directory;
  
  use Solstice::Resource::Directory;
 
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw( Solstice::Resource );

use constant TRUE  => 1;
use constant FALSE => 0;

use constant TYPE_DESCRIPTION => 'Folder';

our ($VERSION) = ('$Revision: 747 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Resource|Solstice::Resource>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item getContentTypeDescription()

Return a string containing a description of this resource.

=cut

sub getContentTypeDescription {
    return TYPE_DESCRIPTION;
}

=item isContainer()

Return TRUE if the resource is a container, FALSE otherwise.

=cut

sub isContainer {
    return TRUE;
}

=item list()

Fetch the contents of this directory. Return TRUE on success,
FALSE otherwise.

=cut

sub list {
    my $self = shift;
    die (ref($self) . "->list(): Not implemented\n");
}

=item contains($filename)

Returns TRUE if the directory contains the passed $filename, FALSE otherwise.

=cut

sub contains {
    my $self = shift;
    die (ref($self) . "->contains(): Not implemented\n");
}

=item addChild()

=cut

sub addChild {
    my $self = shift;

    $self->_taint();
    return $self->Solstice::Tree::addChild(@_);
}

=item isValidChildName($name)

Returns TRUE if passed $name is valid for a child resource, FALSE 
otherwise. 

=cut

sub isValidChildName {
    return TRUE;
}

=item getFileClass()

=cut

sub getFileClass {
    my $self = shift;
    warn ref($self) . "->getFileClass(): Not implemented\n";
    return;
}

=back

=head2 Private Methods

=over 4

=item _store()

Recursively store children.

=cut

sub _store {
    my $self = shift;

    my $return = FALSE;
    for my $child ($self->getChildren()) {
        $return &= $child->store();
    }
    return $return;
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Resource|Solstice::Resource>.

=head1 SEE ALSO

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 747 $

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
