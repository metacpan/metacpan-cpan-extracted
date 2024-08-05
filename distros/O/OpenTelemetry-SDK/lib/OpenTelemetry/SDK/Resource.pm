use Object::Pad ':experimental(init_expr)';
# ABSTRACT: Represents the entity producing OpenTelemetry data
package OpenTelemetry::SDK::Resource;

our $VERSION = '0.024';

class OpenTelemetry::SDK::Resource :does(OpenTelemetry::Attributes) {
    use experimental 'isa';

    use OpenTelemetry;
    use OpenTelemetry::Common 'config';
    use File::Basename 'basename';

    require OpenTelemetry::SDK; # For VERSION

    field $schema_url :param :reader //= '';

    sub empty { shift->new( empty => 1, @_ ) }

    sub BUILDARGS ( $class, %args ) {
        return %args if delete $args{empty};

        my %env = map split( '=', $_, 2 ),
            split ',', config('RESOURCE_ATTRIBUTES') // '';

        for ( keys %env ) {
            if (
                # baggage-octet, as per https://w3c.github.io/baggage/#definition
                #                  !      #  ..  +      -  ..  :      <  ..  [      ]  ..  ~
                $env{$_} =~ /([^ \x{21} \x{23}-\x{2B} \x{2D}-\x{3A} \x{3C}-\x{5B} \x{5D}-\x{7E} ])/xx
            ) {
                OpenTelemetry->logger->warn(
                    'Ignoring invalid resource attribute value in environment: must be percent-encoded',
                    { key => $_ },
                );

                delete $env{$_};
            }
        }

        # Special-cased because of precedence rules
        my $service_name = delete $env{'service.name'};
        $service_name = config('SERVICE_NAME') // $service_name;

        $args{attributes} = {
            'telemetry.sdk.name'      => 'opentelemetry',
            'telemetry.sdk.language'  => 'perl',
            'telemetry.sdk.version'   => $OpenTelemetry::SDK::VERSION,
            'process.pid'             => $$,
            'process.command'         => $0,
            'process.executable.path' => $^X,
            'process.command_args'    => [ @ARGV ],
            'process.executable.name' => basename($^X),
            'process.runtime.name'    => 'perl',
            'process.runtime.version' => "$^V",

            %env,

            %{ $args{attributes} // {} },
        };

        $args{attributes}{'service.name'} //= $service_name if $service_name;

        %args;
    }

    method merge ( $new ) {
        return $self unless $new isa OpenTelemetry::SDK::Resource;

        my $ours   = $self->schema_url;
        my $theirs = $new->schema_url;

        if ( $ours && $theirs && $ours ne $theirs ) {
            OpenTelemetry->logger->warn(
                'Incompatible resource schema URLs when merging resources. Ignoring new one',
                { old => $ours, new => $theirs },
            );
            $theirs = '';
        }

        ( ref $self )->new(
            attributes => { %{ $self->attributes }, %{ $new->attributes } },
            schema_url => $theirs || $ours,
        );
    }
}
