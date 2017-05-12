package Test::MooseX::Types::Locale::Country::Base::Getopt;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use Test::More;


# ****************************************************************
# superclass(es)
# ****************************************************************

use base qw(
    Test::Class
);


# ****************************************************************
# test(s)
# ****************************************************************

sub test_new : Tests(3) {
    my $self = shift;

    my $class = 'Foo';
    my $object = $class->new(
        numeric => 392,
        name    => 'Japan',
    );
    $self->_check_object($object, $class);

    return;
}

sub test_new_with_options : Tests(3) {
    my $self = shift;

    @ARGV = qw(
        --numeric   392
        --name      Japan
    );
    my $class = 'Foo';
    my $object = $class->new_with_options;

    $self->_check_object($object, $class);
}


# ****************************************************************
# other method(s)
# ****************************************************************

sub _check_object {
    my ($self, $object, $class) = @_;

    isa_ok $object, $class;

    cmp_ok $object->numeric, '==', 392;
    cmp_ok $object->name,    'eq', 'Japan';

    return;
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=pod

=head1 NAME

Test::MooseX::Types::Locale::Country::Getopt - Testing baseclass for MooseX::Types::Locale::Country::*

=head1 SYNOPSIS

    package Test::MooseX::Types::Locale::Country::Getopt;

    use base qw(
        Test::MooseX::Types::Locale::Country::Base::Getopt
    );

    # ...

=head1 DESCRIPTION

This module tests
L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country> and
L<MooseX::Types::Locale::Country::Fast|MooseX::Types::Locale::Country::Fast>.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2010 MORIYA Masaki, alias Gardejo

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
