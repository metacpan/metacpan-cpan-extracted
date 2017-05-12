

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.04    |25.04.2006| JSTENZEL | added INDEXCLOUD support;
# 0.03    |09.04.2006| JSTENZEL | new option -acceptedFormat;
#         |          | JSTENZEL | file test adapted to new IMPORT: directive;
#         |22.04.2006| JSTENZEL | new option -version;
# 0.02    |09.12.2005| JSTENZEL | main stream now produces stack objects as well, but
#         |          |          | still outside the special "streamframe" wrapper;
#         |          | JSTENZEL | new option -mainstream;
#         |06.01.2006| JSTENZEL | runParser() supports nested table setting;
#         |08.01.2006| JSTENZEL | "pp2tdo" became "perlpoint", adapted POD;
# 0.01    |25.05.2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Generator> - generic PerlPoint generator

=head1 VERSION

This manual describes version B<0.04>.

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 METHODS

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION ======================================================================

# declare package
package PerlPoint::Generator;

# declare package version and author
$VERSION=0.04;
$AUTHOR=$AUTHOR='J. Stenzel (perl@jochen-stenzel.de), 2003-2006';


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;

# declare object data fields
use fields qw(
              anchorfab
              backend
              buffer
              build
              chapterdata
              cfg
              document
              help
              latest
              optionlist
              options
              pages
              pkg
              safe
              template
             );


# = LIBRARY SECTION ======================================================================

# load modules
use Carp;
use Safe;
use File::Path;
use Getopt::Long;
use File::Basename;
use PerlPoint::Tags;
use Pod::Simple::Text;
use PerlPoint::Anchors;
use PerlPoint::Template;
use File::Copy qw(copy);
use PerlPoint::Parser 0.40;
use PerlPoint::Constants 0.17;
use Cwd qw(:DEFAULT abs_path);
use Storable qw(nstore retrieve);
use Getopt::ArgvFile qw(argvFile);
use PerlPoint::Generator::Object::Page;


# = CODE SECTION =========================================================================

# class data: formatter name table
my %formatters=(
                # most type are set up by constants
                DIRECTIVE_SIMPLE()              => 'formatSimple',
                DIRECTIVE_BLOCK()               => 'formatBlock',
                DIRECTIVE_COMMENT()             => 'formatComment',
                DIRECTIVE_DLIST()               => 'formatDlist',
                DIRECTIVE_DPOINT()              => 'formatDpoint',
                DIRECTIVE_DPOINT_ITEM()         => 'formatDpointItem',
                DIRECTIVE_DPOINT_TEXT()         => 'formatDpointText',
                DIRECTIVE_HEADLINE()            => 'formatHeadline',
                DIRECTIVE_OLIST()               => 'formatOlist',
                DIRECTIVE_OPOINT()              => 'formatOpoint',
                DIRECTIVE_TAG()                 => 'formatTag',
                DIRECTIVE_TEXT()                => 'formatText',
                DIRECTIVE_ULIST()               => 'formatUlist',
                DIRECTIVE_UPOINT()              => 'formatUpoint',
                DIRECTIVE_VERBATIM()            => 'formatVerbatim',
                DIRECTIVE_DSTREAM_ENTRYPOINT()  => 'formatDStreamEntrypoint',

                # a few more are set up by strings
                DSTREAMFRAME                    => 'formatDStreamFrame',
                PAGE                            => 'formatPage',
               );


=pod

=head2 new()


B<Parameters:>

=over 4

=item class

The class name.

=back

B<Returns:> the new object.

B<Example:>


=cut
sub new
 {
  # get parameter
  my ($class, %params)=@_;

  # check parameters
  confess "[BUG] Missing class name.\n" unless $class;
  confess "[BUG] Missing target language parameter.\n" unless exists $params{options}{target} or exists $params{options}{help} or exists $params{options}{version};
  confess "[BUG] This method should be called via its own package only.\n" unless $class eq __PACKAGE__;

  # declarations
  (my __PACKAGE__ $plugin, my $stylepath);

  # init style directory setting
  $params{options}{styledir}=['.'] unless exists $params{options}{styledir};

  # check style settings
  if (exists $params{options}{style})
    {
     # add the style directories subdir "lib" to the Perl include path
     # (this is potentially dangerous because there might be a "lib" subdirectory in the
     # start directory when someone starts without -styledir, but probably there is no
     # PerlPoint::Generator subclass there - so it should cause no trouble, and "lib" is
     # an intuitive name, so we stay with this)
     unshift(@INC, "$_/$params{options}{style}/lib") for @{$params{options}{styledir}};

     # check for a configuration file (first search subdirectory "cfg" (new convention),
     # then fallback to the traditional direct access (style directory itself)
     my $cfg=(grep(-e "$_/$params{options}{style}/cfg/$params{options}{style}.cfg", @{$params{options}{styledir}}))[0];

     # anything found?
     if (defined $cfg)
       {
        # store style path
        $stylepath=$cfg;

        # complete configuration path
        $cfg.="/$params{options}{style}/cfg/$params{options}{style}.cfg";
       }
     else
       {
        # fallback to traditional path
        $cfg=(grep(-e "$_/$params{options}{style}/$params{options}{style}.cfg", @{$params{options}{styledir}}))[0];

        # anything found?
        if (defined $cfg)
          {
           # store style path
           $stylepath=$cfg;

           # complete configuration path
           $cfg.="/$params{options}{style}/$params{options}{style}.cfg";
          }
       }

     # anything found?
     if (defined $cfg)
       {
        # great, we found a style definition, add it to the option list
        unshift(@ARGV, "\@$cfg");
       }
     else
       {
        # oops!
        die "[Fatal] No style definition \"$params{options}{style}/cfg/$params{options}{style}.cfg\" to be found in style directories (", join(', ', @{$params{options}{styledir}}), ").\n";
       }
    }

  # any target setting passed?
  if ($params{options}{target})
    {
     # try to load the language class
     my $pluginClass=join('::', $class, uc($params{options}{target}));
     eval "require $pluginClass" or die "[Fatal] Missing plugin $pluginClass, please install it ($@).\n";
     die $@ if $@;

     # set default formatter, if necessary
     $params{options}{formatter}='Default' unless exists $params{options}{formatter};

     # normalize formatter name
     # $params{options}{formatter}=join('::', map {ucfirst(lc)} split('::', $params{options}{formatter}));

     # build an object of the *plugin* class and check it
     $plugin=$pluginClass->new(formatter=>$params{options}{formatter}, %params);
     confess "[BUG] $pluginClass does not inherit from ", __PACKAGE__, ".\n" unless $plugin->isa(__PACKAGE__);
    }
  else
    {
     # no target specified, so build an object of your own class
     # (this is only allowed to make -help work)
     $plugin=fields::new($class);
    }

  # store more data
  $plugin->{pkg}=exists $params{package} ? $params{package} : caller;

  # perform further initializations
  $plugin->{anchorfab}=new PerlPoint::Anchors('__FINISH__');

  # complete option set
  $plugin->{options}={
                      exists $params{options}{style}    ? (style    => $params{options}{style}) : (),
                      exists $params{options}{styledir} ? (styledir => $params{options}{styledir}) : (),
                      target    => uc($params{options}{target}),
                      formatter => $params{options}{formatter},
                      exists $params{options}{help}     ? (help     => $params{options}{help}) : (),
                      exists $params{options}{version}  ? (version  => $params{options}{version}) : (),
                     };

  # add configuration setting
  $plugin->{cfg}{setup}{stylepath}=$stylepath;

  # perform inits
  $plugin->{build}{docstream}=undef;
  $plugin->{build}{listclosingops}=[];
  $plugin->{build}{listlevels}=[0];
  $plugin->{build}{listtypes}=[];
  $plugin->{build}{nestedTables}=0;
  $plugin->{build}{sourcefilters}=[];
  $plugin->{build}{stack}=[];
  $plugin->{build}{streamData}=[];
  $plugin->{pages}=[new PerlPoint::Generator::Object::Page()];

  # perform bootstrap
  $plugin->bootstrap();

  # all options should be processed now
  Getopt::Long::Configure(qw(no_pass_through));
  die "[Fatal] Unknown options: please use the correct -target and -style settings.\n"
    unless GetOptions();

  # check for a version report request
  if (exists $plugin->{options}{version})
    {
     exit;
    }

  # check for a help request
  if (exists $plugin->{options}{help})
    {
     # build a helper object to parse and display the help texts
     my $helper=new Pod::Simple::Text;

     # collect help text hashes from the main script and from both generators and template
     # engines (templates first: this way, their synopsis is displayed *after* the general
     # synopsis of the generator)
     $plugin->addHelp($plugin, 'main');
     $plugin->addHelp($plugin->{template}, ref($plugin->{template}), 'PerlPoint::Template') if exists $plugin->{template};
     $plugin->addHelp($plugin, ref($plugin));

     no strict 'refs';
     my $package=__PACKAGE__;
     my $pod=join("\n",
                  "=pod",
                  "",
                  "=head1 NAME",
                  "",
                  basename($0),
                  "- This is a ", ref($plugin), " converter.\n\n",
                  "",
                  "=head1 VERSION",
                  "",
                  ${join('::', $plugin->{pkg}, 'VERSION')},
                  "",
                  "=head1 INVOCATION",
                  "",
                  (exists $plugin->{options}{target} and $plugin->{options}{target}) ?
                    (
                     "You are going to produce $plugin->{options}{target} with a",
                     (ref($plugin)=~/${package}::(.+)/),
                     exists $plugin->{template} ? ("formatter using", (ref($plugin->{template})=~/PerlPoint::Template::(.+)/), "templates", exists $plugin->{cfg}{setup}{stylepath} ? "provided by style $plugin->{cfg}{setup}{stylepath}/$plugin->{options}{style}." : '.') : "formatter.",
                    )
                  : (
                     "You did not specify a target yet, so it is unclear what result your call would produce.",
                     "Please set C<-target> to get a more detailled help.",
                    ),
                  "",
                  "=head1 SYNOPSIS",
                  "",
                  "Usage:",
                  "",
                  basename($0), "-target <target> -formatter <formatter> [-styledir <style dir>] [-style <style>] <options> <source>",
                  "",
                  qq(See the I<"Intro"> subsection for details about C<-target>, C<-formatter>, C<-styledir> and C<-style>.),
                  qq(See the I<"Options"> subsection for details about available options (which depend on your choice of target, formatter and style).),
                  "",
                  "=head2 Intro",
                  "",
                  exists $plugin->{help}{SYNOPSIS} ? @{$plugin->{help}{SYNOPSIS}} : (),
                  "",
                  "=head2 Options",
                  "",
                  "For the essential basic options C<-target>, C<-formatter>, C<-styledir> and C<-style>, see the descriptions above.",
                  "",
                  "Your invocation method allows",
                  basename($0),
                  "to offer you the following options:",
                  "",
                  "=over 4",
                  "",
                  (map {join('', "=item -$_\n\n", defined $plugin->{help}{OPTIONS}{$_} ? $plugin->{help}{OPTIONS}{$_} : 'undescribed option, please contact developers', "\n\n")} sort keys %{$plugin->{help}{OPTIONS}}),
                  "",
                  "=back",
                  "",
                  "=head1 AUTHORS",
                  "",
                  join('', basename($0), ' ', ${join('::', $plugin->{pkg}, 'VERSION')}, ', (c) ', ${join('::', $plugin->{pkg}, 'AUTHOR')}, ".\n\n"),
                  reverse(_classCopyright(ref($plugin))),
                  exists $plugin->{template} ? reverse($plugin->{template}->_classCopyright(ref($plugin->{template}))) : (),
                  "",
                  "=head1 SEE ALSO",
                  "",
                  basename($0),
                  "and the modules mentioned in the AUTHORS section above.",
                  "",
                  "=head1 DISCLAIMER",
                  "",
                  <<EOD,

This software is distributed in the hope that it will be useful, but
is provided "AS IS" WITHOUT WARRANTY OF ANY KIND, either expressed or
implied, INCLUDING, without limitation, the implied warranties of
MERCHANTABILITY and FITNESS FOR A PARTICULAR PURPOSE.

The ENTIRE RISK as to the quality and performance of the software
IS WITH YOU (the holder of the software).  Should the software prove
defective, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT WILL ANY COPYRIGHT HOLDER OR ANY OTHER PARTY WHO MAY CREATE,
MODIFY, OR DISTRIBUTE THE SOFTWARE BE LIABLE OR RESPONSIBLE TO YOU OR TO
ANY OTHER ENTITY FOR ANY KIND OF DAMAGES (no matter how awful - not even
if they arise from known or unknown flaws in the software).

Please refer to the Artistic License that came with your Perl
distribution for more details.

EOD
                  "",
                  "=cut",
                 );

     exit($helper->parse_string_document($pod));
    }

  # stack a first (dummy) object (in case there are no headlines)
  $plugin->stackObject(type => 'PAGE');

  # supply new object
  $plugin;
 }


# bootstrap
sub bootstrap
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # read option declarations
  $me->readOptions($me->declareOptions());

  # get option list and resolve the options
  $me->getOptions(keys %{$me->{optionlist}[0]});

  # get source filter declarations
  $me->getSourceFilters;

  # build template engine, if necessary
  if (exists $me->{options}{templatetype})
    {
     # build engine
     $me->{template}=new PerlPoint::Template(generator=>$me);

     # load and read its additional options
     $me->readOptions($me->{template}->declareOptions());
     $me->getOptions(keys %{$me->{optionlist}[0]});
    }

  # display copyright unless suppressed
  unless (exists $me->{options}{nocopyright})
    {
     no strict 'refs';
     warn "\n",
          join('', basename($0), ' ', ${join('::', $me->{pkg}, 'VERSION')}, ', (c) ', ${join('::', $me->{pkg}, 'AUTHOR')}, ".\n\n"),
          "This is a ", ref($me), " converter.\n\n",
           reverse(_classCopyright(ref($me))),
           exists $me->{template} ? ("\n", reverse($me->{template}->_classCopyright(ref($me->{template})))) : (),
          "\n\n";
    }

  # anything more to do?
  unless (exists $me->{options}{help} or exists $me->{options}{version})
   {
    # usage needs to be checked basically
    die "[Fatal] Please use -target to specify a target language.\n" unless exists $me->{options}{target};

    # ok, now perform more specific usage checks
    $me->checkUsage or die;

    # import tags as wished
    PerlPoint::Tags::addTagSets(@{$me->{options}{tagset}}) if exists $me->{options}{tagset};

    # init target directory setting, if necessary
    $me->{options}{targetdir}=cwd() unless $me->{options}{targetdir};

    # make target directory, if necessary
    if (not -d $me->{options}{targetdir})
     {
      warn "[Info] Making target directory $me->{options}{targetdir}.\n" unless exists $me->{options}{noinfo};
      mkpath($me->{options}{targetdir});
     }

    # configure image options as necessary
    $me->{options}{imagedir}=$me->{options}{targetdir} unless exists $me->{options}{imagedir};

    if (not exists $me->{options}{imageref})
     {
      if ($me->{options}{imagedir} eq $me->{options}{targetdir})
        {$me->{options}{imageref}='.';}
      else
        {
         if ($me->{options}{imagedir}=~m(^/))
           {
            # we got an absolute path, use it
            $me->{options}{imageref}=$me->{options}{imagedir};
           }
         else
           {
            # we got a relative path, absolutify it and use the result
            my ($base, $path, $type)=fileparse($me->{options}{imagedir});
            $me->{options}{imageref}=join('/', abs_path($path), basename($me->{options}{imagedir}));
           }
        }
     }

    # make image target directory, if necessary
    if (exists $me->{options}{imagedir} and not -d $me->{options}{imagedir})
     {
      warn "[Info] Making image directory $me->{options}{imagedir}.\n" unless exists $me->{options}{noinfo};
      mkpath($me->{options}{imagedir});
     }

    # bootstrap the template engine, if necessary (check options etc.)
    # - the template engine might rely on our configuration, so this is done in the finish
    # of this method
    $me->{template}->bootstrap() if exists $me->{template};
   }
 }

# inits with parser - this is just a dummy to be overwritten by child classes
sub initParser
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
 }

# inits with backend
sub initBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # bind the backend to the stream (to enable access to its data *before* backend invokation,
  # which might be used in inherited methods)
  $me->{backend}->bind($me->{build}{streamData});
 }

# provide option declarations
sub declareOptions
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # declare options
  (
   # added options
   [
    "acceptedFormat=s@", # more accepted formats (embedded or included);
    "activeContents",    # evaluation of active contents;
    "cache",             # control the cache;
    "cacheCleanup",      # cache cleanup;
    "dstreaming|docstreaming=s", # document stream handling (allow "docstreaming" for backwards compatibility);
    "help",              # online help, usage;
    "imagedir|image_dir=s", # target image directory (allow "image_dir" for backwards compatibility with pp2html);
    "imageref|image_ref=s", # target image directory reference (allow "image_ref" for backwards compatibility with pp2html);
    "includelib=s@",     # library pathes;
    "nocopyright",       # suppress copyright message;
    "noinfo",            # suppress runtime informations;
    "nowarn",            # suppress runtime warnings;
    "prefix|slide_prefix=s", # target file prefix (slide_prefix for pp2html backwards compatibility);
    "quiet",             # suppress all runtime messages except of error ones;
    "reloadStream",      # reload stream from -streamBuffer file;
    "safeOpcode=s@",     # permitted opcodes in active contents;
    "set=s@",            # user settings;
    "skipcomments",      # do not convert PerlPoint comments;
    "skipstream=s@",     # skip certain document streams;
    "mainstream=s",      # choose an alternative name for the "main" stream;
    "streamBuffer=s",    # a file to store the stream;
    "suffix|slide_suffix=s", # target file suffix (slide_suffix for pp2html backwards compatibility);
    "tagset=s@",         # add a tag set to the scripts own tag declarations;
    "targetdir|slide_dir=s", # target file prefix (slide_dir for pp2html backwards compatibility);
    "templatesAccept=s@", # targets accepted by the templates used;
    "templatetype=s",    # template engine type;
    "trace:i",           # activate trace messages;
    "version",           # display version informations and exit;

    # document data ("doc...")
    "docdescription|description=s",  # presentation description (allow "description" for backwards compatibility);
    "doctitle|title=s",  # presentation title (allow "title" for backwards compatibility);
    "docsubtitle=s",     # presentation subtitle;
    "docauthor=s",       # presentation author;
    "docdate=s",         # presentation date explicitly configured;
   ],

   # deactivated options - non at this highest level
   [],
  );
 }

# do not overwrite this - it is intended for internal use
sub readOptions
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($declared, $deactivated))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing declared options parameter.\n" unless $declared;
  confess "[BUG] Declared options parameter is no array reference.\n" unless ref($declared) eq 'ARRAY';
  confess "[BUG] Missing deactivated options parameter.\n" unless $deactivated;
  confess "[BUG] Deactivated options parameter is no array reference.\n" unless ref($deactivated) eq 'ARRAY';

  # update the stored values
  @{$me->{optionlist}[0]}{@$declared}=();
  @{$me->{optionlist}[1]}{@$deactivated}=();

  # if what we declare now was deactivated before, the list of deactivations
  # need to be updated
  /(\w+)[=:]?/, delete $me->{optionlist}[1]{$_} for @$declared;
 }

# provide source filter declarations
sub sourceFilters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # provide the list and add all accepted formats specified by the user
  (
   # most converters will support active content;
   "perl",

   # add formats specified by the user
   exists $me->{options}{acceptedFormat} ? @{$me->{options}{acceptedFormat}} : (),
  );
 }

# display a class specific copyright message
sub _classCopyright
 {
  my ($class)=@_;

  my $rootClass=__PACKAGE__;
  $class=ref($class) if ref($class);
  return '' unless $class and $class=~/^$rootClass/;

  no strict 'refs';
  (_classCopyright(@{join('::', $class, 'ISA')}), join('', $class, ' ', $class->VERSION, ' (c) ', ${join('::', $class, 'AUTHOR')}, ".\n"));
 }


# utility function to register help - overwriting not recommended
sub addHelp
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($object, $class, $rootClass, $validOptions))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing target object parameter.\n" unless $object;
  $rootClass=__PACKAGE__ unless defined $rootClass;
  confess "[BUG] Object parameter is no $rootClass object.\n" unless ref $object and $object->isa($rootClass);

  # do nothing unless the root class belongs to the class family we are working on
  return unless $class and $class=~/^$rootClass/;

  # build method name for a direct call of the $object->help() method *of the specified class*
  my $method="$class\::help";

  # get new help parts
  my $help=$object->$method;

  # store new help fragments for valid options (which should be collected already!)
  my $pattern=qr/^([^=:|]+)/;
  if (not defined $validOptions)
    {
     @$validOptions{map {$_=~$pattern; $1;} sort keys %{$me->{optionlist}[0]}}=();
     delete $validOptions->{$_} for map {$_=~$pattern; $1;} keys %{$me->{optionlist}[1]};
    }
  
  # collect valid options unless we received prepared data
  my @activeOptions=sort grep((exists $validOptions->{$_}), map {$_=~$pattern; $1;} keys %{$help->{OPTIONS}});
  @{$me->{help}{OPTIONS}}{@activeOptions}=map {join('', $help->{OPTIONS}{$_}, join(' ', "\n\nThis option is currently ", exists $me->{options}{$_} ? join('', 'set to "', ref $me->{options}{$_} ? "@{$me->{options}{$_}}" : $me->{options}{$_}, '".') : "unset."))} @activeOptions;

  # get the synopsis part, if any
  unshift(@{$me->{help}{SYNOPSIS}}, $help->{SYNOPSIS}) if exists $help->{SYNOPSIS};

  # recursive call on the next parent level of the current class family
  no strict 'refs';
  $me->addHelp($object, ${join('::', $class, 'ISA')}[0], $rootClass, $validOptions);
 }


# get options (it is not recommended to overwrite this)
sub getOptions
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my @options)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing option list parameter.\n" unless @options;

  # resolve option files
  argvFile(default=>1, home=>1);

  # get options
  GetOptions($me->{options}, @options);

  # propagate options as necessary
  @{$me->{options}}{qw(nocopyright noinfo nowarn)}=(1) x 3 if exists $me->{options}{quiet};
  $me->{options}{trace}=$ENV{SCRIPTDEBUG} if not exists $me->{options}{trace} and exists $ENV{SCRIPTDEBUG};
 }


# provide help portions
sub help
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # to get a flexible tool, help texts are supplied in portions
  {
   # supply the options part
   OPTIONS => {
               acceptedFormat    => <<EOO,

Configures the converter to accept the specified format for embedded or included files.

This option can be specified multiply.

EOO

               activeContents    => <<EOO,

For reasons of security, Active Contents (conditions, embedded Perl, paragraph filters,
import filters etc.) is disabled by default. Use this option to activate it.

Note: you need to specify valid opcodes by C<-safeOpcode> if C<activeContents> is used.

EOO

               cache             => <<EOO,

Activates the cache, see docs for details. By default, the cache is deactivated.

Note: in most cases you can skip this option.

EOO

               cacheCleanup      => <<EOO,

Cleans up the cache. Mostly invoked automatically. See docs for details.

EOO

               dstreaming        => <<EOO,

Document stream handling (for backwards compatibility, C<-docstreaming> can still be used).
Takes a numerical flag value as argument.

 Example: -dstreaming 2

By default (or when 0 is passed as value), document streams are evaluated as streams. A value
of 1 ignores all docstreams, while a value of 2 treats docstream entry points as headlines.

For details about document streams please see the parser documentation and the tutorial.
Docstreams are "inlined documents" embedded into the main document and can be used in
various ways. We recommend to try them out!

EOO

               formatter         => <<EOO,

The formatter determines I<how> the target format (chosen by C<-target>) will be produced.
There can be many formatters available for a certain target, see section I<"Intro"> above
for details.

So, once you have set up your target, you can configure which of the related formatters
should be used.

By convention there is always a formatter "Default" for every target. If the option is
omitted, the converter will use that default one.

EOO

               help              => <<EOO,

provides this online help. The help is composed dynamically, depending on the chosen target,
formatter and template engine. So for a complete help, try to set all of the following as
in a "real" call: C<-target>, C<-formatter>, C<-styledir>, C<-style>.

EOO

               imagedir          => <<EOO,

Images need special handling: they are not transformed but should be made part of generated
documents. Because results are usually generated at another place than sources (and images)
are stored, a converter needs to copy images from their source path to their target directory.
By default, this is the directory of the target files.

To allow flexible usage, it is possible to specify a I<special> target directory for images
with this option, e.g. to collect all image files at a central place on a server.

Please pass the name of the directory images should be copied into as argument.

 Example: The source is ppsrc/doc.pp, files
          are generated into results/doc, and
          images shall be stored in results/img.

          Use these options to achieve this:

          -targetdir results/doc
          -imagedir results.img
          ppsrc/doc.pp

EOO

               imageref          => <<EOO,

As described for option C<-imagedir>, images need special handling. This is true for code
generation as well: target code should use an image path relative to itself, not to the
PerlPoint source or the converters startup directory. In other words, it needs to be ready
for read-time, not convert-time.

This is what C<-imageref> is for. Specify a path (or URL, if appropriate in
${\($me->{options}{target})}) that should be used as read-time path to your images.

 Example: The source is ppsrc/doc.pp, files
          are generated into results/doc, and
          images shall be stored in results/img.

          Use these options to achieve this:

          -targetdir results/doc
          -imagedir results.img
          -imageref ../img
          ppsrc/doc.pp

The option defaults to the I<absolute path> of C<-imagedir>.

EOO

               includelib        => <<EOO,

Specifies a directory (given as argument) that should be searched for files loaded by
C<\\INCLUDE>. This means that with C<-includelib ~/projects/docs>, C<\\INCLUDE{file="file.pp" ...}> will search the directory C<~/projects/docs> for C<file.pp> unless it can be found in the
directory if the source that used C<\\INCLUDE>.

This option can be used multiply, so you can add as many directories as you need. The
directories will be searched in the order of their specification.

Note: the include path can be configured by environment variable C<PERLPOINTLIB> as well,
but directories specified via C<-includelib> are searched first.

 Example:

  * PERLPOINTLIB set to "/home:/home/docs".
  * Program call with -includelib /docs/pp.
  * Source /tmp/source.pp uses \\INCLUDE{file="hello.pp" ...}.

  ==> Search order for "hello.pp": /tmp, /docs/pp, /home, /home/docs.

EOO

               mainstream        => <<EOO,

Sets an alternative name for the default document stream "main".

 Example: -mainstream slidecontent

EOO

               nocopyright       => qq(Suppress copyright message.),
               noinfo            => qq(Suppress runtime informations.),
               nowarn            => qq(Suppress runtime warnings.),
               quiet             => qq(Suppress all runtime messages except of error hints.),
               safeOpcode        => <<EOO,

This option is a supplement to C<-activeContents>. If Active Contents is activated, you need
to declare which opcodes you trust. This is done for reasons of security, in case the processed
PerlPoint sources were written by someone else. Remember, Active Contents is full featured Perl,
unless restricted by this option.

Restrictions are implemented by running Active Contents in a C<Safe> module compartment. C<Safe>
requires to activate trusted opcodes. See the C<Safe> and C<Opcode> modules for a list of valid
opcode specifications.

Please note that C<Safe> cannot run all code, there are things that cannot be done in a
compartment, but try for yourself.

If all this sounds complicated, or if you are sure you can trust all Active Contents entirely,
or if you are using a safe sandbox, consider using the "ALL" argument. As the name intends,
"ALL" in fact enables I<all> opcodes in general. This is done by running Active Contents via
C<eval()>.

EOO

               set               => <<EOO,

This option allows you to pass in user defined options. Those options have no direct impact
to the way C<perlpoint> does its job, instead it allows you to control source processing by making
or omitting settings queried in Active Contents, namely conditions.

 Example: The following condition checks if
          one of the options "a", "b" or "all"
          was set (via -set a, -set b or -set all):

          ? flagSet(qw(a b all))

Note: currently, it is not possible to pass values to such settings. This might be added in
future versions.

EOO

               skipcomments     => <<EOO,

PerlPoint comments are usually transformed into comments of the target language. With
this option, they will be ignored. (Comments might be intended for the author, but make
no sense in generated objects, or skipping them could help to compact the results.)

EOO

               skipstream        => <<EOO,

Implements a document stream filter. The stream specified by the option argument will be
ignored. The option can be used multiply.

 Example: -skipstream details

Note: you cannot skip the "main" stream.

Note: to skip document streams I<in general>, use C<-dstreaming 1>.

EOO

               streamBuffer      => <<EOO,

With this option, the stream produced by the parser will be stored in the specified file.
This is useful to bypass parsing later on with option C<-reloadStream>.

Please note that stream buffering is an "all or nothing" operation. While you can contineously
buffer streams, only the I<complete> last buffered stream can be reloaded. On the other hand,
a complete stream allows complete parser bypassing, which can save you a lot of time.

See the C<-cache> options for a finer grained and controled caching.

EOO

               reloadStream      => <<EOO,

Reloads a stream previously saved via C<-streamBuffer>. C<-streamBuffer> needs to be declared
as well, to get the name of the stream to reload.

Stream reload is a fast alternative to reparsing the sources, which can take a long time.

Please note that stream buffering is an "all or nothing" operation. While you can contineously
buffer streams, only the I<complete> last buffered stream can be reloaded. On the other hand,
a complete stream allows complete parser bypassing, which can save you a lot of time.

No further check is performed to see if the stream is up to date related to the sources, or if
it matches the specified sources at all.

See the C<-cache> options for a finer grained and controled caching.

EOO

               tagset            => <<EOO,

Adds a tag set to the scripts own tag declarations.

Usually, C<perlpoint> only acepts tags declared by the processor to your chosen target format.
This means that an HTML target processor can allow other targets than an SDF target processor.

This makes things very flexible, but can result in nonportable sources. Sources using HTML
only tags might not be processed when translating into SDF, for example.

By adding tagsets of another target processor, the "foreign" tags get be accepted (in fact,
they are recognized as tags but ignored). Read the docs of C<PerlPoint::Tags::...> modules
to find out which tagsets are available.

Note: in most cases, there is no need to deal with tagsets.


EOO

               target            => <<EOO,

Specifies the target format. This is a mandatory setting - in fact, it is I<the> base setting
to be made. Once you have chosen a target, you can decide which formatter should be used to
produce it. See the I<"Intro"> section above for more details about the target choice.

 Examples: -target XML
           -target SDF

There is no default for this option. Calls without a target setting I<will fail> (except
for calls with C<-help>).

EOO

               targetdir   => <<EOO,

specifies the target directory. The path can be specified either absolute or relative
(to the startup path).

 Example: -targetdir docs

In case of an ommitted option the startup directory is taken as default.

EOO

               trace             => <<EOO,

activates trace messages. The trace level is determined by the argument. To combine two
levels, simply add their values:

  0   trace nothing (this is the default),
  1   trace paragraph parsing,
  2   trace lexing,
  4   detailed parser trace (syntactic analysis),
  8   trace semantic analysis,
 16   Active Contents traces,
 32   low level backend traces,
 64   temporary files are not removed.

Traces are a developer instrument. usually there is no need to activate them. In hopefully
rare cases of unclear messages about syntactic errors, it helps to activate level 2 which
displays the exact source processed.

Note: as with all traces, program execution might be delayed significantly when tracing
      is activated.

EOO

               docdescription     => <<EOO,

A short description of the document, to be included in meta tags and the like
(for backwards compatibility, C<-description> can still be used)).

 Example: -docdescription 'Internal informations about ...'

EOO

               description        => <<EOO,

A short description of the document, to be included in meta tags and the like
(available for backwards compatibility - use C<-docdescription> if possible).

 Example: -description 'Internal informations about ...'

EOO
               doctitle          => <<EOO,

Presentation title (for backwards compatibility, C<-title> can still be used)).

 Example: -doctitle 'A test document'

EOO

               title             => <<EOO,

Presentation title (available for backwards compatibility - use C<-doctitle> if possible).

 Example: -title 'A test document'

EOO

               docsubtitle       => <<EOO,

Presentation subtitle.

 Example: -docsubtitle 'An essay of testing'

EOO

               docauthor         => <<EOO,

Presentation author.

 Example: -docauthor 'Gary Speaker'

EOO

               docdate           => <<EOO,

An explicitly configured presentation date string.

 Example: -docdate '01.02.04'

EOO

               version           => <<EOO,

displays version informations and terminates the program. Versions are collected dynamically,
depending on the chosen generator (option C<target>), formatter and template engine. So for
a complete help, try to set all of the following as in a "real" call: C<-target>, C<-formatter>,
C<-styledir>, C<-style>.

EOO

              },

   # supply synopsis part
   SYNOPSIS => <<EOS,

This program converts PerlPoint sources into other formats. Various options control how
this is done, but in any case, you have to begin with C<-target>, which defines the target
format. Formats available can be found by a simple CPAN search for
C<PerlPoint::Generator::<Target\>> modules.

 For example, the PerlPoint::Package distribution comes with

  * PerlPoint::Generator::SDF - produces SDF (use "-target SDF"),
  * PerlPoint::Generator::XML - produces XML (use "-target XML").

The chosen target format determines which I<formatters> can be used. Formatters determine
the I<format> of the produced result and are chosen via option C<-formatter>. By convention,
there is alway a default formatter (C<Default>), so if the option is omitted the program
automatically uses this default.

To find out the available formatters, again a CPAN search can help. Formatter modules are
named C<PerlPoint::Generator::Target::<Formatter\>> (wherein the "<Formatter>" part can
contain various module levels).

 For example, the PerlPoint::Package distribution comes with
 the following XML formatters:

  * PerlPoint::Generator::XML::Default
    - default formatter, use "-formatter Default",
 
  * PerlPoint::Generator::XML::AxPoint
    - produces AxPoint files, use "-formatter AxPoint",

  * PerlPoint::Generator::XML::XHTML
    - produces XHTML, use "-formatter XHTML",

  * PerlPoint::Generator::XML::XHTML::Pages
    - produces paged XHTML, use "-formatter XHTML::Paged".

Formatters can be configured by I<styles>. Styles contain complete configuration setups
and allow to easily reproduce a layout. Different to target processors and formatters,
they are not implemented by Perl modules but provided by users. To start using styles,
please read the related section in the tutorial or try one of the example styles that
come with C<PerlPoint::Package> (see directory C<demos/styles>).

Styles may make use of I<template files>, which are processed by I<template engines>. Template
engines handle certain template languages and are implemented as Perl modules. Invocation of
a template engine happens automatically if a style makes use of it, but you may have to install
the template engine before. See CPAN for a list of available engines, which are named
C<PerlPoint::Template::<Engine\>> (wherin the "<Engine>" part may contain various module levels).

 At the time of this writing, the following engines exist
 and are installed with PerlPoint::Package:

  * PerlPoint::Template::Traditional
    - reimplementation of the traditional pp2html template
      language processor.


EOS
  };
 }

# check usage
sub checkUsage
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # warn if deactivated options were used
  foreach my $option (sort grep((exists $me->{options}{$_}), keys %{$me->{optionlist}[1]}))
    {
     warn "[Warn] Option -$option is ignored by the current formatter.\n";
     delete $me->{options}{$option};
    }

  # check mandatory options, if necessary
  unless (exists $me->{options}{help} or exists $me->{options}{version})
    {
     foreach my $option (qw(doctitle prefix suffix))
       {die "[Fatal] Missing mandatory option -$option.\n" unless exists $me->{options}{$option};}
    }

  # being here means that the check succeeded
  1;
 }


# get source filters (it is not recommended to overwrite this)
sub getSourceFilters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # resolve option files
  argvFile(default=>1, home=>1);

  # get the filters and store them
  $me->{build}{sourceFilters}=[$me->sourceFilters];
 }

# build a parser
sub buildParser
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # build parser
  $me->{build}{parser}=new PerlPoint::Parser;

  # Set up active contents handling. By default, we use a Safe object.
  $me->{safe}=new Safe;
  if (exists $me->{options}{safeOpcode})
    {
     unless (grep($_ eq 'ALL', @{$me->{options}{safeOpcode}}))
       {
        # configure compartment
        $me->{safe}->permit(@{$me->{options}{safeOpcode}});
       }
     else
       {
        # simply flag that we want to execute active contents
        $me->{safe}=1;
       }
    }
 }

# build a backend
sub buildBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # do it
  $me->{backend}=new PerlPoint::Backend(
                                        generator => $me,
                                        name      => ref($me),
                                        display   =>   DISPLAY_ALL
                                                     + (exists $me->{options}{noinfo} ? DISPLAY_NOINFO : 0)
                                                     + (exists $me->{options}{nowarn} ? DISPLAY_NOWARN : 0),
                                        trace     =>   TRACE_NOTHING
                                                     + ((exists $me->{options}{trace} and $me->{options}{trace} & 32) ? TRACE_BACKEND : 0),
                                        vispro    => 1,
                                       );

  # register backend handlers
  $me->{backend}->register(DIRECTIVE_DOCUMENT, \&handleDocument);

  $me->{backend}->register(DIRECTIVE_BLOCK,    \&handleBlock);
  $me->{backend}->register(DIRECTIVE_COMMENT,  \&handleComment);
  $me->{backend}->register(DIRECTIVE_HEADLINE, \&handleHeadline);
  $me->{backend}->register(DIRECTIVE_SIMPLE,   \&handleSimple);
  $me->{backend}->register(DIRECTIVE_TAG,      \&handleTag);
  $me->{backend}->register(DIRECTIVE_TEXT,     \&handleText);
  $me->{backend}->register(DIRECTIVE_VERBATIM, \&handleBlock);

  $me->{backend}->register($_, \&handleList)      foreach (DIRECTIVE_ULIST, DIRECTIVE_OLIST, DIRECTIVE_DLIST);
  $me->{backend}->register($_, \&handleListPoint) foreach (DIRECTIVE_UPOINT, DIRECTIVE_OPOINT, DIRECTIVE_DPOINT);
  $me->{backend}->register(DIRECTIVE_DPOINT_ITEM, \&handleDListPointItem);
  $me->{backend}->register(DIRECTIVE_DPOINT_TEXT, \&handleDListPointText);
  $me->{backend}->register($_, \&handleListShift) foreach (DIRECTIVE_LIST_LSHIFT, DIRECTIVE_LIST_RSHIFT);

  $me->{backend}->register(DIRECTIVE_DSTREAM_ENTRYPOINT, \&handleDocstreamEntry); 

  # the general handler
  $me->{backend}->register(DIRECTIVE_EVERY, \&prehandleDirective);
 }


# run
sub run
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # check sources
  (/^(?:IMPORT:)?(.+)/ and -r $1) or die "[Fatal] Source file $1 does not exist or is unreadable.\n" foreach @ARGV;

  # can we reload a stream?
  if (
          exists $me->{options}{reloadStream}
      and exists $me->{options}{streamBuffer}
      and -r $me->{options}{streamBuffer}
     )
   {
    # restore stream and anchors
    warn "\n[Info] Loading cached stream.\n" unless exists $me->{options}{noinfo};
    ($me->{build}{streamData}, $me->{build}{anchors})=@{retrieve($me->{options}{streamBuffer})}[0, 1];
   }
  else
    {
     # build a parser
     $me->buildParser;

     # init parser
     $me->initParser;

     # run the parser
     $me->runParser;
    }

  # build a backend
  $me->buildBackend;

  # init backend
  $me->initBackend;

  # store chapter data
  $me->storeChapterData;

  # run the backend
  $me->runBackend;

  # finish
  warn "[Info] Finish started ...\n" unless exists $me->{options}{noinfo};
  $me->finish;
  warn "[Info] Finish completed.\n" unless exists $me->{options}{noinfo};
 }


# run the parser
sub runParser
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # and call it
  $me->{build}{parser}->run(
                            stream          => $me->{build}{streamData},

                            files           => \@ARGV,

                            filter          => join('|', @{$me->{build}{sourceFilters}}),

                            safe            => exists $me->{options}{activeContents} ? $me->{safe} : undef,

                            activeBaseData  => {
                                                targetLanguage => $me->{options}{target},
                                                userSettings   => {map {$_=>1} exists $me->{options}{set} ? @{$me->{options}{set}} : ()},
                                               },

                            predeclaredVars => {
                                                CONVERTER_NAME    => basename($0),
                                                CONVERTER_VERSION => $main::VERSION,
                                               },

                            libpath         => exists $me->{options}{includelib} ? $me->{options}{includelib} : [],

                            skipcomments    => exists $me->{options}{skipcomments},

                            docstreams2skip => exists $me->{options}{skipstream} ? $me->{options}{skipstream} : [],

                            docstreaming    => (exists $me->{options}{dstreaming} and ($me->{options}{dstreaming}==DSTREAM_HEADLINES or $me->{options}{dstreaming}==DSTREAM_IGNORE)) ? $me->{options}{dstreaming} : DSTREAM_DEFAULT,

                            nestedTables    => $me->{build}{nestedTables},

                            vispro          => 1,

                            headlineLinks   => 1,

                            cache           =>   (exists $me->{options}{cache} ? CACHE_ON : CACHE_OFF)
                                               + (exists $me->{options}{cacheCleanup} ? CACHE_CLEANUP : 0),
                            display         =>   DISPLAY_ALL
                                               + (exists $me->{options}{noinfo} ? DISPLAY_NOINFO : 0)
                                               + (exists $me->{options}{nowarn} ? DISPLAY_NOWARN : 0),
                            trace           =>   TRACE_NOTHING
                                               + ((exists $me->{options}{trace} and $me->{options}{trace} & TRACE_PARAGRAPHS) ? TRACE_PARAGRAPHS : 0)
                                               + ((exists $me->{options}{trace} and $me->{options}{trace} & TRACE_LEXER)      ? TRACE_LEXER      : 0)
                                               + ((exists $me->{options}{trace} and $me->{options}{trace} & TRACE_PARSER)     ? TRACE_PARSER     : 0)
                                               + ((exists $me->{options}{trace} and $me->{options}{trace} & TRACE_SEMANTIC)   ? TRACE_SEMANTIC   : 0)
                                               + ((exists $me->{options}{trace} and $me->{options}{trace} & TRACE_ACTIVE)     ? TRACE_ACTIVE     : 0)
                                               + ((exists $me->{options}{trace} and $me->{options}{trace} & TRACE_TMPFILES)   ? TRACE_TMPFILES   : 0),
                           ) or exit(1);

  # store new stream data and parser anchors, if required
  nstore([$me->{build}{streamData}, PerlPoint::Parser::anchors], $me->{options}{streamBuffer}) if exists $me->{options}{streamBuffer};
 }


# run the backend
sub runBackend
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # run the backend
  $me->{backend}->run($me->{build}{streamData});

  # if there's a final pending page, produce it
  # (don't forget there might be an open docstream frame)
  $me->handleDocstreamEntry(DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, ''),
  $me->format(item => $me->stackCollect())
    if @{$me->{build}{stack}};

  # rebind backend to the stream, to make its methods available for later access
  $me->{backend}->bind($me->{build}{streamData});
 }


# store chapter data as provided by the backend
# (run this while the backend is bound to a stream)
sub storeChapterData
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # get raw data of all headlines
  my $nr=0;
  foreach my $chapter (@{$me->{backend}->headlineIds2Data([1 .. $me->{backend}->headlineNr])})
    {
     # update number counter (this is the same number as in the initial loop sequence,
     # but well there's still no more elegant construct, is it?)
     $nr++;

     # get all those data stored ...
     my ($id, $opcode, $mode, $level, $fullTitle, $shortTitle, $streamData, $path)=@$chapter;
     my ($fpath, $spath, $npath, $ppath)=@$path;

     # and organize them a way to be searchable both by full path and absolute page number
     my $fullpath=join('|', map {(defined) ? $_ : ''} @$fpath);
     $me->{chapterdata}{bypath}{$fullpath}=$me->{chapterdata}{bypage}{$nr}=[$nr, $level, $fullTitle, $shortTitle, $streamData, $fpath, $spath, $npath, $ppath];
    }
 }


# query chapter data for a certain path
sub getChapterByPath
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($path, $strategy))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing path parameter.\n" unless $path;
  confess "[BUG] Path parameter is no string or array reference.\n" unless not ref($path) or ref($path) eq 'ARRAY';
  confess "[BUG] Invalid strategy parameter.\n" if $strategy and $strategy!~/^firstmatch$/;

  # configure strategy unless done by caller
  $strategy='firstmatch' unless $strategy;

  # the path might be passed in by string or by array, make it a normalized string
  $path=join('|', @$path) if ref($path);

  # make sure there are no whitespaces at the beginning or end of level strings
  $path=~s/\s*\|\s*/\|/g;

  # declare result containers
  my (@data);

  # ready to search - try a direct match first (assume the path is absolute)
  if (exists $me->{chapterdata}{bypath}{$path})
    {
     # prepare result to contain stored data
     @data=($me->{chapterdata}{bypath}{$path});
    }
  else
    {
     # well, search for matching chapters - we provide all matches and let the
     # caller decide how to use them
     foreach my $storedPath (sort grep(/(^|\|)\Q$path\E$/, keys %{$me->{chapterdata}{bypath}}))
       {
        # prepare result to contain stored data
        push(@data, $me->{chapterdata}{bypath}{$storedPath});
       }
    }

  # add dummy data if there's still no result
  $data[0]=[0, 0, qq(ERROR: Missing chapter "$path"), '', undef, ([]) x 3] unless (@data);

  # if there's more than one result, handle it according to the strategy
  if (@data>1)
    {
     if ($strategy eq 'firstmatch')
       {
        # complain and delete additional results
        die "\n[Error] Ambigous page path \"$path\" (matches ",
            join(' and ', map {qq("$_")} map {join('|', @{$_->[5]})} @data),
            ").\n";
        @data=($data[0]);
       }
    }

  # supply results
  @data;
 }

# query chapter data for a certain page number
sub getChapterByPagenr
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my $page)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page number parameter.\n" unless $page;

  # supply data, if available
  exists $me->{chapterdata}{bypage}{$page} ? $me->{chapterdata}{bypage}{$page} : undef;
 }


# get anchor data in general
sub getAnchorData
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my $name)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing path parameter.\n" unless $name;

  # make sure there are no whitespaces at the beginning or end of level strings
  $name=~s/\s*\|\s*/\|/g;

  # get anchor data
  my $data=(exists $me->{build}{parser} ? PerlPoint::Parser::anchors : $me->{build}{anchors})->query($name);

  # supply data, if found
  defined $data ? $data->{$name} : $data;
 }




# finish handling
sub finish
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # this method is just here to have it - it is intended to be overwritten when in need to do so
 }


# add a new slide and make it the current one
sub next
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my %params)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # update document data: headline path data
  $me->{build}{headlinePath}=$params{path};

  # update more build data: list level and docstream flag
  $me->{build}{listlevels}=[0];
  $me->{build}{listtypes}=[];
  $me->{build}{listclosingops}=[];
  $me->{build}{docstream}=undef;

  # make and init a new page structure
  my PerlPoint::Generator::Object::Page $chapter=new PerlPoint::Generator::Object::Page(
                                                                                        nr    => @{$me->{pages}}+1,
                                                                                        fpath => $params{path}[0],
                                                                                        spath => $params{path}[1],
                                                                                        npath => $params{path}[2],
                                                                                        ppath => $params{path}[3],
                                                                                        vars  => $params{path}[4],
                                                                                       );
  # store the page torso
  push(@{$me->{pages}}, $chapter);

  # update document data
  $me->{latest}=$#{$me->{pages}};

  # supply chapter number
  scalar(@{$me->{pages}});
 }


# provide the number of the current page (while processing the stream!!!)
sub currentPage
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # number counting starts with 1
  scalar(@{$me->{pages}});
 }


# provide the number of a certain page - specified by a keyword
# (this is intended to be used after stream processing)
sub pageBySpec
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($spec, $currentPage))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing page specifier parameter.\n" unless defined $spec;
  confess "[BUG] Missing current page number parameter.\n" unless defined $currentPage;

  # process directive
  if (lc($spec) eq 'first')
    {1;}
  elsif (lc($spec) eq 'current')
    {$currentPage;}
  elsif (lc($spec) eq 'up')
    {
     my $npath=$me->page($currentPage)->path(type=>'npath', mode=>'array');
     @$npath>=2 ? $npath->[-2] : undef;
    }
  elsif (lc($spec) eq 'previous')
    {$currentPage>1 ? $currentPage-1 : undef}
  elsif (lc($spec) eq 'next')
    {$currentPage<$me->{backend}->headlineNr() ? $currentPage+1 : undef;}
  elsif (lc($spec) eq 'last')
    {$me->{backend}->headlineNr();}
  else
    {confess "[BUG] Unknown page specifier $spec.\n"}
 }


# provide the data of a certain page - specified by either number or keyword
sub page
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my $page)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Invalid page number $page (valid range: 0 to ", $me->{backend}->headlineNr(), ").\n" if defined $page and ($page<0 or $page>$me->{backend}->headlineNr());

  # return an undefined value for an undefined page number
  return undef unless defined $page;

  # page already registered?
  if (exists $me->{pages}[$page])
    {
     # registered page - provide the object
     $me->{pages}[$page];
    }
  else
    {
     # page number is valid, but the page was not registered yet - build an object yourself
       # make and init a new page structure
     my PerlPoint::Generator::Object::Page $object=new PerlPoint::Generator::Object::Page(
                                                                                          nr    => $page,
                                                                                          fpath => $me->{chapterdata}{bypage}{$page}[5],
                                                                                          spath => $me->{chapterdata}{bypage}{$page}[6],
                                                                                          npath => $me->{chapterdata}{bypage}{$page}[7],
                                                                                          ppath => $me->{chapterdata}{bypage}{$page}[8],
                                                                                          vars  => undef, # TODO: find a way to supply the real variables
                                                                                         );

     # supply this object
     $object;
    }
 }


# invoke a formatter
sub format
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my %params)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing item parameter.\n" unless exists $params{item};

  confess "[BUG] Item parameter is no hash reference.\n" unless ref($params{item}) eq 'HASH';
  confess "[BUG] Item parameter offers no configuration info.\n"  unless exists $params{item}{cfg};
  confess "[BUG] Item parameter offers no data parts.\n"  unless exists $params{item}{parts};

  # declarations and formatter search
  my ($formatter)=(exists $formatters{$params{item}{cfg}{type}} ? $formatters{$params{item}{cfg}{type}} : '');

  # check yourself
  confess "[BUG] There's no formatter prepared for type ", $params{item}{cfg}{type}, ".\n" unless $formatter;
  
  # If there is a formatter available, invoke it. Otherwise just
  # concatenate base data, ignoring all the extra information of the envelope.
  # Carp::cluck "FORMATTER: $formatter";
  my @formatted=$me->can($formatter) ? $me->$formatter($me->{pages}[-1], $params{item}) : join('', @{$params{item}{parts}});

  # check result
  confess "[BUG] Formatter ", ref($me), "::$formatter() supplied a hash reference (which is reserved for internal purposes).\n" if grep((ref) eq 'HASH', @formatted);

  # supply results
  @formatted;
 }



# STACK HANDLING ########################################################################



# make a new stack object
sub stackObject
  {
   # get and check parameters
   ((my __PACKAGE__ $me), my @data)=@_;
   confess "[BUG] Missing object parameter.\n" unless $me;
   confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

   # let's see if this simple structure works (TODO: additionally, each new object should
   # contain the object hierarchy, so that a formatter can know where it is working)
   my %hash=@data;
   push(@{$me->{build}{stack}}, \%hash);

   # update the nesting chain
   push(@{$me->{build}{stackChain}}, $hash{type});
  }

# stack items
sub stackStore
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my @data)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  push(@{$me->{build}{stack}}, @data);
 }


# collect item parts from the stack
sub stackCollect
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # update nesting chain
  pop(@{$me->{build}{stackChain}});

  # setup
  my ($item)=({parts=>[], context=>[@{$me->{build}{stackChain}}]});

  # first: collect all parts (an item consists of a start array plus item text)
  unshift(@{$item->{parts}}, pop(@{$me->{build}{stack}})) while @{$me->{build}{stack}} and not ref($me->{build}{stack}[-1]) eq 'HASH';
  $item->{cfg}=pop(@{$me->{build}{stack}});

  # suppply result
  $item;
 }



# BACKEND HANDLERS ###########################################################


# directive prehandler
sub prehandleDirective
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @more))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # this is a good place to have a look at the stream ... if necessary
  # use Data::Dumper; warn Dumper(\@_);

  # search for incomplete lists followed by something else
  if (
      (
       # a new non list paragraph
          $opcode==DIRECTIVE_BLOCK
       or $opcode==DIRECTIVE_COMMENT
       or $opcode==DIRECTIVE_HEADLINE
       or $opcode==DIRECTIVE_TEXT
       or $opcode==DIRECTIVE_VERBATIM
       or $opcode==DIRECTIVE_DSTREAM_ENTRYPOINT
      )

      # that starts ...
      and $mode==DIRECTIVE_START
     )
    {
     while (@{$me->{build}{listclosingops}})
       {
        $me->{build}{listclosingops}[-1] and $me->{build}{listclosingops}[-1]->();
        pop(@{$me->{build}{listclosingops}});
       }
    }

  # if there is a preformatter, call it now
  $me->preFormatter($opcode, $mode, @more) if $me->can('preFormatter');
 }


# handle document directives
sub handleDocument
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @contents))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # empty by default, but might be overwritten
 }


# simple directive handlers
sub handleSimple
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @contents))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # stack a simple text object
  $me->stackStore($me->format(item => {parts=>[@contents], context => [@{$me->{build}{stackChain}}], cfg => {type=>$opcode}}));
 }


# headlines
sub handleHeadline
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, $level, $fullTitle, $shortTitle, $streamData, $path))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # new slide: if there's a pending docstream / page, produce it
     $me->handleDocstreamEntry(DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, ''),
     $me->format(item => $me->stackCollect()) if @{$me->{build}{stack}};

     # start a new slide and stack a placeholder
     $me->next(title => $fullTitle, path => $path, level => $level);
     $me->stackObject(type => 'PAGE');

     # stack a new headline object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {
                               level => $level,
                               full  => $fullTitle,
                               abbr  => $shortTitle || $shortTitle,
                              },
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));

     # start a new main stream part
     $me->handleDocstreamEntry(DIRECTIVE_DSTREAM_ENTRYPOINT, DIRECTIVE_START, $me->{options}{mainstream} || 'main'),
    }
 }

# text
sub handleText
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # stack a new text paragraph object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {
                              },
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));
    }
 }

# tags
sub handleTag
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, $tag, $settings, $bodyparts))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # special operations: LOCALTOC
     if ($tag eq 'LOCALTOC')
       {
        # get raw data of local toc and store them
        $settings->{__rawtoc__}=$me->{backend}->toc($me->{backend}->currentChapterNr, $settings->{depth});

        # transform the list into a well formed nested array, if possible
        if (@{$settings->{__rawtoc__}})
         {
          my ($lastlevel, @arraylist)=(1, []);
          foreach my $item (@{$settings->{__rawtoc__}})
           {
            # get level and title
            my ($level, $title)=@$item;

            # higher level than before?
            if ($level>$lastlevel)
             {
              # open new containers
              $arraylist[$lastlevel++]=[] while $level>$lastlevel;
             }
            elsif ($level<$lastlevel)
             {
              # close containers and append them to their predecessors
              push(@{$arraylist[-2]}, pop(@arraylist)), $lastlevel-- while $level<$lastlevel;
             }

            # the container at the end is on the entries level now
            push(@{$arraylist[-1]}, $item);
           }

          # to complete preparation, remove all *empty* levels (remember, the levels above reflect real headline
          # levels, and we might have begun on a very high level ourselves)
          shift(@arraylist) until @{$arraylist[0]};

          # finally, close all open sublevels and store the list in the tag data structure
          push(@{$arraylist[-2]}, pop(@arraylist)) while @arraylist>1;
          $settings->{__wellformedtoc__}=$arraylist[0];
         }
       }

     # special operations: IMAGE
     if ($tag eq 'IMAGE')
       {
        # get image basename
        my $basename=basename($settings->{src});

        # copy image, if necessary
        if (
                exists $me->{options}{imagedir}
            and (
                    not -e "$me->{options}{imagedir}/$basename"
                 or -M "$me->{options}{imagedir}/$basename" > -M $settings->{src}
                )
           )
          {
           # inform user, unless suppressed
           warn qq([Info] Copying $settings->{src} to $me->{options}{imagedir}.\n) unless exists $me->{options}{noinfo};

           # perform action
           copy($settings->{src}, $me->{options}{imagedir});
          }
       }

     # special operations: filter index cloud entries by chapters, if necessary
     if ($tag eq 'INDEXCLOUD')
      {
       # scopies
       my (%chapters, %entries);

       # chapters selected?
       if (exists $settings->{chapters})
        {
         # this might be a list, which is indicated by a separator
         # - store all chapter names
         foreach my $chapter (exists $settings->{chapterDelimiter} ? split($settings->{chapterDelimiter}, $settings->{chapters}) : $settings->{chapters})
          {
           # find the chapter *number* belonging to this title
           my @data=$me->getChapterByPath($chapter);

           # anything found?
           next unless $data[0][0];

           # if there are multiple results, take them all and store their page numbers!
           @chapters{map {$_->[0]} @data}=();

           # now we need to find out all their subchapters, to complete the list of
           # chapter numbers that are qualified for this cloud
           foreach my $chapter (keys %chapters)
            {@chapters{map {$chapter+$_} 1 .. @{$me->{backend}->toc($chapter)}}=();}
          }
        }
       else
        {
         # process *all* chapters (or index entries, respectively)
         @chapters{1 .. $me->{backend}->headlineNr}=();
        }

       # finally, delete all index entries that were not found on the specified pages
       foreach my $groupname (keys %{$settings->{__anchors}})
        {
         # in this group, handle all entries
         my $group=$settings->{__anchors}{$groupname};
         foreach my $entry (@$group)
          {
           # for this entry, handle all occurences (we need the complicated loop as the
           # data structure has a special design, every second entry is a scalar that
           # belongs to its predecessor), count usage
           my @buffer;
           for (my $i=0; $i<$#{$entry->[1]}; $i+=2)
            {push(@buffer, @{$entry->[1]}[$i, $i+1]), $entries{$entry->[0]}++ if exists $chapters{$entry->[1][$i][1]}}
           splice(@$entry, 1, 1, @buffer ? \@buffer : ());
          }

         # delete all entries that became empty
         @$group=grep {@$_>1} @$group;

         # and delete this group if it is empty now
         delete $settings->{__anchors}{$groupname} unless @$group;
        }

       # if there is a limit to the x top rated entries, we can decrease the index hash to these records
       if (exists $settings->{top})
        {
         my @entries=map {[$_ => $entries{$_}]} sort {$entries{$b} cmp $entries{$a}} keys %entries;
         %entries=map {(@$_)} splice(@entries, 0, $settings->{top});
        }

       # prepare a mini ranking for quick use: provide the entries and their usage counts
       $settings->{__entries}=\%entries;
      }

     # stack a new tag object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {
                               name      => $tag,
                               options   => $settings,
                               bodyparts => $bodyparts,
                              },
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => ((my $dbg)=$me->stackCollect())));
    }
 }

# blocks
sub handleBlock
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # stack a new tag object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {},
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));
    }
 }

# list
sub handleList
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, $wishedStartNr, $shifted, $sbLevel, $shiftFollows, $sfLevel))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # (re)init current list level
     $me->{build}{listlevels}[-1]=$wishedStartNr-1 if defined $wishedStartNr and $wishedStartNr;

     # if we are continuing a level already started before, the new list type might differ
     # from the original one - check it
     if (    
             @{$me->{build}{listclosingops}}>@{$me->{build}{listlevels}}
         and $opcode!=$me->{build}{listtypes}[$#{$me->{build}{listlevels}}]
        )
       {
        # Indeed - we continue with a new list type. This means that the original list
        # has to be closed.
        $me->handleList($me->{build}{listtypes}[$#{$me->{build}{listlevels}}], DIRECTIVE_COMPLETE, $wishedStartNr, 0, 0, 0, 0);
       }

     # stack a new tag object (unless the list was already opened before)
     unless (@{$me->{build}{listclosingops}}>@{$me->{build}{listlevels}})
       {
        $me->stackObject(
                         type => $opcode,
                         mode => $mode,
                         data => {
                                  # provide the list (nesting) level
                                  level => scalar(@{$me->{build}{listlevels}}),
                                 },

                         # store start number, if necessary
                         $wishedStartNr>1 ? (
                                             options => {
                                                         start => $wishedStartNr,
                                                        }, 
                                            )
                                          : (),
                        );
       }

     # store the current list type
     $me->{build}{listtypes}[$#{$me->{build}{listlevels}}]=$opcode;
    }
  else
    {
     # shift operation following?
     unless ($shiftFollows)
       {
        # no followup shift: the list is complete, so complete the stack object
        $me->stackStore($me->format(item => $me->stackCollect()));

        # shorten the list of closing operations, if necessary
        splice(@{$me->{build}{listclosingops}}, scalar(@{$me->{build}{listlevels}})) if @{$me->{build}{listclosingops}}>@{$me->{build}{listlevels}};
       }
     else
       {
        # a followup shift: delay list closing by storing the close operation at first level ...
        $me->{build}{listclosingops}[scalar(@{$me->{build}{listlevels}})]=sub {$me->stackStore($me->format(item => $me->stackCollect()));};
       }
    }
 }

# list shift
sub handleListShift
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, $offset))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # anything to do?
  return unless $mode==DIRECTIVE_START;

  # handle operation dependend
  if ($opcode==DIRECTIVE_LIST_RSHIFT)
    {
     # deeper nesting: open intermediate levels as requested
     for (1 .. $offset-1)
       {
        # make and init a new list level
        push(@{$me->{build}{listlevels}}, 0);

        # open a new, unordered dummy list ...
        $me->handleList(DIRECTIVE_ULIST, DIRECTIVE_START, 0, 0, 0, 0, 0);

        # and immediately close it, causing handleList() to delay a close operation
        $me->handleList(DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, 0, 0, 0, 1, 1);
       }

     # make the final level and init it
     push(@{$me->{build}{listlevels}}, 0);
    };

  if ($opcode==DIRECTIVE_LIST_LSHIFT)
    {
     # if there are more levels closed, perform the necessary operations:
     for (1 .. $offset)
       {
        # any level left? (the last level cannot be closed by a shift operation)
        if (@{$me->{build}{listlevels}}>1)
          {
           # if the closing of this list level was delayed, perform it now
           splice(@{$me->{build}{listclosingops}}, @{$me->{build}{listlevels}}+1);
           $me->{build}{listclosingops}[-1]() if defined $me->{build}{listclosingops}[-1];
           pop(@{$me->{build}{listclosingops}});

           # close the level point counter and the list type memory of this level
           pop(@{$me->{build}{listlevels}});
           pop(@{$me->{build}{listtypes}});
          }
       }
    }
 }


# list point
sub handleListPoint
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @data))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # update list level description
     $me->{build}{listlevels}[-1]++;

     # stack a new tag object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {
                               # pass the list hierarchy
                               hierarchy => $me->{build}{listlevels},
                              },
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));
    }
 }

# definition list point item
sub handleDListPointItem
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @data))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # stack a new tag object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {
                              },
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));
    }
 }

# definition list point text
sub handleDListPointText
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, @data))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # stack a new tag object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {
                              },
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));
    }
 }

# comment
sub handleComment
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  
  # act mode dependend
  if ($mode==DIRECTIVE_START)
    {
     # stack a new tag object
     $me->stackObject(
                      type => $opcode,
                      mode => $mode,
                      data => {},
                     );
    }
  else
    {
     # complete the stack object
     $me->stackStore($me->format(item => $me->stackCollect()));
    }
 }


# docstream entry point
sub handleDocstreamEntry
 {
  # get and check parameters
  ((my __PACKAGE__ $me), my ($opcode, $mode, $docstream))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # build a pattern to check for default stream and empty pseudo stream
  my $mainstreamName=$me->{options}{mainstream} || 'main';
  my $stdStream=qr/(?:$mainstreamName)?/;

  # all docstreams complete the previous dstream object, except this was the empty pseudo stream
      defined $me->{build}{docstream}
  and $me->{build}{docstream}
  and $me->stackStore($me->format(item => $me->stackCollect()));


  # switching from another docstream to an empty pseudo stream or the default stream
  # we close the docstream frame
      defined $me->{build}{docstream}
  and $me->{build}{docstream}!~/^$stdStream$/
  and $docstream=~/^$stdStream$/
  and $me->stackStore($me->format(item => $me->stackCollect()));


  # switching from default stream or empty pseudo stream to another docstream we start a docstream frame
  if (
          (
              not defined $me->{build}{docstream}
           or $me->{build}{docstream}=~/^$stdStream$/
          )
      and $docstream!~/^$stdStream$/
     )
    {
     # stack a new docstream frame object
     $me->stackObject(
                      type => 'DSTREAMFRAME',
                      mode => $mode,
                      data => {
                              },
                     );
    }


  # all docstreams except the empty pseudo stream produce special objects
  $me->stackObject(
                   type => $opcode,
                   mode => $mode,
                   data => {
                            name => $docstream,
                           },
                  ) if $docstream;


  # flag that we are in this docstream now
  $me->{build}{docstream}=$docstream;
 }


# POSTPROCESSING WRAPPERS ####################################################

# provide options
sub options
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # provide data
  $me->{options};
 }

# provide number of chapters
sub numberOfChapters
 {
  # get and check parameters
  (my __PACKAGE__ $me)=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);

  # provide info
  $me->{backend}->headlineNr;
 }


# build an anchor link (similar to the \REF tag)
sub buildAnchorLink
 {
  # get and check parameters
  ((my __PACKAGE__ $me), (my ($anchor, $text)))=@_;
  confess "[BUG] Missing object parameter.\n" unless $me;
  confess "[BUG] Object parameter is no ", __PACKAGE__, " object.\n" unless ref $me and $me->isa(__PACKAGE__);
  confess "[BUG] Missing anchor parameter.\n" unless $anchor;
  confess "[BUG] Missing text parameter.\n" unless $text;

  # variables
  my ($result)=('');

  # anchors can contain guarded parantheses
  $anchor=~s/\\\)/\)/g;

  # first check for a valid anchor
  if ($me->getAnchorData($anchor))
    {
     # build a "fake" option hash of a virtual REF tag
     my $refopt={
                 name        => $anchor,
                 occasion    => 1,
                 type        => 'linked',
                 valueformat => 'pagetitle',
                 __body__    => 1,
                };

     # stack a tag start
     $me->handleTag(DIRECTIVE_TAG, DIRECTIVE_START, 'REF', $refopt);

     # stack a tag body, which is the link text (or title, if there is no text)
     $anchor=~/([^|]+)$/;
     $me->handleSimple(DIRECTIVE_SIMPLE, DIRECTIVE_START, $text ? $text : $1);

     # stack a tag completion (this includes tag formatting)
     $me->handleTag(DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'REF', $refopt);

     # load tag structure from stack and extract the data part using the appropriate method
     $result=join('', @{$me->stackCollect()->{parts}});
    }
  else
    {
     # unknown anchor, just reply the text
     $anchor=~/([^|]+)$/;
     $result=$text ? $text : $1;
    }

  # supply result
  $result;
 }




# MODULE FRAME COMPLETION ####################################################


# flag successful loading
1;


# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES


=head1 SEE ALSO

=over 4



=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003-2006.
All rights reserved.

This module is free software, you can redistribute it and/or modify it
under the terms of the Artistic License distributed with Perl version
5.003 or (at your option) any later version. Please refer to the
Artistic License that came with your Perl distribution for more
details.

The Artistic License should have been included in your distribution of
Perl. It resides in the file named "Artistic" at the top-level of the
Perl source tree (where Perl was downloaded/unpacked - ask your
system administrator if you dont know where this is).  Alternatively,
the current version of the Artistic License distributed with Perl can
be viewed on-line on the World-Wide Web (WWW) from the following URL:
http://www.perl.com/perl/misc/Artistic.html


=head1 DISCLAIMER

This software is distributed in the hope that it will be useful, but
is provided "AS IS" WITHOUT WARRANTY OF ANY KIND, either expressed or
implied, INCLUDING, without limitation, the implied warranties of
MERCHANTABILITY and FITNESS FOR A PARTICULAR PURPOSE.

The ENTIRE RISK as to the quality and performance of the software
IS WITH YOU (the holder of the software).  Should the software prove
defective, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT WILL ANY COPYRIGHT HOLDER OR ANY OTHER PARTY WHO MAY CREATE,
MODIFY, OR DISTRIBUTE THE SOFTWARE BE LIABLE OR RESPONSIBLE TO YOU OR TO
ANY OTHER ENTITY FOR ANY KIND OF DAMAGES (no matter how awful - not even
if they arise from known or unknown flaws in the software).

Please refer to the Artistic License that came with your Perl
distribution for more details.

