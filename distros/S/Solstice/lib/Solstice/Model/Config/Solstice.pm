package Solstice::Model::Config::Solstice;

use strict;
use warnings;
use 5.006_000;

use XML::LibXML;
use Solstice::View::Config::Solstice;

use base qw(Solstice::Model::Config);

use constant TRUE => 1;
use constant FALSE => 0;


sub _store {
    my $self = shift;
    my $superclass_params = shift;

    my $view = Solstice::View::Config::Solstice->new();
    $view->setParams($superclass_params);
    $view->setParams(
        {
            db_hosts             => $self->_storeDbHosts(),
            memcached_servers    => $self->_storeMemcachedServers(),
            log_modules          => $self->_storeLogModules(),
            app_dirs             => $self->_storeAppDirs(),
            virtual_root         => $self->_storeVirtualRoot(),
            server_string        => $self->_storeServerString(),
            webservice_rest_root => $self->_storeWebserviceRestRoot(),
            support_email        => $self->_storeSupportEmail(),
            admin_email          => $self->_storeAdminEmail(),
            data_root            => $self->_storeDataRoot(),
            debug_level          => $self->_storeDebugLevel(),
            session_backend      => $self->_storeSessionBackend(),
            session_db           => $self->_storeSessionDb(),
            session_cookie       => $self->_storeSessionCookie(),
            smtp_server          => $self->_storeSmtpServer(),
            smtp_mailname        => $self->_storeSmtpMailname(),
            smtp_msg_wait        => $self->_storeSmtpMsgWait(),
            smtp_use_queue       => $self->_storeSmtpUseQueue(),
            encryption_key       => $self->_storeEncryptionKey(),
            development_mode     => $self->_storeDevelopmentMode(),
            require_ssl          => $self->_storeRequireSsl(),
            error_html           => $self->_storeErrorHtml(),
            boilerplate_view     => $self->_storeBoilerplateView(),
            slow_query_time      => $self->_storeSlowQueryTime(),
            compiled_view_path   => $self->_storeCompiledViewPath(),
            lang                 => $self->_storeLang(),
        }
    );

    my $content = '';
    $view->paint(\$content);
    return $content;
}

sub _parseSlowQueryTime {
    my $self = shift;
    $self->_setSlowQueryTime(shift->textContent() || undef);
}

sub _storeSlowQueryTime {
    my $self = shift;
    return $self->getSlowQueryTime();
}

sub _parseCompiledViewPath {
    my $self = shift;
    $self->_setCompiledViewPath(shift->textContent());
}

sub _storeCompiledViewPath {
    my $self = shift;
    return $self->getCompiledViewPath();
}

sub _parseBoilerplateView {
    my $self = shift;
    $self->_setBoilerplateView(shift->textContent());
}

sub _storeBoilerplateView {
    my $self = shift;
    return $self->getBoilerplateView();
}


sub _parseDbHosts {
    my $self = shift;
    my $parent = shift;

    my $servers = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$servers, {
            'password'      => $node->getAttribute('password'),
            'database_name' => $node->getAttribute('database_name'),
            'user'          => $node->getAttribute('user'),
            'host_name'     => $node->getAttribute('host_name'),
            'type'          => $node->getAttribute('type'),
            'port'          => $node->getAttribute('port'),
        };
    }

    $self->_setDBHosts($servers);
}

sub _storeDbHosts {
    my $self = shift;

    my @params;

    for my $host (@{ $self->getDBHosts() }){
        push @params, {
            'password'      => $host->{'password'},
            'database_name' => $host->{'database_name'},
            'user'          => $host->{'user'},
            'host_name'     => $host->{'host_name'},
            'type'          => $host->{'type'},
            'port'          => $host->{'port'},
        };
    }

    return \@params;
}

sub _parseMemcachedServers {
    my $self = shift;
    my $parent = shift;

    my $servers = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$servers, $node->textContent();
    }

    $self->_setMemcachedServers($servers);
}

sub _storeLogModules {
    my $self = shift;

    my @params;

    for my $module (@{ $self->getLogModules() }){
        push @params, {
            'module'      => $module,
        };
    }

    return \@params;
}
sub _storeAppDirs {
    my $self = shift;

    my @params;

    for my $dir (@{ $self->getAppDirs() }){
        push @params, {
            'dir'      => $dir,
        };
    }

    return \@params;
}
sub _storeMemcachedServers {
    my $self = shift;

    my @params;

    for my $host (@{ $self->getMemcachedServers() }){
        push @params, {
            'server'      => $host,
        };
    }

    return \@params;
}

sub _parseVirtualRoot {
    my $self = shift;
    $self->_setVirtualRoot(shift->textContent());
}

sub _storeVirtualRoot {
    my $self = shift;
    return $self->getVirtualRoot();
}

sub _parseServerString {
    my $self = shift;
    $self->_setServerString(shift->textContent());
}

sub _storeServerString {
    my $self = shift;
    return $self->getServerString();
}

sub _parseWebserviceRestRoot {
    my $self = shift;
    $self->_setWebserviceRestRoot(shift->textContent());
}

sub _storeWebserviceRestRoot {
    my $self = shift;
    return $self->getWebserviceRestRoot();
}

sub _parseSupportEmail {
    my $self = shift;
    $self->_setSupportEmail(shift->textContent());
}

sub _storeSupportEmail {
    my $self = shift;
    return $self->getSupportEmail();
}

sub _parseAdminEmail {
    my $self = shift;
    $self->_setAdminEmail(shift->textContent());
}

sub _storeAdminEmail {
    my $self = shift;
    return $self->getAdminEmail();
}

sub _parseDataRoot {
    my $self = shift;
    $self->_setDataRoot(shift->textContent());
}

sub _storeDataRoot {
    my $self = shift;
    return $self->getDataRoot();
}

sub _parseDebugLevel {
    my $self = shift;
    $self->_setDebugLevel(shift->textContent());
}

sub _storeDebugLevel {
    my $self = shift;
    return $self->getDebugLevel();
}

sub _parseSessionBackend {
    my $self = shift;
    $self->_setSessionBackend(shift->textContent());
}

sub _storeSessionBackend {
    my $self = shift;
    return $self->getSessionBackend();
}

sub _parseSessionDb {
    my $self = shift;
    $self->_setSessionDB(shift->textContent());
}

sub _storeSessionDb {
    my $self = shift;
    return $self->getSessionDB();
}

sub _parseSessionCookie {
    my $self = shift;
    $self->_setSessionCookie(shift->textContent());
}

sub _storeSessionCookie {
    my $self = shift;
    return $self->getSessionCookie();
}

sub _parseSmtpServer {
    my $self = shift;
    $self->_setSMTPServer(shift->textContent());
}

sub _storeSmtpServer {
    my $self = shift;
    return $self->getSMTPServer();
}

sub _parseSmtpMailname {
    my $self = shift;
    $self->_setSMTPMailname(shift->textContent());
}

sub _storeSmtpMailname {
    my $self = shift;
    return $self->getSMTPMailname();
}

sub _parseSmtpMsgWait {
    my $self = shift;
    $self->_setSMTPMessageWait(shift->textContent());
}

sub _storeSmtpMsgWait {
    my $self = shift;
    return $self->getSMTPMessageWait();
}

sub _parseSmtpUseQueue {
    my $self = shift;
    $self->_setSMTPUseQueue(shift->textContent());
}

sub _storeSmtpUseQueue {
    my $self = shift;
    return $self->getSMTPUseQueue();
}

sub _parseEncryptionKey {
    my $self = shift;
    $self->_setEncryptionKey(shift->textContent());
}

sub _storeEncryptionKey {
    my $self = shift;
    return $self->getEncryptionKey();
}

sub _parseDevelopmentMode {
    my $self = shift;
    $self->_setDevelopmentMode(shift->textContent());
}

sub _storeDevelopmentMode {
    my $self = shift;
    return $self->getDevelopmentMode();
}

sub _parseRequireSsl {
    my $self = shift;
    $self->_setRequireSsl(shift->textContent());
}

sub _storeRequireSsl {
    my $self = shift;
    return $self->getRequireSsl();
}

sub _parseLogModules {
    my $self = shift;
    my $parent = shift;

    my $log_modules = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$log_modules, $node->textContent();
    }

    $self->_setLogModules($log_modules);
}


sub _parseAppDirs {
    my $self = shift;
    my $parent = shift;

    my $app_dirs = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$app_dirs, $node->textContent();
    }

    $self->_setAppDirs($app_dirs);
}

sub _parseErrorHtml {
    my $self = shift;
    my $html_node = shift;

    $self->_setErrorHTML($html_node->textContent());
}

sub _storeErrorHtml {
    my $self = shift;
    return $self->getErrorHTML();
}

sub _parseLang {
    my $self = shift;
    $self->_setLang(shift->textContent());
}

sub _storeLang {
    my $self = shift;
    return $self->getLang();
}

sub _getAccessorDefinition {
    return [
    {
        name        => 'DBHosts',
        type        => 'ArrayRef',
    },
    {
        name        => 'MemcachedServers',
        type        => 'ArrayRef',
    },
    {
        name        => 'Root',
        type        => 'String',
    },
    {
        name        => 'VirtualRoot',
        type        => 'String',
    },
    {
        name        => 'ServerString',
        type        => 'String',
    },
    {
        name        => 'WebserviceRestRoot',
        type        => 'String',
    },
    {
        name        => 'SupportEmail',
        type        => 'Email',
    },
    {
        name        => 'AdminEmail',
        type        => 'Email',
    },
    {
        name        => 'DataRoot',
        type        => 'String',
    },
    {
        name        => 'DebugLevel',
        type        => 'String',
    },
    {
        name        => 'SessionBackend',
        type        => 'String',
    },
    {
        name        => 'SessionDB',
        type        => 'String',
    },
    {
        name        => 'SessionCookie',
        type        => 'String',
    },
    {
        name        => 'SMTPServer',
        type        => 'String',
    },
    {
        name        => 'SMTPMailname',
        type        => 'String',
    },
    {
        name        => 'SMTPMessageWait',
        type        => 'Number',
    },
    {
        name        => 'SMTPUseQueue',
        type        => 'String',
    },
    {
        name        => 'EncryptionKey',
        type        => 'String',
    },
    {
        name        => 'DevelopmentMode',
        type        => 'Boolean',
    },
    {
        name        => 'RequireSsl',
        type        => 'Boolean',
    },
    {
        name        => 'File',
        type        => 'String',
    },
    {
        name        => 'ErrorHTML',
        type        => 'String',
    },
    {
        name        => 'BoilerplateView',
        type        => 'String',
    },
    {
        name        => 'SlowQueryTime',
        type        => 'Number',
    },
    {
        name        => 'CompiledViewPath',
        type        => 'String',
    },
    {
        name        => 'LogModules',
        type        => 'ArrayRef',
    },
    {
        name        => 'AppDirs',
        type        => 'ArrayRef',
    },
    {
        name        => 'Lang',
        type        => 'String',
    },
    ];
}


1;
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

