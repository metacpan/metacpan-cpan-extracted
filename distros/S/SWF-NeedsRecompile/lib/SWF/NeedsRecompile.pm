package SWF::NeedsRecompile;

use warnings;
use strict;
use 5.008;    # tested only on 5.8.6+, but *should* work on older perls
use Carp;
use English qw(-no_match_vars);
use File::Spec;
use File::Slurp qw();
use Regexp::Common qw(comment);
use File::HomeDir;
use List::MoreUtils qw(any);

our $VERSION = '1.06';

use base qw(Exporter);
our @EXPORT_OK = qw(
   check_files
   as_classpath
   flash_prefs_path
   flash_config_path
);

my $cached_as_classpath;

my $verbosity = 0;
__PACKAGE__->set_verbosity($ENV{SWFCOMPILE_VERBOSITY});

my %os_paths = (
   darwin => {
      pref => [File::Spec->catfile(File::HomeDir->my_home, 'Library', 'Preferences', 'Flash 7 Preferences')],
      conf => [File::Spec->catfile(File::HomeDir->my_home, 'Library', 'Application Support', 'Macromedia',
                                   'Flash MX 2004', 'en', 'Configuration')],
   },
   # TODO: add more entries for "MSWin32", etc
);
# These are mostly Flash 6 component classes
my %exceptions = map { $_ => 1 } qw(
   DataProviderClass
   FScrollSelectListClass
   FSelectableItemClass
   FSelectableListClass
   FStyleFormat
   FUIComponentClass
   Tween
);

sub _get_os_paths    # FOR TESTING ONLY!!!
{
   return \%os_paths;
}

=for stopwords Actionscript Classpath MTASC MX SWF .swf .fla timestamp wildcards UCS2 Dolan Macromedia

=head1 NAME 

SWF::NeedsRecompile - Tests if any SWF or FLA file dependencies have changed

=head1 LICENSE

Copyright 2002-2006 Clotho Advanced Media, Inc.,
L<http://www.clotho.com/>

Copyright 2007-2008 Chris Dolan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SYNOPSIS

    use SWF::NeedsRecompile qw(check_files);
    foreach my $file (check_files(<*.swf>)) {
       print "SWF needs recompilation: $file\n";
    }

=head1 DESCRIPTION

This module parses .fla and .as files and determines dependencies
recursively, via import and #include statements.  It then compares the
timestamps of all of the dependencies against the timestamp of the
.swf file.  If any dependency is newer than the .swf, that file needs
to be recompiled.

=head1 LIMITATIONS

This module only works in its entirety on Mac OS X, and for Flash MX
2004.  Help wanted: extend it to Windows (add appropriate search paths
at the top of the .pm file) and extend it to the Flash 8 author when
that is available.

This module only reports whether or not the .swf is up to date.  It
would be useful to know whether it is out of date because of the .fla
file or any .as files.  In the latter case, the open source MTASC
(L<http://www.mtasc.org/>) application could perform the
recompilation.

This module likely only works with ASCII file names.  The heuristic
used to parse the binary .fla files discards the upper Unicode byte of
any file names.

If there are C<import> statements with wildcards in any .as files,
then all files in the specified directory are considered dependencies,
even if only a subset are actually used.

Direct access to class methods are not detected.  So, if you
Actionscript does something like C<com.example.Foo.doSomething()> then
com/example/Foo.as is not detected as a dependency.  The workaround is
to add an import; in this example it would be
C<import com.example.Foo;>

=head1 FUNCTIONS

=over

=item check_files($file, $file, ...)

Examine a list of .swf and/or .fla files and return the file names of
the ones that need to be recompiled.

Performance note: Information is cached across files, so it's faster
to call this function once with a bunch of files than a bunch of times
with one file each invocation.

=cut

sub check_files
{
   my @files = @_;

   my @needs_recompile;

   # The depends hash is a cache of the #include and import lines in each file
   my %depends;

   foreach my $file (@files)
   {
      (my $base = $file) =~ s/[.](?:swf|fla)\z//xms;
      if ($base eq $file)
      {
         _log(1, "$file is not a .swf or a .fla file");
         next;
      }
      my $swf = "$base.swf";
      my $fla = "$base.fla";

      # Do the simple case first
      if (! -e $swf)
      {
         _log(1, "No file $swf");
         push @needs_recompile, $file;
         next;
      }

      # Look for FLA-specific Classpaths
      my @paths = _get_fla_classpaths($fla);

      # Check all SWF dependencies, recursively
      my @check = ($fla);
      my %checked;
      my $up_to_date = 1;
      while (@check > 0)
      {
         my $checkfile = pop @check;
         next if ($checked{$checkfile});

         if (! -f $checkfile)
         {
            _log(1, "Failed to locate file needed to compile $swf:  $checkfile");
            $up_to_date = 0;
            last;
         }

         _log(2, "check $checkfile");
         $up_to_date = _up_to_date($checkfile, $swf);
         $checked{$checkfile} = 1;
         if (!$up_to_date)
         {
            _log(1, "Failed up to date check for $checkfile vs. $swf");
            last;
         }

         if (! -r $checkfile)
         {
            _log(1, "Unreadable file $checkfile");
            last;
         }

         if (!$depends{$checkfile})
         {
            _log(2, "do deps for $checkfile");
            $depends{$checkfile} = [];
            my $content = File::Slurp::read_file($checkfile);
            my %imported_files;
            my %seen;

            if ($checkfile =~ m/[.]fla\z/ixms)
            {
               # HACK: use C regexp because the ECMAScript regexp can
               # cause an infinite loop on some .fla files.
               # See BUGS AND LIMITATIONS
               $content =~ s/$RE{comment}{C}//gxms;
            }
            else
            {
               $content =~ s/$RE{comment}{ECMAScript}//gxms;
            }

            # check for include and import statements and instantiations via "new"
            my @deps = (
               _get_includes($checkfile, \$content, \%seen),
               _get_imports($checkfile, \$content, \@paths, \%imported_files, \%seen),
               _get_instantiations($checkfile, \$content, \@paths, \%imported_files, \%seen),
            );
            my @problems = map { @{$_} } grep { ref $_ } @deps;
            if (@problems > 0)
            {
               _log(1, "Failed to locate dependencies in $checkfile: @problems");
               $up_to_date = 0;
               last;
            }
            $depends{$checkfile} = \@deps;
         }
         push @check, @{$depends{$checkfile}};
      }

      if (!$up_to_date)
      {
         push @needs_recompile, $file;
      }
   }
   return @needs_recompile;
}

sub _get_fla_classpaths
{
   my $fla = shift;

   my @paths;
   if (-f $fla && (my $content = File::Slurp::read_file($fla, binmode => ':raw')))
   {
      # Limitation: the path must be purely ASCII or this doesn't work
      my @matches = $content =~ m/V\0e\0c\0t\0o\0r\0:\0:\0P\0a\0c\0k\0a\0g\0e\0[ ]\0P\0a\0t\0h\0s\0....((?:[^\0]\0)*)/gxms;
      my %seen;
      for my $match (@matches)
      {
         # Hack: downgrade unicode to ascii
         $match =~ s/\0//gxms;
         next if q{} eq $match;
         my @search_paths = split m/;/xms, $match;
         require File::Spec;
         for my $path (@search_paths)
         {
            if (!File::Spec->file_name_is_absolute($path))
            {
               my $root = [File::Spec->splitpath($fla)]->[1];
               if ($root)
               {
                  $path = File::Spec->rel2abs($path, $root);
               }
            }
            next if ($seen{$path}++);
            push @paths, $path;
         }
      }
      _log(2, "FLA Paths: @paths");
   }
   return @paths;
}

sub _get_includes
{
   my $checkfile   = shift;
   my $content_ref = shift;
   my $seen_ref    = shift;

   my @deps;

   # Check both ascii and ascii-unicode, supporting Flash MX and 2004 .fla files
   # This will fail for non-ascii filenames
   my @matches = ${$content_ref} =~ m/\#\0?i\0?n\0?c\0?l\0?u\0?d\0?e\0?(?:\s\0?)+["]\0?([^"\r\n]+?)["]/gxms; ## no critic (EscapedMeta)
   foreach my $inc (@matches)
   {
      next if ($seen_ref->{$inc}++); # speedup
      # This is a hack.  Strip real Unicode down to ASCII
      $inc =~ s/\0//gxms;
      if ($inc)
      {
         my $file = $inc;
         if (! -f $file)
         {
            if (! File::Spec->file_name_is_absolute($file))
            {
               my $dir = [File::Spec->splitpath($checkfile)]->[1];
               if ($dir)
               {
                  $file = File::Spec->rel2abs($file, $dir);
               }
            }
            return [$inc] if (! -f $file);
         }
         push @deps, $file;
         _log(2, "#include $inc from $checkfile");
      }
   }
   return @deps;
}

sub _get_imports
{
   my $checkfile         = shift;
   my $content_ref       = shift;
   my $fla_path_ref      = shift;
   my $imported_file_ref = shift;
   my $seen_ref          = shift;

   my @deps;
   my @matches = ${$content_ref} =~ m/i\0?m\0?p\0?o\0?r\0?t\0?(?:\s\0?)+((?:[^\;\0\s]\0?)+);/gxms;
   foreach my $imp (@matches)
   {
      next if ($seen_ref->{$imp}++);    # speedup
      # This is a hack.  Strip real Unicode down to ASCII
      $imp =~ s/\0//gxms;
      _log(2, "import $imp from $checkfile");
      my $found = 0;
      foreach my $dir (@{$fla_path_ref}, as_classpath())
      {
         my $f = File::Spec->catdir(File::Spec->splitdir($dir), split m/[.]/xms, $imp);
         if ($f =~ m/[*]\z/xms)
         {
            my @d = File::Spec->splitdir($f);
            pop @d;
            $f = File::Spec->catdir(@d);
            if (-d $f)
            {
               my @as = grep { m/[.]as\z/xms } File::Slurp::read_dir($f);

               for my $file (@as)
               {
                  $imported_file_ref->{$file} = 1;
               }
               @as = map { File::Spec->catfile($f, $_) } @as;

               for my $file (@as)
               {
                  _log(2, "  import $file from $checkfile");
               }
               push @deps, @as;
            }
            $found = 1;
         }
         else
         {
            $f .= '.as';
            if (-f $f)
            {
               my @p = split m/[.]/xms, $imp;
               $imported_file_ref->{$p[-1] . '.as'} = 1;
               _log(2, "  import $f from $checkfile");
               push @deps, $f;
               $found = 1;
               last;
            }
         }
      }
      return [$imp] if (!$found);
   }
   return @deps;
}

sub _get_instantiations
{
   my $checkfile         = shift;
   my $content_ref       = shift;
   my $fla_path_ref      = shift;
   my $imported_file_ref = shift;
   my $seen_ref          = shift;

   # Get a list of all classes defined in this file
   my @classes;
   my @class_matches = ${$content_ref} =~ m/c\0?l\0?a\0?s\0?s\0?(?:\s\0?)+((?:[^;\s\0]\0?)+)/gxms;
   for my $class_match (@class_matches)
   {
      $class_match =~ s/\0//gxms;
      push @classes, $class_match;
   }

   my @deps;
   my @matches = ${$content_ref} =~ m/n\0?e\0?w\0?(?:\s\0?)+((?:[\w.]\0?)+)[(]/gxms;
   foreach my $imp (@matches)
   {
      next if ($seen_ref->{$imp}++); # speedup
      # This is a hack.  Strip real Unicode down to ASCII
      $imp =~ s/\0//gxms;
      next if ($exceptions{$imp});
      _log(2, "instance $imp from $checkfile");
      next if ($imported_file_ref->{$imp . '.as'});
      # Is this class implemented in this very file?
      next if any { $_ eq $imp || m/[.]\Q$imp\E\z/xms } @classes;
      my $found = 0;
      foreach my $dir (@{$fla_path_ref}, as_classpath())
      {
         my $f = File::Spec->catdir(File::Spec->splitdir($dir), split m/[.]/xms, $imp);
         $f .= '.as';
         if (-f $f)
         {
            _log(2, "  instance $f from $checkfile");
            push @deps, $f;
            $found = 1;
            last;
         }
      }
      return [$imp] if (!$found);
   }
   return @deps;
}

=item $pkg->as_classpath()

Returns a list of Classpath directories specified globally in Flash.

=cut

sub as_classpath
{
   if (!$cached_as_classpath)
   {
      my $prefs_file = flash_prefs_path();
      if (!$prefs_file || ! -f $prefs_file)
      {
         #_log(2, 'Failed to locate the Flash prefs file');
         return q{.};
      }

      my $conf_dir = flash_config_path();
      for (File::Slurp::read_file($prefs_file))
      {
         if (m/<Package_Paths>(.*?)<\/Package_Paths>/xms)
         {
            my $cp = $1;
            my @dirs = split /;/xms, $cp;
            for (@dirs)
            {
               if (!$conf_dir)
               {
                  _log(2, "Failed to identify the UserConfig dir for '$_'");
               }
               else
               {
                  s/[$][(]UserConfig[)]/$conf_dir/xms;
               }
            }
            $cached_as_classpath = \@dirs;
            _log(2, "Classpath: @{$cached_as_classpath}");
            last;
         }
      }
   }
   return @{$cached_as_classpath};
}

=item $pkg->flash_prefs_path()

Returns the file name of the Flash preferences XML file.

=cut

sub flash_prefs_path
{
   return _get_path('pref');
}

=item $pkg->flash_config_path()

Returns the path where Flash stores all of its class prototypes.

=cut

sub flash_config_path
{
   return _get_path('conf');
}

=item $pkg->set_verbose($boolean)

=item $pkg->set_verbosity($number)

Changes the verbosity of the whole module.  Defaults to false.  Set to
a number higher than 1 to get very verbose output.

The C<SWFCOMPILE_VERBOSITY> environment variable sets this at module
load time.

The default is C<0> (silent), but we recommend setting verbosity to
C<1>, which emits error messages.  Setting to C<2> also emits
debugging messages.

=cut

sub set_verbose
{
   my $pkg           = shift;
   my $new_verbosity = shift;

   $pkg->set_verbosity($new_verbosity ? 1 : 0);
   return;
}

sub set_verbosity
{
   my $pkg           = shift;
   my $new_verbosity = shift;

   $verbosity = !$new_verbosity                     ? 0
              : $new_verbosity =~ m/\A (\d+) \z/xms ? $1
              :                                       1;
   return;
}

=item $pkg->get_verbosity()

Returns the current verbosity number.

=cut

sub get_verbosity
{
   my $pkg = shift;
   return $verbosity;
}

# Internal helper for the above two functions
sub _get_path
{
   my $type = shift;

   my $os = $os_paths{$OSNAME};    # aka $^O
   if (!$os)
   {
      return;
      #croak "Operating system $^O is not currently supported.  We support:\n   ".
      #    join(q{ }, sort keys %os_paths)."\n";
   }
   my $list = $os->{$type};
   my @match = grep { -e $_ } @{$list};
   if (0 == @match)
   {
      return;
      #croak join("\n  ", 'Failed to find any of the following:', @{$list})."\n";
   }
   return $match[0];
}

# A simplified version of Module::Build::Base::up_to_date
sub _up_to_date
{
   my $src  = shift;
   my $dest = shift;

   return 0 if (! -e $dest);
   return 0 if (-M $dest > -M $src);
   return 1;
}

sub _log
{
   my ($level, @msg) = @_;

   if ($verbosity >= $level)
   {
      print @msg, "\n";
   }
   return;
}

1;
__END__

=back

=head1 BUGS AND LIMITATIONS

=head2 Comments

This module tries to ignore dependencies specified inside comments like these:

   /* #include "foo.as" */
   // var inst = new Some.Class();

but for reasons I don't understand, searching for the latter style of
comments inside binary C<.fla> files can cause a (seemingly) infinite
loop.  So, as a hack we DO NOT ignore C<//...> style comments in
Actionscript that is embedded inside of C<.fla> files.  This can lead
to spurious errors.  Perhaps this is a problem with
Regexp::Common::comment or just that some C<.fla> files have too few
line endings?

=head2 Unicode Class Names and Paths

Flash stores source code and include paths inside of the C<.fla>
binary as (I think) UCS2 strings.  This code converts those strings to
ASCII by simply stripping all of the C<\0> characters.  This is REALLY
BAD, but it works fine for pure-ASCII path names.

=head2 Operating Systems

This code works great on Mac OS X.  The typical paths for the Flash
configuration directory are provided for that platform.

This code will still work marginally under Windows, but for full
support I need to know the path to the preferences file and the
configuration directory.  I need those locations for Macromedia
classes and default include paths.

=head1 SEE ALSO

Module::Build::Flash uses this module.

=head1 AUTHOR

Chris Dolan

This module was originally developed by me at Clotho Advanced Media
Inc.  Now I maintain it in my spare time.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
# End:
# ex: set ts=8 sts=3 sw=3 tw=78 ft=perl expandtab :
