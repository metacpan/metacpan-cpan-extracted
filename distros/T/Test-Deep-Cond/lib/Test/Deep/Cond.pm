package Test::Deep::Cond;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Test::Deep ();
use Test::Deep::Cmp;
use Exporter::Lite;

our @EXPORT = qw(cond);

sub cond(&) {
    my ($code) = @_;
    __PACKAGE__->new($code);
}

sub init {
    my ($self, $code) = @_;
    $self->{code} = $code;
}

sub descend {
    my ($self, $got) = @_;
    local *_ = \$got;
    $self->{code}->();
}

sub diagnostics {
    my $self = shift;
    my ($where, $last) = @_;

    my $data = Test::Deep::render_val($last->{got});
    my $diag = "$where return $data";
}

1;

1;
__END__

=head1 NAME

Test::Deep::Cond - simple code test in Tesst::Deep

=head1 VERSION

This document describes Test::Deep::Cond version 0.01.

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::Cond;

    cmp_deeply(
        {
            hoge => 3,
        },
        {
            hoge => cond { 2 < $_ and $_ < 4 },
        },
    );

=head1 DESCRIPTION

Test::Deep::Cond is simple way to compare value by code reference.
Test::Deep provides C<code> function. But, Test::Deep::Cond is more simply to test.

    cmp_deeply(
        {
            hoge => 3,
        },
        {
            hoge => code(sub { my $val = shift; 2 < $val and $val < 4 }),
        },
    );

This is same meaning as SYNOPSIS by Test::Deep::Code.

=head1 INTERFACE

=head2 Functions

=head3 C<< cond BLOCK >>

Sets $_ for got value in BLOCK. And if BLOCK return true, this test is passed.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Soh Kitahara E<lt>sugarbabe335@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Soh Kitahara. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
