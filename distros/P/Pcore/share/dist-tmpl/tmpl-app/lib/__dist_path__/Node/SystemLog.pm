package <: $module_name ~ "::Node::SystemLog" :>;

use Pcore -class, -const, -sql;
use Pcore::Util::Data qw[to_json];

with qw[<: $module_name ~ "::Node" :>];

has store_interval => 0;    # PositiveOrZeroInt

has _store_timer => ( init_arg => undef );
has _buffer      => ( init_arg => undef );

const our $NODE_REQUIRES => { '*' => 'log.#', };

sub NODE_ON_EVENT ( $self, $ev ) {
    $self->_process_ev($ev) if $ev->{key} =~ /\Alog[.]/sm;

    return;
}

sub BUILD ( $self, $args ) {
    $self->{node}->wait_online if $self->{node};

    $self->on_settings_update( $self->{settings} );

    $self->{dbh} = P->handle( $self->{env}->{db} );

    $self->{dbh}->add_schema_patch(
        1, 'log',
        {   pgsql => <<'SQL',
                CREATE TABLE "system_log" (
                    "id" SERIAL8 PRIMARY KEY NOT NULL,
                    "created" FLOAT NOT NULL DEFAULT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP),
                    "channel" TEXT,
                    "level" TEXT,
                    "title" TEXT,
                    "data" TEXT
                );
SQL
            sqlite => <<'SQL',
                CREATE TABLE "system_log" (
                    "id" INT8 PRIMARY KEY AUTOINCREMENT NOT NULL,
                    "created" FLOAT NOT NULL DEFAULT(time_hires()),
                    "channel" TEXT,
                    "level" TEXT,
                    "title" TEXT,
                    "data" TEXT
                );
SQL
        }
    );

    $self->{dbh}->upgrade_schema;

    # init store timer
    if ( $self->{store_interval} ) {
        $self->{_store_timer} = AE::timer 0, $self->{store_interval}, sub {
            if ( $self->{_buffer} ) {
                Coro::async {
                    $self->_store( delete $self->{_buffer} );

                    return;
                };
            }

            return;
        }
    }

    # create event listener
    P->on(
        ['log.#'],
        sub ( $ev ) {
            $self->_process_ev($ev);

            return;
        }
    );

    return;
}

sub _process_ev ( $self, $ev ) {
    my $row = [    #
        $ev->@{qw[timestamp channel level title]},
        ref $ev->{data} ? to_json $ev->{data}, readable => 1 : $ev->{data},
    ];

    # push log record to the store buffer
    if ( $self->{_store_timer} ) {
        push $self->{_buffer}->@*, $row;
    }

    # store log record immediately
    else {
        $self->_store( [$row] );
    }

    return;
}

sub _store ( $self, $buf ) {
    $self->{dbh}->do( [ 'INSERT INTO "system_log" ("created", "channel", "level", "title", "data")', VALUES $buf ] );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 110                  | Documentation::RequirePackageMatchesPodName - Pod NAME on line 114 does not match the package declaration      |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

<: $module_name ~ "::Node::SystemLog" :>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
