package Solstice::View::PopIn;

# $Id: PopIn.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::View::PopIn - View of a dynamically raised and positioned box.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View);

use constant TEMPLATE => 'pop_in.html';

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View|Solstice::View>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    
    $self->_setTemplate(TEMPLATE); 
    $self->_setTemplatePath('templates');

    return $self;
}


1;

__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $

=head1 SEE ALSO

L<Solstice::View>,
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
