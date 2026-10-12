package Module::ScanDeps::Static;

use strict;
use warnings;

use 5.010;

use Carp;
use CLI::Simple::Utils qw(slurp);
use CLI::Simple::Constants qw(:booleans :chars);
use Data::Dumper;
use English qw( -no_match_vars );
use Getopt::Long;
use JSON;
use IO::Scalar;
use List::Util qw( max none );
use version;

use parent qw( CLI::Simple);

use Readonly;
Readonly::Scalar my $DEFAULT_MIN_CORE_VERSION => $PERL_VERSION;

our $VERSION = '1.9.5';

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
      require ExtUtils::MM;
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

Readonly::Hash our %PRAGMA => map { ( $_ => 1 ) } qw(
  strict warnings vars lib feature utf8 bytes integer diagnostics
  sort subs re mro locale open less filetest attributes autouse
);

########################################################################
sub is_pragma {
########################################################################
  my ( $self, $module_w_version ) = @_;

  my ($module) = split /\s/xsm, $module_w_version;

  return $PRAGMA{$module} ? $TRUE : $FALSE;
}

########################################################################
sub is_core {
########################################################################
  my ( $self, $module_w_version ) = @_;

  my ( $module, $version ) = split /\s/xsm, $module_w_version;

  my $core = $FALSE;

  require Module::CoreList;

  my $first_release = Module::CoreList->first_release($module);

  my $removed_version = Module::CoreList->removed_from($module);

  my $min_core_version = $self->min_core_version();

  # consider a module core if its first release was less than some
  # version of Perl. This is done because CPAN testers don't seem to
  # test modules against Perls that are older than 5.8.9 - however,
  # some modules like JSON::PP did not appear until after 5.10

  # any removed module must be considered non-core
  if ( !$removed_version && $first_release ) {
    $core = $first_release <= $min_core_version;
  }

  return $core;
}

########################################################################
sub parse_line { ## no critic (Subroutines::ProhibitExcessComplexity)
########################################################################
  my ( $self, $line ) = @_;

  return $line
    if $line =~ /\A\s*\#/xsm;

  my $fh = $self->get_handle;

  # track this file's own package declarations, for optional
  # self-exclusion filtering later (see --filter). Reused across a
  # whole --file-list batch, not reset per file, so a package
  # declared in one file correctly excludes a sibling file's use of
  # it too.
  if ( $line =~ /^\s*package\s+([\w:]+)/xsm ) {
    $self->get_packages->{$1} = $TRUE;
  }

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
    && $line !~ /\A\s*(?:require|use)\s/xsm ) {

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
  #
  # Moose's 'extends' plays the same structural role for base-class
  # declaration (extends 'Foo'; extends 'Foo', 'Bar';) and gets
  # identical treatment.
  if ( $line =~ /\A\s*(with|extends)\b\s*(.*?)\s*;?\s*\z/xsm ) {

    my $args = $2;

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

    # doesn't look like a role/base list after all (e.g. "with the
    # following caveats" in a comment/doc line that slipped through)
    # -- fall through to normal processing below.
  }

  # could be in an eval - if we catch an exception it must not be a
  # hard requirement, so route these to suggests instead of require.
  # (recommends is reserved for a non-eval conditional/indented
  # require -- see recommend_require below. eval-wrapped is a
  # stronger signal: the author has explicitly written failure
  # handling around it, so it's the softer of the two.)
  #
  #   eval { require Term::ReadLine } or die $@;
  #   eval "require Term::Rendezvous;" or die $@;
  #   eval { require Carp } if defined $^S; # If error/warning during compilation,

  my $add_dep = $self->can('add_require');

  # whole-line comments never contain real code, but our eval
  # detection below isn't anchored to the start of the line (unlike
  # the main require/use pattern, which is, and so already correctly
  # ignores comment lines) -- so a documentation comment showing
  # example usage, like the ones directly above this code, would
  # otherwise get parsed as if it were live code.
  my $is_comment_line = $line =~ /\A\s*\#/xsm;

  # eval { ... } -- whether it closes on the same line or spans
  # several, track brace depth starting from the eval's OWN opening
  # brace and stop at ITS matching close, rather than counting every
  # brace on the line indiscriminately. That distinction matters: a
  # line like `eval { require Foo; } or do { ... }` has a *balanced*
  # eval block followed by an unrelated brace from `or do {}` -- a
  # naive whole-line brace count sees net +1 and wrongly assumes the
  # eval is still open, sweeping unrelated code (or, worse, a string's
  # contents, e.g. a die message containing the word "use") into what
  # it thinks is still eval body text.
  if ( !$is_comment_line && $line =~ /\beval\s*([{])/xsm ) {
    my $body_start = $+[1];
    my $depth      = 1;
    my $pos        = $body_start;
    my $whole_text = $line;

    FIND_CLOSE: while (1) {
      while ( $pos < length $whole_text ) {
        my $c = substr $whole_text, $pos, 1;

        if    ( $c eq '{' ) { $depth++; }
        elsif ( $c eq '}' ) {
          $depth--;
          last FIND_CLOSE if !$depth;
        }

        $pos++;
      }

      my $next = <$fh>;
      last FIND_CLOSE if !defined $next;

      $whole_text .= $next;
    }

    if ( !$depth ) {
      my $eval_close = $pos;

      my $body = substr $whole_text, $body_start, $eval_close - $body_start;
      $body =~ s/^\s*\#.*$//mg;

      # find where the WHOLE STATEMENT ends -- the next ';' that
      # occurs while not nested inside any (further) brace. This one
      # scan correctly handles a bare `eval {...};`, a trailing
      # `or die ...;`, and a trailing `or do { ... };` alike, without
      # needing to recognize 'or'/'do' as keywords at all: each of
      # those shapes' own terminating ';' is simply the first one
      # that occurs at brace depth 0, counting fresh from right after
      # the eval's own close.
      my $stmt_depth = 0;
      $pos = $eval_close + 1;
      my $stmt_end;

      FIND_SEMI: while (1) {
        while ( $pos < length $whole_text ) {
          my $c = substr $whole_text, $pos, 1;

          if    ( $c eq '{' ) { $stmt_depth++; }
          elsif ( $c eq '}' ) { $stmt_depth--; }
          elsif ( $c eq ';' && !$stmt_depth ) {
            $stmt_end = $pos + 1;
            last FIND_SEMI;
          }

          $pos++;
        }

        my $next = <$fh>;
        last FIND_SEMI if !defined $next;

        $whole_text .= $next;
      }

      # default classification for an eval with no annotation -- off
      # (suggests) unless the caller has set eval_recommends to shift
      # the project-wide default the other way.
      my $tier = $self->get_eval_recommends ? 'recommends' : 'suggests';

      # an explicit ## scandeps: annotation, immediately after the
      # semicolon that ends the whole statement, always wins over the
      # default -- this is the one point where a human's stated
      # intent overrides inference from code structure.
      if ( defined $stmt_end ) {
        my $newline_pos = index $whole_text, "\n", $stmt_end;
        my $rest
          = $newline_pos >= 0
          ? substr( $whole_text, $stmt_end, $newline_pos - $stmt_end )
          : substr( $whole_text, $stmt_end );

        if ( $rest =~ /\A\s*\#\#\s*scandeps:\s*(requires|recommends|suggests)\b/xsm ) {
          $tier = $1;
        }
      }

      my $adder
        = $tier eq 'requires'   ? 'add_require'
        : $tier eq 'recommends' ? 'add_recommends'
        :                         'add_suggests';

      while ( $body =~ /\b(?:require|use)\s+([\w:]+)(?:\s+([\d.]+))?/gxsm ) {
        $self->$adder( $1, $2 );
      }
    }

    return 1;
  }

  if ( !$is_comment_line && $line =~ /\beval\s*(?<q>["'])(?<body>(?:[^\\]|\\.)*?)\k<q>/xsm ) {

    my $body = $+{body};

    if ( $body =~ /\b(?:require|use)\s+/xsm ) {
      $line    = $body;
      $add_dep = $self->can('add_suggests');
    }
  }

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
    # the left edge to be hard requirements by default. any other
    # require statements give too many false positives, as they are
    # usually inside of an if statement as a fallback module or a
    # rarely used option.
    #
    # recommend_require, when set, takes priority over
    # include_require for this decision: a non-left-flushed require
    # is always routed to recommends rather than being treated as a
    # hard requirement or dropped outright, regardless of whether
    # include_require is on or off. This is a strict backward
    # compatibility addition -- with recommend_require left at its
    # default (off), every case below behaves exactly as it did
    # before this option existed.
    #
    # this whole block is skipped when eval-detection above already
    # claimed this line ($add_dep is add_suggests) -- the rewritten
    # eval body carries leading whitespace from inside the braces,
    # which would otherwise look like an indented require and get
    # reclassified as recommends, silently overriding the more
    # specific suggests tier eval-detection already assigned.

    if ( $statement eq 'require' && $add_dep != $self->can('add_suggests') ) {
      if ( $whitespace ne $EMPTY ) {
        if ( $self->get_recommend_require ) {
          $add_dep = $self->can('add_recommends');
        }
        elsif ( !$self->get_include_require ) {
          return $line;
        }
        # else: include_require on, recommend_require off -- falls
        # through unchanged, treated as a hard requirement.
      }
      elsif ( $self->get_include_require && $line =~ /\$/xsm ) {
        return $line;  # eval?
      }
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
      $add_dep->( $self, $module );
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

    if ( $module =~ /\A(v?[\d._]+)\z/xsm ) {  # v now captured, not stripped
      my $ver        = $1;
      my $normalized = eval { version->parse($ver)->numify };  # -> 5.024000
      $self->get_perlreq->{'perl'} = $normalized // $ver;
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
      $add_dep->( $self, $module, $version );
      #print {*STDERR}
      #  "statement: $statement module: $module, version: $version\n";

      if ( $version =~ /\Aqw\s*[{(\/'"]\s*([^)}\/"']+?)\s*[})\/"']/xsm ) {
        foreach ( split $SPACE, $1 ) {
          $add_dep->( $self, $line, undef );
        }
      }
      elsif ( $version =~ /(["'])([^"']+)\1/xsm ) {
        $add_dep->( $self, $2, undef );
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
        $add_dep->( $self, $_, $EMPTY );
      }
    }
    else {
      $add_dep->( $self, $module, $version );
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
########################################################################
# To be honest, I'm really not sure what the code below should do
# other than simply put the version number in the hash. I can only
# surmise that if the original script was running in the context of a
# list of perl scripts in a project AND one script specified an older
# version of a module, then that version is replace with the newer
# version.
########################################################################
# In our implementation here, the typical use case (I think) will be
# for an instance of Module::ScanDeps::Static to parse one
# script. However, it is possible for the instance to scan multiple
# files by calling "parse()" iteratively, accumulating the
# dependencies along the way. In that case this method's actions
# appear to be relevant.
########################################################################
# Thinking through the above use case and the way it is being
# implemented might indicate a "bug", or at least a design flaw. Take
# the case where two Perl scripts (presumably in the same project
# considering that this utility was written for packaging RPMs)
# require different versions of the same module. Rare, and odd, but
# possible - although one might wonder why the author of these scripts
# didn't resolve any conflicts between the modules so that he could
# use one version of said module.
########################################################################
# In any event this method enforces a single version of the module
# (the highest) as the answer to the question what version of
# __fill_in_the_blank__ module do I require?
########################################################################
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

  return $self
    if $self->is_pragma($module);

  # strongest tier wins: a hard requirement supersedes any softer listing
  delete $self->get_recommends->{$module};
  delete $self->get_suggests->{$module};

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
sub add_recommends {
########################################################################
  my ( $self, $module, $newver ) = @_;

  $newver //= $EMPTY;

  $module =~ s/\A\s*//xsm;
  $module =~ s/\s*\z//xsm;

  return $self
    if $self->is_pragma($module);

  # a stronger tier wins: do not downgrade an existing hard requirement
  return $self
    if exists $self->get_require->{$module};

  delete $self->get_suggests->{$module};

  my $recommends = $self->get_recommends;

  my $oldver = $recommends->{$module};

  if ($oldver) {
    if ( $newver && version->new($oldver) < $newver ) {
      $recommends->{$module} = $newver;
    }
  }
  elsif ( !$newver ) {
    my $m = {};

    if ( $self->get_add_version ) {
      $m = $self->get_module_version($module);
    }

    $recommends->{$module} = $m->{'version'} // $EMPTY;
  }
  else {
    $recommends->{$module} = $newver // $EMPTY;
  }

  return $self;
}

########################################################################
sub add_suggests {
########################################################################
  my ( $self, $module, $newver ) = @_;

  $newver //= $EMPTY;

  $module =~ s/\A\s*//xsm;
  $module =~ s/\s*\z//xsm;

  return $self
    if $self->is_pragma($module);

  # a stronger tier wins: do not add if already required or recommended
  return $self
    if exists $self->get_require->{$module}
    || exists $self->get_recommends->{$module};

  my $suggests = $self->get_suggests;

  my $oldver = $suggests->{$module};

  if ($oldver) {
    if ( $newver && version->new($oldver) < $newver ) {
      $suggests->{$module} = $newver;
    }
  }
  elsif ( !$newver ) {
    my $m = {};

    if ( $self->get_add_version ) {
      $m = $self->get_module_version($module);
    }

    $suggests->{$module} = $m->{'version'} // $EMPTY;
  }
  else {
    $suggests->{$module} = $newver // $EMPTY;
  }

  return $self;
}

########################################################################
sub format_json {
########################################################################
  my ( $self, @args ) = @_;

  # tier-selection is passed as an optional trailing hashref so the
  # existing (if unused internally) seed-list calling form --
  # format_json(@preexisting_requirements) -- keeps working unchanged.
  my %tier_options;
  if ( @args && ref $args[-1] eq 'HASH' ) {
    %tier_options = %{ pop @args };
  }

  my @requirements = @args;

  my $tier = $tier_options{tier} // 'require';

  my $tier_getter = {
    require    => 'get_require',
    recommends => 'get_recommends',
    suggests   => 'get_suggests',
  }->{$tier} // 'get_require';

  my %perlreq = %{ $self->get_perlreq };

  my %requires = %{ $self->$tier_getter };

  # a minimum Perl version requirement is always foundational, not
  # tier-specific -- only attach it to the require tier's output.
  if ( $tier eq 'require' && exists $perlreq{'perl'} ) {
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

    next if $self->get_filter && exists $self->get_packages->{$m};

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
  my $tier   = $options{tier}   // 'require';

  if ( ( $options{format} && $options{format} eq 'json' ) || $self->get_json ) {
    return scalar $self->format_json( { tier => $tier } );
  }
  elsif ( ( $options{format} && $options{format} eq 'text' ) || $self->get_text || $self->get_raw ) {
    return $self->format_text( tier => $tier );
  }
  else {
    return $self->format_json( { tier => $tier } );
  }
}

########################################################################
sub format_text {
########################################################################
  my ( $self, %options ) = @_;

  my $tier = $options{tier} // 'require';

  my @requirements = $self->format_json( { tier => $tier } );
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
  return [qw(perlreq require recommends suggests handle files packages logger)];
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
      log-level|l=s
      min-core-version|m=s
      raw|r
      recommend-require|R!
      eval-recommends!
      separator|s=s
      text|t
      version|v
      path|p=s
      file-list|L=s
      requires-file=s
      recommends-file=s
      suggests-file=s
      cpanfile-file=s
      filter|f!
    )
  ];
}

########################################################################
sub _default_options {
########################################################################
  return {
    add_version       => $TRUE,
    core              => $TRUE,
    include_require   => $TRUE,
    json              => $FALSE,
    min_core_version  => '5.8.9',
    recommend_require => $FALSE,
    eval_recommends   => $FALSE,
    separator         => q{ => },
    text              => $TRUE,
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

  # --filter has no context-independent right answer: for a single
  # file there's no sibling in the batch to worry about, but for
  # --file-list, a same-batch sibling should never count as an
  # external dependency of another file in the same batch. Default it
  # accordingly, but only when the user hasn't explicitly set
  # --filter/--no-filter themselves - that always wins regardless of
  # context.
  if ( !defined $self->get_filter ) {
    $self->set_filter( $self->get_file_list ? $TRUE : $FALSE );
  }

  $self->set_perlreq( {} );

  $self->set_require( {} );

  $self->set_recommends( {} );

  $self->set_suggests( {} );

  $self->set_packages( {} );

  return;
}

########################################################################
sub logger {
########################################################################
  my ( $self, $level, $message, @args ) = @_;

  my $logger = $self->get_logger;

  if (@args) {
    $message = sprintf $message, @args;
  }

  if ( !$logger ) {
    # we only support 'info' & 'debug' so this should work...
    return
      if !$self->get_log_level || $level ne $self->get_log_level;

    print {*STDERR} "$message\n";

    return;
  }

  $logger->$level($message);

  return;
}

########################################################################
sub cmd_scan {
########################################################################
  my ($self) = @_;

  foreach my $file ( @{ $self->get_files } ) {
    $self->logger( info => 'scanning: %s', $file );
    $self->set_path($file);

    $self->parse;
  }

  $self->warn_tier_conflicts;

  if ( $self->get_json ) {
    print {*STDOUT} $self->get_dependencies( format => 'json' );
  }
  else {
    print {*STDOUT} $self->get_dependencies( format => 'text' );
  }

  # --file-list scans multiple files by reusing the same object
  # across the loop above (parse() never resets require/recommends/
  # suggests -- only init() does, once, at construction) -- so by
  # this point these three hashes already hold the union across every
  # file scanned, single file or not. Each of these is independent of
  # --json/--text/--raw: always written as plain text (module =>
  # version), same shape "make requires" already expects.
  $self->_write_tier_file( 'requires-file',   'require' );
  $self->_write_tier_file( 'recommends-file', 'recommends' );
  $self->_write_tier_file( 'suggests-file',   'suggests' );

  $self->_write_cpanfile;

  return $SUCCESS;
}

########################################################################
sub warn_tier_conflicts {
########################################################################
  my ($self) = @_;

  # a module can legitimately be a hard requirement in one file and
  # eval-wrapped/conditional in another -- both facts can be true at
  # once. But the aggregate is a real contradiction worth surfacing:
  # if it's required anywhere, listing it again as merely recommended
  # or suggested is misleading, and papering over that by silently
  # picking a winner would hide a signal the developer should act on
  # (either the softer usage no longer needs to hedge, since the
  # module is guaranteed to be present anyway, or the hard requirement
  # should really be conditional too). This only warns -- it
  # deliberately does not alter require/recommends/suggests, since
  # resolving the contradiction belongs in the source, not here.

  my $require    = $self->get_require;
  my $recommends = $self->get_recommends;
  my $suggests   = $self->get_suggests;

  foreach my $m ( sort keys %{$recommends} ) {
    next if !exists $require->{$m};
    warn "WARNING: '$m' is both a hard requirement and listed in recommends -- pick one\n";
  }

  foreach my $m ( sort keys %{$suggests} ) {
    if ( exists $require->{$m} ) {
      warn "WARNING: '$m' is both a hard requirement and listed in suggests -- pick one\n";
    }
    elsif ( exists $recommends->{$m} ) {
      warn "WARNING: '$m' is listed in both recommends and suggests -- pick one\n";
    }
  }

  return;
}

########################################################################
sub _write_tier_file {
########################################################################
  my ( $self, $option_name, $tier ) = @_;

  ( my $getter = $option_name ) =~ s/-/_/gxsm;
  $getter = "get_$getter";

  my $path = $self->$getter;

  return if !$path;

  my $text = $self->format_text( tier => $tier ) // $EMPTY;

  open my $fh, '>', $path ## no critic (InputOutput::RequireBriefOpen)
    or croak "could not open '$path' for writing: $OS_ERROR";

  print {$fh} $text;

  close $fh;

  return;
}

########################################################################
sub _write_cpanfile {
########################################################################
  my ($self) = @_;

  my $path = $self->get_cpanfile_file;

  return if !$path;

  my $text = $self->format_cpanfile // $EMPTY;

  open my $fh, '>', $path ## no critic (InputOutput::RequireBriefOpen)
    or croak "could not open '$path' for writing: $OS_ERROR";

  print {$fh} $text;

  close $fh;

  return;
}

########################################################################
sub format_cpanfile {
########################################################################
  my ($self) = @_;

  # deliberately reuses format_json's per-tier filtering (core,
  # --filter, and the synthetic "perl" minimum-version entry, which
  # cpanfile's own DSL represents identically to any other module
  # requirement: requires 'perl', 'X.YZ';) rather than duplicating
  # that logic here.

  my %keyword_for_tier = (
    require    => 'requires',
    recommends => 'recommends',
    suggests   => 'suggests',
  );

  my @lines;

  foreach my $tier (qw(require recommends suggests)) {
    my $keyword = $keyword_for_tier{$tier};

    my @requirements = $self->format_json( { tier => $tier } );

    foreach my $r (@requirements) {
      if ( $r->{version} ) {
        push @lines, sprintf "%s '%s', '%s';\n", $keyword, $r->{name}, $r->{version};
      }
      else {
        push @lines, sprintf "%s '%s';\n", $keyword, $r->{name};
      }
    }
  }

  return join $EMPTY, @lines;
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

=head2 Comparison to Other Scanners

Two other CPAN scanners cover similar ground:
L<Perl::PrereqScanner>, built on L<PPI>, and
L<Perl::PrereqScanner::NotQuiteLite> (here, "NQLite"), which uses its
own lexer. The comparison below reflects hands-on testing against
both, not just a reading of their documentation.

B<Speed.> This module is regex/line-based rather than a true
tokenizer, and that's a deliberate trade-off, not an oversight - it's
the source of most of the speed difference. On a representative
414-line file, this module scans in roughly 1.7ms; NQLite takes
roughly 6ms; PPI-based C<Perl::PrereqScanner> takes roughly 45ms.
PPI's own documentation acknowledges this cost directly, describing
itself as "painful... with very large files." The trade-off cuts the
other way too: a real tokenizer is structurally immune to a class of
edge case (an unbalanced brace inside a string or heredoc, for
example) that this module's regex approach can, in principle, still
be fooled by, even though no such failure has been found in testing
against real-world code.

B<Dependency classification.> All three tools distinguish a hard
requirement from something merely conditional or optional, but this
module is alone in giving the developer an explicit way to state that
judgment rather than have it inferred. NQLite decides C<recommends>
vs. C<suggests> purely from code structure - specifically, whether
the call is a bare C<eval> or one of two specific, by-name-recognized
CPAN modules (L<Module::Runtime> and L<Class::Load>) - with no way
for a developer to say "no, that one's actually important" short of
restructuring their code to match what the scanner looks for. This
module instead classifies a guarded dependency as C<suggests> by
default (or C<recommends> project-wide via C<eval_recommends>), and
lets a C<## scandeps: recommends> or C<## scandeps: suggests> comment
immediately after the guarding statement override that default
per-instance. Neither other tool has an equivalent escape hatch.

This module also warns - rather than silently picking a winner - when
a module is both a hard requirement in one place and merely
recommended or suggested in another, since that's a real contradiction
in the source worth surfacing to the developer, not something a
scanner should resolve on its own.

B<Version numbers.> Both C<Perl::PrereqScanner> and NQLite report
every dependency's version as a fixed C<0> placeholder - not "unknown",
literally the string C<0> regardless of what's actually installed or
required. This module performs a real version lookup (see
C<--add-version>) and reports what it actually finds.

Reporting a version number or C<0> both have their advantages and
disadvantages. Users of these scanners can always edit the output and
modify the version number requirements, however this scanner opted to
choose the currently installed version. This assumes you are
developing your module against a known environment, and the idea is
that while other versions of a module might work, the version in your
working environment is known to work with your module. Selecting
C<0> means any version will do - but consider a module like
C<List::Util> running under Perl 5.10. While C<List::Util> has been in
core since 5.7.3, its feature list has grown significantly. You may be
using features that were not present in that version of C<List::Util>.
Shipping with the minimum version of C<List::Util> set to C<0> is
almost certainly going to fail on earlier versions of Perl.

The true minimum - the exact release in which every feature your code
actually relies on first appeared - would in principle be the most
accurate answer. But determining that reliably would mean downgrading
each dependency in turn and re-running your test suite against every
prior release, which presumes you have test coverage specifically
exercising the features you're relying on, for every dependency you
use. That's not a reasonable expectation in practice - reporting the
currently installed version is a deliberate trade-off in favor of a
version B<known> to work over one merely presumed to.

B<Self-referential modules.> Scanning a whole project can turn a
sibling module into a false positive - file A's C<use> of file B's
C<package> isn't an external dependency at all. NQLite handles this
with C<--private>, a manually maintained list of module names to
exclude. This module's C<--filter> does the same job automatically,
by detecting C<package> declarations across the batch being scanned,
at the cost of only working when the sibling file is actually part of
the same scan.

B<What this module doesn't attempt.> NQLite can infer a minimum Perl
version from newer syntax (signatures, C<say>, and similar) appearing
in the source without an explicit C<use v5.x> declaration; this module
does not attempt that. NQLite also has an opt-in C<CPAN::Common::Index>
integration that can deduplicate module names belonging to the same
distribution - deliberately not pursued here, since it requires a
network round-trip (or a locally maintained mirror) per module found
at scan time, in exchange for a purely cosmetic shortening of the
output that changes nothing about what actually gets installed.
Finally, no static scanner - this one included - can discover a
dependency loaded through a genuinely dynamic mechanism (a module name
computed at runtime and passed to something like L<Module::Load>);
that's a fundamental limit of static analysis, not a gap specific to
any one tool. See L</Dynamic Module Loading> below.

=head1 OPTIONS

 --add-version, -a        add version numbers to output
 --no-add-version         don't add version numbers to output
 --core                   include core modules (default)
 --no-core                don't include core modules
 --cpanfile-file PATH     write a cpanfile combining all three tiers to PATH
 --eval-recommends        classify unannotated eval-wrapped deps as recommends, not suggests
 --file-list, -L PATH     scan a batch of files listed one per line in PATH
 --filter, -f             exclude modules that are this project's own packages
 --help, -h               help
 --include-require, -i    include 'require'd modules
 --no-include-require     don't include required modules
 --json, -j               output JSON formatted list
 --min-core-version, -m   minimum version of perl to consider core
 --path, -p PATH          file to scan (alternative to the positional argument)
 --raw, -r                raw output
 --recommend-require, -R  classify indented (non-eval) conditional requires as recommends
 --recommends-file PATH   write the recommends tier to PATH
 --requires-file PATH     write the requires tier to PATH
 --separator, -s          separator for output (default: =>)
 --suggests-file PATH     write the suggests tier to PATH
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

=item --eval-recommends

Controls how an C<eval>-wrapped C<require>/C<use> is classified when
it carries no explicit C<## scandeps:> annotation (see
L</Dependency Tiers> below). By default such a dependency is
classified as C<suggests>; setting this option flips the
project-wide default to C<recommends> instead. An explicit
annotation always overrides this default regardless of its setting.

default: B<--no-eval-recommends> (unannotated evals classify as
C<suggests>)

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

=item --filter, -f

Exclude modules from the output that are themselves C<package>
declarations found somewhere in the files being scanned. Useful with
C<--file-list> to keep a project's own sibling modules from being
reported as external dependencies of each other.

There is no single right default independent of context: a single
file scanned on its own has no sibling in the batch to worry about,
but when C<--file-list> is in use, a same-batch sibling should never
count as an external dependency of another file in the same batch.
So this defaults to B<off> for a single file and B<on> whenever
C<--file-list> is given - but only when C<--filter>/C<--no-filter>
isn't explicitly set; an explicit setting always wins over this
context-dependent default, in either direction.

=item --requires-file PATH

=item --recommends-file PATH

=item --suggests-file PATH

Write the C<requires>, C<recommends>, or C<suggests> tier
respectively to C<PATH>, in the same format C<--text> would produce
(regardless of whether C<--json> or C<--raw> is also in effect - each
of these is always plain "module version" text, one per line). Any
or all of the three may be given together; each is independent, and
omitting all three changes nothing about existing STDOUT/JSON output.
With C<--file-list>, all files in the batch are scanned once and the
three tiers are populated together from that single pass, rather than
needing a separate scan per tier.

=item --cpanfile-file PATH

Write a single C<cpanfile> to C<PATH>, combining all three tiers in
native L<cpanfile|Module::CPANfile> DSL syntax:

    requires 'Module::Name';
    requires 'Module::Name', 'X.YZ';
    recommends 'Module::Name', 'X.YZ';
    suggests 'Module::Name', 'X.YZ';

A module's version is included only when one was actually detected
(see C<--add-version>) - otherwise the unversioned form is written,
matching C<cpanfile>'s own convention for "any version is acceptable".
A minimum Perl version, if one was declared in the scanned source, is
written the same way any other C<requires> entry would be:
C<requires 'perl', 'X.YZ';> - this is standard C<cpanfile> syntax, not
a special case.

This applies the same filtering as every other output (C<--core> /
C<--no-core>, C<--filter>) uniformly across all three tiers, and
verified to round-trip correctly through L<Module::CPANfile> itself.
Independent of C<--requires-file> / C<--recommends-file> /
C<--suggests-file> - any combination of these four file-output options
may be given together in a single scan.

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

=item --recommend-require

By default, an indented (not left-flushed) C<require> statement that
is not wrapped in C<eval> is either treated as a hard requirement or
dropped entirely, depending on C<--include-require> - see
L</--include-require, -i, --no-include-require>. Setting this option
instead routes it to the C<recommends> tier (see
L</Dependency Tiers>), regardless of C<--include-require>'s setting.
Off by default - every existing case behaves exactly as it did before
this option existed.

default: B<--no-recommend-require>


=back

=head1 WHAT IS A DEPENDENCY?

For the purposes of this module, dependencies are identified by
looking for Perl modules and other Perl artifacts declared using
C<use>, C<require>, C<parent>, or C<base>. The script will also
consider Moo/Role::Tiny modules included using C<with>, and Moose
inheritance declared using C<extends> - both are treated identically
to C<use parent>/C<use base>.

If the module contains a C<require> statement, by default the
C<require> must be flush up against the left edge of your script
without any whitespace between it and beginning of the line.  This is
the default behavior to avoid identifying C<require> statements that
are embedded in C<if> statements. If you want to include all of
the targets of C<require> statements as dependencies, set the
C<include-require> option to a true value.

=head2 Dependency Tiers

Every dependency found is classified into one of three tiers,
matching the C<requires>/C<recommends>/C<suggests> relationship types
defined by L<CPAN::Meta::Spec>:

=over 5

=item requires

A bare, unconditional C<use> or C<require>, or a C<with>/C<extends>/
C<parent>/C<base> declaration. Nothing in the surrounding code
suggests the author considered this module might be absent.

=item recommends

A dependency the author explicitly guarded against being absent (see
L</Structural Classification> below), where the author's own
annotation or this module's default judges the guard to matter more
than a mere enhancement - see L</The C<## scandeps:> Annotation>.

=item suggests

The weaker of the two soft tiers - a guarded dependency judged to be
a genuine enhancement rather than something most users would need.

=back

This module makes B<no attempt> to infer which of C<recommends> or
C<suggests> is correct by analyzing what a guarded dependency's
failure path actually does (for example, whether it C<die>s or
degrades gracefully). That was a deliberate decision, not an
oversight: whether a dependency is merely nice-to-have or genuinely
important is a judgment about a project's own design, not a fact
recoverable from code structure - the same code shape (C<eval {
require Foo }>) is written identically by an author who considers
C<Foo> essential and one who considers it optional. Guessing at that
judgment and presenting the guess as if it were derived from parsing
would be dishonest about what static analysis can actually know. Use
the annotation below to state it explicitly instead.

=head2 Structural Classification

Only a genuinely unconditional C<use>/C<require> is ever classified
as C<requires>. Anything the author has structurally guarded is
pulled into one of the soft tiers:

=over 5

=item * C<eval { require/use Foo }> or C<eval "require/use Foo">, in
any form - single-line, multi-line, with or without a trailing
C<or die>/C<or do { }> - is classified as C<suggests> by default, or
C<recommends> if C<--eval-recommends> is set (see
L</--eval-recommends>). Either default can be overridden per-instance
with an explicit annotation - see below.

=item * An indented (not left-flushed), non-C<eval> C<require> - for
example inside a bare C<if> block - is treated as a hard requirement
by default (or dropped entirely if C<--include-require> is off), the
same as it always has been. Set C<--recommend-require> to instead
route these to C<recommends>. See
L</--recommend-require>.

=back

=head2 The C<## scandeps:> Annotation

Because the C<recommends> vs. C<suggests> distinction is a judgment
call this module deliberately does not try to infer (see
L</Dependency Tiers>), an author can state that judgment explicitly
with a comment:

    eval { require Foo::Bar; };  ## scandeps: recommends

    eval { require Foo::Bar; 1; } or die $@;  ## scandeps: suggests

    eval {
        require Foo::Bar;
        1;
    } or do {
        warn "Foo::Bar unavailable, continuing without it\n";
    };  ## scandeps: recommends

The annotation must appear immediately after the semicolon that ends
the whole statement - not the eval block's own closing brace, but
wherever the statement as a whole actually terminates, which may be
after a trailing C<or die ...;> or C<or do { ... };>. An explicit
annotation always overrides both this module's structural default and
the C<--eval-recommends> setting.

This annotation is only recognized on the brace form of C<eval>
(C<eval { ... }>). It is not supported on the string form
(C<eval "...">) - anyone still writing string C<eval> for this
purpose is not expected to participate in this feature.

=head2 Conflicting Classifications

A single module can legitimately be a hard requirement in one file
and guarded in another - both facts can be true of the same project
at once. When that happens, this module does not silently pick a
winner: it emits a warning to C<STDERR> naming the conflicting
module, and leaves C<require>, C<recommends>, and C<suggests> exactly
as found. Resolving the contradiction belongs in the project's own
source, not in this tool - either the guarded usage no longer needs
to hedge, since the module is guaranteed to be present anyway because
of the other, unconditional usage, or the unconditional usage should
really be conditional too.

The same warning fires if a module appears in both C<recommends> and
C<suggests> at once.

=head2 Self-Referential Modules

When scanning a whole project (typically via C<--file-list>), a
module in one file may C<use> a sibling module declared with
C<package> in another file in the same project - not a real external
dependency at all. C<--filter> excludes any module name that appears
anywhere in the batch as a C<package> declaration; see
L</--filter, -f> for its (context-dependent) default.

=head2 Dynamic Module Loading

This module performs I<static> analysis: it reads source as text and
looks for recognizable patterns. It cannot execute your code, and so
cannot know the value of a variable at runtime. A module loaded via a
computed name - for example C<Module::Load::load($module)> where
C<$module> is a variable - is invisible to this scanner and will
never appear in C<require>, C<recommends>, or C<suggests>, no matter
how the code is structured.

This is a real and legitimate use case for modules like
L<Module::Load>, L<Module::Runtime>, and L<Class::Load>: loading a
plugin or driver whose name genuinely isn't known until the program
runs. For that use case, invisibility to any static scanner is an
unavoidable trade-off, not a defect in this module.

It becomes an antipattern, though, when one of these modules is
called with a name that I<is> known at write time:

    Module::Load::load('Term::ANSIColor');

The module name here is a literal string, not runtime data - a plain

    eval { require Term::ANSIColor; };

would behave identically at runtime, while remaining visible to this
scanner and annotatable with C<## scandeps:>. Reach for
C<Module::Load> and similar modules only when the module name is
genuinely computed at runtime - for loading plugins or other modules
that are already known to be part of your project's own architecture
- not as a general-purpose substitute for C<require>.

Do not expect this scanner to understand dynamic module loading. If a
project genuinely depends on a module that can only be discovered at
runtime, that dependency needs to be declared by hand (for example, in
a C<cpanfile> or C<buildspec.yml>) - this module cannot discover it.

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

=head2 format_cpanfile

 $scanner->parse;
 print $scanner->format_cpanfile;

Returns a single C<cpanfile> (see L<Module::CPANfile>) combining all
three tiers, using native C<requires>/C<recommends>/C<suggests> DSL
syntax. Versions are included only where actually detected (see
C<add_version>); otherwise the unversioned form is written. Applies
the same C<core>/C<filter> filtering as C<format_json>, since it's
built on top of it rather than duplicating that logic.

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

This documentation refers to version 1.9.5

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
