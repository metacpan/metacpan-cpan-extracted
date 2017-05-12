package Module::License::Report::CPANPLUS;

use warnings;
use strict;
use CPANPLUS::Backend;
use Module::License::Report::CPANPLUSModule;

our $VERSION = '0.02';

=head1 NAME 

Module::License::Report::CPANPLUS - Interface to CPANPLUS::Backend

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    use Module::License::Report::CPANPLUS;
    my $cp = Module::License::Report::CPANPLUS->new();
    my $module = $cp->get_module('Foo::Bar');
    my $license = $module->license();

=head1 DESCRIPTION

This is an abstraction of the CPANPLUS API for use by
Module::License::Report.  It's unlikely that you want to use this
directly.

=head1 FUNCTIONS

=over

=item $pkg->new()

=item $pkg->new({key =E<gt> value, ...})

Create a new instance.  Supported options are C<verbose> and C<cb>.
C<cb> is an instantiated CPANPLUS::Backend instance.  If you omit
that (which is recommended), one will be created for you.

=cut

sub new
{
   my $pkg       = shift;
   my $opts_hash = shift || {};

   my $self = bless {
      %$opts_hash,
      modcache => {},
   }, $pkg;
   if (!$self->{cb})
   {
      $self->{cb} = CPANPLUS::Backend->new();
   }
   $self->{cb}->configure_object->set_conf(verbose => $self->{verbose});
   
   return $self;
}

=item $self->set_host($url)

Changes the mirror site that CPANPLUS uses to download packages.

=cut

sub set_host
{
   my $self = shift;
   my $host = shift;

   if ($host && $host eq 'default')
   {
      # noop
      return 1;
   }
   elsif ($host && $host =~ m{ \A (\w+)://([\w\.\-]+)(/.*) \z }xms)
   {
      $self->{cb}->configure_object->set_conf('hosts', [{
         scheme => $1,
         host => $2,
         path => $3,
      }]);
      return 1;
   }
   else
   {
      return;
   }
}

=item $self->get_module($module_name)

Returns a Module::License::Report::CPANPLUSModule instance.

The argument can be either a module name like C<Foo::Bar> or a
distribution name like C<Foo-Bar>.

=cut

sub get_module
{
   my $self = shift;
   my $modname = shift;

   my $cache = $self->{modcache};
   my $key = lc $modname;
   if (!$cache->{$key})
   {
      my $mod = Module::License::Report::CPANPLUSModule->new($self, $modname);
      $cache->{$key} = $mod;
      if ($mod)
      {
         # Prefill alternate name, if any, in the cache
         $cache->{lc $mod->package_name} = $mod;
      }
   }
   return $cache->{$key};
}

sub _module_by_name
{
   # Returns CPANPLUS module (internal only)
   my $self = shift;
   my $modname = shift;

   if ($modname =~ m/\A \w+ (?: ::\w+)* \z /xms)
   {
      return $self->{cb}->module_tree($modname);
   }
   else
   {
      # E.g. Foo-Bar-0.12.03_01.tar.gz
      my $re = qr/\A \Q$modname\E - \d[\d\._]*\.(?:tar\.gz|zip|tgz) \z /ixms;

      # get matching module with the latest version number
      # use the Schwarzian Transform
      my @mods = map {$_->[0]}
                     sort {$b->[1] cmp $a->[1]}
                          map {[$_, $_->package_version]}
                              $self->{cb}->search(type => 'package', allow => [$re]);

      #print 'Search yielded '.$mods[0]->name." for package $modname\n" if ($mods[0] && $self->{verbose});
      return $mods[0];
   }
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan
