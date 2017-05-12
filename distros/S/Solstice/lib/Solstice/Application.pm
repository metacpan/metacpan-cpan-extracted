package Solstice::Application;

# $Id: Application.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Application - An object representing a Solstice application.

=head1 SYNOPSIS

  # This is always subclassed, enhanced with accessors for data relevent to a specific instantiation of an application.
  use Solstice::Application;
  my $application = new Solstice::Application($app_name);
  my $name = $application->getName();
  my $version = $application->getVersion();
  my $namespace = $application->getNamespace();

  # Returns the StateTracker object for this instantiation of an application.
  my $state = $application->getState();

  # This can be used to put data personalized to the screen in the breadcrumbing.
  my $breadcrumb_info = $application->getStatePersonalInfo();


=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::Configure;
use Solstice::Database;
use Solstice::Configure;
use Solstice::NamespaceService;

use constant TRUE    => 1;
use constant FALSE   => 0;
use constant SUCCESS => 1;
use constant FAIL    => undef;

my %application_cache;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::Application object.  

=cut

sub new {
    my $obj = shift;
    my $input = shift;

    my $self = $obj->SUPER::new();

    if (defined $input and ref $input eq 'HASH') { #info passed as hash
        if($input->{'id'}){
            $self = $self->_init($input->{'id'});
        }elsif($input->{'namespace'}){
            $self = $self->_init($input->{'namespace'});
        }else{
            return;
        }

    } elsif (defined $input) { #pull from id/namespace
        $self = $self->_init($input);

    }else{ # no param - use namespace
        caller =~ m/^(\w+):.*$/;
        my $input = $1;

        if($input eq 'Solstice'){ #abstract superclass
            return undef;
        }else{
            $self = $self->_init($input);
        }
    }

    return $self;
}

=item getNavigationView()

Attempts to return the application's navigation view.  Should be overridden in the subclass
for custom behavior.  This will be called unless some application code explicitly sets a 
navigation view.

=cut

sub getNavigationView {
    my $self = shift;

    my $namespace = Solstice::NamespaceService->new()->getAppNamespace();

    my $nav_view_package = $namespace.'::View::Navigation';

    my $nav_view;
    eval { 
        $self->loadModule($nav_view_package);
        $nav_view = $nav_view_package->new();
    };

    return $nav_view if $nav_view;
}

sub flushApplicationCache {
    %application_cache = ();
    return TRUE;
}


=back

=head2 Private Methods

=over 4

=item _init($id)
=item _init($name)

Initialize the application object

=cut

sub _loadApplicationData {
    my $self = shift;

    my $config = Solstice::Configure->new();
    my $db = Solstice::Database->new();
    my $db_name = $config->getDBName();

    $db->readQuery('SELECT application_id, name, namespace
        FROM '.$db_name.'.Application');

    while( my $row = $db->fetchRow() ){
        $application_cache{ $row->{'application_id'} } = $row;
        $application_cache{ $row->{'namespace'} } = $row;
    }

}

sub _addApplicationEntry {
    my $self = shift;
    my $namespace = shift;

    warn "Creating an entry for ${namespace}::Application in the Solstice Application table!";
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    $db->writeQuery("INSERT INTO $db_name.Application (name, namespace) VALUES (?,?)", $namespace, $namespace);

    $self->flushApplicationCache();
    $self->_loadApplicationData();
}

sub _init {
    my $self = shift;
    my $input = shift;

    return FAIL unless defined $input;

    $self->_loadApplicationData() unless %application_cache;

    if (!defined $application_cache{$input}) {
        #flush and reload application data to ensure some other thread has not 
        #already added this app
        $self->flushApplicationCache();
        $self->_loadApplicationData();

        #if the cache STILL doesn't have the app:
        if (!defined $application_cache{$input}) {
            $self->_addApplicationEntry($input);
        }
    }

    my $data = $application_cache{$input};

    return FAIL unless $data->{'application_id'};

    #swap out the package name if possible
    eval {
        $self->loadModule($data->{'namespace'}.'::Application');
    };
    unless($@){
        $self = bless {}, $data->{'namespace'}.'::Application';
    }

    $self->_setID($data->{'application_id'});
    $self->_setName($data->{'name'});
    $self->_setNamespace($data->{'namespace'});

    return $self;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
    {
        name => 'Name',
        key  => '_name',
        type => 'String',
        private_set => TRUE,
    },
    {
        name => 'Namespace',
        key  => '_namespace',
        type => 'String',
        private_set => TRUE,
    },
    {
        name => 'Version',
        key  => '_version',
        type => 'Float',
        private_set => TRUE,
    },
    {
        name => '500Error',
        key  => '_500_error',
        type => 'Boolean',
    },
    ];
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Database|Solstice::Database>.

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
