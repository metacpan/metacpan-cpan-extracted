package Nitesi::Class;

use strict;
use warnings;

=head1 NAME

Nitesi::Class - Instantiate objects at runtime

=head1 SYNOPSIS

    Nitesi::Class->instantiate('My::Nitesi::Extension', foo => 'bar')

=head1 METHODS

=head2 instantiate

Loads class and instantiates object with optional parameters.

=cut

sub instantiate {
    my ($self, $class, @args) = @_;
    my ($object);

    eval "require $class";

    if ($@) {
	die "failed to load class $class: $@";
    }

    eval {
	$object = $class->new(@args);
    };

    if ($@) {
	die "failed to instantiate class $class: $@";
    }

    return $object;
}

=head2 load

Loads class.

=cut

sub load {
    my ($self, $class) = @_;

    eval "require $class";

    if ($@) {
	die "failed to load class $class: $@";
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
