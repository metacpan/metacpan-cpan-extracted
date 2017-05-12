package Template::Flute::Filter;

use strict;
use warnings;

=head1 NAME

Template::Flute::Filter - Filter base class

=head1 METHODS

=head2 new

Creates Template::Flute::Filter object.

=cut

sub new {
    my ($class, $self);

    $class = shift;
    $self = {};
    bless $self, $class;
    $self->init(@_);
    return $self;
};

=head2 init

No-op initializer, may be overridden in subclass.

=cut

sub init {
};

=head2 filter

No-op filter, supposed to be overridden in subclass.

=cut

sub filter {
    my ($self, $value) = @_;

    return $value;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
