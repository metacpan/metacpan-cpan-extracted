package Module::Build::JSAN::Installable;
BEGIN {
  $Module::Build::JSAN::Installable::VERSION = '0.13';
}

use strict;
use vars qw(@ISA);

use Module::Build::JSAN;
@ISA = qw(Module::Build::JSAN);

use File::Spec::Functions qw(catdir catfile);
use File::Basename qw(dirname);

use Path::Class;
use Config;
use JSON;


__PACKAGE__->add_property('task_name' => 'Core');
__PACKAGE__->add_property('static_dir' => 'static');
__PACKAGE__->add_property('docs_markup' => 'pod');


#================================================================================================================================================================================================================================================
sub new {
    my $self = shift->SUPER::new(@_);
    
    $self->add_build_element('js');
    
    $self->add_build_element('static');
    
    $self->install_base($self->get_jsan_libroot) unless $self->install_base;
    $self->install_base_relpaths(lib  => 'lib');
    $self->install_base_relpaths(arch => 'arch');
    
    return $self;
}



#================================================================================================================================================================================================================================================
sub get_jsan_libroot {
	return $ENV{JSANLIB} || (($^O eq 'MSWin32') ? 'c:\JSAN' : (split /\s+/, $Config{'libspath'})[1] . '/jsan');
}


#================================================================================================================================================================================================================================================
sub process_static_files {
	my $self = shift;
	
	my $static_dir = $self->static_dir;
  
  	return if !-d $static_dir;
  
  	#find all files except directories
  	my $files = $self->rscan_dir($static_dir, sub {
  		!-d $_
  	});
  	
	foreach my $file (@$files) {
		$self->copy_if_modified(from => $file, to => File::Spec->catfile($self->blib, 'lib', $self->dist_name_as_dir, $file) );
	}
  	
}


#================================================================================================================================================================================================================================================
sub ACTION_install {
    my $self = shift;
    
    require ExtUtils::Install;
    
    $self->depends_on('build');
    
    my $map = $self->install_map;
    my $dist_name = quotemeta $self->dist_name();
    
    #trying to be cross-platform
    my $dist_name_to_dir = catdir( split(/\./, $self->dist_name()) );
    
    $map->{'write'} =~ s/$dist_name/$dist_name_to_dir/;
    
    ExtUtils::Install::install($map, !$self->quiet, 0, $self->{args}{uninst}||0);
}


#================================================================================================================================================================================================================================================
sub dist_name_as_dir {
	return split(/\.|-/, shift->dist_name());
}


#================================================================================================================================================================================================================================================
sub comp_to_filename {
	my ($self, $comp) = @_;
	
    my @dirs = split /\./, $comp;
    $dirs[-1] .= '.js';
	
	return file('lib', @dirs);
}


#================================================================================================================================================================================================================================================
sub ACTION_task {
    my $self = shift;
    
	my $components = file('Components.JS')->slurp;

	#removing // style comments
	$components =~ s!//.*$!!gm;

	#extracting from most outer {} brackets
	$components =~ m/(\{.*\})/s;
	$components = $1;

	my $deploys = decode_json $components;
	
	$self->concatenate_for_task($deploys, $self->task_name);
}


#================================================================================================================================================================================================================================================
sub expand_task_entry {
    my ($self, $deploys, $task_name, $seen) = @_;
    
    $seen = {} if !$seen;
    
    die "Recursive visit to task [$task_name] when expanding entries" if $seen->{ $task_name };
    
    $seen->{ $task_name } = 1; 
    
    return map { 
			
		/^\+(.+)/ ? $self->expand_task_entry($deploys, $1, $seen) : $_;
		
	} @{$deploys->{ $task_name }};    
}


#================================================================================================================================================================================================================================================
sub concatenate_for_task {
    my ($self, $deploys, $task_name) = @_;
    
    if ($task_name eq 'all') {
    	
    	foreach my $deploy (keys(%$deploys)) {
    		$self->concatenate_for_task($deploys, $deploy);  	
    	}
    
    } else {
	    my @components = $self->expand_task_entry($deploys, $task_name);
	    die "No components in task: [$task_name]" unless @components > 0;
	    
	    my @dist_dirs = split /\./, $self->dist_name();
	    push @dist_dirs, $task_name;
	    $dist_dirs[-1] .= '.js';
	    
	    my $bundle_file = file('lib', 'Task', @dist_dirs);
	    $bundle_file->dir()->mkpath();
	    
	    my $bundle_fh = $bundle_file->openw(); 
	    
	    foreach my $comp (@components) {
	        print $bundle_fh $self->get_component_content($comp) . ";\n";
	    }
	    
	    $bundle_fh->close();
    };
}


#================================================================================================================================================================================================================================================
sub get_component_content {
    my ($self, $component) = @_;
    
    if ($component =~ /^jsan:(.+)/) {
        my @file = ($self->get_jsan_libroot, 'lib', split /\./, $1);
        $file[ -1 ] .= '.js';
        
        return file(@file)->slurp;
    } elsif ($component =~ /^=(.+)/) {
        return file($1)->slurp;
    } else {
        return $self->comp_to_filename($component)->slurp;
    } 
}



#================================================================================================================================================================================================================================================
sub ACTION_test {
	my ($self) = @_;
	
	my $result = (system 'jsan-prove') >> 8;
	
	if ($result == 1) {
		print "All tests successfull\n";
	} else {
		print "There were failures\n";
	}
}


#================================================================================================================================================================================================================================================
sub ACTION_dist {
    my $self = shift;

    $self->depends_on('manifest');
    $self->depends_on('docs');
    $self->depends_on('distdir');

    my $dist_dir = $self->dist_dir;

    $self->_strip_pod($dist_dir);

    $self->make_tarball($dist_dir);
    $self->delete_filetree($dist_dir);

    $self->add_to_cleanup('META.json');
#    $self->add_to_cleanup('*.gz');
}



#================================================================================================================================================================================================================================================
sub ACTION_docs {
    my $self = shift;
    
    #preparing 'doc' directory possible adding to cleanup 
    my $doc_dir = catdir 'doc';
    
    unless (-e $doc_dir) {
        File::Path::mkpath($doc_dir, 0, 0755) or die "Couldn't mkdir $doc_dir: $!";
        
        $self->add_to_cleanup($doc_dir);
    }
    
    my $markup = $self->docs_markup;
    
    if ($markup eq 'pod') {
        $self->generate_docs_from_pod()
    } elsif ($markup eq 'md') {
        $self->generate_docs_from_md()
    } elsif ($markup eq 'mmd') {
        $self->generate_docs_from_mmd()
    }
}


#================================================================================================================================================================================================================================================
sub generate_docs_from_md {
    my $self = shift;
    
    require Text::Markdown;
    
    $self->extract_inlined_docs({
        html => \sub {
            my ($comments, $content) = @_;
            return (Text::Markdown::markdown($comments), 'html')
        },
        
        md => \sub {
            my ($comments, $content) = @_;
            return ($comments, 'txt');
        }
    })
}


#================================================================================================================================================================================================================================================
sub generate_docs_from_mmd {
    my $self = shift;
    
    require Text::MultiMarkdown;
    
    $self->extract_inlined_docs({
        html => sub {
            my ($comments, $content) = @_;
            return (Text::MultiMarkdown::markdown($comments), 'html')
        },
        
        mmd => sub {
            my ($comments, $content) = @_;
            return ($comments, 'txt');
        }
    })
}


#================================================================================================================================================================================================================================================
sub extract_inlined_docs {
    my ($self, $convertors) = @_;
    
    my $markup      = $self->docs_markup;
    my $lib_dir     = dir('lib');
    my $js_files    = $self->find_dist_packages;
    
    
    foreach my $file (map { $_->{file} } values %$js_files) {
        (my $separate_docs_file = $file) =~ s|\.js$|.$markup|;
        
        my $content = file($file)->slurp;
        
        my $docs_content = -e $separate_docs_file ? file($separate_docs_file)->slurp : $self->strip_doc_comments($content);


        foreach my $format (keys(%$convertors)) {
            
            #receiving formatted docs
            my $convertor = $convertors->{$format};
            
            my ($result, $result_ext) = &$convertor($docs_content, $content);
            
            
            #preparing 'doc' directory for current format 
            my $format_dir = catdir 'doc', $format;
            
            unless (-e $format_dir) {
                File::Path::mkpath($format_dir, 0, 0755) or die "Couldn't mkdir $format_dir: $!";
                
                $self->add_to_cleanup($format_dir);
            }
            
            
            #saving results
            (my $res = $file) =~ s|^$lib_dir|$format_dir|;
            
            $res =~ s/\.js$/.$result_ext/;
            
            my $res_dir = dirname $res;
            
            unless (-e $res_dir) {
                File::Path::mkpath($res_dir, 0, 0755) or die "Couldn't mkdir $res_dir: $!";
                
                $self->add_to_cleanup($res_dir);
            }
            
            open my $fh, ">", $res or die "Cannot open $res: $!\n";
    
            print $fh $result;
    
            close $fh;
        }
    }
}



#================================================================================================================================================================================================================================================
sub strip_doc_comments {
    my ($self, $content) = @_;
    
    my @comments = ($content =~ m[^\s*/\*\*(.*?)\*/]msg);
    
    return join '', @comments; 
}


#================================================================================================================================================================================================================================================
sub generate_docs_from_pod {
    my $self = shift;

    require Pod::Simple::HTML;
    require Pod::Simple::Text;
    require Pod::Select;

    for (qw(html text pod)) {
        my $dir = catdir 'doc', $_;
        
        unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755) or die "Couldn't mkdir $dir: $!";
            
            $self->add_to_cleanup($dir);
        }
    }

    my $lib_dir  = catdir 'lib';
    my $pod_dir  = catdir 'doc', 'pod';
    my $html_dir = catdir 'doc', 'html';
    my $txt_dir  = catdir 'doc', 'text';

    my $js_files = $self->find_dist_packages;
    
    foreach my $file (map { $_->{file} } values %$js_files) {
        (my $pod = $file) =~ s|^$lib_dir|$pod_dir|;
        
        $pod =~ s/\.js$/.pod/;
        
        my $dir = dirname $pod;
        
        unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755) or die "Couldn't mkdir $dir: $!";
        }
        
        # Ignore existing documentation files.
        next if -e $pod;
        
        
        open my $fh, ">", $pod or die "Cannot open $pod: $!\n";

        Pod::Select::podselect( { -output => $fh }, $file );

        print $fh "\n=cut\n";

        close $fh;
    }
    

    for my $pod (@{Module::Build->rscan_dir($pod_dir, qr/\.pod$/)}) {
        # Generate HTML docs.
        (my $html = $pod) =~ s|^\Q$pod_dir|$html_dir|;
        
        $html =~ s/\.pod$/.html/;
        
        my $dir = dirname $html;
        
        unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755) or die "Couldn't mkdir $dir: $!";
        }
        
        open my $fh, ">", $html or die "Cannot open $html: $!\n";
        
        my $parser = Pod::Simple::HTML->new;
        $parser->output_fh($fh);
        $parser->parse_file($pod);
        
        close $fh;

        # Generate text docs.
        (my $txt = $pod) =~ s|^\Q$pod_dir|$txt_dir|;
        
        $txt =~ s/\.pod$/.txt/;
        
        $dir = dirname $txt;
        
        unless (-e $dir) {
            File::Path::mkpath($dir, 0, 0755) or die "Couldn't mkdir $dir: $!";
        }
        
        open $fh, ">", $txt or die "Cannot open $txt: $!\n";
        
        $parser = Pod::Simple::Text->new;
        $parser->output_fh($fh);
        $parser->parse_file($pod);
        
        close $fh;
    }
}


#================================================================================================================================================================================================================================================
sub _write_default_maniskip {
    my $self = shift;
    my $file = shift || 'MANIFEST.SKIP';

    $self->SUPER::_write_default_maniskip($file);

    my $fh = IO::File->new(">> $file") or die "Can't open $file: $!";
    print $fh <<'EOF';
^\.project$
^\.git\b
^\.externalToolBuilders\b
EOF
    $fh->close();
}



#================================================================================================================================================================================================================================================
# Overriding newly created Module::Build method, which add itself to 'configure_requires' - we need to keep it clean
sub auto_require {
    
}


#================================================================================================================================================================================================================================================
# Overriding Module::Build method, which checks for prerequisites being installed 
sub check_prereq {
    return 1
}


#================================================================================================================================================================================================================================================
# Overriding Module::Build method, which checks some other feature 
sub check_autofeatures {
    return 1
}


#================================================================================================================================================================================================================================================
sub prepare_metadata {
    my ($self, $node, $keys, $args) = @_;
    
    $self->meta_add('static_dir' => $self->static_dir);
    
    return $self->SUPER::prepare_metadata($node, $keys, $args);    
}



__PACKAGE__ # nothingmuch (c) 

__END__

=head1 NAME

Module::Build::JSAN::Installable - Build JavaScript distributions for JSAN, which can be installed locally

=head1 SYNOPSIS

In F<Build.PL>:

  use Module::Build::JSAN::Installable;

  my $build = Module::Build::JSAN::Installable->new(
      module_name    => 'Foo.Bar',
      license        => 'perl',
      keywords       => [qw(Foo Bar pithyness)],
      requires     => {
          'JSAN'     => 0.10,
          'Baz.Quux' => 0.02,
      },
      build_requires => {
          'Test.Simple' => 0.20,
      },
      
      static_dir => 'assets',
      docs_markup => 'mmd'
  );

  $build->create_build_script;


To build, test and install a distribution:

  % perl Build.PL
  % ./Build
  % ./Build test  
  % ./Build install


In F<Components.js>:

    COMPONENTS = {
        
        "Kernel" : [
            "JooseX.Namespace.Depended.Manager",
            "JooseX.Namespace.Depended.Resource",
            
            "JooseX.Namespace.Depended.Materialize.Eval",
            "JooseX.Namespace.Depended.Materialize.ScriptTag"
        ],
        
        
        "Web" : [
            "+Kernel",
        
            "JooseX.Namespace.Depended.Transport.AjaxAsync",
            "JooseX.Namespace.Depended.Transport.AjaxSync",
            "JooseX.Namespace.Depended.Transport.ScriptTag",
            
            "JooseX.Namespace.Depended.Resource.URL",
            "JooseX.Namespace.Depended.Resource.URL.JS",
            "JooseX.Namespace.Depended.Resource.JS",
            "JooseX.Namespace.Depended.Resource.JS.External",
            
            //should be the last        
            "JooseX.Namespace.Depended"
        ],
        
        
        "ServerJS" : [
            "+Kernel",
            
            "JooseX.Namespace.Depended.Transport.Require",
            "JooseX.Namespace.Depended.Resource.Require",
            
            //should be the last
            "JooseX.Namespace.Depended"
        ]
        
    } 


=cut


=head1 DESCRIPTION

This is a developer aid for creating JSAN distributions, which can be also installed in the local system. JSAN is the
"JavaScript Archive Network," a JavaScript library akin to CPAN. Visit
L<http://www.openjsan.org/> for details.

This module works nearly identically to L<Module::Build::JSAN>, so please refer to
its documentation for additional details.

=head1 DIFFERENCES

=over 4

=item 1 ./Build install

This action will install current distribution in your local JSAN library. See below for details.

=item 2 ./Build docs

This action will build a documentation files for this distribution. Default markup for documentation is POD. Alternative markup 
can be specified with C<docs_markup> configuration parameter (see Synopsis). Currently supported markups: 'pod', 
'md' (Markdown via Text::Markdown), 'mmd' (MultiMarkdown via Text::MultiMarkdown). 

Resulting documentation files will be placed under B</docs> directory, categorized by the formats. For 'pod' markup there will be
/doc/html, /doc/pod and /doc/text directories. For 'md' and 'mmd' markups there will be /doc/html and /doc/[m]md directories.

For 'md' and 'mmd' markups, its possible to keep the module's documentation in separate file. The file should have the same name as module,
with extensions, changed to markup abbreviature. An example:

      /lib/Module/Name.js
      /lib/Module/Name.mmd
      

=item 3 ./Build task [--task_name=foo]

This action will build a specific concatenated version (task) of current distribution.
Default task name is B<'Core'>, task name can be specified with C<--task_name> command line option.

Information about tasks is stored in the B<Components.JS> file in the root of distribution.
See the Synposys for example of B<Components.JS>. 

After concatenation, resulting file is placed on the following path: B</lib/Task/Distribution/Name/SampleTask.js>, 
assuming the name of your distribution was B<Distribution.Name> and the task name was B<SampleTask>


=item 4 ./Build test

This action relies on not yet released JSAN::Prove module, stay tuned for further updates.

=back


=head1 LOCAL JSAN LIBRARY

This module uses concept of local JSAN library, which is organized in the same way as perl library.

The path to the library is resolved in the following order:

1. B<--install_base> command-line argument

2. environment variable B<JSANLIB>

3. Either the first directory in C<$Config{libspath}>, followed with C</jsan> (probably C</usr/local/lib> on linux systems)
or C<C:\JSAN> (on Windows)

As a convention, it is recommended, that you configure your local web-server
that way, that B</jsan> will point at the B</lib> subdirectory of your local
JSAN library. This way you can access any module from it, with URLs like:
B<'/jsan/Test/Run.js'>  



=head1 STATIC FILES HANDLING

Under static files we'll assume any files other than javascript (*.js). Typically those are *.css files and images (*.jpg, *.gif, *.png etc).

All such files should be placed in the "static" directory. Default name for share directory is B<'/static'>. 
Alternative name can be specified with C<static_dir> configuration parameter (see Synopsis). Static directory can be organized in any way you prefere.

Lets assume you have the following distribution structure:

  /lib/Distribution/Name.js
  /static/css/style1.css 
  /static/img/image1.png

After building (B<./Build>) it will be processed as:

  /blib/lib/Distribution/Name.js
  /blib/lib/Distribution/Name/static/css/style1.css 
  /blib/lib/Distribution/Name/static/img/image1.png

During installation (B<./Build install>) the whole 'blib' tree along with static files will be installed in your local library.


=head1 AUTHOR

Nickolay Platonov, C<< <nplatonov at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-build-jsan-installable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-JSAN-Installable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

=over

=item Examples of installable JSAN distributions 

L<http://github.com/SamuraiJack/JooseX-Namespace-Depended/tree>

L<http://github.com/SamuraiJack/joosex-bridge-ext/tree>

=item L<http://www.openjsan.org/>

Home of the JavaScript Archive Network.

=item L<http://code.google.com/p/joose-js/>

Joose - Moose for JavaScript

=item L<http://github.com/SamuraiJack/test.run/tree>

Yet another testing platform for JavaScript

=back

=head1 SUPPORT

This module is stored in an open repository at the following address:

L<http://github.com/SamuraiJack/Module-Build-JSAN-Installable/tree/>


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Build-JSAN-Installable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Build-JSAN-Installable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Build-JSAN-Installable>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Build-JSAN-Installable/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to David Wheeler for his excelent Module::Build::JSAN, on top of which this module is built.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nickolay Platonov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


