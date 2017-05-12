package MouseX::Foreign;
use 5.008_001;
use Mouse::Util; # turns on strict and warnings

our $VERSION = '1.000';

use Mouse::Util::MetaRole;
use Carp ();

sub import {
    shift;

    my $caller = caller;
    if(!$caller->can('meta')){
        Carp::croak(
              "$caller does not have the meta method"
            . " (did you use Mouse for $caller?)");
    }

    Mouse::Util::MetaRole::apply_metaroles(
        for => $caller,
        class_metaroles => {
            class => ['MouseX::Foreign::Meta::Role::Class'],
        },
    );

    $caller->meta->superclasses(@_) if @_;
    return;
}

1;
__END__

=head1 NAME

MouseX::Foreign - Extends non-Mouse classes as well as Mouse classes

=head1 VERSION

This document describes MouseX::Foreign version 1.000.

=head1 SYNOPSIS

    package MyInt;
    use Mouse;
    use MouseX::Foreign qw(Math::BigInt);

    has name => (
        is  => 'ro',
        isa => 'Str',
    );

=head1 DESCRIPTION


MouseX::Foreign provides an ability for Mouse classes to extend any classes,
including non-Mouse classes, including Moose classes.

 
=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 ACKNOWLEDGEMENT

This is a Mouse port of MooseX::NonMoose, although the name is different.

=head1 SEE ALSO

L<Mouse>

L<Moose>

L<MooseX::NonMoose>

L<MooseX::Alien>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
