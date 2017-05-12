#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package MyApp::Language;

    use Moose;
    use MooseX::Aliases;
    use MooseX::Types::Locale::Language qw(
        Alpha2Language
        LanguageName
    );

    use Data::Util qw(:check);
    use Locale::Language;

    use namespace::clean -except => 'meta';

    has 'alpha2' => (
        traits      => [qw(
            Aliased
        )],
        is          => 'rw',
        isa         => Alpha2Language,
        init_arg    => '_alpha2',
        alias       => 'code',
        coerce      => 1,
        lazy_build  => 1,
        writer      => '_set_alpha2',
        trigger     => sub {
            $_[0]->clear_name;
        },
    );

    has 'name' => (
        is          => 'rw',
        isa         => LanguageName,
        init_arg    => '_name',
        coerce      => 1,
        lazy_build  => 1,
        writer      => '_set_name',
        trigger     => sub {
            $_[0]->clear_alpha2;
        },
    );

    sub BUILDARGS {
        my $class = shift;

        if (@_ == 1 && ! ref $_[0]) {
            my $length = length $_[0];
            return {
                (     $length == 2 ? '_alpha2'
                    :                '_name'   ) => $_[0]
            };
        }
        else {
            return $class->SUPER::BUILDARGS(@_);
        }
    }

    sub _build_alpha2 {
        language2code( $_[0]->name );
    }

    sub _build_name {
        code2language( $_[0]->alpha2 );
    }

    sub set {
        my ($self, $argument) = @_;

        confess ('Cannot set country because: argument is not defined')
            unless defined $argument;
        confess ('Cannot set country because: argument is not string')
            unless is_string($argument);

        my $length = length $argument;
          $length == 2 ? $self->_set_alpha2($argument)
        :                $self->_set_name($argument);

        return $self;
    }

    alias has_code    => 'has_alpha2';
    alias clear_code  => 'clear_alpha2';
    alias _build_code => '_build_alpha2';
    alias _set_code   => '_set_alpha2';

    __PACKAGE__->meta->make_immutable;
}

my $language = MyApp::Language->new('japanese');    # (lower case)
say $language->code;                    # 'ja'
say $language->alpha2;                  # 'ja'
say $language->name;                    # 'Japanese' (canonical case)

$language->set('DE');                   # (upper case)
say $language->code;                    # 'de' (canonical case)
say $language->name;                    # 'German'

$language->set('French');
say $language->code;                    # 'fr'

eval {
    $language->set('Spoken in the Tower of Babel');
};
if ($@) {
    say 'Specified language name does not exist';   # Regrettably, true
}
