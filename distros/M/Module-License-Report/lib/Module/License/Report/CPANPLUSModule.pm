package Module::License::Report::CPANPLUSModule;

use warnings;
use strict;
use CPANPLUS::Internals::Constants;
use File::Slurp qw();
use File::Spec qw();
use Module::License::Report::Object;
use YAML qw();

our $VERSION = '0.02';

# This is a translation from CPAN "dslip" codes to Module::Build YAML codes
#   From: http://cpan.uwinnipeg.ca/htdocs/faqs/dslip.html
#   To:   http://search.cpan.org/dist/Module-Build/lib/Module/Build.pm#license
my %dslip_license_abbrevs = (
   p   => 'perl',
   g   => 'gpl',
   l   => 'lgpl',
   b   => 'bsd',
   a   => 'artistic',
   o   => 'unrestricted',
);


### CHANGES HERE SHOULD BE REFLECTED IN ::Object POD!  ###
# This is an unordered list of possible sources for license information
# Each entry has these fields:
#   name - Machine-readable codeword for the source - should not change ever
#   description - Human-readable description of the source
#   confidence - Number between 100 (high) and 0 (low)
#   sub - Anonymous function that returns (<licensename>, <filename>)
#         Note that the filename may be undef
my @license_sources = (
   {
      name        => 'META.yml',
      description => 'META.yml license field',
      confidence  => 100,
      sub         => sub {
         my $self = shift;
         return $self->yml()->{license}, 'META.yml';
      },
   },
   {
      name        => 'DSLIP',
      description => 'CPAN license field',
      confidence  => 95,
      sub         => sub {
         my $self = shift;
         return $self->dslip()->{license}, undef;
      },
   },
   {
      name        => 'Module',
      description => 'Copyright statement in module file',
      confidence  => 50,
      sub         => sub {
         my $self = shift;
         my $file = $self->version_from();
         return $self->license_from_file($file), $file;
      },
   },
   {
      name        => 'POD',
      description => 'Copyright statement in module pod file',
      confidence  => 45,
      sub         => sub {
         my $self = shift;
         my $file = $self->version_from_pod();
         return $self->license_from_file($file), $file;
      },
   },
   {
      name        => 'LicenseFile',
      description => 'Copyright statement in miscellaneous file',
      confidence  => 25,
      sub         => sub {
         my $self = shift;
         my $file = $self->license_filename();
         return $self->license_from_file($file), $file;
      },
   },
);

=head1 NAME 

Module::License::Report::CPANPLUSModule - Abstraction of a CPAN module

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    use Module::License::Report::CPANPLUS.pm
    use Module::License::Report::CPANPLUSModule.pm
    my $cp = Module::License::Report::CPANPLUS->new();
    my $module = Module::License::Report::CPANPLUSModule->new($cp, 'Foo::Bar');
    my $license = $module->license();

=head1 DESCRIPTION

This is an extension of the CPANPLUS::Module API for use by
Module::License::Report.  It's unlikely that you want to use this
directly.

=head1 FUNCTIONS

=over

=item $pkg->new($cp, $module_name)

The C<$cp> argument is a Module::License::Report::CPANPLUS
instance.  The C<$module_name> should be of a form acceptable to
Module::License::Report::CPANPLUS::get_module().

=cut

sub new
{
   my $pkg  = shift;
   my $cp   = shift; # Module::License::Report::CPANPLUS instance
   my $name = shift;

   my $self = bless {
      cp   => $cp,
      name => $name,
      mod  => $cp->_module_by_name($name),
   }, $pkg;
   
   return $self->{mod} ? $self : ();
}

=item $self->verbose()

Returns a boolean.

=cut

sub verbose
{
   my $self = shift;
   return $self->{cp}->{verbose};
}

=item $self->license()

Returns a Module::License::Report::Object instance, or undef.

=cut

sub license
{
   my $self = shift;

   _announce("Find license for $self->{name}", $self->verbose());
   for my $source (reverse sort {$a->{confidence} <=> $b->{confidence}} @license_sources)
   {
      _announce("  Try source $source->{name}", $self->verbose());
      my ($license, $file) = $source->{sub}($self);
      my $result = {
         name        => $license,
         source_file => $file,
         source_name => $source->{name},
         source_desc => $source->{description},
         confidence  => $source->{confidence},
         module      => $self,
      };
      if ($license)
      {
         return Module::License::Report::Object->new($result);
      }
   }
   return;
}

=item $self->license_from_file($filename)

Searches the specified file for license and/or copyright information.
This uses heuristics.

=cut

sub license_from_file
{
   my $self        = shift;
   my $licensefile = shift;

   if ($licensefile)
   {
      my $filename = File::Spec->catfile($self->extract_dir(), $licensefile);
      if (-f $filename)
      {
         my $content = File::Slurp::read_file($filename);
         if ($content =~ m/=head\d\s+(?:licen[cs]e|licensing|copyright|legal)\b(.*?)(=head\\d.*|=cut.*|)\z/ixms)
         {
            my $licensetext = $1;

            # Check for any of the following phrases (Change spaces to \s+)
            my @phrases = (
               'under the same (?:terms|license) as Perl itself',
            );
            my $regex = join q{|}, map {join '\\s+', split m/\s+/xms, $_} @phrases;
            if ($licensetext =~ m/$regex/ixms)
            {
               return 'perl';
            }
         }
      }
   }

   return undef; ## no critic needs an explicit undef because of list context
}

=item $self->yml()

Loads and parses a C<META.yml> file.  Returns a hashref that has,
minimally, a C<license> field.

=cut

sub yml
{
   my $self = shift;

   if (!$self->{yml})
   {
      $self->{yml} = {
         license => undef,
      };
      my $filename = File::Spec->catfile($self->extract_dir(), 'META.yml');
      if (-f $filename)
      {
         my $yaml = File::Slurp::read_file($filename);
         my $meta = eval { YAML::Load($yaml) };
         if (!$meta)
         {
            _announce('Failed to read META.yml', $self->verbose());
         }
         else
         {
            for my $key (qw(license))
            {
               if ($meta->{$key})
               {
                  $self->{yml}->{$key} = $meta->{$key};
               }
            }
         }
      }
   }
   return $self->{yml};
}

=item $self->dslip()

Parses the CPAN DSLIP metadata.  Returns a hashref that has,
minimally, a C<license> field.

See L<http://cpan.uwinnipeg.ca/htdocs/faqs/dslip.html> for more
information.

=cut

sub dslip
{
   my $self = shift;

   if (!$self->{dslip})
   {
      $self->{dslip} = {
         license => undef,
      };
      my $dslip_str = $self->{mod}->dslip();
      if ($dslip_str)
      {
         my ($devel_stage,
             $support_level,
             $language_used,
             $interface_style,
             $public_license) = $dslip_str =~ m/(.)/gxms;

         if ($public_license)
         {
            $self->{dslip}->{license} = $dslip_license_abbrevs{$public_license};
         }
      }
   }
   return $self->{dslip};
}

=item $self->makefile()

Loads and parses a C<Makefile.PL> file.  Returns a hashref that has,
minimally, a C<license> field.

The parsing is very simplistic.

=cut

sub makefile
{
   my $self = shift;

   if (!$self->{makefile})
   {
      $self->{makefile} = {};
      my $filename = File::Spec->catfile($self->extract_dir(), 'Makefile.PL');
      if (-f $filename)
      {
         my $makefile = File::Slurp::read_file($filename);

         # Get main file from the MakeMaker command
         if ($makefile =~ m/([\'\"]?)VERSION_FROM\1\s*(?:=>|,)\s*(\"[^\"]+|\'[^\']+)/xms)
         {
            my $module_file = substr $2, 1;  # remove leading quote
            $self->{makefile}->{version_from} = $module_file;
         }
      }
   }
   return $self->{makefile};
}

=item $self->buildfile()

Loads and parses a C<Build.PL> file.  Returns a hashref that has,
minimally, a C<license> field.

The parsing is very simplistic.

=cut

sub buildfile
{
   my $self = shift;

   if (!$self->{buildfile})
   {
      $self->{buildfile} = {};
      my $filename = File::Spec->catfile($self->extract_dir(), 'Build.PL');
      if (-f $filename)
      {
         my $buildfile = File::Slurp::read_file($filename);

         # Get main file from the Module::Build constructor
         if ($buildfile =~ m/([\'\"]?)module_name\1\s*(?:=>|,)\s*(\"[^\"]+|\'[^\']+)/xms)
         {
            my $module_name = substr $2, 1;  # remove leading quote

            # This algorithm comes from Module::Build::Base::dist_version() v0.27_02
            my $file = File::Spec->catfile('lib', split m/::/xms, $module_name) . '.pm';

            $self->{buildfile}->{version_from} = $file;
         }
         elsif ($buildfile =~ m/([\'\"]?)dist_version_from\1\s*(?:=>|,)\s*(\"[^\"]+|\'[^\']+)/xms)
         {
            my $module_file = substr $2, 1;  # remove leading quote
            $self->{buildfile}->{version_from} = $module_file;
         }
      }
   }
   return $self->{buildfile};
}

=item $self->version_from()

Returns the name of the file that has the definitive C<VERSION>.
This file might not exist.

This relies on parsing C<META.yml>, C<Build.PL> or C<Makefile.PL>.

=cut

sub version_from
{
   my $self = shift;

   my @candidates = (
      $self->yml()->{version_from},
      $self->buildfile()->{version_from},
      $self->makefile()->{version_from},
   );

   for my $filename (@candidates)
   {
      if ($filename && -f File::Spec->catfile($self->extract_dir(), $filename))
      {
         return $filename;
      }
   }
   return;
}

=item $self->version_from_pod()

Returns the name of a C<.pod> file that corresponds to version_from().
This file might not exist.

=cut

sub version_from_pod
{
   my $self = shift;

   my $version_from = $self->version_from();
   my $version_pod;
   if ($version_from && $version_from =~ m/ \.pm \z /xms)
   {
      ($version_pod = $version_from) =~ s/ \.pm \z /.pod/xms;
   }
   return $version_pod;
}

=item $self->license_filename()

Returns the name of the file that is the most likely source of license or copyright information.

=cut

sub license_filename
{
   my $self = shift;

   # Check files that are for-sure
   my @licenses = grep {m/\A (?:copyright|copying|license|gpl|lgpl|artistic) \b /ixms} $self->root_files();
   if (@licenses > 0)
   {
      return $licenses[0];
   }

   # Check doc files that might have copyright inline
   foreach my $file ((grep {m/\A readme/ixms} $self->root_files()),
                     (grep {defined $_} $self->version_from(), $self->version_from_pod()))
   {
      my $filename = File::Spec->catfile($self->extract_dir(), $file);
      if (-f $filename)
      {
         my $content = File::Slurp::read_file($filename);
         if ($content =~ m/\b(?:licen[sc]e|licensing|copyright)\b/ixms) # [sc] is to catch a common typo
         {
            return $file;
         }
      }
   }

   return;
}

=item $self->root_files()

Returns a list of all files in the root of the distribution directory,
like C<README>, C<Makefile.PL>, etc.

=cut

sub root_files
{
   my $self = shift;

   # Get list of files in the root of the distro
   my @files = grep {-f File::Spec->catfile($self->extract_dir(), $_)}
                    File::Slurp::read_dir($self->extract_dir());
   return @files;
}

=item $self->name()

Returns the module name that was specified in the constructor.

=cut

sub name
{
   my $self = shift;
   return $self->{name};
}

=item $self->package_name()

Returns the name of the package, like C<Foo-Bar>.

=cut

sub package_name
{
   my $self = shift;
   return $self->{mod}->package_name();
}

=item $self->package_version()

Returns the version of the package, like C<0.12.04_01>.

=cut

sub package_version
{
   my $self = shift;
   return $self->{mod}->package_version();
}

=item $self->extract_dir

Returns the path to the extracted distribution.  If the distribution
is not yet extracted, does that first.

=cut

sub extract_dir
{
   my $self = shift;
   return $self->extract();
}

=item $self->extract()

Extracts the distribution archive (perhaps a C<.tar.gz> or a C<.zip>
file) and returns the path.

=cut

sub extract
{
   my $self = shift;

   $self->fetch();
   if (!$self->{mod}->status->extract)
   {
      #_announce('Extract module', $self->verbose());
      $self->{mod}->extract;
      if ($self->verbose)
      {
         _announce('Extracted to ' . $self->{mod}->status()->extract(), $self->verbose());
      }
   }
   return $self->{mod}->status->extract;
}

=item $self->fetch()

Downloads the distribution from CPAN.

=cut

sub fetch
{
   my $self = shift;

   if (!$self->{mod}->status->fetch)
   {
      #_announce('Fetch module', $self->verbose());
      $self->{mod}->fetch;
   }
   return $self->{mod}->status->fetch;
}

sub _announce
{
   my $msg = shift;
   my $verbose = shift;

   if ($verbose)
   {
      print $msg,"\n";
   }
   return;
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan
