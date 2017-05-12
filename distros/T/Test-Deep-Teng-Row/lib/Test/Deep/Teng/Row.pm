package Test::Deep::Teng::Row;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Test::Deep ();
use Test::Deep::Cmp;
use Exporter::Lite;

our @EXPORT = qw(teng_row);

sub teng_row {
    my ($expected) = @_;
    __PACKAGE__->new($expected);
}

sub init {
    my ($self, $val) = @_;
    $self->{val} = $val;
}

sub descend {
    my ($self, $got) = @_;

    unless ( $got->isa('Teng::Row') ) {
        $self->{error} = 'got row is not teng row object';
        return 0;
    }

    unless ( $self->{val}->isa('Teng::Row') ) {
        $self->{error} = 'expected row is not teng row object';
        return 0;
    }

    Test::Deep::wrap($self->{val}->get_columns)->descend($got->get_columns);
}

sub diagnostics {
    my $self = shift;
    return $self->{error};
}

1;
__END__

=head1 NAME

Test::Deep::Teng::Row - Compare Teng::Row object by get_columns method in using Test::Deep

=head1 VERSION

This document describes Test::Deep::Teng::Row version 0.01.

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::Teng::Row;

    cmp_deeply \@got_rows, +[ map { teng_row($_) } @expected_rows ];

=head1 DESCRIPTION

Test::Deep::Teng::Row support to compare Teng::Row object in using Test::Deep.

It is faild to compare got Teng::Row object to expected that is fetched by diffrent sql to got by is_deeply
function. Because Teng::Row object has sql attribute that is used to fetch itself. So this
module provide teng_row function for C<Test::Deep>, and it compare by C<Teng::Row::get_columns> method both
got and expected.

=head1 INTERFACE

=head2 Functions

=head3 C<< teng_row($expected) >>

$expected is Teng::Row object.

This function is exported by this module. It compares C<$got> to C<$expected> by C<Teng::Row::get_columns> method.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Test::Deep>

=head1 AUTHOR

Soh Kitahara E<lt>sugarbabe335@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Soh Kitahara. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
