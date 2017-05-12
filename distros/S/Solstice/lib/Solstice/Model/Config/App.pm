package Solstice::Model::Config::App;

use strict;
use warnings;
use 5.006_000;

use XML::LibXML;

use base qw(Solstice::Model::Config);
use Solstice::View::Config::App;

use constant TRUE => 1;
use constant FALSE => 0;


sub _store {
    my $self = shift;
    my $superclass_params = shift;

    my $view = Solstice::View::Config::App->new();
    $view->setParams($superclass_params);
    $view->setParams(
        {
            error_hanlder    => $self->_storeErrorHandler(),
            config_namespace => $self->_storeConfigNamespace(),
            db_name          => $self->_storeDbName(),
            application_url  => $self->_storeApplicationUrl(),
            urls             => $self->_storeUrls(),
            webservices      => $self->_storeWebservices(),
        }
    );

    my $content = '';
    $view->paint(\$content);
    return $content;
}


sub _storeWebservices {
    my $self = shift;

    my @params;

    for my $url (@{ $self->getWebservices() || [] }){
        push @params,
        {
            virtual_path        => $url->{'virtual_path'},
            url_is_prefix       => $url->{'url_is_prefix'},
            controller          => $url->{'controller'},
            requires_auth       => $url->{'requires_auth'},
        };
    }

    return \@params;
}


sub _storeUrls {
    my $self = shift;

    my @params;

    for my $url (@{ $self->getURLs() }){
        push @params,
            {
            virtual_path        => $url->{'virtual_path'},
            url_is_prefix       => $url->{'url_is_prefix'},
            pageflow            => $url->{'pageflow'},
            initial_state       => $url->{'initial_state'},
            requires_auth       => $url->{'requires_auth'},
            disable_back_button => $url->{'disable_back_button'},
            escape_frames       => $url->{'escape_frames'},
            debug_level         => $url->{'debug_level'},
            view_top_nav        => $url->{'view_top_nav'},
            title               => $url->{'title'},
            boilerplate_view    => $url->{'boilerplate_view'},
            require_session     => $url->{'require_session'},
            };
    }

    return \@params;
}


sub _parseUrls {
    my $self = shift;
    my $parent = shift;

    my $urls = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$urls, {
            virtual_path        => $node->getAttribute('virtual_path'),
            url_is_prefix       => defined $node->getAttribute('url_is_prefix') ? $node->getAttribute('url_is_prefix'): FALSE,
            pageflow            => $node->getAttribute('pageflow'),
            initial_state       => $node->getAttribute('initial_state'),
            requires_auth       => defined $node->getAttribute('requires_auth') ? $node->getAttribute('requires_auth'): FALSE,
            disable_back_button => defined $node->getAttribute('disable_back_button') ? $node->getAttribute('disable_back_button'): FALSE,
            escape_frames       => defined $node->getAttribute('escape_frames') ? $node->getAttribute('escape_frames'): FALSE,
            debug_level         => $node->getAttribute('debug_level'),
            view_top_nav        => defined $node->getAttribute('view_top_nav') ? $node->getAttribute('view_top_nav') : TRUE,
            title               => $node->getAttribute('title'),
            boilerplate_view    => $node->getAttribute('boilerplate_view'),
            require_session     => defined $node->getAttribute('require_session') ?  $node->getAttribute('require_session') : TRUE,
        };
    }

    $self->_setURLs($urls);
}


sub _parseWebservices {
    my $self = shift;
    my $parent = shift;

    my $services = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$services, {
            virtual_path  => $node->getAttribute('virtual_path'),
            controller    => $node->getAttribute('controller'),
            url_is_prefix => defined $node->getAttribute('url_is_prefix') ? $node->getAttribute('url_is_prefix') : FALSE,
            requires_auth => defined $node->getAttribute('requires_auth') ? $node->getAttribute('requires_auth') : FALSE,
        };
    }

    $self->_setWebservices($services);
}

sub _storeConfigNamespace {
    my $self = shift;
    return $self->getConfigNamespace();
}

sub _storeErrorHandler {
    my $self = shift;
    return $self->getErrorHandler();
}

sub _storeDbName {
    my $self = shift;
    return $self->getDBName();
}

sub _storeApplicationUrl {
    my $self = shift;
    return $self->getApplicationURL();
}


sub _parseDbName {
    my $self = shift;
    $self->_setDBName(shift->textContent());
}

sub _parseApplicationUrl {
    my $self = shift;
    $self->_setApplicationURL(shift->textContent());
}

sub _parseConfigNamespace {
    my $self = shift;
    $self->_setConfigNamespace(shift->textContent());
}
sub _parseErrorHandler {
    my $self = shift;
    $self->_setErrorHandler(shift->textContent());
}

sub _getAccessorDefinition {
    return [
    {
        name        => 'Webservices',
        type        => 'ArrayRef',
    },
    {
        name        => 'URLs',
        type        => 'ArrayRef',
    },
    {
        name        => 'ErrorHandler',
        type        => 'String',
    },
    {
        name        => 'ConfigNamespace',
        type        => 'String',
    },
    {
        name        => 'DBName',
        type        => 'String',
    },
    {
        name        => 'ApplicationURL',
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


