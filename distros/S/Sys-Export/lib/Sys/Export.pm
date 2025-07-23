package Sys::Export;

our $VERSION = '0.001'; # VERSION
# ABSTRACT: Export a subset of an OS file tree, for chroot/initrd

use v5.26;
use warnings;
use experimental qw( signatures );
use Carp;
use Scalar::Util qw( blessed looks_like_number );
use Exporter ();
our @EXPORT_OK= qw(
   isa_exporter isa_export_dst isa_userdb isa_user isa_group exporter
   add finish rewrite_path rewrite_user rewrite_group
);
our %EXPORT_TAGS= (
   basic_methods => [qw( exporter add finish rewrite_path rewrite_user rewrite_group )],
   isa => [qw( isa_exporter isa_export_dst isa_userdb isa_user isa_group )],
);
my ($is_module_name, $require_module);

# optional dependency on Module::Runtime.  This way if there's any bug in my cheap
# substitute, the fix is to just install the official module.
if (eval { require Module::Runtime; }) {
   $is_module_name= \&Module::Runtime::is_module_name;
   $require_module= \&Module::Runtime::require_module;
} else {
   $is_module_name= sub { $_[0] =~ /^[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*\z/ };
   $require_module= sub { require( ($_[0] =~ s{::}{/}gr).'.pm' ) };
}


sub import {
   my $class= $_[0];
   my $caller= caller;
   my %ctor_opts;
   for (my $i= 1; $i < $#_; ++$i) {
      if (ref $_[$i] eq 'HASH') {
         %ctor_opts= ( %ctor_opts, %{ splice(@_, $i--, 1) } );
      }
      elsif ($_[$i] =~ /^-(type|src|dst|src_userdb|dst_userdb|rewrite_path|rewrite_user|rewrite_group)\z/) {
         $ctor_opts{$1}= (splice @_, $i--, 2)[1];
      }
   }
   if (keys %ctor_opts) {
      init_global_exporter(%ctor_opts);
      # caller requested the global exporter instance, so also include the standard methods
      # unless it looks like they were more selective about what to import.
      push @_, 'exporter', ':basic_methods'
         unless grep /^(add|:.*methods)\z/, @_;
   }
   goto \&Exporter::import;
}

our $exporter;
sub exporter { $exporter }

our %osname_to_class= (
   linux => 'Linux',
);

sub init_global_exporter(%config) {
   my $type= delete $config{type} // $^O;
   # remap known OS names
   my $class= $osname_to_class{$type} // $type;
   # prefix bare names with namespace
   $class= "Sys::Export::$class" unless $class =~ /::/;
   $is_module_name->($class) or croak "Invalid module name '$class'";
   # if it fails, die with 'croak'
   eval { $require_module->($class) } or croak "$@";
   # now construct one
   $exporter= $class->new(%config);
}


sub add           { $exporter->add(@_) }
sub finish        { $exporter->finish(@_) }
sub rewrite_path  { $exporter->rewrite_path(@_) }
sub rewrite_user  { $exporter->rewrite_user(@_) }
sub rewrite_group { $exporter->rewrite_group(@_) }


sub isa_exporter   :prototype($) { blessed($_[0]) && $_[0]->isa('Sys::Export::Exporter') }
sub isa_export_dst :prototype($) { blessed($_[0]) && $_[0]->can('add') && $_[0]->can('finish') }
sub isa_userdb     :prototype($) { blessed($_[0]) && $_[0]->can('user') && $_[0]->can('group') }
sub isa_user       :prototype($) { blessed($_[0]) && $_[0]->isa('Sys::Export::Unix::UserDB::User') }
sub isa_group      :prototype($) { blessed($_[0]) && $_[0]->isa('Sys::Export::Unix::UserDB::Group') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export - Export a subset of an OS file tree, for chroot/initrd

=head1 SYNOPSIS

  use Sys::Export::CPIO;
  use Sys::Export -src => '/', -dst => Sys::Export::CPIO->new("initrd.cpio");
  
  rewrite_path '/sbin'     => '/bin';
  rewrite_path '/usr/sbin' => '/bin';
  rewrite_path '/usr/bin'  => '/bin';
  
  add '/bin/busybox';
  add ...;
  finish;

=head1 DESCRIPTION

This module is designed to export a subset of an operating system to a new directory,
automatically detecting and including any libraries or interpreters required by the requested
subset, and optionally rewriting paths and users/groups and updating the copied files to refer
to the rewritten paths, when possible.

The actual export implementation is handled by a OS-specific module, like L<Sys::Export::Linux>.
This top-level module just exports methods.  You can configure a global exporter instance on
the C<use> line, and then call its methods via exported functions.  For instance,

  use Sys::Export \%options;

is roughly equivalent to:

  BEGIN {
    if ($^O eq 'linux') {
      require Sys::Export::Linux;
      $Sys::Export::exporter= Sys::Export::Linux->new(\%options);
    } else {
      ...
    }
    sub exporter      { $Sys::Export::exporter }
    sub add           { $Sys::Export::exporter->add(@_) }
    sub rewrite_path  { $Sys::Export::exporter->rewrite_path(@_) }
    sub rewrite_user  { $Sys::Export::exporter->rewrite_user(@_) }
    sub rewrite_group { $Sys::Export::exporter->rewrite_group(@_) }
    sub finish        { $Sys::Export::exporter->finish }
  }

In other words, just a convenience for creating an exporter instance and giving you access to
most of its important methods without needing to reference the object.  You can skip this
module entirely and just directly use a C<Sys::Export::Linux> object, if you prefer.

Currently, only Linux is fully supported.

=head1 CONFIGURATION

The following can be passed on the C<use> line to configure a global exporter object:

=over

=item A Hashref

  use Sys::Export { ... };

The keys of the hashref will be passed to the exporter constructor (aside from the key
C<'type'> which is used to override the default class)

=item -type

Specify a class of exporter, like C<'Linux'> or C<'Sys::Export::Linux'>.  Names without colons
imply a prefix of C<Sys::Export::>.

=item -src

Source directory; see L<Sys::Export::Unix/src>.

=item -dst

Destination directory or CPIO instance; see L<Sys::Export::Unix/dst>.

=item -src_userdb

Defines UID/GID of source filesystem; see L<Sys::Export::Unix/src_userdb>.

=item -dst_userdb

Defines UID/GID of destination; see L<Sys::Export::Unix/dst_userdb>.

=item -rewrite_path

Hashref of rewrites; see L<Sys::Export::Unix/rewrite_path>.

=item -rewrite_user

Hashref of rewrites; see L<Sys::Export::Unix/rewrite_user>.

=item -rewrite_group

Hashref of rewrites; see L<Sys::Export::Unix/rewrite_group>.

=back

=head1 EXPORTS

=head2 exporter

A function to access C<$Sys::Exporter::exporter>

=head2 init_global_exporter

  init_global_exporter(\%config);

A function to initialize C<$Sys::Exporter::exporter>, which also handles autoselecting the
type of the exporter.

=head2 C<:basic_methods> bundle

You get this bundle by default if you configured a global exporter.  The following methods of
the global exporter object get exported as functions:

=over

=item add

=item finish

=item rewrite_path

=item rewrite_user

=item rewrite_group

=back

=head2 C<:isa> bundle

  use Sys::Export ":isa";

These boolean functions are useful for type inspection.

=over

=item isa_exporter

Is it an object and an instance of C<Sys::Export::Exporter>?

=item isa_export_dst

Is it an object which can receive exported files? (C<add> and C<finish> methods)

=item isa_userdb

Is it an instance of C<Sys::Export::Unix::UserDB>?

=item isa_user

Is it an instance of C<Sys::Export::Unix::UserDB::User>?

=item isa_group

Is it an instance of C<Sys::Export::Unix::UserDB::Group>?

=back

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
