package Task::FFIDev;

use strict;
use warnings;
use 5.020;

# ABSTRACT: Task bundle for FFI development
our $VERSION = '0.02'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::FFIDev - Task bundle for FFI development

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 $ cpanm Task::FFIDev

=head1 DESCRIPTION

This L<Task> bundle is useful for those doing FFI development with L<FFI::Platypus>.  Installing it
will give you these modules:

=over 4

=item L<Dist::Zilla::MintingProfile::FFI>

L<Dist::Zilla> minting profile for creating L<FFI::Platypus> bindings.

=item L<Dist::Zilla::Plugin::FFI>

L<Dist::Zilla> plugins useful for FFI

=item L<Dist::Zilla::Plugin::DynamicPrereqs>

L<Dist::Zilla> plugin for dynamic prereqs.  Allows your FFI to use L<Alien>s in fallback mode.

=item L<FFI::C>

Create interfaces to C structured data.

=item L<FFI::CheckLib>

Find dynamic libraries for use with FFI

=item L<FFI::Platypus>

Library for writing your own FFI bindings in perl

=item L<FFI::Platypus::Type::Enum>

Platypus type plugin for enumerated types

=item L<FFI::Platypus::Type::PtrObject>

Platypus type plugin for opaque pointer objects

=item L<PeekPoke::FFI>

Library for peeking and poking arbitrary memory locations.

=item L<Test2::Tools::FFI>

Testing tools for FFI.

=back

The latest versions as of when this L<Task> was released should be installed at minimum, if they are
not already installed.

Other prereqs may be added in the future if they are deemed useful for FFI development.

=head1 CAVEATS

This module does require Perl 5.20 or better currently, because at least some of its prereqs require
that version.  Note that FFI bindings authored with these tools should work on Perls of at least
5.8.4 or better, so this is just a I<development> requirement.

This L<Task> indirectly requires L<Alien::FFI>.  If you do not want to build that from source
or do not have internet access where the build is happening, you will want to pre-install libffi.
On Debian based systems you can do that with C<sudo apt-get update && sudo apt-get install libffi-dev>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
