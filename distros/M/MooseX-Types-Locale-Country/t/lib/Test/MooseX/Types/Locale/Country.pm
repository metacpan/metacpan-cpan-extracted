package Test::MooseX::Types::Locale::Country;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;


# ****************************************************************
# superclass(es)
# ****************************************************************

use base qw(
    Test::MooseX::Types::Locale::Country::Base
);


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use Test::Exception;
use Test::More;


# ****************************************************************
# mock class(es)
# ****************************************************************

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Country qw(
        CountryCode
        Alpha2Country
        Alpha3Country
        NumericCountry
        CountryName
    );

    use namespace::clean -except => 'meta';

    has 'code'
        => ( is => 'rw', isa => CountryCode,    coerce => 1);
    has 'alpha2'
        => ( is => 'rw', isa => Alpha2Country,  coerce => 1);
    has 'alpha3'
        => ( is => 'rw', isa => Alpha3Country,  coerce => 1);
    has 'numeric'
        => ( is => 'rw', isa => NumericCountry);
    has 'name'
        => ( is => 'rw', isa => CountryName,    coerce => 1);

    __PACKAGE__->meta->make_immutable;
}


# ****************************************************************
# test(s)
# ****************************************************************

sub test_use : Tests(1) {
    my $self = shift;

    use_ok 'MooseX::Types::Locale::Country';

    return;
}

sub test_coerce_code : Tests(5) {
    my $self = shift;

    my $mock_instance = $self->mock_instance;

    $self->test_coercion_for
        ('code',    $mock_instance, 'jp',    'JP');
    $self->test_coercion_for
        ('alpha2',  $mock_instance, 'jp',    'JP');
    $self->test_coercion_for
        ('alpha3',  $mock_instance, 'jpn',   'JPN');
    $self->test_coercion_for
        ('numeric', $mock_instance, 392);
    $self->test_coercion_for
        ('name',    $mock_instance, 'JAPAN', 'Japan');

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

Test::MooseX::Types::Locale::Country - Testing subclass for MooseX::Types::Locale::Country

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::MooseX::Types::Locale::Country;

    Test::MooseX::Types::Locale::Country->runtests;

=head1 DESCRIPTION

This module tests
L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country>.

=head1 SEE ALSO

=over 4

=item * L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country>

=item * L<Test::MooseX::Types::Locale::Country::Base|Test::MooseX::Types::Locale::Country::Base>

=item * L<Test::MooseX::Types::Locale::Country::Fast|Test::MooseX::Types::Locale::Country::Fast>

=back

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
