package Solstice::HelpService;

# $Id: HelpService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::HelpService - A service for building a queue of text strings 

=head1 SYNOPSIS

  use Solstice::HelpService;
  my $help_service = new Solstice::HelpService;

  my $str = 'Blah blah';
  
  $help_service->addHelp($str);
  $help_service->clearPageHelp();

  # Returns an array ref
  my $help_list = $help_service->getPageHelp();

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new HelpSystem object.

=cut

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

=item addHelp($string)

=cut

sub addHelp {
    my $self = shift;
    my $help = shift;

    return 0 unless defined $help;
    
    my $help_queue = $self->get('help_queue') || [];
    
    push @$help_queue, $help;

    $self->set('help_queue', $help_queue);

    return 1;
}

=item getPageHelp()

Returns an array ref of all help objects added to the page.

=cut

sub getPageHelp {
    my $self = shift;
    return $self->get('help_queue') || [];
}

=item clearPageHelp()

Removes all help objects added to the page.

=cut

sub clearPageHelp {
    my $self = shift;
    $self->set('help_queue', undef);
    return 1;
}


=back

=head2 Private Methods

=over 4

=cut

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::HelpService';
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
