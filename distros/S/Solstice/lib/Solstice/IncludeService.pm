package Solstice::IncludeService;

# $Id: IncludeService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::IncludeService - Used to include linked resources on a page, such as stylesheets and javascript.

=head1 SYNOPSIS

  use Solstice::IncludeService;

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Digest::SHA1 qw(sha1_hex);
use URI;

use constant JAVASCRIPT_TYPE => 'text/javascript';
use constant CSS_TYPE        => 'text/css';
use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()

Creates a new Solstice::IncludeService object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_init();
    
    return $self;
}

=item addIncludedFile($params)

Add an included file to the service. C<$params> is a reference to a
hash:

    { 
        file => 'path/to/include.js',
        type => 'text/javascript'
    }
or
    {
        file  => 'path/to/include.css',
        type  => 'text/css'
    }

=cut

sub addIncludedFile {
    my $self  = shift;
    my $params = shift;
    return unless (defined $params and $params->{'file'} and $params->{'type'});
    return $self->_addFile($params->{'file'}, $params->{'type'});
}

=item addCSSAplicationIncludes($namespace) 

=cut

sub addCSSApplicationIncludes {
    my $self = shift;
    my $namespace = shift;

    return FALSE unless defined $namespace;
    
    my $config = $self->getConfigService($namespace);
    my $app_url = $config->getAppURL().'/';

    for my $css_file (@{$config->getCSSFiles()}) {
        $self->_addFile($app_url.$css_file, CSS_TYPE);
    }
    return TRUE;
}

=item addCSSFile($file)

=cut

sub addCSSFile {
    my $self  = shift;
    my $file  = shift;
    return $self->_addFile($file, CSS_TYPE);
}

=item addJSApplicationIncludes($namespace)

=cut

sub addJSApplicationIncludes {
    my $self = shift;
    my $namespace = shift;

    return FALSE unless defined $namespace;
    
    my $config = $self->getConfigService($namespace);
    my $app_url = $config->getAppURL().'/';

    for my $file (@{$config->getJSFiles()}) {
        $self->_addFile($app_url.$file, JAVASCRIPT_TYPE); 
    }
    return TRUE;
}

=item addJSFile($file)

=cut

sub addJSFile {
    my $self = shift;
    my $file = shift;
    return $self->_addFile($file, JAVASCRIPT_TYPE);
}

=item addApplicationIncludes($namespace)

=cut

sub addApplicationIncludes {
    my $self  = shift;
    my $namespace = shift;

    return $self->addCSSApplicationIncludes($namespace) &
        $self->addJSApplicationIncludes($namespace);
}

=item getJavascriptIncludes()

=cut

sub getJavascriptIncludes {
    my $self = shift;
    return $self->_getIncludedFiles(JAVASCRIPT_TYPE);
}

=item getCSSIncludes()

=cut

sub getCSSIncludes {
    my $self = shift;
    return $self->_getIncludedFiles(CSS_TYPE);    
}

=item getJavascriptType()

=cut

sub getJavascriptType {
    return JAVASCRIPT_TYPE;
}

=item getCSSType()

=cut

sub getCSSType {
    return CSS_TYPE;
}

=item setPageTitle($str)

=cut

sub setPageTitle {
    my $self = shift;
    my $title = shift;

    return FALSE unless defined $title;

    $self->set('html_title', $title);
    
    return TRUE;
}

=item getPageTitle()

=cut

sub getPageTitle {
    my $self = shift;
    return $self->get('html_title');
}

=back

=head2 Private Methods

=over 4

=cut

=item _init()

=cut

sub _init {
    my $self = shift;

    return if $self->get('include_service_initialized');

    # Add the solstice includes
    my $config = $self->getConfigService();
    for my $js_file (@{$config->getJSFiles()}) {
        $self->_addFile($js_file, JAVASCRIPT_TYPE);
    }
    for my $css_file (@{$config->getCSSFiles()}) {
        $self->_addFile($css_file, CSS_TYPE);
    }
    
    $self->set('include_service_initialized', TRUE);

    return;
}

=item _addFile($file, $type)

=cut

sub _addFile {
    my $self = shift;
    my $file = shift;
    my $type = shift;

    my $lookup = $self->get('include_file_lookup') || {};

    return FALSE if exists $lookup->{$file};

    my $includes = $self->get($type) || [];
    push @$includes, $file;
    $lookup->{$file} = 1;

    $self->set($type, $includes);
    $self->set('include_file_lookup', $lookup);

    return TRUE;
}

=item _getIncludedFiles($type)

=cut

sub _getIncludedFiles {
    my $self = shift;
    my $type = shift;

    my @local_files    = ();
    my @returned_files = ();
    my $included_files = $self->get($type) || [];
    for my $file (@$included_files) {
        if ($file =~ /^http/) {
            push @returned_files, $file;
        } else {
            $file =~ s/\/+/\//g;
            $file =~ s/^\///;
            push @local_files, $file; 
        }
    }

    if ($self->getConfigService()->getDevelopmentMode()) {
        push @returned_files, @local_files;
    } else {
        my $concat = $self->_buildStaticFileConcat(\@local_files, $type);
        push @returned_files, $concat if defined $concat; 
    }

    return \@returned_files;
}

=item _buildStaticFileConcat(\@files, $type)

=cut

sub _buildStaticFileConcat {
    my $self = shift;
    my $files = shift;
    my $type  = shift;
    my $config = $self->getConfigService();

    # Empty array?
    return unless (defined $files and @$files);
    
    #prepare dir
    my $static_concat_dir = $config->getDataRoot() .'/static_file_concat_cache/';
    $self->_dirCheck($static_concat_dir);

    #sum the filenames
    my $include_sum = sha1_hex(join("\n", @$files));
    my $cache_filename = $static_concat_dir . $include_sum;

    #refresh the cache if needed or in dev mode
    if( $config->getDevelopmentMode() || ! -f $cache_filename){
        my $concat = '';
        my $root = $config->getURL();

        for my $file (@$files){
            #locate the url on disk
            my $filename = $config->_getStaticContent('/'.$root.'/'.$file);
            my $file_dir = $file;
            $file_dir =~ s'[^/]*$''; #so we can adjust relative links in css

            open(my $fh, '<', $filename) or next;
            
            $concat .= "/***** File: $file *****/\n";
            while(my $line = <$fh>){
                if (CSS_TYPE eq $type) {
                    # This s/// makes all relative links in the css 
                    # absolute so they work from the concatenated version
                    $line =~ s/url\s*\((.*?)\)/ _removeSlashes("url(\/$root\/". URI->new_abs($1, "\/$file_dir")->as_string() .')') /igse;
                }
                $concat .= $line;
            }
            $concat .= "\n\n";
            
            close($fh);
        }
        
        # This auto minifies our js and css, but it was deemed too 
        # slow on first clicks
#        if(!$config->getDevelopmentMode()){
#            if(CSS_TYPE eq $type){
#                $concat = CSS::Minifier::minify(input => $concat);
#            }elsif(JAVASCRIPT_TYPE eq $type){
#                $concat = JavaScript::Minifier::minify(input => $concat);
#            }
#        }

        open(my $cache_file, '>', $cache_filename) or return;
        print $cache_file $concat;
        close($cache_file);
    }

    my $ext = $self->getContentTypeService()->getExtensionByContentType($type); 

    return ('static_concat/'.$include_sum.'.'.$ext);
}


=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::IncludeService';
}

=item _removeSlashes($path)

Here as a utility for buildStaticFileConcat

=cut

sub _removeSlashes {
    my $input = shift;
    $input =~ s'/+/'/'g;
    return $input;
}


1;

__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

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
