package Proc::tored::Pool::Types;
# ABSTRACT: Type constraints used by Proc::tored::Pool
$Proc::tored::Pool::Types::VERSION = '0.07';
use strict;
use warnings;
use Proc::tored::Pool::Constants ':events';
use Types::Standard -types;
use Type::Utils -all;
use Type::Library -base,
  -declare => qw(
    NonEmptyStr
    Dir
    Task
    PosInt
    Event
  );


declare NonEmptyStr, as Str, where { $_ =~ /\S/ };
declare Dir, as NonEmptyStr, where { -d $_ };
declare PosInt, as Int, where { $_ > 0 };
declare Event, as Enum[assignment, success, failure];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::Pool::Types - Type constraints used by Proc::tored::Pool

=head1 VERSION

version 0.07

=head1 TYPES

=head2 NonEmptyStr

A C<Str> that contains at least one non-whitespace character.

=head2 Dir

A L</NonEmptyStr> that is a valid directory path.

=head2 PosInt

An C<Int> with a positive value.

=head2 Event

One of L<Proc::tored::Pool::Constants/assignment>,
L<Proc::tored::Pool::Constants/success>, or
L<Proc::tored::Pool::Constants/failure>.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
