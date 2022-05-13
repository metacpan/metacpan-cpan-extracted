package Module::ScanDeps::Static;

use strict;
use warnings;

our $VERSION = '0.3';

use 5.010;

use Carp;
use Data::Dumper;
use English qw{ -no_match_vars };
use ExtUtils::MM;
use Getopt::Long;
use JSON::PP;
use Module::CoreList;
use Pod::Usage;
use Pod::Find qw{ pod_where };
use Readonly;
use IO::Scalar;
use List::Util qw{ max };
use version;

use parent qw{ Class::Accessor::Fast };

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw{
    json raw text handle include_require core
    add_version perlreq require path separator min_core_version
  }
);

# booleans
Readonly my $TRUE  => 1;
Readonly my $FALSE => 0;

# shell success/failure
Readonly my $SUCCESS => 0;
Readonly my $FAILURE => 1;

# chars
Readonly my $COMMA        => q{,};
Readonly my $DOUBLE_COLON => q{::};
Readonly my $EMPTY        => q{};
Readonly my $NEWLINE      => qq{\n};
Readonly my $SLASH        => q{/};
Readonly my $SPACE        => q{ };

our $HAVE_VERSION = eval {
  require version;
  return $TRUE;
};

caller or __PACKAGE__->main();

########################################################################
sub new {
########################################################################
  my ( $class, $args ) = @_;

  $args = $args || {};

  my %options = %{$args};

  foreach my $k ( keys %options ) {
    my $v = $options{$k};

    delete $options{$k};

    $k =~ s/-/_/gxsm;

    $options{$k} = $v;
  } ## end foreach my $k ( keys %options)

  # defaults
  $options{'core'}            //= $TRUE;
  $options{'include_require'} //= $FALSE;
  $options{'add_version'}     //= $TRUE;

  my $self = $class->SUPER::new( \%options );

  $self->set_perlreq( {} );
  $self->set_require( {} );

  return $self;
} ## end sub new

########################################################################
sub make_path_from_module {
########################################################################
  my ( $self, $module ) = @_;

  my $file = join $SLASH, split /$DOUBLE_COLON/xsm, $module;

  return "$file.pm";
} ## end sub make_path_from_module

########################################################################
sub get_module_version {
########################################################################
  my ( $self, $module_w_version, @include_path ) = @_;

  if ( !@include_path ) {
    @include_path = @INC;
  } ## end if ( !@include_path )

  my ( $module, $version ) = split /\s+/xsm, $module_w_version;

  my %module_version = (
    module  => $module,
    version => $version,
    path    => undef,
  );

  return \%module_version
    if $version;

  $module_version{'file'} = $self->make_path_from_module($module);

  foreach my $prefix (@include_path) {

    my $path = $prefix . $SLASH . $module_version{'file'};
    next if !-e $path;

    $module_version{'path'} = $path;

    $module_version{'version'}
      = eval { return ExtUtils::MM->parse_version($path) // 0; };

    last;
  } ## end foreach my $prefix (@include_path)

  return \%module_version;
} ## end sub get_module_version

########################################################################
sub is_core {
########################################################################
  my ( $self, $module_w_version ) = @_;

  my ( $module, $version ) = split /\s/xsm, $module_w_version;

  my $core = $FALSE;

  my @ms = Module::CoreList->find_modules(qr/\A$module\z/xsm);

  if (@ms) {
    my $first_release = Module::CoreList->first_release($module);

    my $first_release_version = version->parse($first_release);
    my $min_core_version      = $self->get_min_core_version;

    # consider a module core if its first release was less than some
    # version of Perl. This is done because CPAN testers don't seem to
    # test modules against Perls that are older than 5.8.9 - however,
    # some modules like JSON::PP did not appear until > 5.10

    $core = $first_release_version <= $min_core_version;

  } ## end if (@ms)

  return $core;
} ## end sub is_core

########################################################################
sub parse_line { ## no critic (Subroutines::ProhibitExcessComplexity)
########################################################################
  my ( $self, $line ) = @_;

  my $fh = $self->get_handle;

  # skip the "= <<" block
  if ( $line =~ /\A\s*(?:my\s*)?\$(?:.*)\s*=\s*<<\s*(["'`])(.+?)\1/xsm
    || $line =~ /\A\s*(?:my\s*)?\$(.*)\s*=\s*<<(\w+)\s*;/xsm ) {
    my $tag = $2;

    while ( $line = <$fh> ) {
      chomp $line;

      last if $line eq $tag;
    } ## end while ( $line = <$fh> )

    $line = <$fh>;

    return if !$line;

  } ## end if ( $line =~ ...)

  # skip q{} quoted sections - just hope we don't have curly brackets
  # within the quote, nor an escaped hash mark that isn't a comment
  # marker, such as occurs right here. Draw the line somewhere.
  if ( $line =~ /\A.*\Wq[qxwr]?\s*([{([#|\/])[^})\]#|\/]*$/xsm
    && $line !~ /\A\s*require|use\s/xsm ) {
    my $tag = $1;

    $tag =~ tr/{\(\[\#|\//})]#|\//;
    $tag = quotemeta $tag;

    while ( $line = <$fh> ) {
      last if $line =~ /$tag/xsm;
    } ## end while ( $line = <$fh> )

    return if !$line;
  } ## end if ( $line =~ /\A.*\Wq[qxwr]?\s*([{([#|\/])[^})\]#|\/]*$/xsm...[[({]}]))

  # skip the documentation

  # we should not need to have item in this if statement (it
  # properly belongs in the over/back section) but people do not
  # read the perldoc.

  if ( $line =~ /\A=(head[\d]|pod|for|item)/xsm ) {

    while ( $line = <$fh> ) {
      last if $line =~ /\A^=cut/xsm;
    } ## end while ( $line = <$fh> )

    return if !$line;
  } ## end if ( $line =~ /\A=(head[\d]|pod|for|item)/xsm)

  if ( $line =~ /\A=over/xsm ) {
    while ( $line = <$fh> ) {
      last if /\A=back/xsm;
    } ## end while ( $line = <$fh> )

    return if !$line;
  } ## end if ( $line =~ /\A=over/xsm)

  # skip the data section
  return if $line =~ /\A__(DATA|END)__/xsm;

  my $modver_re = qr/[.\d]+/xsm;

  #
  # The (require|use) match further down in this subroutine will match lines
  # within a multi-line print or return statements.  So, let's skip over such
  # statements whose content should not be loading modules anyway. -BEF-
  #
  if ( $line =~ /print(?:\s+|\s+\S+\s+)\<\<\s*(["'`])(.+?)\1/xsm
    || $line =~ /print(\s+|\s+\S+\s+)\<\<(\w+)/xsm
    || $line =~ /return(\s+)\<\<(\w+)/xsm ) {

    my $tag = $2;
    while ( $line = <$fh> ) {
      chomp $line;
      last if $line eq $tag;
    } ## end while ( $line = <$fh> )

    $line = <$fh>;

    return if !$line;
  } ## end if ( $line =~ /print(?:\s+|\s+\S+\s+)\<\<\s*(["'`])(.+?)\1/xsm...)

  # Skip multiline print and assign statements
  if ( $line =~ /\$\S+\s*=\s*(")([^"\\]|(\\.))*\z/xsm
    || $line =~ /\$\S+\s*=\s*(')([^'\\]|(\\.))*\z/xsm
    || $line =~ /print\s+(")([^"\\]|(\\.))*\z/xsm
    || $line =~ /print\s+(')([^'\\]|(\\.))*\z/xsm ) {

    my $quote = $1;

    while ( $line = <$fh> ) {
      last if $line =~ /\A([^\\$quote]|(\\.))*$quote/xsm;
    } ## end while ( $line = <$fh> )

    $line = <$fh>;

    return if !$line;
  } ## end if ( $line =~ /\$\S+\s*=\s*(")([^"\\]|(\\.))*\z/xsm...)

  # ouch could be in a eval, perhaps we do not want these since we catch
  # an exception they must not be required

  #   eval { require Term::ReadLine } or die $@;
  #   eval "require Term::Rendezvous;" or die $@;
  #   eval { require Carp } if defined $^S; # If error/warning during compilation,

  ## no critic (RegularExpressions::ProhibitComplexRegexes, RegularExpressions::RequireBracesForMultiline)
  if (
    ( $line =~ /\A(\s*) # we hope the inclusion starts the line
         (require|use)\s+(?![{])      # do not want 'do {' loops
         # quotes around name are always legal
         ['"]?([\w:.\/]+?)['"]?[\t; ]
         # the syntax for 'use' allows version requirements
         # the latter part is for "use base qw(Foo)" and friends special case
         \s*($modver_re|(qw\s*[{(\/'"]\s*|['"])[^})\/"'\$]*?\s*[})\/"'])?/xsm
    )
  ) {

    #    \s*($modver_re|(qw\s*[(\/'"]\s*|['"])[^)\/"'\$]*?\s*[)\/"'])?

    my ( $whitespace, $statement, $module, $version ) = ( $1, $2, $3, $4 );

    $version //= $EMPTY;

    # print {*STDERR} "$whitespace, $statement, $module, $version\n";

    # fix misidentification of version when use parent qw{ Foo };
    #
    # Pragmatism dictates that I just identify the misidentification
    # instead of trying to make the regexp above even more
    # complicated...

    if ( $statement eq 'use' && $module =~ /(parent|base)/xsm ) {
      if ( $version =~ /\A\s*qw\s*['"{(\/]\s*([^'")}\/]+)\s*['")}\/]/xsm ) {
        $module  = $1;
        $version = $EMPTY;
      } ## end if ( $version =~ ...)
    } ## end if ( $statement eq 'use'...)
    #

    # print {*STDERR} "$module, $version\n";

    # we only consider require statements that are flushed against
    # the left edge. any other require statements give too many
    # false positives, as they are usually inside of an if statement
    # as a fallback module or a rarely used option

    if ( !$self->get_include_require ) {
      return $line if $whitespace ne $EMPTY && $statement eq 'require';
    } ## end if ( !$self->get_include_require)

    # if there is some interpolation of variables just skip this
    # dependency, we do not want
    #        do "$ENV{LOGDIR}/$rcfile";

    return $line if $module =~ /\$/xsm;

    # skip if the phrase was "use of" -- shows up in gimp-perl, et al.
    return $line if $module eq 'of';

    # if the module ends in a comma we probably caught some
    # documentation of the form 'check stuff,\n do stuff, clean
    # stuff.' there are several of these in the perl distribution

    return $line if $module =~ /[,>]\z/xsm;

    # if the module name starts in a dot it is not a module name.
    # Is this necessary?  Please give me an example if you turn this
    # back on.

    #      ($module =~ m/^\./) && next;

    # if the module starts with /, it is an absolute path to a file
    if ( $module =~ /\A\//xsm ) {
      $self->add_require($module);
      return $line;
    } ## end if ( $module =~ /\A\//xsm)

    # sometimes people do use POSIX qw(foo), or use POSIX(qw(foo)) etc.
    # we can strip qw.*$, as well as (.*$:
    $module =~ s/qw.*\z//xsm;
    $module =~ s/[(].*\z//xsm;

    # if the module ends with .pm, strip it to leave only basename.
    $module =~ s/[.]pm\z//xsm;

    # some perl programmers write 'require URI/URL;' when
    # they mean 'require URI::URL;'

    $module =~ s/\//::/xsm;

    # trim off trailing parentheses if any.  Sometimes people pass
    # the module an empty list.

    $module =~ s/[(]\s*[)]$//xsm;

    if ( $module =~ /\Av?([\d._]+)\z/xsm ) {
      # if module is a number then both require and use interpret that
      # to mean that a particular version of perl is specified

      my $ver = $1;

      $self->get_perlreq->{'perl'} = $ver;

      return $line;

    } ## end if ( $module =~ /\Av?([\d._]+)\z/xsm)

    # ph files do not use the package name inside the file.
    # perlmodlib documentation says:

    #       the .ph files made by h2ph will probably end up as
    #       extension modules made by h2xs.

    # so do not expend much effort on these.

    # there is no easy way to find out if a file named systeminfo.ph
    # will be included with the name sys/systeminfo.ph so only use the
    # basename of *.ph files

    return $line if $module =~ /[.]ph\z/xsm;

    # use base|parent qw(Foo) dependencies
    if ( $statement eq 'use'
      && ( $module eq 'base' || $module eq 'parent' ) ) {
      $self->add_require( $module, $version );

      if ( $version =~ /\Aqw\s*[{(\/'"]\s*([^)}\/"']+?)\s*[})\/"']/xsm ) {
        foreach ( split $SPACE, $1 ) {
          $self->add_require( $line, undef );
        } ## end foreach ( split $SPACE, $1 )
      } ## end if ( $version =~ ...)
      elsif ( $version =~ /(["'])([^"']+)\1/xsm ) {
        $self->add_require( $2, undef );
      } ## end elsif ( $version =~ /(["'])([^"']+)\1/xsm)

      return $line;
    } ## end if ( $statement eq 'use'...)

    if ( $version && $version !~ /\A$modver_re\z/oxsm ) {
      $version = undef;
    } ## end if ( $version && $version...)

    $self->add_require( $module, $version );
  } ## end if ( ( $line =~ /\A(\s*) # we hope the inclusion starts the line...))

  return $line;
} ## end sub parse_line

########################################################################
sub parse {
########################################################################
  my ( $self, $script ) = @_;

  if ( my $file = $self->get_path ) {
    chomp $file;

    open my $fh, '<', $file ## no critic (InputOutput::RequireBriefOpen)
      or croak "could not open file '$file' for reading: $OS_ERROR";

    $self->set_handle($fh);
  } ## end if ( my $file = $self->...)

  if ( !$self->get_handle && $script ) {
    $self->set_handle( IO::Scalar->new($script) );
  } ## end if ( !$self->get_handle...)
  elsif ( !$self->get_handle ) {
    open my $fh, '<&STDIN'  ## no critic (InputOutput::RequireBriefOpen)
      or croak 'could not open STDIN';

    $self->set_handle($fh);
  } ## end elsif ( !$self->get_handle)

  my $fh = $self->get_handle;

  while ( my $line = <$fh> ) {
    last if !$self->parse_line($line);
  } ## end while ( my $line = <$fh> )

  # only close the file if we opened...
  if ( $self->get_path ) {
    close $fh
      or croak 'could not close file ' . $self->get_path . "$OS_ERROR\n";
  } ## end if ( $self->get_path )

  return sort keys %{ $self->get_require };
} ## end sub parse

########################################################################
#
# To be honest, I'm really not sure what the code below should do
# other than simply put the version number in the hash. I can only
# surmise that if the original script was running in the context of a
# list of perl scripts in a project AND one script specified an older
# version of a module, then that version is replace with the newer
# version.
#
# In our implementation here, the typical use case (I think) will be
# for an instance of Module::ScanDeps::Static to parse one
# script. However, it is possible for the instance to scan multiple
# files by calling "parse()" iteratively, accumulating the
# dependencies along the way. In that case this method's actions
# appear to be relevant.
#
# Thinking through the above use case and the way it is being
# implemented might indicate a "bug", or at least a design flaw. Take
# the case where two Perl scripts (presumably in the same project
# considering that this utility was written for packaging RPMs)
# require different versions of the same module. Rare, and odd, but
# possible - although one might wonder why the author of these scripts
# didn't resolve any conflicts between the modules so that he could
# use one version of said module.
#
# In any event this method enforces a single version of the module
# (the highest) as the answer to the question what version of
# __fill_in_the_blank__ module do I require?
#
# The original method did not attempt to find the version of the
# module on the system where this script was being executed. This
# implementation does try to do that if you've sent the "add_version"
# option to a true value.
########################################################################

########################################################################
sub add_require {
########################################################################
  my ( $self, $module, $newver ) = @_;

  $module =~ s/\A\s*//xsm;
  $module =~ s/\s*\z//xsm;

  my $require = $self->get_require;

  my $oldver = $require->{$module};

  if ($oldver) {
    if ( $HAVE_VERSION && $newver && version->new($oldver) < $newver ) {
      $require->{$module} = $newver;
    } ## end if ( $HAVE_VERSION && ...)
  } ## end if ($oldver)
  elsif ( !$newver ) {
    my $m = {};

    if ( $self->get_add_version ) {
      $m = $self->get_module_version($module);
    } ## end if ( $self->get_add_version)

    $require->{$module} = $m->{'version'} // $EMPTY;
  } ## end elsif ( !$newver )
  else {
    $require->{$module} = $newver;
  } ## end else [ if ($oldver) ]

  return $self;
} ## end sub add_require

########################################################################
sub format_json {
########################################################################
  my ( $self, @requirements ) = @_;

  my %perlreq = %{ $self->get_perlreq };

  my %requires = %{ $self->get_require };

  if ( exists $perlreq{'perl'} && $self->get_core ) {
    my $perl_version = $perlreq{'perl'};

    if ( !$perl_version && $self->get_add_version ) {
      $perl_version = $PERL_VERSION;
    } ## end if ( !$perl_version &&...)

    push @requirements,
      {
      name    => 'perl',
      version => $perl_version // $EMPTY
      };
  } ## end if ( exists $perlreq{'perl'...})

  foreach my $m ( sort keys %requires ) {

    next if !$self->get_core && $self->is_core($m);

    push @requirements,
      {
      name    => $m,
      version => $requires{$m}
      };
  } ## end foreach my $m ( sort keys %requires)

  my $json = JSON::PP->new->pretty;

  return wantarray ? @requirements : $json->encode( \@requirements );
} ## end sub format_json

########################################################################
sub get_dependencies {
########################################################################
  my ( $self, %options ) = @_;

  if ( $self->get_json ) {
    return scalar $self->format_json;
  } ## end if ( $self->get_json )
  elsif ( $self->get_text || $self->get_raw ) {
    return $self->format_text;
  } ## end elsif ( $self->get_text ||...)
  else {
    return $self->format_json;
  } ## end else [ if ( $self->get_json )]
} ## end sub get_dependencies

########################################################################
sub format_text {
########################################################################
  my ($self) = @_;

  my @requirements = $self->format_json;
  return if !@requirements;

  my $str = $EMPTY;

  my $max_len = 2 + max map { length $_->{'name'} } @requirements;

  my @output;

  foreach my $module (@requirements) {
    my ( $name, $version ) = @{$module}{qw{ name version }};

    my $separator = $self->get_separator;
    my $format    = "%-${max_len}s%s'%s',";

    if ( $self->get_raw ) {
      $separator = $SPACE;
      $format    = "%-${max_len}s%s%s";
    } ## end if ( $self->get_raw )
    else {
      $name = "'$name'";
    } ## end else [ if ( $self->get_raw ) ]

    push @output, sprintf $format, $name, $separator, $version // $EMPTY;
  } ## end foreach my $module (@requirements)

  return join $NEWLINE, @output, $EMPTY;
} ## end sub format_text

########################################################################
sub to_rpm {
########################################################################
  my ($self) = @_;

  my @rpm_deps = ();

  foreach my $perlver ( sort keys %{ $self->get_perlreq } ) {
    push @rpm_deps, "perl >= $perlver";
  } ## end foreach my $perlver ( sort ...)

  my %require = %{ $self->get_require };

  foreach my $module ( sort keys %require ) {
    next if !$self->get_core && $self->is_core($module);

    if ( !$require{$module} ) {
      my $m;

      if ( $self->get_add_version ) {
        $m = $self->get_module_version($module);
        if ( $m->{'version'} ) {
          $require{$module} = $m->{'version'};

          push @rpm_deps, "perl($module) >= %s", $m->{'version'};
        } ## end if ( $m->{'version'} )
      } ## end if ( $self->get_add_version)

      if ( !$m || !$m->{'version'} ) {
        push @rpm_deps, "perl($module)";
      } ## end if ( !$m || !$m->{'version'...})
    } ## end if ( !$require{$module...})
    else {
      push @rpm_deps, "perl($module) >= $require{$module}";
    } ## end else [ if ( !$require{$module...})]
  } ## end foreach my $module ( sort keys...)

  return join $EMPTY, @rpm_deps;
} ## end sub to_rpm

########################################################################
sub main {
########################################################################

  my %options = (
    core               => $TRUE,
    'add-version'      => $TRUE,
    'include-require'  => $TRUE,
    'json'             => $FALSE,
    'text'             => $TRUE,
    'separator'        => q{ => },
    'min-core-version' => '5.8.9',
  );

  GetOptions(
    \%options,              'json|j',
    'text|t',               'core!',
    'min-core-version|m=s', 'add-version|a!',
    'include-require|i!',   'help|h',
    'separator|s=s',        'version|v',
    'raw|r',
  );

  # print {*STDERR} Dumper( \%options );

  if ( $options{'version'} ) {
    pod2usage(
      -exitval  => 1,
      -input    => pod_where( { -inc => 1 }, __PACKAGE__ ),
      -sections => 'VERSION|NAME|AUTHOR',
      -verbose  => 99,
    );
  } ## end if ( $options{'version'...})

  if ( $options{'help'} ) {
    pod2usage(
      -exitval  => 1,
      -input    => pod_where( { -inc => 1 }, __PACKAGE__ ),
      -sections => 'USAGE|VERSION',
      -verbose  => 99,
    );
  } ## end if ( $options{'help'} )

  $options{'path'} = shift @ARGV;

  my $scanner = Module::ScanDeps::Static->new( {%options} );
  $scanner->parse;

  if ( $options{'json'} ) {
    print $scanner->get_dependencies( format => 'json' );
  } ## end if ( $options{'json'} )
  else {
    print $scanner->get_dependencies( format => 'text' );
  } ## end else [ if ( $options{'json'} )]

  exit $SUCCESS;
} ## end sub main

1;

__END__

=pod

=head1 NAME

Module::ScanDeps::Static - a cleanup of rpmbuild's perl.req

=head1 SYNOPSIS

 my $scanner = Module::ScanDeps::Static->new({ file => 'myfile.pl' });
 $scanner->parse;
 print $scanner->get_dependencies;

=head1 DESCRIPTION

This module is a mashup (and cleanup) of the `/usr/lib/rpm/perl.req`
file found in the rpm build tools library (see L</LICENSE>) below.

Successful identification of the required Perl modules for a module or
script is the subject of more than one project on CPAN. While each
approach has its pros and cons I have yet to find a better scanner
than the simple parser that Ken Estes wrote for the rpm build tools
package.

C<Module::ScanDeps::Static> is a simple static scanner that
essentially uses regular expressions to locate C<use>, C<require>,
C<parent>, and C<base> in all of their disguised forms inside your
Perl script or module.  It's not perfect and the regular expressions
could use some polishing, but it works on a broad enough set of
situations as to be useful.

I<NOTE: Only direct dependencies are returned by this module. If you
want a recursive search for dependencies, use C<scandeps.pl>>

I<!!EXPERIMENTAL!!>

I<The methods and output of this module is subject to revision!>

=head1 USAGE

scandeps-static.pl [options] Module

If "Module" is not provided, the script will read from STDIN.

=head2 Examples

 scandeps-static.pl --no-core $(which scandeps-static.pl)

 scandeps-static.pl --json $(which scandeps-static.pl)

=head2 Options

=over 5

=item --add-version, -a, --no-add-version

Add the version number to the dependency list by inspecting the version of
the module in your @INC path.

default: B<--add-version>

=item --core, -c, --no-core

Include or exclude core modules. See --min-core-version for
description of how core modules are identified.

default: B<--core>

=item --help, -h

Show usage.

=item --include-require, -i, --no-include-require

Include statements that have C<Require> in them but are not
necessarily on the left edge of the code (possibly in tests).

default: <--include-require>

=item --json, -j

Output the dependency list as a JSON encode string.

=item --min-core-version, -m

The minimum version of Perl that is considered core. Use this to
consider some modules non-core if they did not appear until after the
C<min-core-version>.

Core modules are identified using C<Module::CoreList> and comparing
the first release value of the module with the the minimum version of
Perl considered as a baseline.  If you're using this module to
identify the dependencies for your script B<AND> you know you will be
using a specific version of Perl, then set the C<min-core-version> to
that version of Perl.

default: 5.8.9

=item --separator, -s

Use the specified sting to separate modules and version numbers in formatted output.

default: ' => '

=item --text, -t

Output the dependency list as a simple text listing of module name and
version in the same manner as C<scandeps.pl>.

default: B<--text>

=item --raw, -r

Output the list with no quotes separated by a single whitespace
character.

=back

=head1 WHAT IS A DEPENDENCY?

For the purposes of this module, dependencies are identified by
looking for Perl modules and other Perl artifacts declared using
C<use>, C<require>, C<parent>, or C<base>.

If the module contains a C<require> statement, by default the
C<require> must be flush up against the left edge of your script
without any whitespace between it and beginning of the line.  This is
the default behavior to avoid identifying C<require> statements that
are embedded in C<if> statements. If you want to include all of
the targets of C<require> statements as dependencies, set the
C<include-require> option to a true value.

=head1 MINOR IMPROVEMENTS TO C<perl.req>

=over 5

=item * Allow detection of C<require> not at beginning of line.

Use the C<--include-require> to expand the definition of a dependency
to any module or Perl script that is the argument of the C<require>
statement.

=item * Allow detection of the C<parent>, C<base> statemens use of curly braces.

The regular expression and algorithm in C<parse> has been enhanced to
detect the use of curly braces in C<use> or C<parent> declarations.

=item * Exclude core modules.

Use the C<--no-core> option to ignore core modules.

=item * Add the current version of installed module if version not explicitly specified.

=back

=head1 CAVEATS

There are still many situations (including multi-line statements) that
may prevent this module from properly identifying a dependency. As
always, YMMV.

=head1 METHODS AND SUBROUTINES

=head2 new

 new(options)

Returns a C<Module::ScanDeps::Static> object.

=head3 Options

=over 5

=item include_require

Boolean value that determines whether to consider C<require>
statements that are not left-aligned to be considered dependencies.

default: B<false>

=item add_version

Boolean value that determines whether to include the version of the
module currently installed if there is no version specified.

default: B<false>

=item core

Boolean value that determines whether to include core modules as part
of the dependency listing.

default: B<true>

=item json

Boolean value that indicates output should be in JSON format.

default: B<false>

=item min_core_version

The minimum version of Perl which will be used to decide if a module
is include in Perl core.

default: 5.8.9

=item separator

Character string to use formatting dependency list as text. This
string will be used to separate the module name from the version.

default: ' => '

 Module::ScanDeps::Static 0.1

=item text

Boolean value that indicates output should be in the same format as C<scandeps.pl>.

dafault: B<true>

=item raw

Boolean value that indicates output should be in raw format (module version).

default: B<falue>

=back

=head2 get_require

After calling the C<parse()> method, call this method to retrieve a
hash containing the dependencies and (potentially) their version
numbers.

 $scanner->parse

=head2 parse

=over 5

=item parse a file

 my @dependencies = Module::ScanDeps::Static->new({ path => $path })->parse;

=item parse from file handle

 my @dependencies = Module::ScanDeps::Static->new({ handle => $path })->parse;
 
=item parse STDIN

 my @dependencies = Module::ScanDeps::Static->new->parse(\$script);

=item parse string

 my @dependencies = parse(\$script);

=back

Scans the specified input and returns a list Perl modulde dependencies.

Use the C<get_dependencies> method to retrieve the dependencies as a
formatted string or as a list of dependency objects. Use the
C<get_require> and C<get_perlreq> methods to retrieve dependencies as
a list of hash refs.

 my $scanner = Module::ScanDeps::Static->new({ path => 'my-script.pl' });
 my @dependencies = $scanner->parse;

=head2 get_dependencies

Returns a formatted list of dependencies or a list of dependency objects.

As JSON:

 print $scanner->get_dependencies( format => 'json' )

 [
   {
    "name" : "Module::Name",
    "version" "version"
   },
   ...
 ]

..or as text:

 print $scanner->get_dependencies( format => 'text' )

 Module::Name >= version
 ...

In scalar context in the absence of an argument returns a JSON
formatted string. In list context will return a list of hashes that
contain the keys "name" and "version" for each dependency.

=head1 VERSION

0.3

=head1 AUTHOR

This module is largely a lift and drop of Ken Este's `perl.req` script
lifted from rpm build tools.

Ken Estes Mail.com kestes@staff.mail.com

The method `parse` is a cleaned up version of `process_file` from the
same script.

Rob Lauer - <bigfoot@cpan.org>

=head1 LICENSE

This statement was lifted right from C<perl.req>...

=over 10

I<The entire code base may be distributed under the terms of the
GNU General Public License (GPL), which appears immediately below.
Alternatively, all of the source code in the lib subdirectory of the
RPM source code distribution as well as any code derived from that
code may instead be distributed under the GNU Library General Public
License (LGPL), at the choice of the distributor. The complete text of
the LGPL appears at the bottom of this file.>

I<This alternatively is allowed to enable applications to be linked
against the RPM library (commonly called librpm) without forcing
such applications to be distributed under the GPL.>

I<Any questions regarding the licensing of RPM should be addressed to
Erik Troan <ewt@redhat.com>.>

=back

=cut
