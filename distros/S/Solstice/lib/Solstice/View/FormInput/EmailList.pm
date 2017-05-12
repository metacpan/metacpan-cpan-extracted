package Solstice::View::FormInput::EmailList;

# $Id: EmailList.pm 107 2005-09-01 23:14:11Z mcrawfor $

=head1 NAME

Solstice::View::FormInput::EmailList - A view of an html <textarea> element containing email addresses

=head1 SYNOPSIS

  # See L<Solstice::View> for usage.

=head1 DESCRIPTION

A view of a form input, showing email addresses

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::View::FormInput);

use Solstice::List;
use Solstice::StringLibrary qw(unrender);

use constant TRUE  => 1;
use constant FALSE => 0;

our $template = 'form_input/email_list.html';

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_setTemplatePath('templates');

    return $self;
}

=item setInvalidEmails(\@list)

=cut

sub setInvalidEmails {
    my $self = shift;
    $self->{'_invalid_emails'} = shift;
}

=item getInvalidEmails()

=cut

sub getInvalidEmails {
    my $self = shift;
    return $self->{'_invalid_emails'};
}

=item generateParams()

=cut

sub generateParams {
    my $self = shift;
    my $email_list = $self->getModel();

    my $name = $self->getName();
    
    $self->setParam('name', $name);

    if (my $error = $self->getError()) {
        my $error_hash = $error->getFormMessages();
        for my $key (keys %$error_hash){
            if ($key =~ /^err_$name$/) {
                $self->setParam('error', $error_hash->{$key});
                
                #TODO: maximum number of invalid emails displayed?
                for my $str (@{$self->getInvalidEmails()}) {
                    $self->addParam('invalid', { address => unrender($str) });
                }
                last;
            }
        }
    }
    
    my $iterator = $email_list->iterator();
    while (my $email = $iterator->next()) {
        $self->addParam('addresses', { address => unrender($email) });
    }
    
    return TRUE;
}


1;
__END__

=back

=head1 AUTHOR

Educational Technology Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 107 $

=head1 SEE ALSO

L<UMail::View>,
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
