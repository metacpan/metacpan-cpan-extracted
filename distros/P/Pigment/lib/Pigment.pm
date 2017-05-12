use strict;
use warnings;

package Pigment;

use parent qw/DynaLoader/;
use Gtk2;
use GStreamer;

our $VERSION = '0.01';

sub dl_load_flags { 0x01 };

__PACKAGE__->bootstrap($VERSION);

sub import {
    my ($class, @args) = @_;

    my $init = 1;

    for my $arg (@args) {
        if (/^-?no_?init$/) {
            $init = 0;
        }
    }

    $class->init if $init;
    return;
}

1;

__END__

=head1 NAME

Pigment - User interfaces with embedded multimedia

=head1 SYNOPSIS

See the C<examples/> directory.

=head1 DESCRIPTION

Pigment allows building of user interfaces with embedded multimedia components.
It is designed with portability in mind and its plugin system will select a
particular underlying graphical API on each platform. This module binds the
pigment library to perl.

=head1 INITIALISATION

=head2 Pigment-E<gt>B<init>

Initializes Pigment. Automatically parses C<@ARGV>, stripping any options known
Pigment. This is called implicitly by C<use Pigment;> unless the C<-no_init>
option is specified.

=head2 boolean = Pigment-E<gt>B<init_check>

Checks if initialization is possible. Returns a true value if so.

=head2 Pigment-E<gt>B<deinit>

Deinitializs Pigment.

=head1 MAINLOOP

=head2 Pigment-E<gt>B<main>

Runs the mainloop. Will not return until terminated with C<main_quit>.

=head2 Pigment-E<gt>B<main_quit>

Quits running the mainloop.

=head2 boolean = Pigment-E<gt>B<events_pending>

Checks if there are events that weren't processed by the mainloop yet. Blocks
until at least one event was processed.

=head2 Pigment-E<gt>B<main_iteration>

Run one iteration of the mainloop, then return.

=head2 Pigment-E<gt>B<main_iteration_do> ($blocking)

=over

=item * $blocking (boolean)

=back

Run one iteration of the mainloop, then return. Same as C<main_iteration>, but
allows passing a false value as the only argument to prevent blocking if there
are no events to be processed.

=head1 VERSION CHECKING

=head2 (major, minor, micro, nano) = Pigment-E<gt>B<version>

Returns the version information of the Pigment library this module was compiled
against.

=head2 string = Pigment-E<gt>B<version_string>

Returns a textual description of the pigment library version.

=head1 SEE ALSO

=over

=item L<Pigment::index>

List of automatically generated documentation.

=item L<https://code.fluendo.com/pigment/trac>

Pigment library's website.

=back

=head1 LICENSE

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009  Florian Ragwitz

=cut
