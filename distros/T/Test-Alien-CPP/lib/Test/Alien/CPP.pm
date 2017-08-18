package Test::Alien::CPP;

use strict;
use warnings;
use 5.008001;
use Test::Alien 0.95 ();
use base qw( Exporter );

# ABSTRACT: Testing tools for Alien modules for projects that use C++
our $VERSION = '0.96'; # VERSION


our @EXPORT = @Test::Alien::EXPORT;

Test::Alien->import(grep !/^xs_ok$/, @EXPORT);


sub xs_ok
{
  my $cb;
  $cb = pop if defined $_[-1] && ref $_[-1] eq 'CODE';
  my($xs, $message) = @_;

  $xs = { xs => $xs } unless ref $xs;
  $xs->{pxs}->{'C++'} = 1;
  $xs->{cbuilder_compile}->{'C++'} = 1;
  
  if($Test::Alien::VERSION >= 0.96)
  {
    $xs->{c_ext} = 'cpp';
  }
  else
  {
    $xs->{cpp} = 1;
  }
  
  $cb ? Test::Alien::xs_ok($xs, $message, $cb) : Test::Alien::xs_ok($xs, $message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Alien::CPP - Testing tools for Alien modules for projects that use C++

=head1 VERSION

version 0.96

=head1 SYNOPSIS

 use Test2::V0;
 use Test::Alien;
 use Alien::libmycpplib;
 
 alien_ok 'ALien::libmycpplib';
 my $xs = do { local $/; <DATA> };
 xs_ok $xs, with_subtest {
   my($module) = @_;
   ok $module->version;
 };
 
 done_testing;
 
 __DATA__
 
 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 #include <mycpplib.h>
 
 MODULE = TA_MODULE PACKAGE = TA_MODULE
 
 const char *
 version(klass)
     const char *klass
   CODE:
     RETVAL = MyCppLib->version;
   OUTPUT:
     RETVAL

=head1 DESCRIPTION

This module works exactly like L<Test::Alien> except that it supports C++.  All
functions like C<alien_ok>, etc that are exported by L<Test::Alien> are exported
by this module.  The only difference is that C<xs_ok> injects C++ support before
delegating to L<Test::Alien>.

=head1 FUNCTIONS

=head2 xs_ok

 xs_ok $xs;
 xs_ok $xs, $message;

Compiles, links the given C<XS> / C++ code and attaches to Perl.
See L<Test::Alien> for further details on how this test works.

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=item L<Test::Alien::CanCompileCpp>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
