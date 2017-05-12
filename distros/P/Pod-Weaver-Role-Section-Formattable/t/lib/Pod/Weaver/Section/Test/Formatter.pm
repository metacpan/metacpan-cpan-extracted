#
# This file is part of Pod-Weaver-Role-Section-Formattable
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::Section::Test::Formatter;

use Moose;
use namespace::autoclean;

with 'Pod::Weaver::Role::Section::Formattable';

sub default_format { 'Hi there %n, remember to eat your pears!' }

sub default_section_name { 'PEARS!' }

sub additional_codes {
    my ($self) = @_;

    return (

        n => sub { shift->{name} },
    );
}

__PACKAGE__->meta->make_immutable;
!!42;
__END__
