package Test01::CommandB;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

use Moose::Util::TypeConstraints;

has 'param_a' => (
    isa         => 'Str',
    is          => 'rw',
);

option 'param_b' => (
    isa         => enum([qw(aaa bbb ccc ddd eee fff)]),
    is          => 'rw',
    required    => 1,
);

sub run {
    print "RUN COMMAND-B";
}

=encoding utf8

=head1 NAME

Test01::CommandB - Test class command B for test 01

=head1 SYNOPSIS

use with care

=head1 DESCRIPTION

Some description of B<command B>

 some code
 some code

=head2 SUB HEADLINE

some more desc

=over

=item * item 1

=item * item 2

=over

=item * item 2.1

=item * item 2.2

=back

=back

hase ist so super and this is a very long sentence witch breaks after i have
written some bla bla.

another interesting paragraph.

=head1 METHODS

hase

=head2 SUB A

bär

=head1 SUB B

some methods

=cut

1;