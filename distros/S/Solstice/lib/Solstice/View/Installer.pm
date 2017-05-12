package Solstice::View::Installer;

# $Id: $

=head1 NAME

Solstice::View::Installer - Controls the process on configuring a new Solstice install 

=head1 SYNOPSIS

=head1 DESCRIPTION

This controls the process of installing/configuring the Solstice Framework, once the initial web presence is in place.  Since most of Solstice isn't ready for use, we can't use almost any of the usual tools for app navigation.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View);

use Solstice::View::MessageService;
use Sys::Hostname;
use Solstice::CGI;
use Solstice::StringLibrary qw(unrender);

use constant SUCCESS => 1;
use constant FAIL    => 0;
use constant TRUE    => 1;
use constant FALSE   => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    my $solstice_root = $self->getConfigService()->getRoot();
    
    $self->setPossibleTemplates(
        'installer/basic.html', 
        'installer/post_install.html', 
    );

    my $model = $self->getModel();
    if ($model->getPersistenceDone()) {
        $self->_setTemplate('installer/post_install.html');
    }else{
        $self->_setTemplate('installer/basic.html');
    }

    return $self;
}

sub generateParams {
    my $self = shift;

    my $persister = $self->getModel();

    $self->addChildView('messaging_pane', Solstice::View::MessageService->new()) if $self->getMessageService()->getMessages();

    if($persister->getPersistenceDone()){
        $self->_generatePostInstallParams();
    }else{
        $self->_generateBasicParams();
        $self->_generateDBParams();
    }
}

sub _generatePostInstallParams {
    my $self = shift;
    my $persister = $self->getModel();

    if ($persister->getPersistenceNonWritableConfig()) {
        $self->setParam('non_writable_config', TRUE);
        $self->setParam('config_content', unrender($persister->getPersistenceConfigContent()));
        my $cpath = $self->getConfigService()->getRoot().'/conf/solstice_config.xml';
        $cpath =~ s/\/+/\//g;
        $self->setParam('config_file_path', $cpath);
    }
    
}

sub _generateDBParams {
    my $self = shift;

    $self->setParam('dbhost', defined param('dbhost') ? param('dbhost') : '');
    $self->setParam('dbuser', defined param('dbuser') ? param('dbuser') : 'solstice');
    $self->setParam('dbpass', defined param('dbpass') ? param('dbpass') : '');
    $self->setParam('dbport', defined param('dbport') ? param('dbport') : '3306');
    $self->setParam('session_dbname', defined param('session_dbname') ? param('session_dbname') : 'sessions');
    $self->setParam('solstice_dbname', defined param('solstice_dbname') ? param('solstice_dbname') : 'solstice');
}

sub _generateBasicParams {
    my $self = shift;

    my $persister = $self->getModel();

    my $hostname      = defined param('server_name') ? param('server_name') : ( ucfirst(hostname) ." Solstice Server");
    my $virtual_root  = defined param('virtual_root') ? param('virtual_root') : '/solstice/';
    my $data_root     = defined param('log_directory') ? param('log_directory') : $self->_makeCanonicalPath($self->getConfigService()->getRoot()."/../solstice_data/");
    my $app_path      = defined param('app_path') ? param('app_path') : $self->_makeCanonicalPath($self->getConfigService()->getRoot() ."/../solstice_apps");

    $self->setParam('server_name', $hostname);
    $self->setParam('virtual_root', $virtual_root);
    $self->setParam('app_path', $app_path);
    $self->setParam('support_email', defined param('support_email') ? param('support_email') : '');
    $self->setParam('admin_email', defined param('admin_email') ? param('admin_email') : '');
    $self->setParam('log_directory', $data_root);
    $self->setParam('is_dev_server', defined param('is_dev') ? param('is_dev') : FALSE);
    $self->setParam('generate_key', defined param('generate_key') ? param('generate_key') : TRUE );
    $self->setParam('encryption_key', param('encryption_key'));
    $self->setParam('host_name', defined param('host_name') ? param('host_name') : 'your-host.com');
}

sub _makeCanonicalPath {
    my $self = shift;
    my $path = shift;

    # XXX - assumes unix-isms.
    $path =~ s'/+'/'g;
    my @dirs = split('/', $path);
    my @new_path;
    for (my $i = 0; $i <= $#dirs; $i++) {
        if ($dirs[$i] ne '..' and $dirs[$i] ne '.') {
            push @new_path, $dirs[$i];
        }
        if ($dirs[$i] eq '..') {
            pop @new_path;
        }
    }
    my $return = join('/', @new_path);
    return "$return/";
}

1;
__END__

=back

=head2 Modules Used

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: $



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
