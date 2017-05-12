=head1 NAME

Perl::LibExtractor - determine perl library subsets for building distributions

=head1 SYNOPSIS

   use Perl::LibExtractor;

=head1 DESCRIPTION

The purpose of this module is to determine subsets of your perl library,
that is, a set of files needed to satisfy certain dependencies (e.g. of a
program).

The goal is to extract a part of your perl installation including
dependencies. A typical use case for this module would be to find out
which files are needed to be build a L<PAR> distribution, to link into
an L<App::Staticperl> binary, or to pack with L<Urlader>, to create
stand-alone distributions tailormade to run your app.

=head1 METHODS

To use this module, first call the C<new>-constructor and then as many
other methods as you want, to generate a set of files. Then query the set
of files and do whatever you want with them.

The command-line utility F<perl-libextract> can be a convenient
alternative to using this module directly, and offers a few extra options,
such as to copy out the files into a new directory, strip them and/or
manipulate them in other ways.

=cut

package Perl::LibExtractor;

our $VERSION = '1.1';

use Config;
use File::Spec ();
use File::Temp ();

use common::sense;

sub I_SRC  () { 0 }
sub I_DEP  () { 1 }

sub croak($) {
   require Carp;
   Carp::croak "(Perl::LibExtractor) $_[0]";
}

my $canonpath     = File::Spec->can ("canonpath");
my $case_tolerant = File::Spec->case_tolerant;

sub canonpath($) {
   local $_ = $canonpath->(File::Spec::, $_[0]);
   s%\\%/%g;
#   $_ = lc if $case_tolerant; # we assume perl file name case is always the same
   $_
}

=head2 CREATION

=over 4

=item $extractor = new Perl::LibExtractor [key => value...]

Creates a new extractor object. Each extractor object stores some
configuration options and a subset of files that can be queried at any
time,.

Binary executables (such as the perl interpreter) are stored inside
F<bin/>, perl scripts are stored under F<script/>, perl library files are
stored under F<lib/> and shared libraries are stored under F<dll/>.

The following key-value pairs exist, with default values as specified.

=over 4

=item inc => \@INC without "."

An arrayref with paths to perl library directories. The default is
C<\@INC>, with F<.> removed.

To prepend custom dirs just do this:

   inc => ["mydir", @INC],

=item use_packlist => 1

Enable (if true) or disable the use of C<.packlist> files. If enabled,
then each time a file is traced, the complete distribution that contains
it is included (but not traced).

If disabled, only shared objects and autoload files will be added.

Debian GNU/Linux doesn't completely package perl or any perl modules, so
this option will fail. Other perls should be fine.

=item extra_deps => { file => [files...] }

Some (mainly runtime dependencies in the perl core library) cannot be
detected automatically by this module, especially if you don't use
packlists and C<add_core>.

This module comes with a set of default dependencies (such as L<Carp>
requiring L<Carp::Heavy>), which you cna override with this parameter.

To see the default set of dependencies that come with this module, use
this:

   perl -MPerl::LibExtractor -MData::Dumper -e 'print Dumper $Perl::LibExtractor::EXTRA_DEPS'

=back

=cut

our $EXTRA_DEPS = {
   'bytes.pm'    => ['bytes_heavy.pl'],
   'utf8.pm'     => ['utf8_heavy.pl'],
   'Config.pm'   => ['Config_heavy.pl', 'Config_git.pl'],
   'Carp.pm'     => ['Carp/Heavy.pm'],
   'Exporter.pm' => ['Exporter/Heavy.pm'],
};

sub new {
   my ($class, %kv) = @_;

   my $self = bless {
      inc          => [grep $_ ne ".", @INC],
      use_packlist => 1,
      extra_deps   => $EXTRA_DEPS,
      %kv,
      set => {},
   }, $class;

   my %inc_seen;
   my @inc = grep !$inc_seen{$_}++ && -d "$_/.", @{ $self->{inc} };
   $self->{inc} = \@inc;

   # maybe not inc, but these?
   # sitearchexp
   # sitelib
   # vendorarchexp
   # vendorlibexp
   # archlibexp
   # privlibexp

   $self->_set_inc;

   $self
}

sub _perl_path() {
   my $secure_perl_path = $Config{perlpath};

   if ($^O ne 'VMS') {
      $secure_perl_path .= $Config{_exe}
         unless $secure_perl_path =~ m/$Config{_exe}$/i;
   }

   $secure_perl_path
}

sub _path2match {
   my $re = join "|", map "\Q$_", @_;

   $re = "^(?:$re)\\/";
   $re =~ s%\\[/\\]%[/\\\\]%g; # we support / and \ on all OSes, keep your fingers crossed
   
   $case_tolerant
      ? qr<$re>i
      : qr<$re>
}

sub _read_packlist {
   my ($self, $path) = @_;

   my $pfxmatch = $self->{pfxmatch};
   my $lib      = $self->{lib};

   my @packlist;

   open my $fh, "<:perlio", $path
      or die "$path: $!";

   while (<$fh>) {
      chomp;
      s/ .*$//; # newer-style .packlists might contain key=value pairs

      s%\\%/%g; # we only do unix-style paths internally

      s/$pfxmatch// and exists $lib->{$_}
         or next;

      push @packlist, canonpath $_;
   }

   \@packlist
}

sub _set_inc {
   my ($self) = @_;

   my $pfxmatch = _path2match @{ $self->{inc }};

   my %lib;
   my @packlists;

   # find all files in all libdirs, earlier ones overwrite later ones
   my @scan = map [$_, ""], @{ $self->{inc} };

   while (@scan) {
      my ($root, $dir) = @{ pop @scan };

      my $pfx = length $dir ? "$dir/" : "";

      for (do {
         opendir my $fh, "$root/$dir"
            or croak "$root/$dir: $!";
         grep !/^\.\.?$/, readdir $fh
      }) {
         if (-d "$root/$dir/$_/.") {
            $lib{"$pfx$_/"} = "$root/$pfx$_";
            push @scan, [$root, "$pfx$_"];
         } elsif ($_ eq ".packlist" && $pfx =~ m%^auto/%) {
            push @packlists, "$root/$pfx.packlist";
         } elsif (/\.bs$/ && $pfx =~ m%^auto/% && !-s "$root/$dir/$_") {
            # skip empty .bs files
#         } elsif (/\.(?:pod|h|html)$/) {
#            # not interested in those
         } else {
            #push @files, $_;
            $lib{"$pfx$_"} = "$root/$pfx$_";
         }
      }

      #$lib{"$_[1]/"} = [\@dirs, \@files]; # won't work nice with overwrite
   }

   $self->{lib}      = \%lib;
   $self->{pfxmatch} = $pfxmatch;

   my %packlist;

   # need to go forward here
   for (@packlists) {
      my $packlist = $self->_read_packlist ($_);

      $packlist{$_} = $packlist
         for @$packlist;
   }

   $self->{packlist} = \%packlist;
}

=back

=head2 TRACE/PACKLIST BASED ADDING

The following methods add various things to the set of files.

Each time a perl file is added, it is scanned by tracing either loading,
execution or compiling it, and seeing which other perl modules and
libraries have been loaded.

For each library file found this way, additional dependencies are added:
if packlists are enabled, then all files of the distribution that contains
the file will be added. If packlists are disabled, then only shared
objects and autoload files for modules will be added.

Only files from perl library directories will be added automatically. Any
other files (such as manpages or scripts installed in the F<bin>
directory) are skipped.

If there is an error, such as a module not being found, then this module
croaks (as opposed to silently skipping). If you want to add something of
which you are not sure it exists, then you can wrap the call into C<eval
{}>. In some cases, you can avoid this by executing the code you want
to work later using C<add_eval> - see C<add_core_support> for an actual
example of this technique.

Note that packlists are meant to add files not covered by other
mechanisms, such as resource files and other data files loaded directly by
a module - they are not meant to add dependencies that are missed because
they only happen at runtime.

For example, with packlists, when using L<AnyEvent>, then all event loop
backends are automatically added as well, but I<not> any event loops
(i.e. L<AnyEvent::Impl::POE> is added, but L<POE> itself is not). Without
packlists, only the backend that is being used is added (i.e. normally
none, as loading AnyEvent does not instantly load any backend).

To catch the extra event loop dependencies, you can either initialise
AnyEvent so it picks a suitable backend:

   $extractor->add_eval ("use AnyEvent; AnyEvent::detect");

Or you can directly load the backend modules you plan to use:

   $extractor->add_mod ("AnyEvent::Impl::EV", "AnyEvent::Impl::Perl");

An example of a program (or module) that has extra resource files is
L<Deliantra::Client> - the normal tracing (without packlist usage) will
correctly add all submodules, but miss the fonts and textures. By using
the packlist, those files are added correctly.

=over 4

=cut

sub _add {
   my ($self, $add) = @_;

   my $lib = $self->{lib};
   my $path;

   for (@$add) {
      $path = "lib/$_";

      $self->{set}{$path} ||= do {
         my @info;

         $info[I_SRC] = $lib->{$_}
            or croak "$_: unable to locate file in perl library";

         if ($self->{use_packlist} && exists $self->{packlist}{$_}) {
            $self->{set}{"lib/$_"} ||= [$self->{lib}{$_} or die]
               for @{ $self->{packlist}{$_} };

#            for (grep /\.pm$/, @{ $self->{packlist}{$_} }) {
#               s/\.pm$//;
#               s%/%::%g;
#               my $pkg = "libextractor" . ++$self->{count};
#               $self->add_eval ("{ package $pkg; eval 'use $_' }")
#                  unless $self->{_add_do}{$_}++;
#            }
#
#            $self->{_add_do}{$_}++ or $self->add_eval ("do q\x00$_\x00")
#               for grep /\.pl$/, @{ $self->{packlist}{$_} };

         } elsif (/^(.*)\.pm$/) {
            (my $auto = "auto/$1/") =~ s%::%/%g;
            $auto =~ m%/([^/]+)/$% or die;
            my $base = $1;

            if (exists $lib->{$auto}) {
               # auto dir exists, scan it for cool stuff

               # 1. shared object, others are of no interest to us
               my $so = "$auto$base.$Config{dlext}";
               if (my $src = $lib->{$so}) {
                  $so = "lib/$so";
                  push @{ $info[I_DEP] }, $so; $self->{set}{$so} = [$src];
               }

               # 2. autoloader/autosplit
               my $ix = "${auto}autosplit.ix";
               if (my $src = $lib->{$ix}) {
                  $ix = "lib/$ix";
                  push @{ $info[I_DEP] }, $ix; $self->{set}{$ix} = [$src];

                  open my $fh, "<:perlio", $src
                     or croak "$src: $!";

                  my $package;

                  while (<$fh>) {
                     if (/^\s*sub\s+ ([^[:space:];]+) \s* (?:\([^)]*\))? \s*;?\s*$/x) {
                        my $al = "auto/$package/$1.al";
                        my $src = $lib->{$al}
                           or croak "$al: autoload file not found, but should be there.";

                        $al = "lib/$al";
                        push @{ $info[I_DEP] }, $al; $self->{set}{$al} = [$src];

                     } elsif (/^\s*package\s+([^[:space:];]+)\s*;?\s*$/) {
                        ($package = $1) =~ s/::/\//g;
                     } elsif (/^\s*(?:#|1?\s*;?\s*$)/) {
                        # nop
                     } else {
                        warn "WARNING: $src: unparsable line, please report: $_";
                     }
                  }
               }

               skip:
            }
         }

         if (exists $self->{extra_deps}{$_}) {
            # we require it again, because many extra dependencies require the main module to be loaded
            $self->add_eval ("require q\x00$_\x00");

            exists $lib->{$_} and $self->add_require ($_)
               for @{ $self->{extra_deps}{$_} };
         }

         \@info
      };
   }
}

sub _trace {
   my ($self, $file, $eval) = @_;

   $self->{trace_begin} .= "\n#line \"$file\" 1\n$eval;\n";
}

sub _trace_flush {
   my ($self) = @_;

   # ->_add might add additional files to trace
   while (exists $self->{trace_begin} or exists $self->{trace_check}) {
      my $tmpdir = newdir File::Temp;
      my $dir = $tmpdir->dirname;

      open my $fh, ">:perlio", "$dir/eval"
         or croak "$dir/eval: $!";
      syswrite $fh,
         'BEGIN { @INC = (' . (join ", ", map "q\x00$_\x00", @{ $self->{inc} }) . ") }\n"
         . "BEGIN { chdir q\x00$dir\x00 or die q\x00$dir: \$!\x00 }\n"
         . 'BEGIN { ' . (delete $self->{trace_begin}) . "}\n"
         . "CHECK {\n"
            . 'open STDOUT, ">:raw", "out" or die "out: $!";'
            . 'print join "\x00", values %INC;'
            . 'open STDERR, ">stderr";' # suppress "syntax OK" message from perl
         . "}\n"
         . (delete $self->{trace_check});
      close $fh;

      system _perl_path, "-c", "$dir/eval"
         and croak "trace failure, check trace process output - caught";

      my @inc = split /\x00/, do {
         open my $fh, "<:perlio", "$dir/out"
            or croak "$dir/out: $!";
         local $/;
         scalar readline $fh 
      };

      my $pfxmatch = $self->{pfxmatch};

      # remove the library directory prefix, hope for the best
      s/$pfxmatch//
         or croak "$_: file outside any library directory"
         for @inc;

      $self->_add (\@inc);
   }
}

=item $extractor->add_mod ($module[, $module...])

Adds the given module(s) to the file set - the module name must be specified
as in C<use>, i.e. with C<::> as separators and without F<.pm>.

The program will be loaded with the default import list, any dependent
files, such as the shared object implementing xs functions, or autoload
files, will also be added.

If you want to use a different import list (for those rare modules wghere
import lists trigger different backend modules to be loaded for example),
you can use C<add_eval> instead:

  $extractor->add_eval ("use Module qw(a b c)");

Example: add F<Coro.pm> and F<AnyEvent/AIO.pm>, and all relevant files
from the distribution they are part of.

  $extractor->add_mod ("Coro", "AnyEvent::AIO");

=cut

sub add_mod {
   my $self = shift;

   for (@_) {
      my $pkg = "libextractor" . ++$self->{count};
      $self->_trace ("use $_", "{ package $pkg; use $_ }")
         unless $self->{add_mod}{$_}++;
   }
}

=item $extractor->add_require ($name[, $name...])

Works like C<add_mod>, but uses C<require $name> to load the module, i.e.
the name must be a filename.

Example: load Coro and AnyEvent::AIO, but using C<add_require> instead of C<add_mod>.

   $extractor->add_require ("Coro.pm", "AnyEvent/AIO.pm");

=cut

sub add_require {
   my $self = shift;

   for (@_) {
      $self->add_eval ("require q\x00$_\x00")
         unless $self->{add_require}{$_}++;
   }
}

=item $extractor->add_bin ($name[, $name...])

Adds the given (perl) program(s) to the file set, that is, a program
installed by some perl module, written in perl (an example would be the
L<perl-libextract> program that is part of the C<Perl::LibExtractor>
distribution).

Example: add the deliantra client program installed by the
L<Deliantra::Client> module and put it under F<bin/deliantra>.

   $extractor->add_bin ("deliantra");

=cut

sub add_bin {
   my $self = shift;

   exe:
   for my $exe (@_) {
      for my $dir ($Config{sitebinexp}, $Config{vendorbinexp}, $Config{binexp}) {
         if (open my $fh, "<:perlio", "$dir/$exe") {
            if (-f $fh) {
               my $file = do { local $/; readline $fh };

               $self->_trace_flush if exists $self->{trace_check};
               $self->{trace_check} = $file;

               $self->{set}{"bin/$exe"} = ["$dir/$exe"];
               next exe;
            }
         }
      }

      croak "add_bin ($exe): executable not found";
   }
}

=item $extractor->add_eval ($string)

Evaluates the string as perl code and adds all modules that are loaded
by it. For example, this would add L<AnyEvent> and the default backend
implementation module and event loop module:

   $extractor->add_eval ("use AnyEvent; AnyEvent::detect");

Each code snippet will be executed in its own package and under C<use
strict>.

=cut

sub add_eval {
   my ($self, $eval) = @_;

   (my $file = substr $eval, 0, 64) =~ s/\015?\012/\\n/g;

   my $pkg = "libextractor" . ++$self->{count};
   $eval =~ s/\x00/\x00."\\x00".q\x00/g;
   $self->_trace ($file,
      "local \$^H = \$^H;" # vvvvvvvvvvvvvvvvvvvv = use strict; use utf8
      . "eval q\x00package $pkg; BEGIN { \$^H = \$^H | 0x800600 } $eval\x00; die \"\$\@\" if \$\@;\n"
   );
}

=back

=head2 OTHER METHODS FOR ADDING FILES

The following methods add commonly used files that are either not covered
by other methods or add commonly-used dependencies.

=over 4

=item $extractor->add_perl

Adds the perl binary itself to the file set, including the libperl dll, if
needed.

For example, on UNIX systems, this usually adds a F<exe/perl> and possibly
some F<dll/libperl.so.XXX>.

=cut

sub add_perl {
   my ($self) = @_;

   $self->{set}{"exe/perl$Config{_exe}"} = [_perl_path];

   # on debian, we have the special case of a perl binary linked against
   # a static libperl.a (which is not available), but the Config says to use
   # a shared library, which is in the wrong directory, too (which breaks
   # every other perl installation on the system - they are so stupid).

   # that means we can't find the libperl.so, because dbeian actively breaks
   # their perl install, and we don't need it. we work around this by silently
   # not including the libperl if we cannot find it.

   if ($Config{useshrplib} eq "true") {
      my ($libperl, $libpath);

      if ($^O eq "cygwin") {
         $libperl = $Config{libperl};
         $libpath = "$Config{binexp}/$libperl";
      } elsif ($^O eq "MSWin32") {
         ($libperl = $Config{libperl}) =~ s/\Q$Config{_a}\E$/.$Config{so}/;
         $libpath = "$Config{binexp}/$libperl";
      } else {
         $libperl = $Config{libperl};
         $libpath = $self->{lib}{"CORE/$libperl"};
      }

      $self->{set}{"dll/$libperl"} = [$libpath]
         if length $libpath && -e $libpath;
   }
}

=item $extractor->add_core_support

Try to add modules and files needed to support commonly-used builtin
language features. For example to open a scalar for I/O you need the
L<PerlIO::scalar> module:

   open $fh, "<", \$scalar

A number of regex and string features (e.g. C<ucfirst>) need some unicore
files, e.g.:

   'my $x = chr 1234; "\u$x\U$x\l$x\L$x"; $x =~ /\d|\w|\s|\b|$x/i';

This call adds these files (simply by executing code similar to the above
code fragments).

Notable things that are missing are other PerlIO layers, such as
L<PerlIO::encoding>, and named character and character class matches.

=cut

sub add_core_support {
   my ($self) = @_;

   $self->add_eval ('
      # PerlIO::Scalar
      my $v; open my $fh, "<", \$v;

      # various unicore regex/builtin gambits
      my $x = chr 1234;
      "\u$x\U$x\l$x\L$x";
      $x =~ /$_$x?/i
         for qw(\d \w \s \b \R \h \v);
      split " ", $x; # usually covered by the regex above
   ');

   $self->add_eval ('/\x{1234}(?<a>)\g{a}/') if $] >= 5.010; # usually covered by the regex above
}

=item $extractor->add_unicore

Adds (hopefully) all files from the unicore database that will ever be
needed.

If you are not sure which unicode character classes and similar unicore
databases you need, and you do not care about an extra one thousand(!)
files comprising 4MB of data, then you can just call this method, which
adds basically all files from perl's unicode database.

Note that C<add_core_support> also adds some unicore files, but it's not a
subset of C<add_unicore> - the former adds all files neccessary to support
core builtins (which includes some unicore files and other things), while
the latter adds all unicore files (but nothing else).

When in doubt, use both.

=cut

sub add_unicore {
   my ($self) = @_;

   $self->_add ([grep m%^unicore/.*\.pl$%, keys %{ $self->{lib} }]);
}

=item $extractor->add_core

This adds all files from the perl core distribution, that is, all library
files that come with perl.

This is a superset of C<add_core_support> and C<add_unicore>.

This is quite a lot, but on the plus side, you can be sure nothing is
missing.

This requires a full perl installation - Debian GNU/Linux doesn't package
the full perl library, so this function will not work there.

=cut

sub add_core {
   my ($self) = @_;

   my $lib = $self->{lib};

   for (@{
      $self->_read_packlist (".packlist")
   }) {
      $self->{set}{$_} ||= [
         "lib/"
         . ($lib->{$_} or croak "$_: unable to locate file in perl library")
      ];
   }
}

=back

=head2 GLOB-BASED ADDING AND FILTERING

These methods add or manipulate files by using glob-based patterns.

These glob patterns work similarly to glob patterns in the shell:

=over 4

=item /

A F</> at the start of the pattern interprets the pattern as a file
path inside the file set, almost the same as in the shell. For example,
F</bin/perl*> would match all files whose names starting with F<perl>
inside the F<bin> directory in the set.

If the F</> is missing, then the pattern is interpreted as a module name
(a F<.pm> file). For example, F<Coro> matches the file F<lib/Coro.pm> ,
while F<Coro::*> would match F<lib/Coro/*.pm>.

=item *

A single star matches anything inside a single directory component. For
example, F</lib/Coro/*.pm> would match all F<.pm> files inside the
F<lib/Coro/> directory, but not any files deeper in the hierarchy.

Another way to look at it is that a single star matches anything but a
slash (F</>).

=item **

A double star matches any number of characters in the path, including F</>.

For example, F<AnyEvent::**> would match all modules whose names start
with C<AnyEvent::>, no matter how deep in the hierarchy they are.

=back

=cut

sub _extglob2re {
   for (quotemeta $_[1]) {
      s/\\\*\\\*/.*/g;
      s/\\\*/[^\/]*/g;
      s/\\\?/[^\/]/g;

      unless (s%^\\/%%) {
         s%\\:\\:%/%g;
         $_ = "lib/$_\\.pm";
      }

      $_ .= '$';
      s/(?: \[\^\/\] | \. ) \*\$$//x; # remove ** at end

      return qr<^$_>s
   }
}

=over 4

=item $extractor->add_glob ($modglob[, $modglob...])

Adds all files from the perl library that match the given glob pattern.

For example, you could implement C<add_unicore> yourself like this:

   $extractor->add_glob ("/unicore/**.pl");

=cut

sub add_glob {
   my $self = shift;

   for (@_) {
      my $pat = $self->_extglob2re ($_);
      $self->_add ([grep /$pat/, keys %{ $self->{lib} }]);
   }
}

=item $extractor->filter ($pattern[, $pattern...])

Applies a series of include/exclude filters. Each filter must start with
either C<+> or C<->, to designate the pattern as I<include> or I<exclude>
pattern. The rest of the pattern is a normal glob pattern.

An exclude pattern (C<->) instantly removes all matching files from
the set. An include pattern (C<+>) protects matching files from later
removals.

That is, if you have an include pattern then all files that were matched
by it will be included in the set, regardless of any further exclude
patterns matching the same files.

Likewise, any file excluded by a pattern will not be included in the set,
even if matched by later include patterns.

Any files not matched by any expression will simply stay in the set.

For example, to remove most of the useless autoload functions by the POSIX
module (they either do the same thing as a builtin or always raise an
error), you would use this:

   $extractor->filter ("-/lib/auto/POSIX/*.al");

This does not remove all autoload files, only the ones not defined by a
subclass (e.g. it leaves C<POSIX::SigRt::xxx> alone).

=cut

sub filter {
   my ($self, @patterns) = @_;

   $self->_trace_flush;

   my $set = $self->{set};
   my %include;

   for my $pat (@patterns) {
      $pat =~ s/^([+\-])//
         or croak "$_: not a valid filter pattern (missing + or - prefix)";
      my $inc = $1 eq "+";
      $pat = $self->_extglob2re ($pat);

      my @match = grep /$pat/, keys %$set;

      if ($inc) {
         @include{@match} = delete @$set{@match};
      } else {
         delete @$set{@{ $_->[I_DEP] }} # remove dependents
            for delete @$set{@match};
      }
   }

   my @include = keys %include;
   @$set{@include} = delete @include{@include};
}

=item $extractor->runtime_only

This removes all files that are not needed at runtime, such as static
archives, header and other files needed only for compilation of modules,
and pod and html files (which are unlikely to be needed at runtime).

This is quite useful when you want to have only files actually needed to
execute a program.

=cut

sub runtime_only {
   my ($self) = @_;

   $self->_trace_flush;

   my $set = $self->{set};

   # delete all static libraries, also windows stuff
   delete @$set{ grep m%^lib/auto/(?:.+/)?([^\/]+)/\1(?:\Q$Config{_a}\E|\.pdb|\.exp)$%s, keys %$set };

   # delete all extralibs.ld and extralibs.all (no clue what the latter is for)
   delete @$set{ grep m%^lib/auto/.*/extralibs\.(?:ld|all)$%s, keys %$set };

   # delete all .pod, .h, .html files (hopefully none of them are used at runtime)
   delete @$set{ grep m%^lib/.*\.(?:pod|h|html)$%s, keys %$set };

   # delete unneeded unicore files
   delete @$set{ grep m%^lib/unicore/(?:mktables(?:\.lst)?|.*\.txt)$%s, keys %$set };
}

=back

=head2 RESULT SET

=over 4

=item $set = $extractor->set

Returns a hash reference that represents the result set. The hash is the
actual internal storage hash and can only be modified as described below.

Each key in the hash is the path inside the set, without a leading slash,
e.g.:

   bin/perl
   lib/unicore/lib/Blk/Superscr.pl
   lib/AnyEvent/Impl/EV.pm

The value is an array reference with mostly unspecified contents, except
the first element, which is the file system path where the actual file can
be found.

This code snippet lists all files inside the set:

   print "$_\n"
      for sort keys %{ $extractor->set });

This code fragment prints C<< filesystem_path => set_path >> pairs for all
files in the set:

   my $set = $extractor->set;
   while (my ($set,$fspath) = each %$set) {
      print "$fspath => $set\n";
   }

You can implement your own filtering by asking for the result set with
C<< $extractor->set >>, and then deleting keys from the referenced hash
- since you can ask for the result set at any time you can add things,
filter them out this way, and add additional things.

=back

=cut

sub set {
   $_[0]->_trace_flush;
   $_[0]{set}
}

=head1 EXAMPLE

To package he deliantra client (L<Deliantra::Client>), finding all
(perl) files needed to run it is a first step. This can be done by using
something like the following code snippet:

   my $ex = new Perl::LibExtractor;

   $ex->add_perl;
   $ex->add_core_support;
   $ex->add_bin ("deliantra");
   $ex->add_mod ("AnyEvent::Impl::EV");
   $ex->add_mod ("AnyEvent::Impl::Perl");
   $ex->add_mod ("Urlader");
   $ex->filter ("-/*/auto/POSIX/**.al");
   $ex->runtime_only;

First it sets the perl library directory to F<pm> and F<.> (the latter
to work around some AutoLoader bugs), so perl uses only the perl library
files that came with the binary package.

Then it sets some environment variable to override the system default
(which might be incompatible).

Then it runs the client itself, using C<require>. Since C<require> only
looks in the perl library directory this is the reaosn why the scripts
were put there (of course, since F<.> is also included it doesn't matter,
but I refuse to yield to bugs).

Finally it exits with a clean status to signal "ok" to Urlader.

Back to the original C<Perl::LibExtractor> script: after initialising a
new set, the script simply adds the F<perl> interpreter and core support
files (just in case, not all are needed, but some are, and I am too lazy
to find out which ones exactly).

Then it adds the deliantra executable itself, which in turn adds most of
the required modules. After that, the AnyEvent implementation modules are
added because these dependencies are not picked up automatically.

The L<Urlader> module is added because the client itself does not depend
on it at all, but the wrapper does.

At this point, all required files are present, and it's time to slim
down: most of the ueseless POSIX autoloaded functions are removed,
not because they are so big, but because creating files is a costly
operation in itself, so even small fiels have considerable overhead when
unpacking. Then files not required for running the client are removed.

And that concludes it, the set is now ready.

=head1 SEE ALSO

The utility program that comes with this module: L<perl-libextract>.

L<App::Staticperl>, L<Urlader>, L<Perl::Squish>.

=head1 LICENSE

This software package is licensed under the GPL version 3 or any later
version, see COPYING for details.

This license does not, of course, apply to any output generated by this
software.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=cut

1;

