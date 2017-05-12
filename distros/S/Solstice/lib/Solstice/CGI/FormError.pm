package Solstice::CGI::FormError;

# $Id$

=head1 NAME

Solstice::CGI::FormError - A form error object for Solstice. 

=head1 SYNOPSIS

  use Solstice::CGI::FormError;

  my $error = new Solstice::CGI::FormError()

=head1 DESCRIPTION

This API will be used by Solstice::View::MessageService to display an error message.

=cut

use 5.006_000;
use strict;
use warnings;

our ($VERSION) = ('$Revision$' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::CGI::FormError object.

=cut

sub new {
    my $obj = shift;

    my $self = bless {}, $obj;

    return $self;
}


=item setFormMessages(\%messages)

Sets any form error message strings.

=cut

sub setFormMessages {
    my $self = shift;
    my ($messages) = @_;

    $self->{_form_messages} = $messages;
}


=item getFormMessages()

Get the form error message strings.

=cut

sub getFormMessages {
    my $self = shift;

    return $self->{_form_messages};
}


1;
__END__

=back

=head1 AUTHOR

Jim Laney, E<lt>jlaney@u.washington.eduE<gt>

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision$



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
