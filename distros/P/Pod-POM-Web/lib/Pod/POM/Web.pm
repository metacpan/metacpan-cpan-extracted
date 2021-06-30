#======================================================================
package Pod::POM::Web; # see doc at end of file
#======================================================================
use strict;
use warnings;
use 5.010;

use parent 'Plack::Component';                             # web app based on Plack architecture
use Plack::Request;                                        # Plack API for an HTTP request
use Plack::Response;                                       # Plack API for an HTTP response
use Plack::Util;                                           # encode_html()
use Pod::POM 0.25;                                         # parsing Pod
use List::Util          qw/min max/;                       # numeric minimum & maximum
use List::MoreUtils     qw/uniq firstval any/;             # list utilities
use Module::CoreList;                                      # asking if a module belongs to Perl core
use MIME::Types;                                           # translate file extension into MIME type
use Alien::GvaScript 1.021000;                             # javascript files
use Config;                                                # to find where are the perl script directories
use Encode              qw/encode_utf8 decode_utf8/;       # utf8 encoding
use Params::Validate    qw/validate_with SCALAR ARRAYREF/; # check validity of parameters
use Path::Tiny          qw/path/;                          # easy access to file contents
use CPAN::Common::Index::Mux::Ordered;                     # current CPAN version of a module
use Pod::POM::Web::Util qw/slurp_native_or_utf8 parse_version extract_POM_items/;


# other modules that may be required dynamically :
# Getopt::Long, PPI::HTML, ActiveState::Scineplex, Plack::Runner


#----------------------------------------------------------------------
# GLOBAL VARIABLES
#---------------------------------------------------------------------

our $VERSION = '1.25';

# directories for modules -- filter @INC (we don't want '.', nor server_root added by mod_perl)
my $server_root = eval {Apache2::ServerUtil::server_root()} || "";
my @default_module_dirs = grep {!/^\./ && $_ ne $server_root} @INC;

# directories for executable perl scripts
my @default_script_dirs = grep {$_}
                          @Config{qw/sitescriptexp vendorscriptexp scriptdirexp/};


(my $default_index_dir = __FILE__) =~ s[Web\.pm$][Web/index];


# parameters for instantiating the module. They could also come from cmd-line options
my %params_for_new = (
  page_title  => {type => SCALAR  , default => 'Perl documentation'},
  module_dirs => {type => ARRAYREF, default => \@default_module_dirs},
  script_dirs => {type => ARRAYREF, default => \@default_script_dirs},
  index_dir   => {type => SCALAR  , default => $default_index_dir},
  script_name => {type => SCALAR  , optional => 1}, # will be filled at first web request
 );
my @params_for_getopt = (
  'page_title|title=s',
  'module_dirs|mdirs=s@{,}',
  'script_dirs|sdirs=s@{,}',
  'index_dir|idir=s',
);


# some subdirs never contain Pod documentation
my @ignore_toc_dirs = qw/auto unicore/;


# syntax coloring (optional)
my $coloring_package
  = eval {require PPI::HTML}              ? "PPI"
  : eval {require ActiveState::Scineplex} ? "SCINEPLEX"
  : "";

# A sequence of optional filters to apply to the source code before
# running it through Pod::POM. Source code is passed in $_[0] and
# should be modified in place.
my @podfilters = (

  # Pod::POM fails to parse correctly when there is an initial blank line
  sub { $_[0] =~ s/\A\s*// },

  # Pod::POM only understands =encoding utf8, not utf-8
  sub { $_[0] =~ s/=encoding utf-8/=encoding utf8/i; },

);

my %special_podfilters = (

  perlfunc => # remove args in links to function names
              # (for ex. L<C<open>|/open FILEHANDLE,MODE,EXPR> becomes L<C<open>|/open>
              sub {$_[0] =~ s[(L<.*?\|/\w+)\s.*?>][$1>]g},

  # perlre: the POM parser is not smart enough to parse
  # L</C<< (?>pattern) >>>, so we translate them into L<C<< (?E<gt>pattern) >>|/(?E<gt>pattern)>
  perlre   => sub {$_[0] =~ s[\(\?>][(?E<gt>]g;
                   $_[0] =~ s[L</C<< (.*?) >>>][L<C<< $1 >>|/$1>]g},

  # POSIX: the POM parser is not smart enough to parse
  # L<C<function>(3)>, so we translate them into C<L<function(3)>>
  POSIX    => sub {$_[0] =~ s[L<C<(\w+)>\((\d)\)>][C<L<$1($2)>>]g},
 );



#----------------------------------------------------------------------
# CLASS METHODS
#----------------------------------------------------------------------

# functions exported so that they can be called from command-line
sub import {
  my $class = shift;
  my ($package, $filename) = caller;
  no strict 'refs';

  # export "server" and "index" -- for "perl -MPod::POM::Web -e ..."
  if ($package eq 'main' and $filename eq '-e') {
    *{'main::server'} = sub { $class->server };
    *{'main::index'}  = sub { $class->index(@_) };
  }

  # export "app" --- for "plackup -MPod::POM::Web -e app"
  elsif($package eq 'Plack::Runner') {
    *{'Plack::Runner::app'} = sub {$class->app};
  }
}


# launch the app via Plack::Runner when called from perl cmd-line
sub server {
  my $class = shift;

  require Plack::Runner;
  my $runner = Plack::Runner->new;
  $runner->parse_options(@ARGV);
  $runner->run($class->app);
}


# return an app suitable to run under Plack::Runner
sub app {
  my $class = shift;

  # get options from command-line
  require Getopt::Long;
  my $parser = Getopt::Long::Parser->new(config => [qw/pass_through/]);
  $parser->getoptions(\my %options, @params_for_getopt);

  # create a Pod::POM::Web instance and make it into a Plack app
  my $obj = $class->new(%options);
  return $obj->to_app;
}


# backcompat : a class method to be used as a CGI script or as a modperl handler
sub handler : method  {
  my ($class, $r) = @_;

  if ($r && ref $r =~ /^Apache/) {
    require Plack::Handler::Apache2;
    Plack::Handler::Apache2->call_app($r, $class->app);
  }
  else {
    require Plack::Handler::CGI;
    Plack::Handler::CGI->new->run($class->app);
  }
}

# façade to the Indexer class -- for facilitating command-line invocation
sub index {
  my ($class, %options) = @_;

  my $self = $class->new();
  $self->indexer(%options)->start_indexing_session;
}


# constructor
sub new {
  my $class = shift;

  # validate input parameters
  my $self = validate_with(
    params      => \@_,
    spec        => \%params_for_new,
    allow_extra => 0,
   );

  # sources for CPAN index. The default requires an internet connexion. If there is a
  # local MiniCPAN mirror, it will be detected and used as an alternate source.
  my @cpan_indices = (MetaDB => {}); 

  if (my $local_minicpan = eval {require CPAN::Mini;
                                 my %conf = CPAN::Mini->read_config;
                                 $conf{local}}) {
    unshift @cpan_indices,
      LocalPackage => { source => "$local_minicpan/modules/02packages.details.txt.gz" };
  }
  $self->{cpan_index} = CPAN::Common::Index::Mux::Ordered->assemble(@cpan_indices);

  # create instance
  bless $self, $class;
}


#----------------------------------------------------------------------
# INSTANCE METHODS
#----------------------------------------------------------------------


# simple-minded accessors
sub module_dirs {@{shift->{module_dirs}}}
sub script_dirs {@{shift->{script_dirs}}}

# lazy instantiation of the indexer class
sub indexer {
  my ($self, %options) = @_;

  # NOTE : the indexer cannot be cached, because this would lock the .BDB files, preventing updates
  require Pod::POM::Web::Indexer;
  my $indexer = Pod::POM::Web::Indexer->new(index_dir   => $self->{index_dir},
                                            module_dirs => $self->{module_dirs},
                                            %options);
  return $indexer;
}


# main request dispatcher (see L<Plack::Component>)
sub call {
  my ($self, $env) = @_;

  # plack request object
  my $req = Plack::Request->new($env);

  # at first request, register the script name
  $self->{script_name} = $req->script_name if not exists $self->{script_name};

  # dispatching will be based on path_info
  my $path_info = $req->path_info;

  # security check : no outside directories
  $path_info =~ m[(\.\.|//|\\|:)] and die "illegal path: $path_info";

  # dispatch
  $path_info =~ s[^/][] or return $self->index_frameset($req);
  for ($path_info) {
    /^$/               and return $self->index_frameset($req);
    /^index$/          and return $self->index_frameset($req);
    /^toc$/            and return $self->main_toc($req);
    /^toc\/(.*)$/      and return $self->toc_for($1);   # Ajax calls
    /^script\/(.*)$/   and return $self->serve_script($1);
    /^search$/         and return $self->dispatch_search($req);
    /^source\/(.*)$/   and return $self->serve_source($1, $req);
    /^ft_index$/       and return $self->ft_index($req);

    # files with extensions (.css, .js, images)
    /\.(\w+)$/         and return $self->serve_file($path_info, $1);

    # otherwise, it must be a module
    return $self->serve_module($path_info);
  }
}



#----------------------------------------------------------------------
# main frameset
#----------------------------------------------------------------------

sub index_frameset{
  my ($self, $req) = @_;

  # initial page to open
  my $ini         = $req->parameters->{open};
  my $ini_content = $ini || "perl";
  my $ini_toc     = $ini ? "toc?open=$ini" : "toc";

  # HTML title
  my $title = Plack::Util::encode_html($self->{page_title});

  return $self->respond_html(<<__EOHTML__);
<html>
  <head><title>$title</title></head>
  <frameset cols="25%, 75%">
    <frame name="tocFrame"     src="$self->{script_name}/$ini_toc">
    <frame name="contentFrame" src="$self->{script_name}/$ini_content">
  </frameset>
</html>
__EOHTML__
}




#----------------------------------------------------------------------
# serving a single file (source code, raw content or POD documentation)
#----------------------------------------------------------------------

sub serve_source {
  my ($self, $path, $req) = @_;

  my $params = $req->parameters;

  # default (if not printing): line numbers and syntax coloring are on
  $params->{lines} = $params->{coloring} = 1 unless $params->{print};

  # find the source file(s)
  my @files = $path =~ s[^script/][] ? $self->find_script($path)
                                     : $self->find_module($path)
      or die "did not find source for '$path'";

  # last modification
  my $mtime = max map{(stat $_)[9]} @files;

  # build formatted source
  my $view = $self->mk_view(
    line_numbering  => $params->{lines},
    syntax_coloring => ($params->{coloring} ? $coloring_package : "")
   );
  my $formatted_sources = "";
  foreach my $file (@files) {
    my $source = slurp_native_or_utf8($file);
    $source =~ s/\r\n/\n/g;
    my $formatted_source = $view->view_verbatim($source);
    $formatted_sources .= "<p/><h2>$file</h2><p/><pre>$formatted_source</pre>";
  }

  my $offer_print = $params->{print} ? "" : <<__EOHTML__;
<form method="get" target="_blank">
<input type="submit" name="print" value="Print"> with<br>
<input type="checkbox" name="lines" checked>line numbers<br>
<input type="checkbox" name="coloring" checked>syntax coloring
</form>
__EOHTML__

  my $script = $params->{print} ? <<__EOHTML__ : "";
<script>
window.onload = function () {window.print()};
</script>
__EOHTML__

  my $doc_link = $params->{print} ? "" : <<__EOHTML__;
<a href="$self->{script_name}/$path" style="float:right">Doc</a>
__EOHTML__

  my $css_links = $self->css_links;

  (my $module = $path) =~ s[/][::]g;

  my $html = <<__EOHTML__;
<html>
<head>
  <title>Source of $module</title>
  $css_links
  <style>
    PRE {border: none; background: none}
    FORM {float: right; font-size: 70%; border: 1px solid}
  </style>
</head>
<body>
$doc_link
<h1>Source of $module</h1>
$offer_print
$formatted_sources
</body>
</html>
__EOHTML__

  $self->respond_html($html, $mtime);
}



sub serve_file {
  my ($self, $path, $extension) = @_;

  my ($fullpath) = $self->find_files(module_dirs => $path)
    or return $self->respond(code => 404,
                             content   => "$path: no such file");

  my $mime_type  = MIME::Types->new->mimeTypeOf($extension);
  my $content    = path($fullpath)->slurp_raw;
  my $mtime      = (stat $fullpath)[9];
  $self->respond(content   => $content,
                 mtime     => $mtime,
                 mime_type => $mime_type);
}

sub serve_module {
  my ($self, $path) = @_;
  $path =~ s[::][/]g; # just in case, if called as /perldoc/Foo::Bar

  # find file(s) corresponding to $path
  my @sources = $self->find_module($path)
    or return $self->_no_such_module($path);
  my $mtime   = max map {(stat $_)[9]} @sources;

  # module version
  my $version = firstval {$_} map {parse_version($_)} grep {/\.pm$/} @sources;

  # latest CPAN version -- needs hack because CPAN::Common::Index reports 'undef' instead of undef
  (my $mod_name = $path) =~ s[/][::]g;
  my $cpan_package = $self->{cpan_index}->search_packages( { package => $mod_name } );
  my $cpan_version = $cpan_package ? $cpan_package->{version} : undef;
  undef $cpan_version if $cpan_version && $cpan_version eq 'undef';

  # special pre-processing for some specific paths
  my @special_podfilters = ($special_podfilters{$path} // ());

  # POD content, preferably from the 1st file in list, otherwise from the 2nd
  my $pom     = $self->extract_POM($sources[0], @special_podfilters);
  my @content = $pom->content;
  $pom = $self->extract_POM($sources[1], @special_podfilters)
    if @sources > 1 and !@content;

  # generate HTML through the view class
  my $view = $self->mk_view(version         => $version,
                            mtime           => $mtime,
                            path            => $path,
                            mod_name        => $mod_name,
                            cpan_version    => $cpan_version,
                            syntax_coloring => $coloring_package);
  my $html = $view->print($pom);

  # special handling for perlfunc : ids should be just function names
  $html =~ s/li id="(.*?)_.*?"/li id="$1"/g
    if $path =~ /\bperlfunc$/;

  # special handling for 'perl' : hyperlinks to man pages
  if ($path =~ /\bperl$/) {
    my $sub = sub {my $txt = shift;
                   $txt =~ s[(perl\w+)]
                            [<a href="$self->{script_name}/$1">$1</a>]g;
                   return $txt};
    $html =~ s[(<pre.*?</pre>)][$sub->($1)]egs;
  }

  return $self->respond_html($html, $mtime);
}



sub serve_script {
  my ($self, $path) = @_;

  # find file(s) corresponding to $path
  my ($fullpath) = $self->find_script($path)
    or die "no such script : $path";

  # last modification time
  my $mtime   = (stat $fullpath)[9];

  # call view to generate HTML
  my $pom    = $self->extract_POM($fullpath);
  my $view   = $self->mk_view(path            => "script/$path",
                              mtime           => $mtime,
                              syntax_coloring => $coloring_package);
  my $html   = $view->print($pom);

  # return HTML
  return $self->respond_html($html, $mtime);
}


sub extract_POM {
  my ($self, $sourcefile, @more_podfilters) = @_;

  my $pod    = slurp_native_or_utf8($sourcefile);
  $_->($pod) foreach @podfilters, @more_podfilters;
  my $parser = Pod::POM->new;
  my $pom    = $parser->parse_text($pod) or die $parser->error;

  return $pom;
}

sub _no_such_module {
  my ($self, $module) = @_;

  $module =~ s!/!::!g;
  $module = Plack::Util::encode_html($module);
  my $html =  <<__EOHTML__;
<html>
  <head>
    <title>$module not found</title>
  </head>
  <body>
    <h1>$module not found</h1>
    <p>
      The module <code>$module</code> could not be found on this server.
      It may not be installed locally. Please try 
      <a href='https://metacpan.org/pod/$module' target='_blank'>$module on Metacpan</a>.
    </p>
  </body>
</html>
__EOHTML__

  $self->respond_html($html);
}



#----------------------------------------------------------------------
# tables of contents
#----------------------------------------------------------------------


sub toc_for { # partial toc (called through Ajax)
  my ($self, $prefix) = @_;

  # special handling for builtin paths
  for ($prefix) {
    /^perldocs$/ and return $self->toc_perldocs;
    /^pragmas$/  and return $self->toc_pragmas;
    /^scripts$/  and return $self->toc_scripts;
  }

  # otherwise, find and htmlize entries under a given prefix
  my $entries = $self->find_entries_for($prefix);
  if ($prefix eq 'Pod') {
    # in old versions of perl, basic docs are under Pod/perl*.pod. They should not be listed in the toc.
    delete $entries->{$_} for grep /^perl/, keys %$entries;
  }
  return $self->respond_html($self->htmlize_entries($entries));
}


sub toc_perldocs {
  my ($self) = @_;

  my %perldocs;

  # Old versions of perl had basic docs under "Pod". More recent have it under "pods".
  # "perllocal.pod" is in the root dir.
  for my $subdir (qw/Pod pods/, "") {
    my $entries = $self->find_entries_for($subdir);

    # just keep the perl* entries, without subdir prefix
    foreach my $key (grep /^perl/, keys %$entries) {
      $perldocs{$key}       = $entries->{$key};
      $perldocs{$key}{node} =~ s[^$subdir/][]i;
    }
  }

  return $self->respond_html($self->htmlize_perldocs(\%perldocs));
}



sub toc_pragmas {
  my ($self) = @_;

  my $entries  = $self->find_entries_for("");    # files found at root level
  delete $entries->{$_} for @ignore_toc_dirs, qw/pod pods inc/;
  delete $entries->{$_} for grep {/^perl/ or !/^[[:lower:]]/} keys %$entries;

  return $self->respond_html($self->htmlize_entries($entries));
}


sub toc_scripts {
  my ($self) = @_;

  my %scripts;

  # gather all scripts and group them by initial letter
  foreach my $dir ($self->script_dirs) {
    opendir my $dh, $dir or next;
  NAME:
    foreach my $name (readdir $dh) {
      for ("$dir/$name") {
        -x && !-d && -T or next NAME ; # try to just keep Perl executables
      }
      $name =~ s/\.(pl|bat)$//i;
      my $letter = uc substr $name, 0, 1;
      $scripts{$letter}{$name} = {node => "script/$name", pod => 1};
    }
  }

  # htmlize the structure
  my $html = "";
  foreach my $letter (sort keys %scripts) {
    my $content = $self->htmlize_entries($scripts{$letter});
    $html .= closed_node(label   => $letter,
                         content => $content);
  }

  return $self->respond_html($html);
}


sub find_entries_for {
  my ($self, $prefix) = @_;

  # if $prefix is of shape A*, we want top-level modules starting
  # with that letter
  my $filter;
  if ($prefix =~ /^([A-Z])\*/) {
    $filter = qr/^$1/;
    $prefix = "";
  }

  my %entries;

  foreach my $root_dir ($self->module_dirs) {
    my $dirname = $prefix ? "$root_dir/$prefix" : $root_dir;
    opendir my $dh, $dirname or next;
    foreach my $name (readdir $dh) {
      next if $name =~ /^\./;
      next if $filter and $name !~ $filter;
      my $is_dir  = -d "$dirname/$name";
      my $has_pod = $name =~ s/\.(pm|pod)$//;

      # skip if this subdir is a member of @INC (not a real module namespace)
      next if $is_dir and grep {m[^\Q$dirname/$name\E]} $self->module_dirs;

      if ($is_dir || $has_pod) { # found a TOC entry
        $entries{$name}{node} = $prefix ? "$prefix/$name" : $name;
        $entries{$name}{dir}  = 1 if $is_dir;
        $entries{$name}{pod}  = 1 if $has_pod;
      }
    }
  }
  return \%entries;
}


sub htmlize_perldocs {
  my ($self, $perldocs) = @_;
  my $parser  = Pod::POM->new;

  # Pod/perl.pom Synopsis contains a classification of perl*.pod documents
  my ($perl_path) = $self->find_module("perl")
    or die "'perl.pod' does not seem to be installed on this system";

  my $perlpom = $self->extract_POM($perl_path);

  my $h1 =  (firstval {$_->title eq 'GETTING HELP'} $perlpom->head1)
         || (firstval {$_->title eq 'SYNOPSIS'}     $perlpom->head1);
  my $html = "";

  # classified pages mentioned in the synopsis
  foreach my $h2 ($h1->head2) {
    my $title   = $h2->title;
    my $content = $h2->verbatim;

    # "Internals and C-Language Interface" is too long
    $title =~ s/^Internals.*/Internals/;

    # gather leaf entries
    my @leaves;
    while ($content =~ /^\s*(perl\S*)(?:\h+(\w.+))?/gm) {
      my ($ref, $descr) = ($1, $2);
      my $attrs = qq{id='$ref'};
      $attrs .= qq{ title='$descr'} if $descr;
      my $entry = delete $perldocs->{$ref} or next;
      push @leaves, {label => $ref,
                     href  => $entry->{node},
                     attrs => $attrs};
    }
    # sort and transform into HTML
    @leaves = map {leaf(%$_)}
              sort {$a->{label} cmp $b->{label}} @leaves;
    $html .= closed_node(label   => $title,
                         content => join("\n", @leaves));
  }

  # maybe some remaining pages
  if (keys %$perldocs) {
    $html .= closed_node(label   => 'Unclassified',
                         content => $self->htmlize_entries($perldocs));
  }

  return $html;
}




sub htmlize_entries {
  my ($self, $entries) = @_;
  my $html = "";
  my $has_index = $self->indexer->has_index;

  foreach my $name (sort {uc($a) cmp uc($b)} keys %$entries) {
    my $entry = $entries->{$name};
    (my $id = $entry->{node}) =~ s[/][::]g;
    my %args = (class => 'TN_leaf',
                label => $name,
                attrs => qq{id='$id'});
    if ($entry->{dir}) {
      $args{class}  = 'TN_node TN_closed';
      $args{attrs} .= qq{ TN:contentURL='toc/$entry->{node}'};
    }
    if ($entry->{pod}) {
      $args{href}     = $entry->{node};
      $args{module_descr} = $self->indexer->get_module_description($entry->{node})
        if $has_index;
    }
    $html .= generic_node(%args);
  }
  return $html;
}



sub main_toc {
  my ($self, $req) = @_;

  # initial page to open
  my $ini        = $req->parameters->{open};
  my $select_ini = $ini ? "selectToc('$ini');" : "";

  # perlfunc entries in JSON format for the DHTML autocompleter
  my @funcs = map {$_->title} grep {$_->content =~ /\S/} $self->perlfunc_items;
  s|[/\s(].*||s foreach @funcs;
  my $json_funcs = "[" . join(",", map {qq{"$_"}} uniq @funcs) . "]";

  # perlvar entries in JSON format for the DHTML autocompleter
  my @vars = map {$_->title} grep {!/->/} map {@$_} $self->perlvar_items;
  s|\s*X<.*||s foreach @vars;
  s|\\|\\\\|g  foreach @vars;
  s|"|\\"|g    foreach @vars;
  my $json_vars = "[" . join(",", map {qq{"$_"}} uniq @vars) . "]";

  # initial sections : perldocs, pragmas and scripts
  my @perl_sections = map {closed_node(
      label       => ucfirst($_),
      label_class => "TN_label small_title",
      attrs       =>  qq{TN:contentURL='toc/$_' id='$_'},
     )} qw/perldocs pragmas scripts/;

  # following sections : alphabetical list of modules (details will be loaded dynamically)
  my $alpha_list = "";
  for my $letter ('A' .. 'Z') {
    $alpha_list .= closed_node (
      label       => $letter,
      label_class => "TN_label",
      attrs       =>  qq{TN:contentURL='toc/$letter*' id='${letter}:'},
     );
  }
  my $modules = generic_node (label       => "Modules",
                              label_class => "TN_label small_title",
                              content     => $alpha_list);

  # build the HTML response
  my $css_links  = $self->css_links;
  my $js_scripts = $self->js_scripts;
  return $self->respond_html(<<__EOHTML__);
<html>
<head>
  <base target="contentFrame">
  $css_links
  $js_scripts
  <script>
    var treeNavigator;
    var perlfuncs  = $json_funcs;
    var perlvars   = $json_vars;
    var completers = {};

    function submit_on_event(event) {
        \$('search_form').submit();
    }

    function resize_tree_navigator() {
      // compute available height -- comes either from body or documentElement,
      // depending on browser and on compatibility mode !!
      var doc_el_height = document.documentElement.clientHeight;
      var avail_height
        = (Prototype.Browser.IE && doc_el_height) ? doc_el_height
                                                  : document.body.clientHeight;

      var tree_height = avail_height - \$('toc_frame_top').scrollHeight - 5;
      if (tree_height > 100)
        \$('TN_tree').style.height = tree_height + "px";
    }

    function open_nodes(first_node, rest) {

      var node = \$(first_node);
      if (!node || !treeNavigator) return;

      // shift to next node in sequence
      first_node = rest.shift();

      // build a handler for "onAfterLoadContent" (closure on first_node/rest)
      var open_or_select_next = function() {

        // delete handler that might have been placed by previous call
        delete treeNavigator.onAfterLoadContent;

        //
        if (rest.length > 0) {
          open_nodes(first_node, rest)
        }
        else {
          treeNavigator.openEnclosingNodes(\$(first_node));
          treeNavigator.select(\$(first_node));
        }
      };


      // if node is closed and currently has no content, we need to register
      // a handler, open the node so that it gets its content by Ajax,
      // and then execute the handler to open the rest after Ajax returns
      if (treeNavigator.isClosed(node)
          && !treeNavigator.content(node)) {
        treeNavigator.onAfterLoadContent = open_or_select_next;
        treeNavigator.open(node);
      }
      // otherwise just a direct call
      else {
        open_or_select_next();
      }

    }


    function selectToc(entry) {

      // build array of intermediate nodes (i.e "Foo", "Foo::Bar", etc.)
      var parts = entry.split(new RegExp("/|::"));
      var accu = '';
      var sequence = parts.map(function(e) {
         accu = accu ? (accu + "::" + e) : e;
         return accu;
        });

      // choose id of first_node by analysis of entry
      var initial = entry.substr(0, 1);
      var first_node

        // CASE module (starting with uppercase)
        = (initial <= 'Z')           ? (initial + ":")

        // CASE perl* documentation page
        : entry.search(/^perl/) > -1 ? "perldocs"

        // CASE other lowercase entries
        :                              "pragmas"
        ;

      // open each node in sequence
      open_nodes(first_node, sequence);
    }

    function setup() {

      treeNavigator
        = new GvaScript.TreeNavigator('TN_tree', {tabIndex:-1});

      completers.perlfunc = new GvaScript.AutoCompleter(
             perlfuncs,
             {minimumChars: 1,
              minWidth: 100,
              offsetX: -20,
              autoSuggestDelay: 400});
      completers.perlfunc.onComplete = submit_on_event;

      completers.perlvar = new GvaScript.AutoCompleter(
             perlvars,
             {minimumChars: 1,
              minWidth: 100,
              offsetX: -20,
              autoSuggestDelay: 400});
      completers.perlvar.onComplete = submit_on_event;

      completers.modlist  = new GvaScript.AutoCompleter(
             "search?source=modlist&search=",
             {minimumChars: 2, minWidth: 100, offsetX: -20, typeAhead: false});
      completers.modlist.onComplete = submit_on_event;

      resize_tree_navigator();
      $select_ini
    }

    document.observe('dom:loaded', setup);
    window.onresize = resize_tree_navigator;
    // Note: observe('resize') doesn't work. Why ?

    function displayContent(event) {
        var label = event.controller.label(event.target);
        if (label && label.tagName == "A") {
          label.focus();
          return Event. stopNone;
        }
    }

   function maybe_complete(input) {
     if (input._autocompleter)
        input._autocompleter.detach(input);

     switch (input.form.source.selectedIndex) {
       case 0: completers.perlfunc.autocomplete(input); break;
       case 1: completers.perlvar.autocomplete(input); break;
       case 3: if (!no_indexer)
                 completers.modlist.autocomplete(input);
               break;
     }
   }


  </script>
  <style>
   .small_title {color: midnightblue; font-weight: bold; padding: 0 3 0 3}
   FORM     {margin:0px}
   BODY     {margin:0px; font-size: 70%; overflow-x: hidden}
   DIV      {margin:0px; width: 100%}
   #TN_tree {overflow-y:scroll; overflow-x: hidden}
  </style>
</head>
<body>

<div id='toc_frame_top'>
<div class="small_title"
     style="text-align:center;border-bottom: 1px solid">
$self->{page_title}
</div>
<div style="text-align:right">
<a href="$self->{script_name}/Pod/POM/Web/Help" class="small_title">Help</a>
</div>

<form action="search" id="search_form" method="get" accept-charset="UTF-8">
<span class="small_title">Search in</span>
     <select name="source">
      <option>perlfunc</option>
      <option>perlvar</option>
      <option>perlfaq</option>
      <option>modules</option>
      <option>full-text</option>
     </select><br>
<span class="small_title">&nbsp;for&nbsp;</span><input
         name="search" size="15"
         autocomplete="off"
         onfocus="maybe_complete(this)">
</form>
<br>
<div class="small_title"
     style="border-bottom: 1px solid">Browse</div>
</div>

<!-- In principle the tree navigator below would best belong in a
     different frame, but instead it's in a div because the autocompleter
     from the form above sometimes needs to overlap the tree nav. -->
<div id='TN_tree' onPing='displayContent'>
@perl_sections
$modules
</div>

</body>
</html>
__EOHTML__
}

#----------------------------------------------------------------------
# searching
#----------------------------------------------------------------------

sub dispatch_search {
  my ($self, $req) = @_;

  my $params        = $req->parameters;
  my $search_string = decode_utf8($params->{search});

  for ($params->{source}) {
    /^perlfunc$/  and return $self->search_perlfunc($search_string);
    /^perlvar$/   and return $self->search_perlvar($search_string);
    /^perlfaq$/   and return $self->search_perlfaq($search_string);
    /^modules$/   and return $self->serve_module($search_string);
    /^full-text$/ and return $self->search_fulltext($search_string, $params);
    /^modlist$/   and return $self->modules_matching_prefix($search_string);

    # otherwise
    die "cannot search in '$_'";
  }
}

sub perlfunc_items {
  my ($self) = @_;

  # gather POM description of all functions in perlfunc -- lazy loading at first call
  if (!$self->{perlfunc_items}) {
    my ($func_path)  = $self->find_module("perlfunc")
      or die "'perlfunc.pod' does not seem to be installed on this system";
    my $funcpom       = $self->extract_POM($func_path, $special_podfilters{perlfunc});
    my ($description) = grep {$_->title eq 'DESCRIPTION'} $funcpom->head1;
    my ($alphalist)
      = grep {$_->title =~ /^Alphabetical Listing/i} $description->head2;
    my @items = $alphalist->over->[0]->item;
    $self->{perlfunc_items} = \@items;
  }

  return @{$self->{perlfunc_items}};
}

sub search_perlfunc {
  my ($self, $func) = @_;

  # find items matching the $func request
  my @matching_items = grep {$_->title =~ /^$func\b/} $self->perlfunc_items
     or return $self->respond_html("No documentation found for perl "
                                  ."function '<tt>$func</tt>'");
  # htmlize
  my $view      = $self->mk_view(path => "perlfunc/$func");
  my @li_items  = map {$_->present($view)} @matching_items;

  # hack the perlfunc internal links so that they call again search?source=perlfunc
  s[href="#(\w+)"][href="$self->{script_name}/search?source=perlfunc&search=$1"]g
    foreach @li_items;

  # HTML response
  my $css_links = $self->css_links;
  return $self->respond_html(<<__EOHTML__);
<html>
<head>
  $css_links
</head>
<body>
<h2>Extract from <a href="$self->{script_name}/perlfunc">perlfunc</a></h2>
<ul>@li_items</ul>
</body>
__EOHTML__
}



sub perlvar_items {
  my ($self) = @_;

  # lazily compute at first request; then store in $self
  unless ($self->{perlvar_items}) {

    # gather POM items defining variables
    my ($var_path) = $self->find_module("perlvar")
      or die "'perlvar.pod' does not seem to be installed on this system";
    my $varpom     = $self->extract_POM($var_path);
    my @items      = extract_POM_items($varpom);

    # group items having common content
    my $tmp = [];
    foreach my $item (@items) {
      push @$tmp, $item;
      if ($item->content . "") { # force stringification
        push @{$self->{perlvar_items}}, $tmp;
        $tmp = [];
      }
    }
  };

  return @{$self->{perlvar_items}};
}


sub search_perlvar {
  my ($self, $var) = @_;

  # HTML list of items matching the $func request
  my @items = grep {any { $_->title =~ /^\Q$var\E(\s|$)/ } @$_}
                   $self->perlvar_items
     or return $self->respond_html("No documentation found for perl "
                                  ."variable '<tt>$var</tt>'");
  my $view      = $self->mk_view(path => "perlvar/$var");
  my @li_items  = map {$_->present($view)} map {@$_} @items;

  # HTML response
  my $css_links = $self->css_links;
  return $self->respond_html(<<__EOHTML__);
<html>
<head>
  $css_links
</head>
<body>
<h2>Extract from <a href="$self->{script_name}/perlvar">perlvar</a></h2>

<ul>@li_items</ul>
</body>
__EOHTML__
}



sub search_perlfaq {
  my ($self, $faq_entry) = @_;
  my $regex = qr/\b\Q$faq_entry\E\b/i;
  my $answers   = "";
  my $n_answers = 0;

  my $view = $self->mk_view(path => "perlfaq/$faq_entry");

  # gather headings that match the regex in any of the perlfaq* pages
 FAQ:
  foreach my $faq (map {"perlfaq$_"} 1..9) {
    my ($faq_path) = $self->find_module($faq)
      or die "'$faq.pod' does not seem to be installed on this system";
    my $faqpom    = $self->extract_POM($faq_path);
    my @questions = map {grep {$_->title =~ $regex} $_->head2} $faqpom->head1
      or next FAQ;
    my @nodes = map {$view->print($_)} @questions;
    my $html  = join "", @nodes;

    my @split_on_tags = split /(<.*?>)/, $html;
    for (my $i = 0; $i < @split_on_tags; $i += 2) {
      $split_on_tags[$i] =~ s[($regex)][<span class="hl">$1</span>]g;
    }
    $html = join "", @split_on_tags;


    $answers .= generic_node(label     => "Found in $faq",
                             label_tag => "h2",
                             content   => $html);
    $n_answers += @nodes;
  }

  # HTML response
  my $css_links  = $self->css_links;
  my $js_scripts = $self->js_scripts;
  return $self->respond_html(<<__EOHTML__);
<html>
<head>
  $css_links
  $js_scripts
  <style>
    .hl  {background-color: lightpink}
  </style>
  <script>
    var treeNavigator;
    function setup() {
      treeNavigator = new GvaScript.TreeNavigator('TN_tree');
    }
    window.onload = setup;
   </script>
</head>
<body>
<h1>Extracts from <a href="$self->{script_name}/perlfaq">perlfaq</a></h1><br>
<em>searched for regex '$faq_entry' in titles of faq documents: $n_answers answers</em><br><br>
<div id='TN_tree'>
$answers
</div>
</body>
__EOHTML__

}


sub search_fulltext {
  my ($self, $search_string, $params) = @_;

  # start of HTML page
  my $css_links = $self->css_links;
  my $html = <<__EOHTML__;
<html>
<head>
  $css_links
  <style>
    .src {font-size:70%; float: right}
    .sep {font-size:110%; font-weight: bolder; color: magenta;
          padding-left: 8px; padding-right: 8px}
    .hl  {background-color: lightpink}
    .reindex_form {float: right; border: 3px double #888;}

  </style>
  <script>
    function confirm_reindex() {
       var want_reindex = confirm("This action may take a few minutes. The index will use " +
                                  "about 20MB on your hard disk. Proceed ?");
       if (want_reindex) 
         document.getElementById('ft_results').innerHTML 
             = "Reindex in progress, please wait...";

       return want_reindex;
    }
  </script>
</head>
<body>

<form class="reindex_form" action="$self->{script_name}/ft_index"
  onsubmit="return confirm_reindex()">
(Re)generate index
<label><input type=radio name=from_scratch value=0 checked>incrementally</label>
<label><input type=radio name=from_scratch value=1>from scratch</label>
<input type=submit value=Go>
</form>

<div id="ft_results">
__EOHTML__

  # main content
  if (!$self->indexer->has_index) {
    $html .= "No full-text index found in $self->{index_dir}."
          .  "Please use the form above to generate the index";
  }
  else {
    my $count         = $params->{count} || 50;
    my $start_record  = $params->{start} || 0;
    my $end_record    = $start_record + $count - 1;

    # callback function used by the indexer to access the content of documents
    my $get_doc_content = sub {
      my $path = shift;
      my @filenames = $self->find_module($path);
      return join "\n", map {slurp_native_or_utf8($_)} @filenames;
    };

    # results from the indexer
    my $results = $self->indexer->search($search_string, $start_record, $end_record,
                                         $get_doc_content);
    my $killedWords = join ", ", @{$results->{killedWords}};
    $killedWords &&= " (ignoring words : $killedWords)";

    # adjust numbers
    my $n_in_slice = @{$results->{modules}};
    $end_record    = $start_record + $n_in_slice -1;
    my $n_total    = $results->{n_total};

    # build navigation links
    my $base_url  = encode_utf8("?source=full-text&search=$search_string");
    my $nav_links = $self->nav_links($base_url, $start_record, $end_record, $count, $n_total);

    # more HTML content
    $html .= "<b>Full-text search</b> for '$search_string'$killedWords<br>"
           . "$nav_links<hr>\n";

    # generate HTML for each result 
    foreach my $module (@{$results->{modules}}) {
      my ($path, $description, $excerpts) = @$module;
      foreach (@$excerpts) {
        s/&/&amp;/g,  s/</&lt;/g, s/>/&gt;/g;          # replace entities
        s/\[\[/<span class='hl'>/g, s/\]\]/<\/span>/g; # highlight
      }
      my $lst_excerpts = join "<span class='sep'>/</span>", @$excerpts;
      $html .= "<p>"
             . "<a href='$self->{script_name}/source/$path' class='src'>source</a>"
             . "<a href='$self->{script_name}/$path'>$path</a>"
             . ($description ? " <em>$description</em>" : "")
             . "<br>"
             . "<small>$lst_excerpts</small>"
             . "</p>";
    }
    $html .= "<hr>$nav_links\n";
  }

  # finish the page
  $html .= "</div></body></html>";

  # respond
  return $self->respond_html($html);
}



sub nav_links {
  my ($self, $base_url, $start_record, $end_record, $n_slice, $n_total) = @_;

  my $prev_idx  = max($start_record - $n_slice, 0);
  my $next_idx  = $start_record + $n_slice;
  my $prev_link = $start_record > 0    ? "$base_url&start=$prev_idx" : "";
  my $next_link = $next_idx < $n_total ? "$base_url&start=$next_idx" : "";

  # URI escape
  s{([^;\/?:@&=\$,A-Za-z0-9\-_.!~*'()])}
   {sprintf("%%%02X", ord($1))         }ge for $prev_link, $next_link;

  $_ += 1 for $start_record, $end_record;
  my $nav_links = "";
  $nav_links .= "<a href='$prev_link'>[Previous &lt;&lt;]</a> " if $prev_link;
  $nav_links .= "Results <b>$start_record</b> to <b>$end_record</b> "
              . "from <b>$n_total</b>";
  $nav_links .= " <a href='$next_link'>[&gt;&gt; Next]</a> " if $next_link;
  return $nav_links;
}


sub modules_matching_prefix { # called by Ajax
  my ($self, $search_string) = @_;

  $self->indexer->has_index
    or die "module list : no index";

  my @matching_modules = $self->indexer->modules_matching_prefix($search_string);
  my $json    = "[" . join(",", map {qq{"$_"}} sort @matching_modules) . "]";

  return $self->respond(content   => $json,
                        mime_type => 'application/x-json');
}



#----------------------------------------------------------------------
# updating the fulltext index
#----------------------------------------------------------------------


sub ft_index {
  my ($self, $req) = @_;

  # free the indexer
  delete $self->{indexer};

  # start another process for updating or building the fulltext index
  my $command = "index";
  $command .= "(from_scratch=>1)" if $req->parameters->get('from_scratch');
  warn "STARTING COMMAND $command\n";
  open my $pipe, '-|', qq{perl -Ilib -MPod::POM::Web -e "$command"};

  # pipe progress reports from the subprocess into the HTTP response,
  # using Plack's streaming API
  my $res = Plack::Response->new(200);
  $res->content_type('text/plain');
  $res->body($pipe);
  return $res->finalize;
}

#----------------------------------------------------------------------
# encapsulation of Plack response
#----------------------------------------------------------------------


sub respond_html {
  my ($self, $html, $mtime) = @_;

  $self->respond(content => encode_utf8($html),
                 code    => 200,
                 mtime   => $mtime,
                 charset => 'UTF-8');
}



sub respond {
  my ($self, %args) = @_;

  my $charset   = $args{charset};
  my $length    = length $args{content};
  my $mime_type = $args{mime_type} || "text/html";
     $mime_type .= "; charset=$charset" if $charset and $mime_type =~ /html/;
  my $code      = $args{code} || 200;
  my $headers   = {Content_type   => $mime_type,
                   Content_length => $length};
  $headers->{Last_modified} = gmtime($args{mtime}) if $args{mtime};
  my $r = Plack::Response->new($code, $headers, $args{content});
  $r->finalize;
}


#----------------------------------------------------------------------
# miscellaneous
#----------------------------------------------------------------------

sub mk_view {
  my ($self, %args) = @_;

  my $view = Pod::POM::View::HTML::_PerlDoc->new(
    script_name => $self->{script_name},
    css_links   => $self->css_links,
    js_scripts  => $self->js_scripts,
    %args
   );

  return $view;
}

sub find_module { 
  my ($self, $path) = @_;
  return $self->find_files(module_dirs => "$path.pod", "$path.pm",
                                          "pod/$path.pod", "pods/$path.pod");
}

sub find_script {
  my ($self, $path) = @_;
  return $self->find_files(script_dirs => $path, "$path.pl", "path.bat");
}

sub find_files {
  my ($self, $dirs_method, @file_candidates) = @_;

  # try each dir in turn. The first successful search wins.
  foreach my $dir ($self->$dirs_method) {
    my @found = grep {-f} map {"$dir/$_"} @file_candidates;
    return @found if @found; # returns a list because there could be both a *.pm and *.pod
  }

  # empty list if nothing is found
  return;
}

sub css_links {
  my ($self) = @_;

  my @css   = qw(Alien/GvaScript/lib/GvaScript.css Pod/POM/Web/lib/PodPomWeb.css);
  my @links = map {"<link href='$self->{script_name}/$_' rel='stylesheet' type='text/css'>\n"}
                  @css;

  return join "", @links;
}

sub js_scripts {
  my ($self) = @_;

  my @src     = qw(Alien/GvaScript/lib/prototype.js Alien/GvaScript/lib/GvaScript.js);
  my @scripts = map {"<script src='$self->{script_name}/$_'></script>\n"} @src;

  return join "", @scripts;
}


#----------------------------------------------------------------------
# generating GvaScript treeNavigator structure
#----------------------------------------------------------------------

sub generic_node {
  my %args = @_;
  $args{class}       ||= "TN_node";
  my $attrs            = $args{attrs} ? " $args{attrs}" : "";
  $args{content}     ||= "";
  $args{content}     &&= qq{<div class="TN_content">$args{content}</div>};
  my ($default_label_tag, $label_attrs)
    = $args{href} ? ("a",    qq{ href='$args{href}'})
                  : ("span", ""                     );
  $args{label_tag}   ||= $default_label_tag;
  $args{label_class} ||= "TN_label";
  if ($args{module_descr}) {
    my $module_descr = Plack::Util::encode_html($args{module_descr});
    $label_attrs .= qq{ title="$module_descr"};
  }
  return qq{<div class="$args{class}"$attrs>}
       .    qq{<$args{label_tag} class="$args{label_class}"$label_attrs>}
       .         $args{label}
       .    qq{</$args{label_tag}>}
       .    $args{content}
       . qq{</div>};
}

sub closed_node {
  return generic_node(@_, class => "TN_node TN_closed");
}

sub leaf {
  return generic_node(@_, class => "TN_leaf");
}

1;
#======================================================================
# END OF package Pod::POM::Web
#======================================================================


#======================================================================
package Pod::POM::View::HTML::_PerlDoc; # View package
#======================================================================
use strict;
use warnings;
no warnings         qw/uninitialized/;
use base            qw/Pod::POM::View::HTML/;
use POSIX           qw/strftime/;              # date formatting
use List::MoreUtils qw/firstval/;
use Plack::Util;



# SUPER::view_seq_text tries to find links automatically ... but is buggy
# for URLs that contain '$' or ' '. So we disable it, and only consider
# links explicitly marked with L<..>, handled in view_seq_link() below.
sub view_seq_text {
  my ($self, $text) = @_;

  for ($text) {
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
  }

  return $text;
}



# some adaptations to SUPER::view_seq_link
sub view_seq_link {
  my ($self, $link) = @_;


  # we handle the L<link_text|...> syntax here, because we also want
  # link_text for http URLS (not supported by SUPER::view_seq_link)
  my $link_text;
  $link =~ s/^([^|]+)\|// and $link_text = $1;

  # links to external resources will open in a blank page
  my $is_external_resource = ($link =~ m[^\w+://]);

  # call parent and reparse the result
  my $linked = $self->SUPER::view_seq_link($link);
  my ($url, $label) = ($linked =~ m[^<a href="(.*?)">(.*)</a>]);

  # fix link for 'hash' part of the url
  $url =~ s[#(.*)]['#' . _title_to_id($1)]e unless $is_external_resource;

  # if explicit link_text given by client, take that as label, unchanged
  if ($link_text) {
    $label = $link_text;
  }
  # if "$page/$section", replace by "$section in $page"
  elsif ($label !~ m{^\w+://}s) { # but only if not a full-blown URL
    $label =~ s[^(.*?)/(.*)$][$1 ? "$2 in $1" : $2]e ;
  }

  # return link (if external resource, opens in a new browser window)
  my $target = $is_external_resource ? " target='_blank'" : "";
  return qq{<a href="$url"$target>$label</a>};
}



sub view_seq_link_transform_path {
  my($self, $page) = @_;
  $page =~ s[::][/]g;
  return "$self->{script_name}/$page";
}


sub view_item {
  my ($self, $item) = @_;

  my $title = eval {$item->title->present($self)} || "";
     $title = "" if $title =~ /^\s*\*\s*$/;

  my $class = "";
  my $id    = _title_to_id($title);
  $id &&= qq{ id="$id"};

  my $content = $item->content->present($self);
  $title   = qq{<b>$title</b>} if $title;
  return qq{<li$id$class>$title\n$content</li>\n};
}



sub _title_to_id {
  my $title = shift;
  $title =~ s/<.*?>//g;          # no tags
  $title =~ s/[,(].*//;          # drop argument lists or text lists
  $title =~ s/\s*$//;            # drop final spaces
  $title =~ s/[^A-Za-z0-9_]/_/g; # replace chars unsuitable for an id
  return $title;
}


sub view_pod {
  my ($self, $pom) = @_;

  # compute view
  my $content = $pom->content->present($self)
    or return "no documentation found in <tt>$self->{path}</tt><br>\n"
            . "<a href='$self->{script_name}/source/$self->{path}'>Source</a>";

  # parse name and description
  my $name_h1   = firstval {$_->title =~ /^(NAME|TITLE)\b/} $pom->head1();
  my $doc_title = $name_h1 ? $name_h1->content->present('Pod::POM::View')
                                               # retrieve content as plain text
                           : 'Untitled';
  my ($name, $description) = ($doc_title =~ /^\s*(.*?)\s+-+\s+(.*)/);
  $name ||= $doc_title;
  $name =~ s/\n.*//s;

  # installation date
  my $installed = strftime("%x", localtime($self->{mtime}));

  # if this is a module (and not a script), get additional info
  my ($version, $core_release, $orig_version, $module_refs) = ("") x 5;
  if (my $mod_name = $self->{mod_name}) {

    # version
    $version = $self->{version} ? "v. $self->{version}, " : "";

    # is this module in Perl core ?
    $core_release = Module::CoreList->first_release($mod_name) || "";
    $orig_version
      = $Module::CoreList::version{$core_release}{$mod_name} || "";
    $orig_version &&= "v. $orig_version ";
    $core_release &&= "; ${orig_version}entered Perl core in $core_release";

    # latest CPAN version
    my $latest_version = $self->{cpan_version} ? " (v. $self->{cpan_version})" : "";

    # hyperlinks to various internet resources
    $module_refs = qq{<br>
     <a href="https://metacpan.org/pod/$mod_name"
        target="_blank">meta::cpan$latest_version</a>
    };
  }

  my $toc        = $self->make_toc($pom, 0);
  my $css_links  = $self->{css_links};
  my $js_scripts = $self->{js_scripts};
  return <<__EOHTML__
<html>
<head>
  <title>$name</title>
  $css_links
  $js_scripts
  <script>
    var treeNavigator;
    function setup() {
      new GvaScript.TreeNavigator(
         'TN_tree',
         {selectFirstNode: (location.hash ? false : true),
          tabIndex: 0}
      );

     var tocFrame = window.parent.frames.tocFrame;
     if (tocFrame) {
       try {tocFrame.eval("selectToc('$name')")}
       catch(e) {};
      }
    }
    window.onload = setup;
    function jumpto_href(event) {
      var label = event.controller.label(event.target);
      if (label && label.tagName == "A") {
        /* label.focus(); */
        return Event.stopNone;
      }
    }
  </script>
  <style>
    #TOC .TN_content .TN_label {font-size: 80%; font-weight: bold}
    #TOC .TN_leaf    .TN_label {font-weight: normal}

    #ref_box {
      clear: right;
      float: right;
      text-align: right;
      font-size: 80%;
    }
    #title_descr {
       clear: right;
       float: right;
       font-style: italic;
       margin-top: 8px;
       margin-bottom: 8px;
       padding: 5px;
       text-align: center;
       border: 3px double #888;
    }
  </style>
</head>
<body>
<div id='TN_tree'>
  <div class="TN_node">
   <h1 class="TN_label">$name</h1>
   <small>(${version}installed $installed$core_release)</small>
   <span id="title_descr">$description</span>
   <span id="ref_box">
   <a href="$self->{script_name}/source/$self->{path}">Source</a>
   $module_refs
   </span>

   <div class="TN_content">
     <div class="TN_node"  onPing="jumpto_href" id="TOC">
       <h3 class="TN_label">Table of contents</h3>
       <div class="TN_content">
         $toc
       </div>
     </div>
     <hr/>
   </div>
  </div>
$content
</div>
</body>
</html>
__EOHTML__

}

# generating family of methods for view_head1, view_head2, etc.
BEGIN {
  for my $num (1..6) {
    no strict 'refs';
    *{"view_head$num"} = sub {
      my ($self, $item) = @_;
      my $title   = $item->title->present($self);
      my $id      = _title_to_id($title);
      my $content = $item->content->present($self);
      my $h_num   = $num + 1;
      return <<EOHTML
  <div class="TN_node" id="$id">
    <h$h_num class="TN_label">$title</h$h_num>
    <div class="TN_content">
      $content
    </div>
  </div>
EOHTML
    }
  }
}


sub view_seq_index {
  my ($self, $item) = @_;
  return ""; # Pod index tags have no interest for HTML
}


sub view_verbatim {
  my ($self, $text) = @_;

  my $coloring = $self->{syntax_coloring};
  if ($coloring) {
    my $method = "${coloring}_coloring";
    $text = $self->$method($text);
  }
  else {
    $text = Plack::Util::encode_html($text);
  }

  # hyperlinks to other modules
  $text =~ s{(\buse\b(?:</span>)?\ +(?:<span.*?>)?)([\w:]+)}
            {my $url = $self->view_seq_link_transform_path($2);
             qq{$1<a href="$url">$2</a>} }eg;

  if ($self->{line_numbering}) {
    my $line = 1;
    $text =~ s/^/sprintf "%6d\t", $line++/egm;
  }
  return qq{<pre class="$coloring">$text</pre>};
}



sub PPI_coloring {
  my ($self, $text) = @_;
  my $ppi = PPI::HTML->new();
  my $html = $ppi->html(\$text);

  if ($html) {
    $html =~ s/<br>//g;
    return $html;
  }
  else { # PPI failed to parse that text
    return Plack::Util::encode_html($text);
  }
}


sub SCINEPLEX_coloring {
  my ($self, $text) = @_;
  eval {
    $text = ActiveState::Scineplex::Annotate($text,
                                             'perl',
                                             outputFormat => 'html');
  };
  return $text;
}


sub make_toc {
  my ($self, $item, $level) = @_;

  my $html      = "";
  my $method    = "head" . ($level + 1);
  my $sub_items = $item->$method;

  foreach my $sub_item (@$sub_items) {
    my $title   = $sub_item->title->present($self);
    my $id      = _title_to_id($title);

    my $node_content = $self->make_toc($sub_item, $level + 1);
    my $class        = $node_content ? "TN_node" : "TN_leaf";
    $node_content  &&= qq{<div class="TN_content">$node_content</div>};

    $html .= qq{<div class="$class">}
           .    qq{<a class="TN_label" href="#$id">$title</a>}
           .    $node_content
           . qq{</div>};
  }

  return $html;
}


sub DESTROY {} # avoid AUTOLOAD

1;



__END__

=encoding ISO8859-1

=head1 NAME

Pod::POM::Web - HTML Perldoc server

=head1 DESCRIPTION

L<Pod::POM::Web> is a Web application for browsing
the documentation of Perl components installed
on your local machine. Since pages are dynamically
generated, they are always in sync with code actually
installed.

The application offers

=over

=item *

a tree view for browsing through installed modules
(with dynamic expansion of branches as they are visited)

=item *

a tree view for navigating and opening / closing sections while
visiting a documentation page

=item *

a source code view with hyperlinks between used modules
and optionally with syntax coloring
(see section L</"Optional features">)


=item *

direct access to L<perlfunc> entries (builtin Perl functions)

=item *

search through L<perlfaq> headers

=item *

full-text search, including names of Perl variables
(this is an optional feature -- see section L</"Optional features">).

=item *

parsing and display of version number

=item *

display if and when the displayed module entered Perl core.

=item *

parsing pod links and translating them into hypertext links

=item *

links to MetaCPAN

=back

The application may be hosted by an existing Web server, or otherwise
may run its own builtin Web server. Instructions for launching the application
are given in the next section.

Usage of the application is described in a separate document
L<Pod::POM::Web::Help>.

=head1 STARTING THE WEB APPLICATION



=head2 Starting from the command-line

The simplest way to use this application is to start a process invoking
the builtin HTTP server :

  perl -MPod::POM::Web -e server

This is useful if you have no other HTTP server, or if
you want to run this module under the perl debugger.
The server will listen at L<http://localhost:5000>.
A different port may be specified  :

  perl -MPod::POM::Web -e server -- -p 8888

Notice the double dash C<--> : this is used to separate options to the
C<perl> command itself from options to C<Pod::POM::Web>.

The internal implementation of C<server> is based on L<Plack::Runner>, the same
module that also supports the L<plackup> utility. All plackup options
can also be used here -- see plackup's documentation.

Another way to start the server is to call C<plackup> directly :

  plackup -MPod::POM::Web -e app -p 8888

In this case no double dash is required.


=head3 As a cgi-bin script

Alternatively, you can run this application as a cgi-script
by writing a simple file F<perldoc> in your C<cgi-bin> directory,
containing :

  #!/path/to/perl
  use Pod::POM::Web;
  use Plack::Handler::CGI;

  my $app = Pod::POM::Web->new->to_app;
  Plack::Handler::CGI->new->run($app);


For historical reasons, the module also supports a simpler invocation,
written as follows :

  #!/path/to/perl
  use Pod::POM::Web;
  Pod::POM::Web->handler;

Make this script executable,
then navigate to URL L<http://localhost/cgi-bin/perldoc>.


=head3 Other Web architectures -- PSGI

The application is built on top of the well-known L<Plack> middleware for
web applications, using the L<PSGI> protocol. Therefore it can be integrated 
easily in various Web architectures. Write a F<.psgi> file as follows :

  use Pod::POM::Web;
  Pod::POM::Web->new->to_app;

and invoke one of the Web server adapters under L<Plack::Handler>.



=head2 Opening a specific initial page

By default, the initial page displayed by the application
is F<perl>. This can be changed by supplying an C<open> argument
with the path to any documentation page: for example

  http://localhost:8080?open=Pod/POM/Web
  http://localhost:8080?open=perlfaq

=head2 Setting a specific title

If you run several instances of C<Pod::POM::Web> simultaneously, you may
want them to have distinct titles. This can be done like this:

  perl -MPod::POM::Web -e server -- --title "My Own Perl Doc"


=head1 MISCELLANEOUS

=head2 Note about security

This application is intended as a power tool for Perl developers,
not as an Internet application. It will give read access to any file
installed under your C<@INC> path or Apache C<lib/perl> directory;
so it is probably a B<bad idea>
to put it on a public Internet server.


=head2 Optional features

=head3 Syntax coloring

Syntax coloring improves readability of code excerpts.
If your Perl distribution is from ActiveState, then
C<Pod::POM::Web> will take advantage
of the L<ActiveState::Scineplex> module
which is already installed on your system. Otherwise,
you need to install L<PPI::HTML>, available from CPAN.

=head3 Full-text indexing

C<Pod::POM::Web> can index the documentation and source code
of all your installed modules, including Perl variable names,
C<Names:::Of::Modules>, etc. To use this feature you need to

=over

=item *

install L<Search::Indexer> from CPAN

=item *

build the index as described in L<Pod::POM::Web::Indexer> documentation.

=back


=head3 Indication of the latest CPAN version

When displaying a module, L<CPAN::Common::Index> is used to try to identify the
latest CPAN version of that module. By default the information comes from
C<http://cpanmetadb.plackperl.org/v1.0/>, but it requires an internet connection.
If a local installation of L<CPAN::Mini> is available, this will be used as
a primary source of information.



=head1 HINTS TO POD AUTHORING

=head2 Images

The Pod::Pom::Web server also serves non-pod files within the C<@INC>
hierarchy. This is useful for example to include images in your
documentation, by inserting chunks of HTML as follows :

  =for html
    <img src="pretty_diagram.jpg">

or

  =for html
    <object type="image/svg+xml" data="try.svg" width="640" height="480">
    </object>

Here it is assumed that auxiliary files C<pretty_diagram.jpg> or
C<try.svg> are in the same directory than the POD source; but
of course relative or absolute links can be used.



=head1 CLASS METHODS

=head2 import

When the module is C<use>d from the command-line, the C<import> method
automatically exports a C<server> function and an C<app> function to
facilitate server startup.

=head2 server

Invokes L<Plack::Runner> to launch the server.

=head2 app

Creates an instance of the module and returns a L<PSGI> app.

Options from the command-line that are not consumed by L<plackup>
are read and passed to to the L<new> method. Available options are :

=over

=item C<page_title> or C<title>

Title for this instance of the application.

=item C<module_dirs> or C<mdirs>

Additional directories to search for modules.

=item C<script_dirs> or C<sdirs>

Additional directories to search for scripts.

=back


=head2 handler

Legacy class method, used by CGI scripts or mod_perl handlers.

=head2 new

Constructor. May take the following arguments :

=over 

=item C<page_title>

for specifying the HTML title
of the application (useful if you run several concurrent instances
of Pod::POM::Web).

=item C<module_dirs>

directories for searching for modules,
in addition to the standard ones installed with your perl executable.

=item C<script_dirs>

additional directories for searching for scripts

=item C<script_name>

URL fragment to be prepended before each internal hyperlink.

=back


=head1 INSTANCE METHODS

Instance methods are not meant to be called by external clients.
Some documentation can be found in the source code.



=head1 ACKNOWLEDGEMENTS

This web application was deeply inspired by :

=over

=item *

the structure of HTML Perl documentation released with
ActivePerl (L<http://www.activeperl.com/ASPN/Perl>).


=item *

the  excellent tree navigation in Microsoft's former MSDN Library Web site
-- since they rebuilt the site, keyboard navigation has gone  !

=item *

the standalone HTTP server implemented in L<Pod::WebServer>.

=item *

the wide possibilities of Andy Wardley's L<Pod::POM> parser.

=back

Thanks
to Philippe Bruhat who mentioned a weakness in the API,
to Chris Dolan who supplied many useful suggestions and patches,
to Rémi Pauchet who pointed out a regression bug with Firefox CSS,
to Alexandre Jousset who fixed a bug in the TOC display,
to Cédric Bouvier who pointed out a IO bug in serving binary files,
to Elliot Shank who contributed the "page_title" option,
to Olivier 'dolmen' Mengué who suggested to export "server" into C<main::>,
to Ben Bullock who added the 403 message for absent modules,
and to Paul Cochrane for several improvements in the doc and in the
repository structure.

=head1 AUTHOR

Laurent Dami, C<< <dami AT cpan DOT org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2007-2021 Laurent Dami, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

