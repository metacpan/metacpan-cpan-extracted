package Module::License::Report;

use warnings;
use strict;
use File::Spec;
use Module::License::Report::CPANPLUS;
use Carp;
use English qw(-no_match_vars);

our $VERSION = '0.02';

=head1 NAME 

Module::License::Report - Determine the license of a module

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    use Module::License::Report;
    
    my $reporter = Module::License::Report->new();
    my $license = $reporter->license('Module::License::Report');
    print $license;                     # 'perl'
    print $license->source_file();      # 'META.yml'
    print $license->confidence();       # '100'
    print $license->package_version();  # '0.01'
    
    my %lic = $reporter->license_chain('Module::License::Report');
    # ( Module-License-Report => 'perl', CPANPLUS => 'perl', ... )

=head1 DESCRIPTION

People who redistribute Perl code must be careful that all of the
included libraries are compatible with the final distribution license.
A large fraction of CPAN packages are licensed as C<Artistic/GPL>,
like Perl itself, but not all.  If you are going to package your work
in, say, a PAR archive with all of its dependencies it's critical
that you inspect the licenses of those dependencies.  This module can
help.

This module utilizes CPANPLUS to do much of the hard work of
locating the requested CPAN distribution, downloading and extracting
it.  If you've never used CPANPLUS before, there will be a one-time
setup step for that module.

=head1 FUNCTIONS

=over

=item $pkg->new()

=item $pkg->new({key =E<gt> value, ...})

Creates a new instance.  Optional parameters can be passed in a hash
reference.  The recognized options are:

=over

=item verbose => BOOLEAN

Causes some diagnostics to be printed to STDOUT if true.

=item cpanhost => URL

Changes the default CPANPLUS mirror to be the specified URL.

=back

=cut

sub new
{
   my $pkg       = shift;
   my $opts_hash = shift || {};

   my $self = bless {
      opts          => $opts_hash,
      license_cache => {},
      depends_cache => {},
   }, $pkg;

   $self->{cp} = Module::License::Report::CPANPLUS->new({
      verbose => $self->{opts}->{verbose},
      cb      => $self->{opts}->{cb},  # primarily just for testing
   });

   if ($self->{opts}->{cpanhost})
   {
      if (!$self->{cp}->set_host($self->{opts}->{cpanhost}))
      {
         croak 'Failed to set CPAN host URL';
      }
   }

   return $self;
}

=item $self->license($module_name)

Retrieves a license object for the specified module, or undef if no
license could be found.  The license object stringifies to the name of
the license.  See also Module::License::Report::Object.

The C<$module_name> argument is usually a package name like
C<Foo::Bar>.  It can also be the distribution name, like C<Foo-Bar>.
This is useful for distributions like Text-PDF where there is no
actual module named Text::PDF, but which has Text::PDF::File
instead.

This method uses CPANPLUS to download and inspect the source
distribution of the module.  If you've never used CPANPLUS before,
there will be a one-time setup phase to configure that module.

=cut

sub license
{
   my $self        = shift;
   my $module_name = shift;

   if (!defined $self->{license_cache}->{$module_name})
   {
      my $mod = $self->{cp}->get_module($module_name);
      if ($mod)
      {
         my $dist_name = $mod->package_name();
         if (defined $self->{license_cache}->{$dist_name})
         {
            $self->{license_cache}->{$module_name} = $self->{license_cache}->{$dist_name};
         }
         else
         {
            my $alt_name = $mod->name();
            my $license = $mod->license() || 0;
            $self->{license_cache}->{$module_name} = $license;
            $self->{license_cache}->{$alt_name} = $license;
            $self->{license_cache}->{$dist_name} = $license;
         }
      }
      else
      {
         $self->{license_cache}->{$module_name} = 0;
      }
   }
   return $self->{license_cache}->{$module_name} || undef;
}

=item $self->license_chain($module_name)

Returns a hash of C<dist_name =E<gt> license> pairs where the
C<dist_name> keys are the distributions of specified module and all of
its dependencies, as reported by Module::Depends.  The values are
Module::License::Report::Object instances.  Perl core modules are
omitted, as those are all known to be licensed like Perl itself.

=cut

sub license_chain
{
   my $self        = shift;
   my $module_name = shift;

   eval { require Module::Depends::Intrusive; };
   if ($EVAL_ERROR)
   {
      croak 'Cannot load Module::Depends';
   }

   eval { require Module::CoreList; };
   if ($EVAL_ERROR)
   {
      croak 'Cannot load Module::CoreList';
   }

   my %seen;
   my %dist_licenses;
   my @stack = ($module_name);
 MODULE:
   while (@stack > 0)
   {
      my $mod_name = shift @stack;
      next MODULE if ($seen{$mod_name}++);

      next MODULE if ($mod_name eq 'perl');

      my $core = Module::CoreList->first_release($mod_name);
      next MODULE if ($core);
      
      my $license = $self->license($mod_name);
      if (!$license)
      { 
         warn "Can't find a license for $mod_name\n";
      }
      else
      {
         if ($license->module_name() ne $mod_name)
         {
            $mod_name = $license->module_name();
            $seen{$mod_name}++;
            my $core = Module::CoreList->first_release($mod_name);
            next MODULE if ($core);
         }
         
         $dist_licenses{$license->package_name()} = $license;
         
         push @stack, $self->_deps($mod_name, $license->package_dir());
      }
   }

   return %dist_licenses;
}

sub _deps
{
   my $self        = shift;
   my $module_name = shift;
   my $dir         = shift;
   
   if (!$self->{depends_cache}->{$module_name})
   {
      my $deps = Module::Depends->new();
      eval { $deps->dist_dir($dir)->find_modules(); };
      if ($deps->error())
      {
         $deps = Module::Depends::Intrusive->new();
         eval { $deps->dist_dir($dir)->find_modules(); };
      }
      $self->{depends_cache}->{$module_name} = [];
      if ($deps && $deps->requires())
      {
         push @{$self->{depends_cache}->{$module_name}},
              sort keys %{$deps->requires()}
      }
   }
   return @{$self->{depends_cache}->{$module_name}};
}

1;
__END__

=back

=head1 BUGS

No specific bugs known.  See rt.cpan.org for more up-to-date
information.

The heuristics for guessing the license from files other than META.yml
are sketchy.  These could always use improvement.

=head1 SEE ALSO

=head2 Modules used internally

Module::License::Report::Object,
Module::License::Report::CPANPLUS,
CPANPLUS,
Module::Depends

=head2 Comparison to other CPAN modules

I am not aware of any other module that performs the function of
determining license, except in limited ways (like CPANPLUS determines
DSLIP and Module::Build uses C<Build.PL>).

Other modules that report module/package metadata include:
Module::Info, Module::Info::File.

=head1 CODING STYLE

This module has over 80% test code coverage in every category and over
90% overall, as reported by Devel::Cover via C<perl Build
testcover>.

This module passes Perl Best Practices guidelines, as enforced by
Perl::Critic v0.12_03.

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=head1 CREDITS

Thanks to I<module-authors @ perl.org> for naming advice.
