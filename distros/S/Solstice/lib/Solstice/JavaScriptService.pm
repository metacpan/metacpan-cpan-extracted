package Solstice::JavaScriptService;

# $Id:$

=head1 NAME

Solstice::JavaScriptService - Allows models at all levels to know whether the user's browser supports Javascript.

=head1 SYNOPSIS

  use Solstice::JavaScriptService;
  
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::Session;

our ($VERSION) = ('$Revision: 2061 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::JavaScriptService object.

=cut

sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
}

=item hasJavascript()

Returns whether or not the current user has js enabled

=cut

sub hasJavascript {
    my $self = shift;
    unless( defined $self->get('has_javascript') ){
        my $session = Solstice::Session->new();
        $self->setHasJavascript($session->hasJavascript());
    }
    return $self->get('has_javascript'); 
}

=item setHasJavascript($bool)

=cut

sub setHasJavascript {
    my $self = shift;
    my $has_js = shift;
    $self->set('has_javascript', $has_js);
}

=back

=head2 Private Methods

=over 4

=cut

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::JavaScriptService';
}


1;

__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2061 $



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
