package Module::ScanDeps::Static;

use strict;
use warnings;

use 5.010;

use Carp;
use CLI::Simple::Utils qw(slurp);
use CLI::Simple::Constants qw(:booleans :chars);
use Data::Dumper;
use English qw( -no_match_vars );
use ExtUtils::MM;
use Getopt::Long;
use JSON;
use Module::CoreList;
use Pod::Usage;
use Pod::Find qw( pod_where );
use IO::Scalar;
use List::Util qw( max none );
use version;

use parent qw( CLI::Simple);

use Readonly;
Readonly::Scalar my $DEFAULT_MIN_CORE_VERSION => $PERL_VERSION;

our $VERSION = '1.9.1';

__PACKAGE__->use_log4perl( level => 'info' );

caller or exit __PACKAGE__->main();

########################################################################
sub make_path_from_module {
########################################################################
  my ( $self, $module ) = @_;

  my $file = join $SLASH, split /$DOUBLE_COLON/xsm, $module;

  return "$file.pm";
}

########################################################################
sub get_module_version {
########################################################################
  my ( $self, $module_w_version, @include_path ) = @_;

  if ( !@include_path ) {
    @include_path = @INC;
  }

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

    $module_version{'version'} = eval {
      my $v = ExtUtils::MM->parse_version($path);

      return $v eq 'undef' ? 0 : $v || 0;
    };

    last;
  }

  return \%module_version;
}

########################################################################
sub min_core_version {
########################################################################
  my ($self) = @_;

  my $min_core_version = $self->get_min_core_version;
  $min_core_version = $min_core_version =~ /^v/xsm ? $min_core_version : "v$min_core_version";

  return version->parse($min_core_version)->numify;
}

########################################################################
sub is_core {
########################################################################
  my ( $self, $module_w_version ) = @_;

  my ( $module, $version ) = split /\s/xsm, $module_w_version;

  my $core = $FALSE;

  my $first_release = Module::CoreList->first_release($module);

  my $removed_version = Module::CoreList->removed_from($module);

  my $min_core_version = $self->min_core_version();

  $self->get_logger->debug(
    sprintf 'module: %s first_release: %s removed_version: %s min_core_version: %s',
    $module_w_version,
    $first_release   // q{-},
    $removed_version // q{-},
    $min_core_version,
  );

  # consider a module core if its first release was less than some
  # version of Perl. This is done because CPAN testers don't seem to
  # test modules against Perls that are older than 5.8.9 - however,
  # some modules like JSON::PP did not appear until after 5.10

  # any removed module must be considered non-core
  if ( !$removed_version && $first_release ) {
    $core = $first_release <= $min_core_version;
  }

  $self->get_logger->debug( sprintf 'module: %s is %score', $module_w_version, $core ? q{} : 'NOT ' );

  return $core;
}

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
    }

    $line = <$fh>;

    return if !$line;

  }

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
    }

    return if !$line;
  }

  # skip the documentation

  # we should not need to have item in this if statement (it
  # properly belongs in the over/back section) but people do not
  # read the perldoc.

  if ( $line =~ /\A=(head[\d]|pod|for|item)/xsm ) {

    while ( $line = <$fh> ) {
      last if $line =~ /\A^=cut/xsm;
    }

    return if !$line;
  }

  if ( $line =~ /\A=over/xsm ) {
    while ( $line = <$fh> ) {
      last if /\A=back/xsm;
    }

    return if !$line;
  }

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
    }

    $line = <$fh>;

    return if !$line;
  }

  # Skip multiline print and assign statements
  if ( $line =~ /\$\S+\s*=\s*(")([^"\\]|(\\.))*\z/xsm
    || $line =~ /\$\S+\s*=\s*(')([^'\\]|(\\.))*\z/xsm
    || $line =~ /print\s+(")([^"\\]|(\\.))*\z/xsm
    || $line =~ /print\s+(')([^'\\]|(\\.))*\z/xsm ) {

    my $quote = $1;

    while ( $line = <$fh> ) {
      last if $line =~ /\A([^\\$quote]|(\\.))*$quote/xsm;
    }

    $line = <$fh>;

    return if !$line;
  }

  # Role::Tiny::With / Moo::with-style role composition:
  #
  #   use Role::Tiny::With;
  #   with 'Foo';
  #
  #   with 'Foo', 'Bar';
  #   with qw(Foo Bar);
  #
  # 'with' is not a use/require statement so it never enters the
  # require|use branch below. Anchor on 'with' as the leading token
  # (whitespace immediately after) so we don't match "without", a
  # hash key 'with => ...', or prose in comments/POD.
  if ( $line =~ /\A\s*with\b\s*(.*?)\s*;?\s*\z/xsm ) {

    my $args = $1;

    # with('Foo') / with ('Foo', 'Bar') -- strip an enclosing call
    # paren, but only when it isn't the paren belonging to qw(...).
    if ( $args =~ /\A[(](.*)[)]\z/xsm && $args !~ /\Aqw\b/xsm ) {
      $args = $1;
    }

    if ( $args =~ /\Aqw\s*[{(\/'"]\s*([^)}\/'"]+)\s*[)}\/'"]/xsm ) {
      foreach ( split $SPACE, $1 ) {
        $self->add_require( $_, undef );
      }

      return $line;
    }
    elsif ( $args =~ /\A(["'])[\w:]+\1(\s*,\s*(["'])[\w:]+\3)*\z/xsm ) {
      while ( $args =~ /(["'])([\w:]+)\1/gxsm ) {
        $self->add_require( $2, undef );
      }

      return $line;
    }

    # doesn't look like a role list after all (e.g. "with the
    # following caveats" in a comment/doc line that slipped through)
    # -- fall through to normal processing below.
  }

  # ouch could be in a eval, perhaps we do not want these since we catch
  # an exception they must not be required

  #   eval { require Term::ReadLine } or die $@;
  #   eval "require Term::Rendezvous;" or die $@;
  #   eval { require Carp } if defined $^S; # If error/warning during compilation,

  ## no critic (ProhibitComplexRegexes, RequireBracesForMultiline)
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

    #print {*STDERR} "$whitespace, $statement, $module, $version\n";

    # fix misidentification of version when use parent qw{ Foo };
    #
    # Pragmatism dictates that I just identify the misidentification
    # instead of trying to make the regexp above even more
    # complicated...

    if ( $statement eq 'use' && $module =~ /(parent|base)/xsm ) {
      if ( $version =~ /\A\s*qw?\s*['"{(\/]\s*([^'")}\/]+)\s*['")}\/]/xsm ) {
        $module  = $1;
        $version = $EMPTY;
      }
      elsif ( $version =~ /\A\s*['"]([^"']+)['"]\s*\z/xsm ) {
        $module  = $1;
        $version = $EMPTY;
      }
    }

    #print {*STDERR} "$whitespace, $statement, $module, $version\n";

    #

    # we only consider require statements that are flushed against
    # the left edge. any other require statements give too many
    # false positives, as they are usually inside of an if statement
    # as a fallback module or a rarely used option

    if ( !$self->get_include_require ) {
      return $line if $whitespace ne $EMPTY && $statement eq 'require';
    }
    elsif ( $statement eq 'require' ) {
      return $line if $line =~ /\$/xsm;  # eval?
    }

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
    }

    # sometimes people do use POSIX qw(foo), or use POSIX(qw(foo)) etc.
    # we can strip qw.*$, as well as (.*$:
    $module =~ s/qw.*\z//xsm;
    $module =~ s/[(].*\z//xsm;

    # some perl programmers write 'require URI/URL;' when
    # they mean 'require URI::URL;'
    if ( $module !~ /[.]pl$/xsm ) {
      # if the module ends with .pm, strip it to leave only basename.
      $module =~ s/[.]pm\z//xsm;

      $module =~ s/\//::/xsgm;
    }

    # trim off trailing parentheses if any.  Sometimes people pass
    # the module an empty list.
    $module =~ s/[(]\s*[)]$//xsm;

    if ( $module =~ /\Av?([\d._]+)\z/xsm ) {
      # if module is a number then both require and use interpret that
      # to mean that a particular version of perl is specified

      my $ver = $1;

      $self->get_perlreq->{'perl'} = $ver;

      return $line;

    }

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
      #print {*STDERR}
      #  "statement: $statement module: $module, version: $version\n";

      if ( $version =~ /\Aqw\s*[{(\/'"]\s*([^)}\/"']+?)\s*[})\/"']/xsm ) {
        foreach ( split $SPACE, $1 ) {
          $self->add_require( $line, undef );
        }
      }
      elsif ( $version =~ /(["'])([^"']+)\1/xsm ) {
        $self->add_require( $2, undef );
      }

      return $line;
    }

    if ( $version && $version !~ /\A$modver_re\z/oxsm ) {
      $version = undef;
    }
    #print {*STDERR}
    #  "statement: $statement module: $module, version: $version\n";

    my @module_list = split /\s+/xsm, $module;

    if ( @module_list > 1 ) {
      for (@module_list) {
        $self->add_require( $_, $EMPTY );
      }
    }
    else {
      $self->add_require( $module, $version );
    }
  }

  return $line;
}

########################################################################
sub parse {
########################################################################
  my ( $self, $script ) = @_;

  if ( my $file = $self->get_path ) {
    chomp $file;

    open my $fh, '<', $file ## no critic (InputOutput::RequireBriefOpen)
      or croak "could not open file '$file' for reading: $OS_ERROR";

    $self->set_handle($fh);
  }

  if ( !$self->get_handle && $script ) {
    $self->set_handle( IO::Scalar->new($script) );
  }
  elsif ( !$self->get_handle ) {
    open my $fh, '<', \*STDIN ## no critic (InputOutput::RequireBriefOpen)
      or croak 'could not open STDIN';

    $self->set_handle($fh);
  }

  my $fh = $self->get_handle;

  while ( my $line = <$fh> ) {
    last if !$self->parse_line($line);
  }

  # only close the file if we opened...
  if ( $self->get_path ) {
    close $fh
      or croak 'could not close file ' . $self->get_path . "$OS_ERROR\n";
  }

  my @sorted_dependencies = sort keys %{ $self->get_require };

  return @sorted_dependencies;
}

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

  $newver //= $EMPTY;

  $module =~ s/\A\s*//xsm;
  $module =~ s/\s*\z//xsm;

  my $require = $self->get_require;

  my $oldver = $require->{$module};

  if ($oldver) {
    if ( $newver && version->new($oldver) < $newver ) {
      $require->{$module} = $newver;
    }
  }
  elsif ( !$newver ) {
    my $m = {};

    if ( $self->get_add_version ) {
      $m = $self->get_module_version($module);
    }

    $require->{$module} = $m->{'version'} // $EMPTY;
  }
  else {
    $require->{$module} = $newver // $EMPTY;
  }

  return $self;
}

########################################################################
sub format_json {
########################################################################
  my ( $self, @requirements ) = @_;

  my %perlreq = %{ $self->get_perlreq };

  my %requires = %{ $self->get_require };

  if ( exists $perlreq{'perl'} ) {
    my $perl_version = $perlreq{'perl'};

    if ( !$perl_version && $self->get_add_version ) {
      $perl_version = $PERL_VERSION;
    }

    push @requirements,
      {
      name    => 'perl',
      version => $perl_version // $EMPTY
      };
  }

  foreach my $m ( sort keys %requires ) {

    next if !$self->get_core && $self->is_core($m);

    push @requirements,
      {
      name    => $m,
      version => $requires{$m}
      };
  }

  my $json = JSON->new->pretty;

  return wantarray ? @requirements : $json->encode( \@requirements );
}

########################################################################
sub get_dependencies {
########################################################################
  my ( $self, %options ) = @_;

  my $format = $options{format} // $EMPTY;

  if ( ( $options{format} && $options{format} eq 'json' ) || $self->get_json ) {
    return scalar $self->format_json;
  }
  elsif ( ( $options{format} && $options{format} eq 'text' ) || $self->get_text || $self->get_raw ) {
    return $self->format_text;
  }
  else {
    return $self->format_json;
  }
}

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
    }
    else {
      $name = "'$name'";
      $separator //= $SPACE;
    }

    push @output, sprintf $format, $name, $separator, $version // $EMPTY;
  }

  return join "\n", @output, $EMPTY;
}

########################################################################
sub to_rpm {
########################################################################
  my ($self) = @_;

  my @rpm_deps = ();

  foreach my $perlver ( sort values %{ $self->get_perlreq } ) {
    push @rpm_deps, "perl >= $perlver";
  }

  my %require = %{ $self->get_require };

  foreach my $module ( sort keys %require ) {
    next if !$self->get_core && $self->is_core($module);

    if ( !$require{$module} ) {
      my $m;

      if ( $self->get_add_version ) {
        $m = $self->get_module_version($module);
        if ( $m->{'version'} ) {
          $require{$module} = $m->{'version'};

          push @rpm_deps, "perl($module) >= $m->{'version'}";
        }
      }

      if ( !$m || !$m->{'version'} ) {
        push @rpm_deps, "perl($module)";
      }
    }
    else {
      push @rpm_deps, "perl($module) >= $require{$module}";
    }
  }

  return join "\n", @rpm_deps, $EMPTY;
}

########################################################################
sub _extra_options {
########################################################################
  return [qw(perlreq require handle files)];
}

########################################################################
sub _option_specs {
########################################################################
  return [
    qw(
      add-version|a!
      core|c!
      help|h
      include-require|i!
      json|j
      log-level|l
      min-core-version|m=s
      raw|r
      separator|s=s
      text|t
      version|v
      path|p=s
      file-list|L=s
    )
  ];
}

########################################################################
sub _default_options {
########################################################################
  return {
    add_version      => $TRUE,
    core             => $TRUE,
    include_require  => $TRUE,
    json             => $FALSE,
    min_core_version => '5.8.9',
    separator        => q{ => },
    text             => $TRUE,
  };
}

########################################################################
sub new {
########################################################################
  my ( $class, $options ) = @_;

  # extra_options (perlreq, require, handle, files) are accessor-only
  # fields -- CLI::Simple creates get_X/set_X for them but never
  # populates them via GetOptions, since they aren't part of
  # option_specs at all (and in handle's case, can't be: a filehandle
  # reference isn't representable as a command-line string). Pull
  # these out before building @argv and set them directly on the
  # constructed object instead.
  my %is_extra = map { $_ => 1 } @{ _extra_options() };

  my %extra_values;
  my %cli_values;

  foreach my $o ( keys %{$options} ) {
    if ( $is_extra{$o} ) {
      $extra_values{$o} = $options->{$o};
    }
    else {
      $cli_values{$o} = $options->{$o};
    }
  }

  # classify each known option_spec as negatable ('!'), plain boolean
  # (no type suffix at all -- presence-only, no --no-X form), or
  # value-taking ('=s' etc.), so the hashref -> @ARGV translation below
  # can represent each key correctly instead of treating them all the
  # same way.
  my %spec_type;

  foreach my $spec ( @{ _option_specs() } ) {
    my ($name) = split /[^\w-]/xsm, $spec;

    if ( $spec =~ /[!]\z/xsm ) {
      $spec_type{$name} = 'negatable';
    }
    elsif ( $spec =~ /[=:]/xsm ) {
      $spec_type{$name} = 'value';
    }
    else {
      $spec_type{$name} = 'boolean';
    }
  }

  my @argv;

  foreach my $o ( keys %cli_values ) {
    ( my $dashed = $o ) =~ s/_/-/gxsm;

    my $arg_name = length $dashed == 1 ? "-$dashed" : "--$dashed";

    my $type = $spec_type{$dashed};

    if ( !defined $type ) {
      # unrecognized key that isn't an extra_options field either --
      # not something we know how to represent; pass through as-is
      # and let GetOptions report the error.
      push @argv, ( $arg_name => $cli_values{$o} );
    }
    elsif ( $type eq 'negatable' ) {
      push @argv, $cli_values{$o} ? $arg_name : "--no-$dashed";
    }
    elsif ( $type eq 'boolean' ) {
      # no negated form exists for these -- omit entirely when false
      # rather than emitting a flag GetOptions won't recognize.
      push @argv, $arg_name if $cli_values{$o};
    }
    elsif ( defined $cli_values{$o} ) {
      push @argv, ( $arg_name => $cli_values{$o} );
    }
    else {
      push @argv, $arg_name;
    }
  }

  local @ARGV = @argv;

  my $self = __PACKAGE__->main($TRUE);

  foreach my $k ( keys %extra_values ) {
    my $setter = "set_$k";
    $self->$setter( $extra_values{$k} );
  }

  return $self;
}

########################################################################
sub main {
########################################################################
  my ( $class, $setup ) = @_;

  my $cli = __PACKAGE__->SUPER::new(
    commands         => { scan => \&cmd_scan },
    option_specs     => _option_specs(),
    default_options  => _default_options(),
    extra_options    => _extra_options(),
    validate_command => $FALSE,
  );

  return $setup ? $cli : return $cli->run;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my @args = $self->get_args;

  if ( !@args ) {
    $self->command_args( $self->command() );  # set the args to the command
    $self->command('scan');  # set the command to your default
  }
  else {
    die "ERROR: unknown command\n"
      if !$self->commands->{ $self->command };  # validate the command
  }

  my @file_list = eval {

    if ( my $file_list = $self->get_file_list ) {
      my $list = slurp($file_list);

      $self->set_json($FALSE);

      return split /\n/xsm, $list;
    }

    return $self->get_path
      if $self->get_path;

    return $self->get_args;
  };

  $self->set_files( \@file_list );

  $self->set_perlreq( {} );

  $self->set_require( {} );

  return;
}

########################################################################
sub cmd_scan {
########################################################################
  my ($self) = @_;

  my @deps;

  foreach my $file ( @{ $self->get_files } ) {
    $self->set_path($file);

    $self->parse;

    if ( $self->get_json ) {
      push @deps, $self->get_dependencies( format => 'json' );
    }
    else {
      push @deps, $self->get_dependencies( format => 'text' );
    }
  }

  print {*STDOUT} "@deps";

  return $SUCCESS;
}

1;

__END__

=pod

=head1 NAME

Module::ScanDeps::Static - a cleanup of rpmbuild's perl.req

=head1 SYNOPSIS

 scandeps-static [options] Module

If "Module" is not provided, the script will read from STDIN.

 my $scanner = Module::ScanDeps::Static->new({ path => 'myfile.pl' });
 $scanner->parse;
 print $scanner->format_text;

=head1 DESCRIPTION

This module is a mashup (and cleanup) of the F</usr/lib/rpm/perl.req>
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

I<Only direct dependencies are returned by this module. If you
want a recursive search for dependencies, use C<find-requires>
included in this distribution.>

=head1 OPTIONS

 --add-version, -a        add version numbers to output
 --no-add-version         don't add version numbers to output
 --core                   include core modules (default)
 --no-core                don't include core modules
 --file-list, -L PATH     scan a batch of files listed one per line in PATH
 --help, -h               help
 --include-require, -i    include 'require'd modules
 --no-include-require     don't include required modules
 --json, -j               output JSON formatted list
 --min-core-version, -m   minimum version of perl to consider core
 --path, -p PATH          file to scan (alternative to the positional argument)
 --raw, -r                raw output
 --separator, -s          separator for output (default: =>)
 --text, -t               output as text (default)
 --version, -v            version

=head2 Examples

 scandeps-static --no-core lib/Some/Module.pm

 scandeps-static --json lib/Some/Module.pm

I<Use the C<find-requires> script included in this distribution to
recurse directories and create dependency files like C<cpanfile>>.

=head1 OPTION DETAILS

=over 5

=item --add-version, -a, --no-add-version

Add the version number to the dependency list by inspecting the version of
the module in your @INC path.

default: B<--add-version>

=item --core, -c, --no-core

Include or exclude core modules. See --min-core-version for
description of how core modules are identified.

default: B<--core>

=item --file-list, -L PATH

Scan a batch of files in a single process instead of one file per
invocation. C<PATH> is a file containing one source file path per
line (relative or absolute); each listed file is scanned in turn and
the results are aggregated. There is currently no way to supply the
list via C<STDIN> - C<PATH> must be a real file.

Batching this way avoids paying Perl's own process-startup cost and
the C<Module::CoreList> module-load cost (non-trivial - loading
C<Module::CoreList> alone is roughly an order of magnitude slower
than a bare C<perl> startup) once per file scanned, which matters a
great deal once a project has more than a handful of source files.

Because more than one JSON document cannot be safely concatenated
into a single valid JSON result, C<--json> is silently ignored
whenever C<--file-list> resolves to more than one file - output is
always text in that case. If the list happens to contain exactly one
file, C<--json> is honored normally.

=item --help, -h

Show usage.

=item --include-require, -i, --no-include-require

Include statements that have C<Require> in them but are not
necessarily on the left edge of the code (possibly in tests).

default: B<--include-require>

=item --json, -j

Output the dependency list as a JSON encode string. Silently ignored
in favor of text output when combined with C<--file-list> and more
than one file is being scanned - see L</--file-list, -L PATH>.

=item --min-core-version, -m

The minimum version of Perl that is considered core. Use this to
consider some modules non-core if they did not appear until after the
C<min-core-version>.

Core modules are identified using C<Module::CoreList> and comparing
the first release value of the module with the minimum version of
Perl considered as a baseline.  If you're using this module to
identify the dependencies for your script B<AND> you know you will be
using a specific version of Perl, then set the C<min-core-version> to
that version of Perl.

Note: this only governs the "not yet in core as of my baseline" case.
A module that was core at some point but has since been B<removed>
from core is always treated as non-core, regardless of
C<min-core-version> - there is no way to know which specific Perl an
end user actually has installed, so the only safe answer once a
module has ever been removed is to require it explicitly. See
L</is_core> for details.

default: C<5.8.9> (the C<Module::ScanDeps::Static> constructor's
C<min_core_version> option defaults this to the running Perl's version
instead)

=item --path, -p PATH

Path to the file to scan. Equivalent to supplying the path as a bare
positional argument; provided as a named option for clarity in
scripts that build up the command line programmatically. Ignored if
C<--file-list> is also given.

=item --separator, -s

Use the specified string to separate modules and version numbers in formatted output.

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
C<use>, C<require>, C<parent>, or C<base>. The script will also
consider Moo/Role::Tiny modules include using C<with>.

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

=item * Allow detection of the C<parent>, C<base> statements use of curly braces.

The regular expression and algorithm in C<parse> has been enhanced to
detect the use of curly braces in C<use> or C<parent> declarations.

=item * Exclude core modules.

Use the C<--no-core> option to ignore core modules.

=item * Add the current version of an installed module if the version
is not explicitly specified.

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

=item path

Path to a file to scan. When set, C<parse()> opens this file and reads
from it.

default: B<none> (if neither C<path> nor C<handle> is given, C<parse()>
reads from C<STDIN>)

=item handle

An open filehandle (or any C<IO::Handle>-like object) to read from
instead of a file. Ignored when C<path> is set.

default: B<none>

=item core

Boolean value that determines whether to include core modules as part
of the dependency listing.

default: B<true>

=item include_require

Boolean value that determines whether to consider C<require>
statements that are not left-aligned to be considered dependencies.

default: B<false> (the C<scandeps-static.pl> CLI defaults this to true)

=item add_version

Boolean value that determines whether to include the version of the
module currently installed if there is no version specified.

default: B<true>

=item min_core_version

The minimum version of Perl which will be used to decide if a module
is included in Perl core. See C<is_core> and the C<--min-core-version>
option for details.

default: B<the running Perl's version> (C<$PERL_VERSION>). The
C<scandeps-static.pl> CLI defaults this to C<5.8.9>.

=item json

Boolean value that indicates output should be in JSON format.

default: B<false>

=item text

Boolean value that indicates output should be in the same format as
C<scandeps.pl>. This is the default output format for C<get_dependencies>
when neither C<json> nor C<raw> is set.

default: B<true>

=item raw

Boolean value that indicates output should be in raw format
(module version).

default: B<false>

=item separator

Character string used to separate the module name from the version in
text output.

default: B<none> from the constructor; C<format_text> falls back to a
single space. The C<scandeps-static.pl> CLI sets this to C< => >.

=back

=head2 get_require

After calling the C<parse()> method, call this method to retrieve a
hash containing the dependencies and (potentially) their version
numbers.

 $scanner->parse;
 my $requires = $scanner->get_require;

=head2 get_perlreq

Returns a hash ref of Perl version requirements discovered while
parsing (keyed by C<'perl'>). Populated for C<use 5.010;> /
C<require 5.010;> style statements. Pair with C<get_require>.

 $scanner->parse;
 my $perlreq = $scanner->get_perlreq;  # { perl => '5.010', ... }

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

Scans the specified input and returns a list of Perl module dependencies.

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
    "version" : "version"
   },
   ...
 ]

..or as text:

 print $scanner->get_dependencies( format => 'text' )

 Module::Name => version
 ...

In scalar context in the absence of an argument returns a JSON
formatted string. In list context will return a list of hashes that
contain the keys "name" and "version" for each dependency.

Note: this context-sensitivity only applies when none of C<json>,
C<text>, or C<raw> is set (or when C<< format => 'json' >> /
C<< format => 'text' >> is passed explicitly). If the C<json> option is
true, C<get_dependencies> always returns a scalar JSON string, even
when called in list context.

=head2 format_text

 $scanner->parse;
 print $scanner->format_text;

Returns the dependency list as a formatted text string, one module per
line, honoring the C<separator> and C<raw> options. Core modules are
omitted when C<core> is false.

=head2 format_json

 my $json     = $scanner->format_json;   # scalar context
 my @requires = $scanner->format_json;   # list context

In scalar context returns a pretty-printed JSON string; in list context
returns a list of hash refs of the form C<< { name => ..., version =>
... } >>. Core modules are omitted when C<core> is false. Any arguments
are treated as a seed list and prepended to the results.

=head2 is_core

 my $bool = $scanner->is_core($module);
 my $bool = $scanner->is_core("$module $version");

Returns true if C<$module> is considered core. A module is core when
C<Module::CoreList> reports its first release at or before
C<min_core_version> B<and> the module has never been removed from
core at any point in its history.

A module that was core at some earlier Perl but has since been
removed is always treated as non-core, regardless of how
C<min_core_version> compares to the version it was removed at. There
is no way to know which Perl an end user actually has installed - a
version comparison against a single reference point only protects
against removals that happen to fall on one particular side of it, so
the only safe answer once a module has ever been removed is to always
require it explicitly.

=head2 min_core_version

 my $numified = $scanner->min_core_version;

Returns the C<min_core_version> option numified via C<version> (e.g.
C<5.008009>) for comparison inside C<is_core>. Note this is distinct
from the generated C<get_min_core_version> accessor, which returns the
raw stored value.

=head2 get_module_version

 my $info = $scanner->get_module_version($module, @include_path);

Returns a hash ref describing C<$module>:

 { module => ..., version => ..., path => ..., file => ... }

Searches C<@include_path> (defaulting to C<@INC>) for the module and
extracts its version via C<ExtUtils::MM->parse_version>. If C<$module>
already carries a version (C<"Foo::Bar 1.23">), that version is returned
without a filesystem lookup.

=head2 add_require

 $scanner->add_require($module);
 $scanner->add_require($module, $version);

Registers C<$module> as a dependency, optionally with C<$version>. When
no version is supplied and the C<add_version> option is true, the
installed version is looked up. Retains the higher of two versions if
the module is added more than once. Returns C<$self>.

=head2 to_rpm

 my $deps = $scanner->to_rpm;

Returns the dependency list as RPM-style requirement expressions
(C<perl(Module) E<gt>= version>, plus C<perl E<gt>= version> for any
Perl version requirement). Core modules are omitted when C<core> is
false.

=head1 VERSION

This documentation refers to version 1.8.2

=head1 AUTHOR

This module is largely a lift and drop of Ken Este's C<perl.req> script
lifted from rpm build tools.

Ken Estes Mail.com kestes@staff.mail.com

The method C<parse> is a cleaned up version of C<process_file> from the
same script.

Rob Lauer - <bigfoot@cpan.org>

=head1 LICENSE

This statement was lifted directly from C<perl.req>...

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
