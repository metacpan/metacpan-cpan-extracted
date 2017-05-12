package Solstice::ImplementationManager;

=head1 NAME

Solstice::ImplementationManager - Manages inter-app communication.

=head1 SYNOPSIS

  my $manager = Solstice::ImplementationManager->new();
  # The list returned constists of Solstice::ImplementationData objects.
  my $list = $manager->createList({
      person => $solstice_person,
    method => 'methodName',
    args   => \@arguments_to_method,
  });

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::List;
use Solstice::Database;

use constant TRUE => 1;
use constant FALSE => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::ImplementationManager object.  

=cut

sub new {
    my $obj = shift;
    my $self = bless {}, ref $obj || $obj;

    return $self;
}

=item getToolImplementationManagers()

Returns a L<List> containing all available managers.

=cut

sub getToolImplementationManagers {
    my $self = shift;
    $self->_initializeManagers();

    my $list = Solstice::List->new();
    for my $obj (@{$self->{'_tool_managers'}}) {
        $list->push($obj);
    }
    return $list;
}

=item getAppsWithoutManager()

Returns a L<List> containing all installed applications that don't have a manager.

=cut

sub getAppsWithoutManager {
    my $self = shift;
    $self->_initializeManagers();

    my $list = Solstice::List->new();
    for my $obj (@{$self->{'_tools_without_managers'}}) {
        $list->push($obj);
    }
    return $list;
}

=item createList({ person => $solstice_person, method => 'methodName', args => \@args_to_method })

Calls the given method on all installed factories, returning a L<List> of L<Solstice::ImplementationData> objects.

=cut

sub createList {
    my $self = shift;
    my $input = shift;
    my $factories = $self->getToolImplementationManagers();

    my $method = $input->{'method'};
    my $person = $input->{'person'};
    my $arg_ref = $input->{'args'};

    my $impl_list = Solstice::List->new();

    if (!defined $method or !$method) {
        warn "createList called without a method.  caller: ".join(' ', caller) ."\n";
        return $impl_list; 
    }
    
    my $manager_iterator = $factories->iterator();
    while ($manager_iterator->hasNext()) {
        my $manager = $manager_iterator->next();
        if ($manager->can($method)) {
            my $sub_list = eval { $manager->$method(@$arg_ref); };
            warn $@ if $@;
            if (defined $sub_list && $sub_list) {
                my $iterator = $sub_list->iterator();
                while ($iterator->hasNext()) {
                    $impl_list->push($iterator->next());
                }
            }
        }
    }
    return $impl_list;
}

=item _initializeManagers()

Determines what tools have managers, and creates them, while tracking those that don't.

=cut

sub _initializeManagers {
    my $self = shift;
    if (defined $self->{'_initialized_managers'} and $self->{'_initialized_managers'}) {
        return TRUE;
    }

    my @no_manager_apps;
    my @managers;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT name, namespace FROM '.$db_name.'.Application');
    while (my $application= $db->fetchRow()) {
        my $name   = $application->{'name'};
        my $prefix = $application->{'namespace'};
        if(defined $prefix && $prefix){
            $prefix .= "::ImplementationManager";

            eval{
                $self->loadModule($prefix);
            };
            if($@){
                push @no_manager_apps, $name;
            }else{
                my $obj = $prefix->new();
                push @managers, $obj;
            }
        }
    }

    $self->{'_tools_without_managers'} = \@no_manager_apps;
    $self->{'_tool_managers'} = \@managers;
    $self->{'_initialized_managers'} = TRUE;

    return TRUE;
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Database|Solstice::Database>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2579 $ 



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
