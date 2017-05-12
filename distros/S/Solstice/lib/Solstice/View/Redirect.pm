package Solstice::View::Redirect;

# $Id: $

=head1 NAME

Solstice::View::Redirect - The view for Redirect

=head1 SYNOPSIS

  # See L<Solstice::View> for usage.

=head1 DESCRIPTION

This is the view for the page Redirect

The canonical solstice redirector.  Give it a URL, users will be redirected to it.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View::Download);

use Solstice::Server;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    
    return $self;
}

sub sendHeaders {
    my $self = shift;
    my $server = Solstice::Server->new();

    $server->addHeader('Location', $self->getModel());
    $server->setStatus(302);
    $server->printHeaders();
}


=item generateParams()

=cut

sub printData {
    my $self = shift;

    print "<a href='".$self->getModel()."'>Click here...</a>";

    return TRUE;
}

1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

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

