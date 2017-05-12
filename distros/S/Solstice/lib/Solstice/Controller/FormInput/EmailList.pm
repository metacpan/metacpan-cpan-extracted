package Solstice::Controller::FormInput::EmailList;

# $Id: EmailList.pm 25 2006-01-14 00:50:12Z jlaney $

=head1 NAME

Solstice::Controller:FormInput::EmailList - Collects and validates a box of email addresses

=head1 SYNOPSIS

  # See L<Solstice::Controller> for usage.

=head1 DESCRIPTION

This is a controller to handle form input consisting of a list of email addresses 

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::FormInput);

use Solstice::View::FormInput::EmailList;

use Solstice::CGI;
use Solstice::List;
use Solstice::StringLibrary qw(trimstr);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant PARAM => 'email_list';

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=item new($model)

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    unless (defined $self->getModel()) {
        $self->setModel(Solstice::List->new());
    }

    return $self;
}

=item getView()

Creates the view object for the home page.

=cut

sub getView {
    my $self = shift;

    my $view = Solstice::View::FormInput::EmailList->new($self->getModel());
    $view->setName($self->getName() || PARAM);
    $view->setInvalidEmails($self->getInvalidEmails());
    
    return $view;
}

=item update()

=cut

sub update { 
    my $self = shift;

    my $email_str = param($self->getName() || PARAM);
    
    my $list = $self->getModel();
    $list->clear();
    
    return TRUE unless defined $email_str;
   
    my %existing_emails = (); 
    for my $str (split /[\n\r,]+/, $email_str) {
        next unless (defined $str and $str =~ /\w/);
        $str = trimstr($str);
        
        # Disallow duplicates
        next if exists $existing_emails{$str};
        $existing_emails{$str} = 1;

        $list->push($str);
    }
    
    return TRUE;
}

=item validate()

=cut

sub validate {
    my $self = shift;

    my $name = $self->getName() || PARAM;
   
    my $param = $self->getIsRequired()
        ? $self->createRequiredParam($name)
        : $self->createOptionalParam($name);
    
    $param->addConstraint('invalid_emails', $self->constrainValidEmailList());
    
    return $self->processConstraints();
}

=item constrainValidEmailList()

=cut

sub constrainValidEmailList {
    my $self = shift;

    my $valid = TRUE;
    
    my $iterator = $self->getModel()->iterator();
    while (my $email = $iterator->next()) {
        unless ($self->isValidEmail($email)) {
            $valid = FALSE;
            $self->addInvalidEmail($email);
        }
    }
    return sub { return $valid; };
}

=item addInvalidEmail($str)

=cut

sub addInvalidEmail {
    my $self = shift;
    my $str  = shift;
    push @{$self->getInvalidEmails()}, $str;
    return TRUE;
}

=item getInvalidEmails()

=cut

sub getInvalidEmails {
    my $self = shift;
    return $self->{'_invalid_emails'} if defined $self->{'_invalid_emails'};
    return $self->{'_invalid_emails'} = [];
}

1;
__END__

=back

=head1 AUTHOR

Educational Technology Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 25 $

=head1 SEE ALSO

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
