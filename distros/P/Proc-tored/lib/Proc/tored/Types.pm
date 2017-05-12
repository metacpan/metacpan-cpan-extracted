package Proc::tored::Types;
# ABSTRACT: Type constraints used by Proc::tored
$Proc::tored::Types::VERSION = '0.17';
use strict;
use warnings;
use Types::Standard -types;
use Type::Utils -all;
use Type::Library -base,
  -declare => qw(
    NonEmptyStr
    Dir
    SignalList
  );


declare NonEmptyStr, as Str, where { $_ =~ /\S/sm };
declare Dir, as NonEmptyStr, where { -d $_ && -w $_ };
declare SignalList, as ArrayRef[Str], where { @$_ == 0 || $^O ne 'MSWin32' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::Types - Type constraints used by Proc::tored

=head1 VERSION

version 0.17

=head1 TYPES

=head2 NonEmptyStr

A C<Str> that contains at least one non-whitespace character.

=head2 Dir

A L</NonEmptyStr> that is a valid, writable directory path.

=head2 SignalList

An array ref of strings suitable for use in C<%SIG>, except on MSWin32 systems.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
