package Mojolicious::Plugin::ChromeLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Mojo::JSON qw/encode_json/;

our $VERSION = 0.06;

has logs => sub { return [] };

my %types_map = (
    'debug' => '',
    'info'  => 'info',
    'warn'  => 'warn',
    'error' => 'error',
    'fatal' => 'error',
);

sub register {
    my ( $self, $app, $opts ) = @_;

    $opts->{show_session} //= 1;
    $opts->{show_stash}   //= 1;
    $opts->{show_config}  //= 0;

    # We do use monkey patch instead of inheriting Mojo::Log to be compatible with Log::Any::Adapter::Mojo
    $self->_monkey_patch_logger();

    $app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            my $logs = $self->logs;

            # Leave static content untouched
            return if $c->stash('mojo.static');

            # Do not allow if not development mode
            return if $c->app->mode ne 'development';

            my $data = {
                version => $VERSION,
                columns => [ 'log', 'backtrace', 'type' ],
                rows    => []
            };

            my $rows = $data->{rows};

            # Start main group
            my $main_group = 'Mojolicious: ' . $c->req->method . ' ' . $c->req->url->path->to_string;
            push @$rows, [[ $main_group ], undef,  'groupCollapsed'];

            # Add session
            if ( $opts->{show_session} ) {
                push @$rows, [[ { '___class_name' => 'Session', %{$c->session} }], undef,  ''];
            }

            # Add config
            if ( $opts->{show_config} ) {
                push @$rows, [[ { '___class_name' => 'Config', %{$c->config} }], undef,  ''];
            }

            # Add stash
            if ( $opts->{show_stash} ) {
                my %clean_stash = map { $_ => $c->stash($_) } grep { $_ !~ /^(?:mojo\.|config$)/ } keys %{ $c->stash };
                push @$rows, [[ { '___class_name' => 'Stash', %clean_stash }], undef,  ''];
            }

            # Logs: fatal, info, debug, error
            push @$rows, [[ 'logs' ], undef,  'group'];

            foreach my $msg (@$logs) {
                push @$rows, [ $msg->[1], $msg->[2], $types_map{ $msg->[0] } ];
            }

            push @$rows, [[ 'logs' ], undef,  'groupEnd'];

            # End main group
            push @$rows, [[ $main_group ], undef,  'groupEnd'];

            my $json       = encode_json($data);
            my $final_data = b($json)->b64_encode('');
            $c->res->headers->add( 'X-ChromeLogger-Data' => $final_data );

            $self->logs( [] );
        }
    );
}

sub _monkey_patch_logger {
    my ($self) = @_;

    no strict 'refs';
    my $stash = \%{"Mojo::Log::"};

    foreach my $level (qw/debug info warn error fatal/) {
        my $orig  = delete $stash->{$level};

        *{"Mojo::Log::$level"} = sub {
            my ($package, $filename, $line) = caller;
            push @{ $self->logs }, [ $level, [ $_[-1] ], "at $filename:$line" ];
            $orig->(@_);
        };
    }
}

1;

=head1 NAME

Mojolicious::Plugin::ChromeLogger - Pushes Mojolicious logs, stash, session, config to Google Chrome console

=head1 DESCRIPTION

L<Mojolicious::Plugin::ChromeLogger> pushes Mojolicious log messages, stash, session and config to Google Chrome console. Works with all types of responses(including JSON).
To view logs in Google Chrome you should install ChromeLogger extenstion. Logging works only in development mode.

See details here http://craig.is/writing/chrome-logger

=head1 USAGE

    use Mojolicious::Lite;

    plugin 'ChromeLogger';
    #  or with options - plugin 'ChromeLogger' => {show_config => 1};

    get '/' => sub {
        my $self = shift;

        app->log->debug('Some debug here');
        app->log->info('Some info here');
        app->log->warn('Some warn here');
        app->log->error('Some error here');
        app->log->fatal('Some fatal here');

        $self->render( text => 'Open Google Chrome console' );
    };

    app->start;

=head1 CONFIG

=head2 C<show_config>

push config to ChromeLogger (default 0)

By default we do not show config. It is usually static and can contain confidential data.

=head2 C<show_stash>

push stash to ChromeLogger (default 1)

=head2 C<show_session>

push session to ChromeLogger (default 1)

=head1 SEE ALSO

L<Mojolicious::Plugin::ConsoleLogger>

=head1 DEVELOPMENT

L<https://github.com/koorchik/Mojolicious-Plugin-ChromeLogger>

=head1 CREDITS

Inspired by L<Mojolicious::Plugin::ConsoleLogger>

=head1 AUTHORS

Viktor Turskyi koorchik@cpan.org

=cut
