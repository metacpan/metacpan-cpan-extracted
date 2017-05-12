package Solstice::Controller::Resource::File::Download;

# $Id: Download.pm 452 2005-07-05 18:33:46Z mcrawfor $

=head1 NAME

Solstice::Controller::Resource::File::Download

=head1 SYNOPSIS

  # See L<Solstice::Controller> for usage.

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Controller);

use Solstice::CGI;
use Solstice::Encryption;
use Solstice::Model::FileTicket;
use Solstice::Resource::File::BlackBox;
use Solstice::View::Resource::File::Download;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 452 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Controller|Solstice::Controller>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return $self if defined $self->getModel();

    # If file is not defined, this might be a ticketed download.
    # The ticket will contain the data needed to get the file.
    my $enc_param;
    if ($enc_param = param('tkt')) {
        my $ticket = Solstice::Model::FileTicket->new({key => $enc_param});
        if (defined $ticket) {
            my $file_class = $ticket->getFileClass();
            $self->loadModule($file_class);

            $self->setModel($file_class->new($ticket->getFileID()));

            $ticket->expire();
        }
    } elsif ($enc_param = param('ptkt')) {
        my $param = Solstice::Encryption->new()->decryptHex($enc_param);
        if ($param =~ /^permanent_ticket_id_(\d+)$/){
            $self->setModel(Solstice::Resource::File::BlackBox->new($1));
        }
    }
 
    return $self;
}

=item getView()

=cut

sub getView {
    my $self = shift;
    return Solstice::View::Resource::File::Download->new($self->getModel());
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Controller|Solstice::Controller>,

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 452 $

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
