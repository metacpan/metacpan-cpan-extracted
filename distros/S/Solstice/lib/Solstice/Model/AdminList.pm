package Solstice::Model::AdminList;

# $Id:$

=head1 NAME

Solstice::AdminList - allows for the editing and fetching of admin data

=head1 SYNOPSIS

  use SolsticeAdmin::AdminList;

  my $model = SolsticeAdmin::AdminList->new();
  
=head1 DESCRIPTION

This manages the Administrators table in the solstcie database
=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::Configure;
use Solstice::Person;
use Solstice::List;
use Solstice::Database;
use base qw(Solstice::Model::List);

use constant TRUE    => 1;
use constant FALSE    => 0;

our ($VERSION) = ('$Revision: 110 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=item new()

Constructor.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);

    $self->_init();
    
    return $self;
}

sub isAdmin{
    my $self = shift;

    #this is because userservice can be defeated via overrides
    my $login = $ENV{'REMOTE_USER'};

    if(!defined $login){
        my $user_service = $self->getUserService();
        my $user = $user_service->getOriginalUser();
        return FALSE unless defined $user;
        
        $login = $user->getLoginName();
    }
    
    return FALSE unless defined $login;
    
    my $iterator = $self->iterator();
    
    while (my $admin = $iterator->next()){
        return TRUE if $admin->getLoginName() eq $login;
    }
    return FALSE;
}

sub _init{
    my $self = shift;

    my $db = Solstice::Database->new();

    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery("SELECT person_id FROM $db_name.Administrators");
    while (my $data = $db->fetchRow()) {
        $self->add(Solstice::Person->new($data->{'person_id'}));
    }
}

sub removeAdminByID{
    my $self = shift;
    my $id = shift;

    my @admins = @{$self->getAll()};

    $self->clear();

    for my $admin (@admins){
        $self->add($admin) unless $admin->getID() == $id;
    }
}



sub store{
    my $self = shift;

    my $db = Solstice::Database->new();

    my $iterator = $self->iterator();

    my @ids;
    while($iterator->hasNext()){
        my $person = $iterator->next();
        push @ids, $person->getID();
    }

    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    
    my $values_string = "(" . join("), (", @ids) . ")";

    $db->writeQuery("DELETE FROM $db_name.Administrators");
    if(@ids){
        $db->writeQuery("INSERT INTO $db_name.Administrators (person_id) values $values_string");
    }

}

1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 110 $



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
