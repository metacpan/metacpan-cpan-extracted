package Solstice::State::Memory;

# $Id: Memory.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::State::Memory - An interface to some global memory where the all of the state information is stored.

=cut

=head1 SYNOPSIS

  use Solstice::State::Memory;

  my $state_service = new Solstice::State::Memory;

=cut

=head1 DESCRIPTION

All of the states, pageflows, and remotes are stored in one place --
right here.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service::Memory);

use File::stat;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service::Memory|Solstice::Service::Memory>

=head2 Methods

=over 4

=cut


=item new()

Constructor.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    return $self;
}


=item setMachine($state)

Sets the state machine.

=cut

sub setMachine {
    my ($self, $state_machine) = @_;
    $self->setValue('stateMachine', $state_machine);
}


=item getMachine()

Gets the state machine.

=cut

sub getMachine {
    my ($self) = @_;
    return $self->getValue('stateMachine');
}


=item setLastParsedTime($pageflow_file, $time)

Sets the timestamp for the last time a pageflow file was parsed.

=cut

sub setLastParsedTime {
    my ($self, $pageflow_file, $time) = @_;
    $self->setValue('last_parsed_time_'.$pageflow_file, $time);
}


=item requiresParsing($pageflow_file)

Gets whether the pageflow file needs to be parsed (i.e., been
changed since the last time it was parsed).

=cut

sub requiresParsing {
    my ($self, $pageflow_file) = @_;
    my $file_info = stat($pageflow_file);
    my $last_modified_time = $file_info->mtime;
    my $last_parsed_time = $self->getValue('last_parsed_time_'.$pageflow_file) || 0;
    return ($last_modified_time > $last_parsed_time);
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service::Memory|Solstice::Service::Memory>.

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
