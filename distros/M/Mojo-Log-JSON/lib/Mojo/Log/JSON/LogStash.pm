package Mojo::Log::JSON::LogStash;

use Mojo::Base 'Mojo::Log::JSON';

use Time::HiRes qw/ gettimeofday /;

our $VERSION = '0.04';

has default_fields => sub {
    {   '@version'   => 1,
        '@timestamp' => sub {

            my ( $seconds, $microseconds ) = gettimeofday();

            my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime($seconds);

            sprintf(
                "%04d-%02d-%02dT%02d:%02d:%02d.%06dZ",
                $year + 1900,
                $mon + 1, $mday, $hour, $min, $sec, $microseconds
            );
        },
    };
};

1;

__END__

=encoding utf-8

=head1 NAME

Mojo::Log::JSON::LogStash - Simple JSON logger to produce LogStash format logs

=head1 SYNOPSIS

    package MyApp;

    use Mojo::Log::JSON::LogStash;

    sub startup {
        my $self = shift;

        ...

        open my $handle, '|-',
            'logstash-forwarder -config=/path/to/logstash-forwarder-config.conf'
            or die "can't run logstash-forwarder: $!";

        my $logger = Mojo::Log::JSON::LogStash->new( handle => $handle );

        $logger->default_fields->{foo} = "bar";    # add extra default field

        ...
    }

    # Log messages - debug, info, warn, error, fatal (same as Mojo::Log)

    $log->debug( "A simple string" );
    $log->debug( "A", "message", "over", "multiple", "lines" );
    $log->debug( { message => "A data structure", foo => "bar" } );

    # The above examples would generate something like the following:
    {"@timestamp":"2014-03-13T13:15:44.005134Z","@version":1,"level":"debug","message":"A simple string"}
    {"@timestamp":"2014-03-13T13:15:45.123565Z","@version":1,"level":"debug","message":"A\nmessage\nover\nmultiple\nlines"}
    {"@timestamp":"2014-03-13T13:15:46.863454Z","@version":1,"foo":"bar","level":"debug","message":"A data structure"}

=head1 DESCRIPTION

L<Mojo::Log::JSON::LogStash> is a simple subclass of L<Mojo::Log::JSON> to
produce JSON logs suitable for LogStash.

The key C<level> is always added to the data structure, with the value set to
the level of the log message being emitted.

The required LogStash keys C<@timestamp> and C<@version> are also added to the
data structure. C<@timestamp> is set with a value of the current time in UTC in
ISO 8601 format, with microseconds.

These can be overridden or other fields added via the C<default_fields>
attributes.

=head1 ATTRIBUTES

See L<Mojo::Log::JSON>.

=head1 METHODS

See L<Mojo::Log::JSON>.

=head1 SEE ALSO

=over

=item L<Mojo::Log>

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/mojo-log-json/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/mojo-log-json>

    git clone git://github.com/mjemmeson/mojo-log-json.git

=head1 AUTHOR

Michael Jemmeson E<lt>mjemmeson@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

