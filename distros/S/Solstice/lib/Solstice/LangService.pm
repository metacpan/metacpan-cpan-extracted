package Solstice::LangService;

# $Id: LangService.pm 2061 2005-03-04 23:26:00Z jlaney $

=head1 NAME

Solstice::LangService - Provides strings of the appropriate language to applications.

=head1 SYNOPSIS

  use Solstice::LangService;
  
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service::Memory);

use File::stat;
use XML::LibXML;

use constant DEFAULT_PATH  => 'lang';
use constant TAG_DELIMITER => '::';
use constant ELEMENT_TYPE  => 1;

our ($VERSION) = ('$Revision: 2061 $' =~ /^\$Revision:\s*([\d.]*)/);
our $display_tags = 0; # package-level flag for displaying tag information

our $group_tags = {
    msgs => 'msg',
    errs => 'err',
    hlps => 'hlp',
    btns => 'btn',
    strs => 'str',
};

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new([$namespace])

Creates a new Solstice::Service::Lang object.

=cut

sub new {
    my $pkg = shift;
    my $namespace = shift;
    
    my $self = $pkg->SUPER::new(@_);

    unless (defined $namespace) {
        caller =~ m/^(\w+):.*$/;
        $namespace = $1;
    }
    
    $self->setNamespace($namespace);
    
    return $self;
}

=item getMessage($key [, \%params])

=cut

sub getMessage {
    my $self = shift;
    my ($key, $params, $namespace) = @_;

    my $text = $self->_getLangData($namespace)->{'msgs'}->{$key};

    unless (defined $text) {
        if (defined $namespace && $namespace eq 'Solstice') {
            print STDERR "getMessage(): key '$key' not found from ". join(" ", caller)."\n";
            return '';
        }
        $text = $self->getMessage($key, $params, 'Solstice');
    }
    
    if ($display_tags) {
        $text = $group_tags->{'msgs'}.TAG_DELIMITER.$key.TAG_DELIMITER.$text;
    }
    
    return $self->_insertParams($key, $params, $namespace, $text);
}

=item getError($key [,$params, $namespace])

=cut

sub getError {
    my $self = shift;
    my ($key, $params, $namespace) = @_;
    
    my $text = $self->_getLangData($namespace)->{'errs'}->{$key};
    
    unless (defined $text) {
        if (defined $namespace && $namespace eq 'Solstice') {
            print STDERR "getError(): key '$key' not found from ". join(" ", caller)."\n";
            return '';
        }
        $text = $self->getError($key, $params, 'Solstice');
    }

    if ($display_tags) {
        $text = $group_tags->{'errs'}.TAG_DELIMITER.$key.TAG_DELIMITER.$text;
    }

    return $self->_insertParams($key, $params, $namespace, $text);
}

=item getErrors()

=cut

sub getErrors {
    my $self = shift;
    return $self->_getLangData()->{'errs'} || {};
}

=item getHelp($key [, $params, $namespace])

=cut

sub getHelp {
    my $self = shift;
    my ($key, $params, $namespace) = @_;

    my $text = $self->_getLangData($namespace)->{'hlps'}->{$key};
    
    unless (defined $text) {
        if (defined $namespace && $namespace eq 'Solstice') {
            print STDERR "getHelp(): key '$key' not found from ". join(" ", caller)."\n";
            return '';
        }
        $text = $self->getHelp($key, $params, 'Solstice');
    }

    if ($display_tags) {
        $text = $group_tags->{'hlps'}.TAG_DELIMITER.$key.TAG_DELIMITER.$text;
    }

    return $self->_insertParams($key, $params, $namespace, $text);
}

=item getString($key [, $params, $namespace, caller])

=cut

sub getString {
    my $self = shift;
    my ($key, $params, $namespace, $caller) = @_;

    my $text = $self->_getLangData($namespace)->{'strs'}->{$key};
    
    unless (defined $text) {
        if (defined $namespace && $namespace eq 'Solstice') {
            if (!defined $caller) {
                $caller = join(' ', caller);
            }
            print STDERR "getString(): key '$key' not found from $caller\n";
            return '';
        }
        if (!defined $caller) {
            my @caller_info = caller;
            if ($caller_info[1] =~ /^\(eval [\d]+\)$/) {
                $caller = $caller_info[0];
            }
            else {
                $caller = join(' ', @caller_info[1,2]);
            }
        }
        $text = $self->getString($key, $params, 'Solstice', $caller);
    }

    if ($display_tags) {
        $text = $group_tags->{'strs'}.TAG_DELIMITER.$key.TAG_DELIMITER.$text;
    }

    return $self->_insertParams($key, $params, $namespace, $text);
}

=item getButtonLabel($key [, $params, $namespace])

=cut

sub getButtonLabel {
    my $self = shift;
    my ($key, $params, $namespace) = @_;

    my $text = $self->_getLangData($namespace)->{'btns'}->{$key}->{'content'};

    unless (defined $text) {
        if (defined $namespace && $namespace eq 'Solstice') {
            print STDERR "getButtonLabel(): key '$key' not found from ". join(" ", caller) ."\n";
            return '';
        }
        $text = $self->getButtonLabel($key, $params, 'Solstice');
    }

    if ($display_tags) {
        $text = $group_tags->{'btns'}.TAG_DELIMITER.$key.TAG_DELIMITER.$text;
    }

    return $self->_insertParams($key, $params, $namespace, $text);
}

=item getButtonTitle($key [, $params, $namespace])

=cut

sub getButtonTitle {
    my $self = shift;
    my ($key, $params, $namespace) = @_;

    my $text = $self->_getLangData($namespace)->{'btns'}->{$key}->{'title'};

    unless (defined $text) {
        if (defined $namespace && $namespace eq 'Solstice') {
            print STDERR "getButtonTitle(): key '$key' not found from ". join(" ", caller)."\n";
            return '';
        }
        $text = $self->getButtonTitle($key, $params, 'Solstice');
    }

    if ($display_tags) {
        $text = $group_tags->{'btns'}.TAG_DELIMITER.$key.TAG_DELIMITER.$text;
    }

    return $self->_insertParams($key, $params, $namespace, $text);
}

=back

=head2 Private Methods

=over 4

=cut

=item _insertParams($key, $params, $namespace, $text)

=cut

sub _insertParams {
    my $self = shift;
    my ($key, $params, $namespace, $text) = @_;

    $text =~ s/<!--\s+sol_var\s+(name=\s*){0,1}(\w+)\s+-->/$self->_replaceParam($2, $key, $params, $namespace)/gsex;

    return $text;
}

=item _replaceParam($match, $key, $params, $namespace)

=cut

sub _replaceParam {
    my $self      = shift; 
    my $match     = shift;
    my $key       = shift;
    my $params    = shift || {};
    my $namespace = shift || $self->getNamespace();   

    if (exists $params->{$match}) {
        return $params->{$match} if defined $params->{$match};
        warn "Undefined value for key \"$match\" in lang string \"$key\" \n";
    } else {
        if ($match eq 'app_url') {
            return $self->getConfigService($namespace)->getAppURL();
        }
        warn "Missing param \"$match\" in lang string \"$key\" \n";
    }
    return '';
}

=item _getLangData()

=cut

sub _getLangData {
    my $self = shift;
    my $namespace = shift || $self->getNamespace();

    $self->_initialize() || die 'Initialization failed: '.$self->{'_errstr'} ."\n";

    return $self->getValue($namespace . '_lang_data');
}

=item _initialize()

=cut

sub _initialize {
    my $self = shift;

    my $namespace = $self->getNamespace(); 

    unless (defined $namespace) {
        $self->{'_errstr'} = 'namespace is not defined';
        return 0;
    }

    my $config_section = ($namespace eq 'Solstice') ? undef : $namespace;
    my $config = $self->getConfigService($config_section);
    
    if (
        defined $self->getValue($namespace . '_lang_initialized_timestamp') &&
        ! $config->getDevelopmentMode()

    ) {
        return 1;
    }

    my $last_read = $self->getValue($namespace.'_lang_initialized_timestamp');
   
    my $app_root = $config->getAppRoot() || $config->getRoot();
    my $lang = $config->getLang() || 'en';
    my $lang_file = $app_root.'/lang/'.$lang.'.xml';
    
    my $file_info = stat($lang_file);

    # We want to read in lang files that have been modified, but not parse 
    # xml unneccesarily
    if (defined $last_read and ($file_info->mtime < $last_read)) {
        return 1;
    }
    
    unless (-f $lang_file) { 
        $self->{'_errstr'} = "File $lang_file does not exist";        
        return 0;
    }
    
    my $doc = $self->_parseLangFile($lang_file);

#    unless ($self->_validateLangXML($doc, $config->getRoot().'/conf/schemas/lang.xsd')) {
#        $self->{'_errstr'} = "Lang file $lang_file failed validation: ".
#            $self->{'_errstr'};
#        return 0;
#    }
    
    my $data = $self->_readLangXML($doc);
    
    $self->setValue($namespace . '_lang_data', $data);
    $self->setValue($namespace . '_lang_initialized_timestamp', time);

    return 1;
}

=item _validateLangXML($doc)

=cut

sub _validateLangXML {
    my ($self, $doc, $schema_path) = @_;
    
    my $schema = XML::LibXML::Schema->new(location => $schema_path);

    eval { $schema->validate($doc) };
    if ($@) {
        $self->{'_errstr'} = $@;
        return 0; 
    }
    return 1;
}

=item _readLangXML($doc)

=cut

sub _readLangXML {
    my $self = shift;
    my $doc  = shift;
    my $data = {};
    
    for my $node ($doc->getDocumentElement()->childNodes()) {
        next unless $node->nodeType() == ELEMENT_TYPE;
        
        my $group = $node->nodeName();
        #each group needs a hash to store elements in
        $data->{$group} = {};

        if ($group eq 'btns') {
            for my $child ($node->getChildrenByTagName('btn')) {
                $data->{$group}->{$child->getAttribute('name')} = {
                    content => $child->textContent(),
                    title   => $child->hasAttribute('title') ? $child->getAttribute('title') : $child->textContent(),
                };
            }
        } else {
            for my $child ($node->getChildrenByTagName($group_tags->{$group})) {
                $data->{$group}->{$child->getAttribute('name')} = $child->textContent();
            }
        }    
    }
    return $data;
}    

=item _parseLangFile($path)

=cut

sub _parseLangFile {
    my ($self, $path) = @_;

    my $parser = XML::LibXML->new();

    my $doc;
    eval { $doc = $parser->parse_file($path) };
    die "Lang file $path could not be parsed:\n$@\n" if $@;

    return $doc;
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::LangService';
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2061 $



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
