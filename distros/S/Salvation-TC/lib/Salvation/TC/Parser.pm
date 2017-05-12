package Salvation::TC::Parser;

use strict;
use warnings;

use Module::Load ();
use Class::Inspector ();

our $VERSION = 0.12;
our $BACKEND;

{
    my $loaded;

    sub detect {

        $_[ 0 ] -> load_backend();
        return $BACKEND if defined $BACKEND;

        if( eval { require Salvation::TC::Parser::XS; 1 } ) {

            $BACKEND = 'Salvation::TC::Parser::XS';
            $loaded = 1;

        } else {

            $BACKEND = 'Salvation::TC::Parser::PP';
        }

        $_[ 0 ] -> load_backend();
        return $BACKEND;
    }

    sub load_backend {

        return unless defined $BACKEND;

        unless( $loaded ) {

            $loaded = 1;

            Module::Load::load( $BACKEND );
        }

        return;
    }
}

{
    my $code;

    sub tokenize_type_str {

        goto $code if defined $code;

        $_[ 0 ] -> detect();
        my $name = "${BACKEND}::tokenize_type_str_impl";

        no strict 'refs';

        goto $code = *$name{ 'CODE' };
    }
}

{
    my $code;

    sub tokenize_signature_str {

        goto $code if defined $code;

        $_[ 0 ] -> detect();
        my $name = "${BACKEND}::tokenize_signature_str_impl";

        no strict 'refs';

        goto $code = *$name{ 'CODE' };
    }
}

sub parameterizable_type_class_ns {

    return 'Salvation::TC::Meta::Type::Parameterized';
}

{
    my $re = qr/^Salvation::TC::Type::(.+?)$/;

    sub look_for_type_short_name {

        my ( $self, $full_name ) = @_;

        return ( $full_name =~ $re )[ 0 ];
    }
}

sub load_parameterizable_type_class {

    my ( $self, $word ) = @_;

    my $ns = $self -> parameterizable_type_class_ns();
    my $class = "${ns}::${word}";
    my $parameterizable_type = '';

    local $SIG{ '__DIE__' } = 'DEFAULT';

    if(
        Class::Inspector -> loaded( $class )
        || eval{ Module::Load::load( $class ); 1 }
    ) {

        $parameterizable_type = $class;

    } elsif( defined( $word = $self -> look_for_type_short_name( $word ) ) ) {

        $class = "${ns}::${word}";

        if(
            Class::Inspector -> loaded( $class )
            || eval{ Module::Load::load( $class ); 1 }
        ) {

            $parameterizable_type = $class;
        }
    }

    return $parameterizable_type;
}

1;

__END__
