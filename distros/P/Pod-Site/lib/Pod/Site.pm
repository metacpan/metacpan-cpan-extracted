package Pod::Site;

use strict;
use warnings;
use File::Spec;
use Carp;
use Pod::Simple '3.12';
use HTML::Entities;
use File::Path;
use Object::Tiny qw(
    module_roots
    doc_root
    base_uri
    index_file
    css_path
    favicon_uri
    js_path
    versioned_title
    replace_css
    replace_js
    label
    verbose
    mod_files
    bin_files
);

our $VERSION = '0.56';

sub go {
    my $class = shift;
    $class->new( $class->_config )->build;
}

sub new {
    my ( $class, $params ) = @_;
    my $self = bless {
        index_file => 'index.html',
        verbose    => 0,
        js_path    => '',
        css_path   => '',
        %{ $params || {} }
    } => $class;

    if (my @req = grep { !$self->{$_} } qw(doc_root base_uri module_roots)) {
        my $pl = @req > 1 ? 's' : '';
        my $last = pop @req;
        my $disp = @req ? join(', ', @req) . (@req > 1 ? ',' : '')
            . " and $last" : $last;
        croak "Missing required parameters $disp";
    }

    my $roots = ref $self->{module_roots} eq 'ARRAY'
        ? $self->{module_roots}
        : ( $self->{module_roots} = [$self->{module_roots}] );
    for my $path (@{ $roots }) {
        croak "The module root $path does not exist\n" unless -e $path;
    }

    $self->{base_uri} = [$self->{base_uri}] unless ref $self->{base_uri};
    return $self;
}

sub build {
    my $self = shift;
    File::Path::mkpath($self->{doc_root}, 0, 0755);

    $self->batch_html;

    # The index file is the home page.
    my $idx_file = File::Spec->catfile( $self->doc_root, $self->index_file );
    open my $idx_fh, '>', $idx_file or die qq{Cannot open "$idx_file": $!\n};

    # The TOC file has the table of contents for all modules and programs in
    # the distribution.
    my $toc_file = File::Spec->catfile( $self->{doc_root}, 'toc.html' );
    open my $toc_fh, '>', $toc_file or die qq{Cannot open "$toc_file": $!\n};

    # Set things up.
    $self->{toc_fh} = $toc_fh;
    $self->{seen} = {};
    $self->{indent} = 1;
    $self->{base_space} = '      ';
    $self->{spacer} = '  ';
    $self->{uri} = '';

    # Make it so!
    $self->sort_files;
    $self->start_nav($idx_fh);
    $self->start_toc($toc_fh);
    $self->output($idx_fh, $self->mod_files);
    $self->output_bin($idx_fh);
    $self->finish_nav($idx_fh);
    $self->finish_toc($toc_fh);
    $self->copy_etc;

    # Close up shop.
    close $idx_fh or die qq{Could not close "$idx_file": $!\n};
    close $toc_fh or die qq{Could not close "$toc_file": $!\n};
}

sub sort_files {
    my $self = shift;

    # Let's see what the search has found.
    my $stuff = Pod::Site::Search->instance->name2path;

    # Sort the modules from the scripts.
    my (%mods, %bins);
    while (my ($name, $path) = each %{ $stuff }) {
        if ($name =~ /[.]p(?:m|od)$/) {
            # Likely a module.
            _set_mod(\%mods, $name, $stuff->{$name});
        } elsif ($name =~ /[.](?:plx?|bat)$/) {
            # Likely a script.
            (my $script = $name) =~ s{::}{/}g;
            $bins{$script} = $stuff->{$name};
        } else {
            # Look for a shebang line.
            if (open my $fh, '<', $path) {
                my $shebang = <$fh>;
                close $fh;
                if ($shebang && $shebang =~ /^#!.*\bperl/) {
                    # Likely a script.
                    (my $script = $name) =~ s{::}{/}g;
                    $bins{$script} = $stuff->{$name};
                } else {
                    # Likely a module.
                    _set_mod(\%mods, $name, $stuff->{$name});
                }
            } else {
                # Who knows? Default to module.
                _set_mod(\%mods, $name, $stuff->{$name});
            }
        }
    }

    # Save our findings.
    $self->{mod_files} = \%mods;
    $self->{bin_files} = \%bins;
}

sub start_nav {
    my ($self, $fh) = @_;
    my $class   = ref $self;
    my $version = __PACKAGE__->VERSION;
    my $title   = encode_entities $self->title;
    my $head    = encode_entities $self->nav_header;

    print STDERR "Starting site navigation file\n" if $self->verbose > 1;
    my $base = join "\n        ", map {
        qq{<meta name="base-uri" content="$_" />}
    } @{ $self->{base_uri} };

    my $favicon = '';
    if (my $uri = $self->{favicon_uri}) {
       my $type = $uri;
       $type =~ s/.*\.([^.]+)/$1/;
       $favicon = qq(<link rel="icon" type="img/$type" href="$uri">);
    }
    print $fh _udent( <<"    EOF" );
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>$title</title>
        <link rel="stylesheet" type="text/css" href="$self->{css_path}podsite.css" />
        $base
        $favicon
        <script type="text/javascript" src="$self->{js_path}podsite.js"></script>
        <meta name="generator" content="$class $version" />
      </head>
      <body>
        <div id="nav">
          <h3>$head</h3>
          <ul id="tree">
            <li id="toc"><a href="toc.html">TOC</a></li>
    EOF
}

sub start_toc {
    my ($self, $fh) = @_;

    my $sample  = encode_entities $self->sample_module;
    my $version = Pod::Site->VERSION;
    my $title   = encode_entities $self->title;

    print STDERR "Starting browser TOC file\n" if $self->verbose > 1;
    print $fh _udent( <<"    EOF");
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>$title</title>
        <meta name="generator" content="Pod::Site $version" />
      </head>

      <body>
        <h1>$title</h1>
        <h1>Instructions</h1>

        <p>Select class names from the navigation tree to the left. The tree
           shows a hierarchical list of modules and programs. In addition to
           this URL, you can link directly to the page for a particular module
           or program. For example, if you wanted to access
           $sample, any of these links will work:</p>

        <ul>
          <li><a href="./?$sample">/?$sample</a></li>
          <li><a href="./$sample">/$sample</a></li>
        </ul>

        <p>Happy Hacking!</p>

        <h3>Classes &amp; Modules</h3>
        <ul>
    EOF
}

sub output {
    my ($self, $fh, $tree) = @_;
    for my $key (sort keys %{ $tree }) {
        my $data = $tree->{$key};
        (my $fn = $key) =~ s/\.[^.]+$//;
        my $class = join ('::', split('/', $self->{uri}), $fn);
        print STDERR "Reading $class\n" if $self->verbose > 1;
        if (ref $data) {
            # It's a directory tree. Output a class for it, first, if there
            # is one.
            my $item = $key;
            if ($tree->{"$key.pm"}) {
                my $path = $tree->{"$key.pm"};
                if (my $desc = $self->get_desc($class, $path)) {
                    $item = qq{<a href="$self->{uri}$key.html">$key</a>};
                    $self->_output_navlink($fh, $fn, $path, $class, 1, $desc);
                }
                $self->{seen}{$class} = 1;
            }

            # Now recursively descend the tree.
            print STDERR "Outputting nav link\n" if $self->verbose > 2;
            print $fh $self->{base_space}, $self->{spacer} x $self->{indent},
              qq{<li id="$class">$item\n}, $self->{base_space},
              $self->{spacer} x ++$self->{indent}, "<ul>\n";
            ++$self->{indent};
            $self->{uri} .= "$key/";
            $self->output($fh, $data);
            print $fh $self->{base_space}, $self->{spacer} x --$self->{indent},
                "</ul>\n", $self->{base_space},
                $self->{spacer} x --$self->{indent}, "</li>\n";
            $self->{uri} =~ s|$key/$||;
        } else {
            # It's a class. Create a link to it.
            $self->_output_navlink($fh, $fn, $data, $class)
                unless $self->{seen}{$class};
        }
    }
}

sub output_bin {
    my ($self, $fh) = @_;
    my $files = $self->bin_files;
    return unless %{ $files };

    # Start the list in the tree browser.
    print $fh $self->{base_space}, $self->{spacer} x $self->{indent},
      qq{<li id="bin">bin\n}, $self->{base_space}, $self->{spacer} x ++$self->{indent}, "<ul>\n";
    ++$self->{indent};

    for my $pl (sort { lc $a cmp lc $b } keys %{ $files }) {
        my $file = $files->{$pl};
        $self->_output_navlink($fh, $pl, $file, $pl);
    }

    print $fh $self->{base_space}, $self->{spacer} x --$self->{indent}, "</ul>\n",
      $self->{base_space}, $self->{spacer} x --$self->{indent}, "</li>\n";
}

sub finish_nav {
    my ($self, $fh) = @_;
    print STDERR "Finishing browser navigation file\n" if $self->verbose > 1;
    print $fh _udent( <<"    EOF" );
          </ul>
        </div>
        <div id="doc"></div>
      </body>
    </html>
    EOF
}

sub finish_toc {
    my ($self, $fh) = @_;
    print STDERR "finishing browser TOC file\n" if $self->verbose > 1;
    print $fh _udent( <<"    EOF" );
        </ul>
      </body>
    </html>
    EOF
}

sub batch_html {
    my $self = shift;
    require Pod::Simple::HTMLBatch;
    print STDERR "Creating HTML with Pod::Simple::XHTML\n" if $self->verbose > 1;
    my $batchconv = Pod::Simple::HTMLBatch->new;
    $batchconv->index(1);
    $batchconv->verbose($self->verbose);
    $batchconv->contents_file( undef );
    $batchconv->css_flurry(0);
    $batchconv->javascript_flurry(0);
    $batchconv->html_render_class('Pod::Site::XHTML');
    $batchconv->search_class('Pod::Site::Search');
    our $BASE_URI;
    local $BASE_URI = $self->base_uri->[0];
    $batchconv->batch_convert( $self->module_roots, $self->{doc_root} );
    return 1;
}

sub copy_etc {
    my $self = shift;
    require File::Copy;
    (my $from = __FILE__) =~ s/[.]pm$//;
    for my $ext (qw(css js)) {
        my $dest = File::Spec->catfile($self->{doc_root}, "podsite.$ext");
        File::Copy::copy(
            File::Spec->catfile( $from, "podsite.$ext" ),
            $self->{doc_root}
        ) unless -e $dest && !$self->{"replace_$ext"};
    }
}

sub get_desc {
    my ($self, $what, $file) = @_;

    open my $fh, '<', $file or die "Cannot open $file: $!\n";
    my ($desc, $encoding);
    local $_;
    # Cribbed from Module::Build::PodParser.
    while (not ($desc and $encoding) and $_ = <$fh>) {
        next unless /^=(?!cut)/ .. /^=cut/;  # in POD
        ($desc) = /^  (?:  [a-z0-9:]+  \s+ - \s+  )  (.*\S)  /ix unless $desc;
        ($encoding) = /^=encoding\s+(.*\S)/ unless $encoding;
    }
    Encode::from_to($desc, $encoding, 'UTF-8') if $desc && $encoding;

    close $fh or die "Cannot close $file: $!\n";
    print "$what has no POD or no description in a =head1 NAME section\n"
      if $self->{verbose} && !$desc;
    return $desc || '';
}

sub sample_module {
    my $self = shift;
    $self->{sample_module} ||= $self->main_module;
}

sub main_module {
    my $self = shift;
    $self->{main_module} ||= $self->_find_module;
}

sub name {
    my $self = shift;
    $self->{name} || $self->main_module;
}

sub title {
    my $self = shift;
    return $self->{title} ||= join ' ',
        $self->name,
        ( $self->versioned_title ? $self->version : () ),
        ( $self->label ? $self->label : () );
}

sub nav_header {
    my $self = shift;
    $self->name . ($self->versioned_title ? ' ' . $self->version : '');
}

sub version {
    my $self = shift;
    return $self->{version} if $self->{version};
    require Module::Metadata;
    my $mod  = $self->main_module;
    my $file = Pod::Site::Search->instance->name2path->{$mod}
        or die "Could not find $mod\n";
    my $info = Module::Metadata->new_from_file( $file )
        or die "Could not find $file\n";
    return $self->{version} ||= $info->version;
}

sub _pod2usage {
    shift;
    require Pod::Usage;
    Pod::Usage::pod2usage(
        '-verbose'  => 99,
        '-sections' => '(?i:(Usage|Options))',
        '-exitval'  => 1,
        '-input'    => __FILE__,
        @_
    );
}

sub _config {
    my $self = shift;
    require Getopt::Long;
    Getopt::Long::Configure( qw(bundling) );

    my %opts = (
        verbose    => 0,
        css_path   => '',
        js_path    => '',
        index_file => 'index.html',
        base_uri   => undef,
    );

    Getopt::Long::GetOptions(
        'name|n=s'           => \$opts{name},
        'doc-root|d=s'       => \$opts{doc_root},
        'base-uri|u=s@'      => \$opts{base_uri},
        'favicon-uri=s'      => \$opts{favicon_uri},
        'sample-module|s=s'  => \$opts{sample_module},
        'main-module|m=s'    => \$opts{main_module},
        'versioned-title|t!' => \$opts{versioned_title},
        'label|l=s'          => \$opts{label},
        'index-file|i=s'     => \$opts{index_file},
        'css-path|c=s'       => \$opts{css_path},
        'js-path|j=s'        => \$opts{js_path},
        'replace-css'        => \$opts{replace_css},
        'replace-js'         => \$opts{replace_js},
        'verbose|V+'         => \$opts{verbose},
        'help|h'             => \$opts{help},
        'man|M'              => \$opts{man},
        'version|v'          => \$opts{version},
    ) or $self->_pod2usage;

    # Handle documentation requests.
    $self->_pod2usage(
        ( $opts{man} ? ( '-sections' => '.+' ) : ()),
        '-exitval' => 0,
    ) if $opts{help} or $opts{man};

    # Handle version request.
    if ($opts{version}) {
        require File::Basename;
        print File::Basename::basename($0), ' (', __PACKAGE__, ') ',
            __PACKAGE__->VERSION, $/;
        exit;
    }

    # Check required options.
    if (my @missing = map {
        ( my $opt = $_ ) =~ s/_/-/g;
        "--$opt";
    } grep { !$opts{$_} } qw(doc_root base_uri)) {
        my $pl = @missing > 1 ? 's' : '';
        my $last = pop @missing;
        my $disp = @missing ? join(', ', @missing) . (@missing > 1 ? ',' : '')
            . " and $last" : $last;
        $self->_pod2usage( '-message' => "Missing required $disp option$pl" );
    }

    # Check for one or more module roots.
    $self->_pod2usage( '-message' => "Missing path to module root" )
        unless @ARGV;

    $opts{module_roots} = \@ARGV;

    # Modify options and set defaults as appropriate.
    for (@{ $opts{base_uri} }) { $_ .= '/' unless m{/$}; }

    return \%opts;
}

sub _set_mod {
    my ($mods, $mod, $file) = @_;
    if ($mod =~ /::/) {
        my @names = split /::/ => $mod;
        my $data = $mods->{shift @names} ||= {};
        my $lln = pop @names;
        for (@names) { $data = $data->{$_} ||= {} }
        $data->{"$lln.pm"} = $file;
    } else {
        $mods->{"$mod.pm"} = $file;
    }
}

sub _udent {
    my $string = shift;
    $string =~ s/^[ ]{4}//gm;
    return $string;
}

sub _output_navlink {
    my ($self, $fh, $key, $fn, $class, $no_link, $desc) = @_;

    $desc ||= $self->get_desc($class, $fn);
    $desc = "—$desc" if $desc;

    # Output the Tree Browser Link.
    print "Outputting $class nav link\n" if $self->{verbose} > 2;
    print $fh $self->{base_space}, $self->{spacer} x $self->{indent},
      qq{<li id="$class"><a href="$self->{uri}$key.html">$key</a></li>\n}
      unless $no_link;

    # Output the TOC link.
    print "Outputting $class TOC link\n" if $self->{verbose} > 2;
    print {$self->{toc_fh}} $self->{base_space}, $self->{spacer},
      qq{<li><a href="$self->{uri}$key.html" rel="section" name="$class">$class</a>$desc</li>\n};
    return 1;
}

sub _find_module {
    my $self = shift;
    my $search = Pod::Site::Search->instance or return;
    my $bins   = $self->bin_files || {};
    for my $mod (sort {
        lc $a cmp lc $b
    } keys %{ $search->instance->name2path }) {
        return $mod unless $bins->{$mod};
    }
}

##############################################################################
package Pod::Site::Search;

use base 'Pod::Simple::Search';
use strict;
use warnings;
our $VERSION = '0.56';

my $instance;
sub instance { $instance }

sub new {
    my $self = shift->SUPER::new(@_);
    $self->laborious(1);
    $self->inc(0);
    $instance = $self;
    return $self;
}

##############################################################################
package Pod::Site::XHTML;

use strict;
use base 'Pod::Simple::XHTML';
our $VERSION = '0.56';

sub new {
    my $self = shift->SUPER::new;
    $self->index(1);

    # Strip leading spaces from verbatim blocks equivalent to the indent of
    # the first line.
    $self->strip_verbatim_indent(sub {
        my $lines = shift;
        (my $indent = $lines->[0]) =~ s/\S.*//;
        return $indent;
    });

    return $self;
}

sub start_L {
    my ($self, $flags) = @_;
    my $search = Pod::Site::Search->instance
        or return $self->SUPER::start_L($self);
    my $to  = $flags->{to} || '';
    my $url = $to && $search->name2path->{$to} ? $Pod::Site::BASE_URI . join('/', split /::/ => $to) . '.html' : '';
    my $id  = $flags->{section};
    return $self->SUPER::start_L($flags) unless $url || ($id && !$to);
    my $rel = $id ? 'subsection' : 'section';
    $url   .= '#' . $self->idify($id, 1) if $id;
    $to   ||= $self->title || $self->default_title || '';
    $self->{scratch} .= qq{<a rel="$rel" href="$url" name="$to">};
}

sub html_header {
    my $self = shift;
    my $title = $self->force_title || $self->title || $self->default_title || '';
    my $version = Pod::Site->VERSION;
    return qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="generator" content="Pod::Site $version" />
    <title>$title</title>
  </head>
  <body class="pod">};
}

1;
__END__

=head1 Name

Pod::Site - Build browsable HTML documentation for your app

=head1 Synopsis

 use Pod::Site;
 Pod::Site->go;

=head1 Usage

  podsite --name App                      \
          --doc-root /path/to/output/html \
          --base-uri /browser/base/uri    \
          /path/to/perl/libs              \
          /path/to/perl/bins

=head1 Description

This program searches a list of directories and generates a
L<jQuery|http://jquery.org/>-powered documentation site from all of the POD
files it finds. It was originally designed for the
L<Bricolage|http://bricolagecms.org/> project but is has evolved for general
use. Have a look at the L<Bricolage API
Browser|http://www.bricolagecms.org/docs/current/api/> to see a sample
documentation site in action. The generated documentation site supports
Safari, Firefox, and IE7 and up.

=head2 Configuration

Sites generated by Pod::Site are static HTML sites with all interactivity
powered by CSS and jQuery. It does its best to create links to documents
within the site, and for Pod outside the site it links to L<CPAN
search|http://search.cpan.org/>.

You can specify links directly to a specific document on your site by simply
adding a module name to the URL after a question mark. An example:

  http://www.example.com/docs/?MooseX::Declare

There is one server configuration that you'll want to make to allow links
without the question-mark:

  http://www.example.com/docs/MooseX::Declare

Getting this to work is simple: Just have your Web server send 404s to the
index page. If your base URI is F</docs/api>, for example, in Apache's
F<httpd.conf> you can just do this:

 <Location /docs/api>
   ErrorDocument 404 /docs/current/api/index.html
 </Location>

=head1 Options

  -d --doc-root DIRECTORY   Browser document root
  -u --base-uri URI         Browser base URI
  -n --name NAME            Site name
  -t --versioned-title      Include main module version number in title
  -l --label LABEL          Label to append to site title
  -m --main-module MODULE   Primary module for the documentation
  -s --sample-module MODULE Module to use for sample links
  -i --index-file FILENAME  File name for index file
  -c --css-path PATH        Path to CSS file
  -j --js-path PATH         Path to CSS file
     --replace-css          Replace existing CSS file
     --replace-js           Replace existing JavaScript file
     --favicon-uri URI      Add a favicon linking to the given URI
  -V --verbose              Incremental verbose mode.
  -h --help                 Print a usage statement and exit.
  -M --man                  Print the complete documentation and exit.
  -v --version              Print the version number and exit.

=head1 Class Interface

=head2 Class Method

=head3 C<go>

  Pod::Site->go;

Called from C<podsite>, this class method parses command-line options in
C<@ARGV>, passes them to the constructor, and builds the site.

=head2 Constructor

=head3 C<new>

  my $ps = Pod::Site->new(\%params);

Constructs and returns a Pod::Site object. The supported parameters are:

=over

=item C<module_roots>

An array reference of directories to search for Pod files, or for the paths of
Pod files themselves. These files and directories will be searched for the Pod
documentation to build the browser.

=item C<doc_root>

Path to a directory to use as the site document root. This directory will be
created if it does not already exist.

=item C<base_uri>

Base URI for the Pod site. For example, if your documentation will be served
from F</docs/2.0/api>, then that would be the base URI for the site.

May be an array reference of base URIs. This is useful if your Pod site will
be served from more than one URL. This is common for versioned documentation,
where you might have docs in F</docs/2.0/api> and a symlink to that directory
from F</docs/current/api>. This parameter is important to get links from one
page to another within the site to work properly.

=item C<name>

The name of the site. Defaults to the name of the main module.

=item C<versioned_title>

If true, the version of the main module will be included in the site title.

=item C<label>

Optional label to append to the site title. Something like "API Browser" is
recommended.

=item C<main_module>

The main module defining the site. For example, if you were building a
documentation site for the L<Moose>, L<Class::MOP>, and C<MooseX> namespaces,
the main module would be "Moose". Defaults to the first module found when all
module names are sorted in alphabetical order.

=item C<sample_module>

Module to use in the example documentation links in the table of contents.
This is the main page displayed on the site

=item C<index_file>

Name of the site index file. Defaults to F<index.html>, but you might need it
to be, e.g., F<default.html> if you were deploying to a Windows server.

=item C<css_path>

Path to CSS files. Defaults to the base URI.

=item C<js_path>

Path to JavaScript files. Defaults to the base URI.

=item C<replace_css>

=item C<replace_js>

If you're building a new site over an old site, by default Pod::Site will not
replace the CSS and JavaScript files, seeing as you might have changed them.
If you want it to replace them, pass a true value for this parameter.

If you're building a new site over an old site, by default Pod::Site will not
replace the CSS and JavaScript files, seeing as you might have changed them.
If you want it to replace them (and in general you ought to), pass a true
value for these parameters.

=item C<favicon_uri>

Link to favicon file.  Extracts type from extension.

=item C<verbose>

Pass a value greater than 0 for verbose output. The higher the number, the
more verbose (up to 3).

=back

=head1 Instance Interface

=head2 Instance Methods

=head3 C<build>

  $ps->build;

Builds the Pod::Site. This is likely the only instance method you'll ever
need. In summary, it:

=over

=item *

Searches through the module roots for Pod files (modules and scripts) using
L<Pod::Simple::Search>

=item *

Creates HTML files for all the files found using L<Pod::Simple::HTMLBatch> and
a custom subclass of L<Pod::Simple::XHTML>

=item *

Iterates over the list of files to create the index with the navigation tree
and the table of contents page (F<toc.html>).

=back

=head3 C<sort_files>

 $ps->sort_files;

Iterates through the Pod files found by L<Pod::Simple::Search> and sorts them
into two categories: modules and scripts. All appear in the navigation tree,
but scripts are listed under "bin" and are not otherwise in tree form.

=head3 C<start_nav>

  $ps->start_nav($filehandle);

Starts the HTML for the navigation document, writing the output to $filehandle.

=head3 C<start_toc>

  $ps->start_toc($filehandle);

Starts the HTML for the table of contents document, writing the output to
$filehandle.

=head3 C<output>

  $ps->output($filehandle, $tree);

Writes the content of the module tree to the navigation document via
$filehandle. The $tree argument contains the tree. This method is called
recursively as it descends through the tree to create the navigation tree.

=head3 C<output_bin>

  $ps->output_bin($filehandle);

Outputs the list of script files to the table of contents document via
$filehandle.

=head3 C<finish_nav>

  $ps->finish_nav($filehandle);

Finishes the HTML for the navigation document, writing the output to
$filehandle.

=head3 C<finish_toc>

  $ps->finish_toc($filehandle);

Finishes the HTML for the table of contents document, writing the output to
$filehandle.

=head3 C<batch_html>

  $ps->batch_html;

Does the work of invoking L<Pod::Simple::HTMLBatch> to look for Pod files and
write out the corresponding HTML files for each.

=head3 C<copy_etc>

  $ps->copy_etc;

Copies the additional files, F<podsite.js> and F<podsite.css> to the document
root. These files are necessary to the functioning of the site.

=head3 C<get_desc>

  $ps->get_desc( $module, $file);

Parses the Pod in $file to find the description of $module. This is the text
after the hyphen in the `=head1 Name` section of the Pod, often called the
"abstract" by toolchain modules like L<Module::Build>.

=head2 Instance Accessors

=head3 C<main_module>

  my $mod = $ps->main_module;

Returns the name of the main module as specified by the C<main_module>
parameter to C<new()> or, if none was specified, as first module in the list
of found modules, sorted case-insensitively.

=head3 C<sample_module>

  my $mod = $ps->sample_module;

The name of the module to use for the sample links in the table of contents.
Defaults to C<main_module>.

=head3 C<name>

  my $name = $ps->name;

Returns the name of the site. Defaults to C<main_module>.

=head3 C<label>

  my $label = $ps->label;

Returns the optional label to append to the site title. None by default.

=head3 C<title>

  my $title = $ps->title;

Returns the title of the site. This will be constructed from C<name> and
C<label> and, if C<versioned_title> is true, the title of the main module.

=head3 C<nav_header>

  my $header = $ps->nav_header;

Returns the header used at the top of the navigation. This will be constructed
from C<name> and, if C<versioned_title> is true, the title of the main module.

=head3 C<versioned_title>

  my $versioned_title = $ps->versioned_title;

Returns true if the version is to be included in the site title, and false if
it is not, as specified via the C<versioned_title> parameter to C<new()>.

=head3 C<version>

  my $version = $ps->version;

Returns the version number of the main module.

=head3 C<module_roots>

  my $roots = $ps->module_roots;

Returns an array reference of the directories and files passed to the
C<module_roots> parameter to C<new()>.

=head3 C<doc_root>

  my $doc_root = $ps->doc_root;

Returns the path to the document root specified via the C<doc_root> parameter
to C<new()>.

=head3 C<base_uri>

  my $base_uri = $ps->base_uri;

Returns the value of the base URI as specified via the C<base_uri> parameter
to C<new()>.

=head3 C<index_file>

  my $index_file = $ps->index_file;

Returns the value of index files as specified via the C<index_file> parameter
to C<new()>. Defaults to F<index.html>.

=head3 C<css_path>

  my $css_path = $ps->css_path;

Returns the URI path for CSS files as specified via the C<css_path> parameter
to C<new()>. Defaults to an empty string, meaning it will be fetched from the
directory relative to the current URL. This is the recommended value as it
allows any URL under the base URL to work, such as F</docs/MooseX::Declare>,
enabled by the L<Web server configuration|/Configuration>.

=head3 C<js_path>

  my $js_path = $ps->js_path;

Returns the URI path for JavaScript files as specified via the C<js_path>
parameter to C<new()>. Defaults to an empty string, meaning it will be fetched
from the directory relative to the current URL. This is the recommended value
as it allows any URL under the base URL to work, such as
F</docs/MooseX::Declare>, enabled by the L<Web server
configuration|/Configuration>.

=head3 C<replace_css>

  my $replace_css = $ps->replace_css;

Returns true if Pod::Site should replace an existing F<podsite.css> file when
regenerating a site, as specified via the C<replace_css> parameter to
C<new()>.

=head3 C<replace_js>

  my $replace_js = $ps->replace_js;

Returns true if Pod::Site should replace an existing F<podsite.js> file when
regenerating a site, as specified via the C<replace_js> parameter to C<new()>.

=head3 C<mod_files>

  my $mod_files = $ps->mod_files;

Returns a tree structure containing all the module files with Pod found by
L<Pod::Simple::Search>. The structure has file base names as keys and full
file names as values. For nested structures, the keys are the last part of a
module name and the values are an array of more file names and module
branches. For example, a partial tree of module files for Moose might be
structured like this:

  $mod_files = {
      'Moose.pm' => 'lib/Moose.pm',
      'Moose'    => {
          'Meta' => {
              'Class.pm'    => 'lib/Moose/Meta/Class.pm',
              'Instance.pm' => 'lib/Moose/Meta/Instance.pm',
              'Method.pm'   => 'lib/Moose/Meta/Method.pm',
              'Role.pm'     => 'lib/Moose/Meta/Role.pm',
          },
      },
 }

=head3 C<bin_files>

  my $bin_files = $ps->bin_files;

Returns a tree structure containing all the scripts with Pod found by
L<Pod::Simple::Search>. The structure has file names as keys and full file
names as values.

=head3 C<verbose>

  my $verbose = $ps->verbose;

Returns the value passed for the C<verbose> parameter to C<new()>. Defaults to
0.

=head1 To Do

=over

=item *

Add support for resizing the nav pane.

=item *

Allow right and middle clicks on nav window links to copy links or open them
in a new Window (L<Issue #1|http://github.com/theory/pod-site/issues/1>).

=back

This module is stored in an open L<GitHub
repository|http://github.com/theory/pod-site/>. Feel free to fork and
contribute!

Found a bug? Please L<file a report|http://github.com/theory/pod-site/issues>!

=head1 Support

This module is stored in an open GitHub repository,
L<http://github.com/theory/pod-site/>. Feel free to fork and contribute!

Please file bug reports at L<http://github.com/theory/pod-site/issues/>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2004-2015 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
