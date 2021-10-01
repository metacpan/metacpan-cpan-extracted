package Task::AlienDev;

use strict;
use warnings;
use 5.022;

# ABSTRACT: Task bundle for Alien development
our $VERSION = '0.02'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::AlienDev - Task bundle for Alien development

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 $ cpanm Task::AlienDev

=head1 DESCRIPTION

This L<Task> bundle is useful for those doing L<Alien> development.  Installing it will give
you these modules:

=over 4

=item L<Alien::Build>

Framework for writing L<Alien>s.

=item L<Alien::MSYS>

Is used on Windows to make autoconf style packages work.

=item L<App::af>

The C<af> command line application for working with L<alienfile>s.

=item L<Dist::Zilla::MintingProfile::AlienBuild>

The L<Dist::Zilla> minting profile for creating L<Alien::Build> based L<Alien>s.

=item L<Dist::Zilla::Plugin::AlienBuild>

Some useful L<Dist::Zilla> plugins useful for developing L<Alien::Build> based L<Alien>s.

=back

The latest versions as of when this L<Task> was released should be installed at minimum if
they are not already installed.

In addition these modules, which are dynamic dependencies on some platforms, are installed:

=over 4

=item L<Env::ShellWords>

=item L<File::Listing>

=item L<HTTP::Tiny>

=item L<Mojo::DOM58>

=item L<Sort::Versions>

=item L<URI>

=back

Having these dynamic dependencies pre-installed makes it easier to test L<Alien>s in both
C<share> and C<system> modes.

Other prereqs may be added in the future if they are deemed useful for L<Alien> development.

=head1 CAVEATS

This module does require Perl 5.22 or better currently because at least some of its prereqs
require that version.  Note that L<Alien>s authored with these tools should work on Perls
of at least 5.8.4 or better, so this is just a I<development> requirement.

This L<Task> indirectly requires both L<Alien::FFI> and L<Alien::Libarchive3>.  If you do
not want to build them from source or do not have internet access where the build is
happening you will want to pre-install C<libffi> and C<libarchive>.  On Debian based systems
you can do that with C<sudo apt-get update && sudo apt-get install libffi-dev libarchive-dev>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
