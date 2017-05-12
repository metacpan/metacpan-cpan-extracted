package Perl::Destruct::Level;

use strict;
use warnings;
use XSLoader ();

our $VERSION = '0.02';

XSLoader::load 'Perl::Destruct::Level', $VERSION;

sub import {
    shift;
    my %p = @_;
    set_destruct_level($p{level}) if exists $p{level};
}

1;

__END__

=head1 NAME

Perl::Destruct::Level - Allow to change perl's destruction level

=head1 SYNOPSIS

    use Perl::Destruct::Level level => 1;

    my $current_destruct_level = Perl::Destruct::Level::get_destruct_level();

=head1 DESCRIPTION

This module allows to change perl's internal I<destruction level>.

The default value of the destruct level is 0; it means that perl won't
bother destroying all its internal data structures, but let the OS do
the cleanup for it at exit.

For perls built with debugging support (C<-DDEBUGGING>), an environment
variable C<PERL_DESTRUCT_LEVEL> allows to control the destruction level.
This modules enables to modify it on non-debugging perls too.

Relevant values recognized by perl are 1 and 2. Consult your source
code to know exactly what they mean. Note that some embedded environments
might extend the meaning of the destruction level for their own purposes:
mod_perl does that, for example.

=head1 CAVEATS

This module won't work when used from within an END block.

Loading the C<threads> module will set the destruction level to 2. (This
is to enable spawned threads to properly cleanup their objects.) Loading
modules that load C<threads>, even if they don't spawn threads, will
also set the destruction level to 2. (A common example of such a module
is C<Test::Builder>.)

=head1 AUTHOR

Copyright (c) 2007 Rafael Garcia-Suarez. This program is free software; you
may redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perlrun>, L<perlhack>

=cut
