  package Package::Subroutine::Sugar
# **********************************
; use strict; use warnings
# ************************
; our $VERSION='0.02'
# *******************

; sub import
    { eval <<'__PERL__'
; package from
# ************
; our $VERSION='0.08'
; no warnings 'redefine'
; use Package::Subroutine 'Package::Subroutine'
    => qw/import export findsubs mixin version/
__PERL__
    }

; sub unimport
    { delete $::{'from::'}
    }

; 1

__END__

=head1 NAME

Package::Subroutine::Sugar

=head1 SYNOPSIS

    use Package::Subroutine::Sugar;

    package Ican::not::program;

    import from 'Animal::Words' => qw/moo mae meow/

=head2 DESCRIPTION

This module creates the namespace C<from>. The following and methods are
imported from L<Package::Subroutine>:

=over 4

=item import

=item export

=item findsubs

=item mixin

=item version

=back

As the name suggests it provides some (syntactic) sugar.

Please have fun with it but please think twice before using it seriously.


=head1 AUTHOR

Sebastian Knapp, <rock@ccls-online.de>

=head1 BUGS

=head2 unimport

   ; no from # this deletes from package

Unfortunatly I'm not sure if this is the right way to do it (how could this be done better?).

Please report more bugs or feature requests to
C<bug-package-subroutine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyleft 2007-2008 Sebastian Knapp

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
