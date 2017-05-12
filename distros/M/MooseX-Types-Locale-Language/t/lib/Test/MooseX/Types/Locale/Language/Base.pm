package Test::MooseX::Types::Locale::Language::Base;


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
use Test::Warn;


# ****************************************************************
# superclass(es)
# ****************************************************************

use base qw(
    Test::Class
);


# ****************************************************************
# test(s)
# ****************************************************************

sub test_new : Tests(19) {
    my $self = shift;

    my $mock_class = $self->mock_class;

    $self->test_constraint($mock_class);
    $self->test_exceptions_of_constraints($mock_class);

    return;
}


# ****************************************************************
# test snippet(s)
# ****************************************************************

sub test_constraint {
    my ($self, $mock_class) = @_;

    ok $mock_class->new(
        code            => 'ja',
        alpha2          => 'ja',
        alpha3          => 'jpn',
        bibliographic   => 'chi',   # Chinese
        terminologic    => 'zho',   # Zhongwen
        name            => 'Japanese',
    ) => 'Instantiated object using export types';

    return;
}

sub test_exceptions_of_constraints {
    my ($self, $mock_class) = @_;

    my %alignment = (
        code            => qr{language code .+ ISO 639-1},
        alpha2          => qr{language code .+ ISO 639-1},
        alpha3          => qr{language code .+ ISO 639-2},
        bibliographic   => qr{language code .+ ISO 639-2},
        terminologic    => qr{language code .+ ISO 639-2},
        name            => qr{language name .+ ISO 639},
    );

    while (my ($attribute, $message_pattern) = each %alignment) {
        throws_ok {
            $mock_class->new( $attribute => 'junk!!' )
        } $message_pattern,
            => "Constraint of ($attribute)";
        warning_is {
            dies_ok {
                $mock_class->new( $attribute => undef );
            } 'expecting to die';
        } undef,
            'no warnings to assign undef';
    }

    return;
}


# ****************************************************************
# other method(s)
# ****************************************************************

sub mock_class {
    return 'Foo';
}

sub mock_instance {
    my $self = shift;

    my $mock_class = $self->mock_class;

    return $mock_class->new(@_);
}

sub test_coercion_for {
    my ($self, $attribute, $mock_instance, $from, $to) = @_;

    $mock_instance->$attribute($from);

    if (defined $to) {
        is $mock_instance->$attribute, $to
            => "Coercion of ($attribute)";
    }
    else {
        is $mock_instance->$attribute, $from
            => "Coercion of ($attribute) does not work";
    }

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

Test::MooseX::Types::Locale::Language::Base - Testing baseclass for MooseX::Types::Locale::Language::*

=head1 SYNOPSIS

    package Test::MooseX::Types::Locale::Language;

    use base qw(
        Test::MooseX::Types::Locale::Language::Base
    );

    # ...

=head1 DESCRIPTION

This module tests
L<MooseX::Types::Locale::Language|MooseX::Types::Locale::Language> and
L<MooseX::Types::Locale::Language::Fast|MooseX::Types::Locale::Language::Fast>.

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
