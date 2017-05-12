package Solstice::View::DeniedBrowser;

# $Id: DeniedBrowser.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::View::DeniedBrowser - View shown to users whose browser is in the blacklist.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;
use Solstice::View;

use constant TEMPLATE => 'denied_browser.html';

our @ISA = qw(Solstice::View);
our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View|Solstice::View>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new ()

Constructor.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    
    $self->_setTemplate(TEMPLATE);
    $self->_setTemplatePath('templates');
    
    return $self;
}

=back

=head2 Private Methods

=over 4

=cut

=item _getTemplateParams()

=cut

sub _getTemplateParams {
    my $self = shift;
    return {};
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>.

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
