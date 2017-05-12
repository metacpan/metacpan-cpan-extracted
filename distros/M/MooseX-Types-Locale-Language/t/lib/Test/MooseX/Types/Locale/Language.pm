package Test::MooseX::Types::Locale::Language;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use Test::Exception;
use Test::More;


# ****************************************************************
# superclass(es)
# ****************************************************************

use base qw(
    Test::MooseX::Types::Locale::Language::Base
);


# ****************************************************************
# mock class(es)
# ****************************************************************

{
    package Foo;

    use Moose;
    use MooseX::Types::Locale::Language qw(
        LanguageCode
        Alpha2Language
        BibliographicLanguage
        Alpha3Language
        TerminologicLanguage
        LanguageName
    );

    use namespace::clean -except => 'meta';

    has 'code'
        => ( is => 'rw', isa => LanguageCode,          coerce => 1);
    has 'alpha2'
        => ( is => 'rw', isa => Alpha2Language,        coerce => 1);
    has 'alpha3'
        => ( is => 'rw', isa => Alpha3Language,        coerce => 1);
    has 'bibliographic'
        => ( is => 'rw', isa => BibliographicLanguage, coerce => 1);
    has 'terminologic'
        => ( is => 'rw', isa => TerminologicLanguage,  coerce => 1);
    has 'name'
        => ( is => 'rw', isa => LanguageName,          coerce => 1);

    __PACKAGE__->meta->make_immutable;
}


# ****************************************************************
# test(s)
# ****************************************************************

sub test_use : Tests(1) {
    my $self = shift;

    use_ok 'MooseX::Types::Locale::Language';

    return;
}

sub test_coerce_code : Tests(6) {
    my $self = shift;

    my $mock_instance = $self->mock_instance;

    $self->test_coercion_for
        ('code',          $mock_instance, 'JA',       'ja');
    $self->test_coercion_for
        ('alpha2',        $mock_instance, 'JA',       'ja');
    $self->test_coercion_for
        ('alpha3',        $mock_instance, 'JPN',      'jpn');
    $self->test_coercion_for
        ('bibliographic', $mock_instance, 'CHI',      'chi');   # Chinese
    $self->test_coercion_for
        ('terminologic',  $mock_instance, 'ZHO',      'zho');   # Zhongwen
    $self->test_coercion_for
        ('name',          $mock_instance, 'JAPANESE', 'Japanese');

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

Test::MooseX::Types::Locale::Language - Testing subclass for MooseX::Types::Locale::Language

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::MooseX::Types::Locale::Language;

    Test::MooseX::Types::Locale::Language->runtests;

=head1 DESCRIPTION

This module tests
L<MooseX::Types::Locale::Language|MooseX::Types::Locale::Language>.

=head1 SEE ALSO

=over 4

=item * L<MooseX::Types::Locale::Language|MooseX::Types::Locale::Language>

=item * L<Test::MooseX::Types::Locale::Language::Base|Test::MooseX::Types::Locale::Language::Base>

=item * L<Test::MooseX::Types::Locale::Language::Fast|Test::MooseX::Types::Locale::Language::Fast>

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
