package Solstice::Model::Config;

use strict;
use warnings;
use 5.006_000;

use XML::LibXML;

use base qw(Solstice::Model Solstice::Service::Memory);

use constant TRUE => 1;
use constant FALSE => 0;

sub new {
    my $obj = shift;
    my $file = shift;
    my $schema_file = shift;

    if($obj eq 'Solstice::Model::Config'){
        die "Solstice::Model::Config is an abstract class, please use a subclass";
    }

    my $self = bless {}, $obj;

    $self->_initAttributes($self);

    if($file){
        $self->_init($file, $schema_file);
    }
    return $self;
}

sub _init {
    my $self = shift;
    my $file = shift;
    my $schema_file = shift;

    my $parser = XML::LibXML->new();

    my $doc;
    eval { $doc = $parser->parse_file($file) };
    die "Config file $file could not be parsed:\n$@" if $@;

    #validate
    if( $schema_file ){
        my $schema = XML::LibXML::Schema->new(location => $schema_file);
        eval { $schema->validate($doc) };
        if ($@) {
            die "Failed to validate config file $file: $@";
        }
    }

    #firstChild gets us past <solstice_config>
    for my $node ($self->_getRelevantChildNodes($doc->firstChild())){

        my $node_name = $node->nodeName();

        #we auto-generate the method name
        $node_name =~ s/_(.)/uc($1)/ge;
        $node_name = '_parse' .ucfirst($node_name);

        if($self->can($node_name)){
            $self->$node_name($node);
        }else{
            warn $node->nodeName() ." found in config file but not handled by $node_name";
        }
    }
}

sub store {
    my $self = shift;

    #subclass specific, but we pass down all the params we handle
    my $content = $self->_store({
            css_files   => $self->_storeCssFiles(),
            js_files    => $self->_storeJsFiles(),
            keys        => $self->_storeKeys(),
            remotes     => $self->_storeRemotes(),
            statics     => $self->_storeStatics(),
            cgis        => $self->_storeCgis(),
        }); 

    return $content;
}

sub _store {
    my $self = shift;
    die "_store notimplemnted in Solstice::Model::Config subclass '".ref $self ."'";
}


sub _parseKeys {
    my $self = shift;
    my $keys = shift;

    my $key_info = {};
    for my $node ($self->_getRelevantChildNodes($keys)){
        $key_info->{$node->getAttribute('name')} = $node->textContent();
    }

    $self->_setKeys($key_info);
}

sub _storeKeys {
    my $self = shift;

    my @params;
    my %keys = %{$self->getKeys()};

    for my $key (sort keys %keys){
        push @params, {
            name    => $key,
            value   => $keys{$key},
        };
    }

    return \@params;
}

sub _parseRemotes {
    my $self = shift;
    my $remote_node = shift;

    my $remote_info = {};
    for my $node ($self->_getRelevantChildNodes($remote_node)){
        $remote_info->{$node->getAttribute('name')} = $node->textContent();
    }

    $self->_setRemotes($remote_info);
}

sub _storeRemotes {
    my $self = shift;

    my @params;
    my %remotes= %{$self->getRemotes() || {}};

    for my $key (sort keys %remotes){
        push @params, {
            name    => $key,
            controller => $remotes{$key},
        };
    }

    return \@params;
}


sub _parseCssFiles {
    my $self = shift;
    my $parent = shift;

    my $css_files = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$css_files, $node->textContent();
    }

    $self->_setCSSFiles($css_files);
}


sub _storeCssFiles {
    my $self = shift;

    my @params;

    for my $file (@{$self->getCSSFiles()}){
        push @params, {
            file => $file,
        };
    }

    return \@params;
}


sub _parseJsFiles {
    my $self = shift;
    my $parent = shift;

    my $js_files = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$js_files , $node->textContent();
    }

    $self->_setJSFiles($js_files);
}

sub _storeJsFiles {
    my $self = shift;

    my @params;

    for my $file (@{$self->getJSFiles()}){
        push @params, {
            file => $file,
        };
    }

    return \@params;
}

sub _parseStatics {
    my $self = shift;
    my $parent = shift;

    my $statics= [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$statics, {
            virtual_path => $node->hasAttribute('virtual_path') ? $node->getAttribute('virtual_path') : $node->textContent(),
            filesys_path => $node->textContent(),
        };
    }

    $self->_setStaticDirs($statics);
}

sub _storeStatics {
    my $self = shift;

    my @params;

    for my $static(@{$self->getStaticDirs() || []}){
        push @params, {
            virtual_path    => $static->{'virtual_path'},
            filesys_path    => $static->{'filesys_path'},
        };
    }

    return \@params;
}

sub _parseCgis {
    my $self = shift;
    my $parent = shift;

    my $cgis = [];
    for my $node ($self->_getRelevantChildNodes($parent)){
        push @$cgis, {
            'virtual_path'  => $node->hasAttribute('virtual_path') ? $node->getAttribute('virtual_path') : $node->textContent(),
            'filesys_path'  => $node->textContent(),
            'requires_auth' => $node->getAttribute('requires_auth'),
            'url_is_prefix' => defined $node->getAttribute('url_is_prefix') ? $node->getAttribute('url_is_prefix') : FALSE,
        };
    }

    $self->_setCGIs($cgis);
}

sub _storeCgis {
    my $self = shift;

    my @params;

    for my $cgi (@{$self->getCGIs()}){
        push @params, {
            virtual_path    => $cgi->{'virtual_path'},
            filesys_path    => $cgi->{'filesys_path'},
            requires_auth   => $cgi->{'requires_auth'},
            url_is_prefix   => $cgi->{'url_is_prefix'},
        };
    }

    return \@params;
}


#filters text and comments
sub _getRelevantChildNodes {
    my $self = shift;
    my $node = shift;
    return (grep ($_->nodeName() !~/text|comment/, $node->childNodes()));
}


sub _getAccessorDefinition {
    return [
    {
        name        => 'CSSFiles',
        type        => 'ArrayRef',
    },
    {
        name        => 'JSFiles',
        type        => 'ArrayRef',
    },
    {
        name        => 'Keys',
        type        => 'HashRef',
    },
    {
        name        => 'Remotes',
        type        => 'HashRef',
    },
    {
        name        => 'StaticDirs',
        type        => 'ArrayRef',
    },
    {
        name        => 'CGIs',
        type        => 'ArrayRef',
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

