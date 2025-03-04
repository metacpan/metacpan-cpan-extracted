use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A context class for OpenTelemetry

package
    OpenTelemetry::Context::Key;

our $VERSION = '0.027';

class OpenTelemetry::Context::Key {
    use UUID::URandom 'create_uuid';

    field $name   :param;
    field $string :reader;

    ADJUST { $string = $name . '-' . unpack( 'H*', create_uuid ) };
}

package OpenTelemetry::Context;

our $VERSION = '0.027';

sub key ( $, $name ) {
    OpenTelemetry::Context::Key->new( name => $name );
}

class OpenTelemetry::Context {
    use OpenTelemetry::X;

    use isa 'OpenTelemetry::Context::Key';

    field $data :param = {};

    sub BUILDARGS ( $class, %args ) { ( data => { %args } ) }

    method get ( $key ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless isa_OpenTelemetry_Context_Key $key;

        $data->{ $key->string };
    }

    method set ( $key, $value ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless isa_OpenTelemetry_Context_Key $key;

        OpenTelemetry::Context->new( %$data, $key->string, $value )
    }

    method delete ( $key ) {
        die OpenTelemetry::X->create(
            Invalid => 'Keys in a context object must be instances of OpenTelemetry::Context::Key',
        ) unless isa_OpenTelemetry_Context_Key $key;

        my %copy = %$data;
        delete $copy{$key->string};

        OpenTelemetry::Context->new(%copy);
    }
}

# Context management
{
    use Sentinel;

    use isa 'OpenTelemetry::Context';

    my $current = OpenTelemetry::Context->new;
    sub current :lvalue {
        sentinel(
            get => sub { $current },
            set => sub {
                die OpenTelemetry::X->create(
                    Invalid => 'Current context must be an instance of OpenTelemetry::Context, received instead ' . ref $_[0],
                ) unless isa_OpenTelemetry_Context $_[0];

                $current = $_[0];
            },
        );
    }
}

1;
