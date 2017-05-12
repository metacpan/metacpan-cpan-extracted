package Solstice::UserService;

# $Id: UserService.pm 3382 2006-05-15 21:25:18Z pmichaud $

=head1 NAME

Solstice::UserService - Provides access to the logged-in user.

=head1 SYNOPSIS

  use Solstice::UserService;

  my $service = Solstice::UserService->new();

  my $user = $service->getUser();

=head1 DESCRIPTION

You can get the currently logged-in user at any time using this service.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::Service::LoginRealm;
use Solstice::Factory::Person;
use Solstice::Session;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3382 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported..

=head2 Methods

=over 4

=cut

=item getUser()

Returns a Person object.  If there is no Session, or no user in
Session, $person is created using Solstice::Service::LoginRealm. 

=cut

sub getUser {
    my $self = shift;
    
    my $session = Solstice::Session->new();
    
    unless (defined $session) {
        die "Session not defined in UserService::getUser, called from ". join(' ', caller)."\n";
    }
    
    my $person;
    if ($person = $session->getUser()) {
        $self->loadModule(ref $person->getLoginRealm());
        return $person;
    }

    if (my $login = Solstice::Service::LoginRealm->new()->getLogin()) {
        $person = Solstice::Factory::Person->new()->createByLogin($login);
        $person->updateLoginDate();
        $session->setUser($person);
        return $person;
    }

    return;
}

=item hasUser()

Returns TRUE if a user can be created. This means the session has a user, or $ENV{'REMOTE_USER'} is defined.

=cut

sub hasUser {
    my $self = shift;
    return (defined Solstice::Session->new()->getUser()) ? TRUE : FALSE;
}

=item getOriginalUser()

Returns the original Person object, ignoring administrative overrides.

=cut

sub getOriginalUser {
    my $self = shift;

    my $session = Solstice::Session->new();

    my $person = $session->getOriginalUser();
    return $person if defined $person;

    $self->getUser(); #init the original user, then
    $session = Solstice::Session->new();
    return $session->getOriginalUser();
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>,
L<Solstice::Factory::Person|Solstice::Factory::Person>,
L<Solstice::Service::LoginRealm|Solstice::Service::LoginRealm>,
L<Solstice::Session|Solstice::Session>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3382 $



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
