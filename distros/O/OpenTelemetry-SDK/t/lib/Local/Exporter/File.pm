use Object::Pad;

class Local::Exporter::File :does(OpenTelemetry::Exporter) {
    use File::Temp 'tempfile';
    use Future::AsyncAwait;
    use JSON::PP;

    use feature 'say';

    field $path;
    field $done;

    ADJUST { ( undef, $path ) = tempfile }

    method $log {
        open my $handle, '>>', $path or die $!;
        say $handle encode_json [ @_ ];
        return 0;
    }

    method calls {
        open my $handle, '<', $path or die $!;

        my @calls;
        while ( my $line = <$handle> ) {
            push @calls, decode_json $line;
        }

        \@calls;
    }

    method reset {
        open my $handle, '>', $path or die $!;
        print $handle '';
    }

    method export { $self->$log( export => @_ ) }

    async method force_flush {
        return 0 if $done;
        $self->$log( force_flush => @_ );
    }

    async method shutdown {
        return 0 if $done;
        $done = 1;
        $self->$log( shutdown => @_ );
    }
}
