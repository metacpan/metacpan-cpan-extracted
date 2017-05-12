package Test::PlugAuth::Plugin::Refresh;

use strict;
use warnings;
use PlugAuth;
use Clustericious::Config;
use Test::PlugAuth::Plugin;
use Test::Builder;
use Role::Tiny ();
use base qw( Exporter );

our @EXPORT = qw( run_tests );

# ABSTRACT: Test a PlugAuth Refresh plugin for correctness
our $VERSION = '0.35'; # VERSION


my $Test = Test::Builder->new;

sub run_tests
{
  my($class) = @_;
  $class = "PlugAuth::Plugin::$class" unless $class =~ /::/;
  eval qq{ use $class };
  die $@ if $@;
  
  $Test->plan( tests => 4);
  
  my $object = eval { $class->new(Clustericious::Config->new({}), Clustericious::Config->new({}), PlugAuth->new) };
  my $error = $@;
  if(ref $object)
  {
    $Test->ok(1, "New returns a reference");
  }
  else
  {
    $Test->ok(0, "New returns a reference");
    $Test->diag("ERROR: $error");
  }
  
  $Test->ok( Role::Tiny::does_role($object, 'PlugAuth::Role::Plugin'),  'does Plugin');
  $Test->ok( Role::Tiny::does_role($object, 'PlugAuth::Role::Refresh'), 'does Refresh');
  $Test->ok( eval { $object->can('refresh') }, "can refresh");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PlugAuth::Plugin::Refresh - Test a PlugAuth Refresh plugin for correctness

=head1 VERSION

version 0.35

=head1 SYNOPSIS

 use Test::PlugAuth::Plugin::Refresh;
 run_tests 'MyPlugin';  # runs tests against PlugAuth::Plugin::MyPlugin

=head1 FUNCTIONS

=head2 run_tests $plugin_name

Run the specification tests against the given plugin.

=head1 SEE ALSO

L<PlugAuth>,
L<PlugAuth::Guide::Plugin>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
