use strict;
use warnings;
use Test::More;
use Mojo::Log::Colored;
use Capture::Tiny 'capture_stderr';
use Term::ANSIColor 'colorstrip';

my $log = Mojo::Log::Colored->new;

my %defaults = (
    debug => "\e[1;97m",
    info  => "\e[1;94m",
    warn  => "\e[1;32m",
    error => "\e[1;33m",
    fatal => "\e[1;33;41m",
);

for my $level ( sort keys %defaults ) {
    my $stderr = capture_stderr { $log->$level("$level") };

    like $stderr, qr{
        ^
        \Q$defaults{$level}\E   # color of this level, escaped
    }x, "$level starts with color";

    like $stderr, qr{
        \e\[0m                  # end of coloring
        $        
    }x, "$level ends with end of color";

    my $plain = colorstrip($stderr);
    chomp $plain;    # all levels have one newline
    chomp $plain;    # fatal has one more

    like $plain, qr{
        \[[^]]+\]               # the date
        \s
        \[$level\]              # the level
        \s
        $level                  # the message
    }x, "... and the format is correct";
}

for my $level ( sort keys %defaults ) {
    $log->format( sub {$level} );
    $log->colors( { $level => "magenta" } );

    my $stderr = capture_stderr { $log->$level($level) };    # this is the call to log

    like $stderr, qr{
        ^
        \e\[35m                 # magenta
    }x, "$level with custom format starts with custom color";

    like $stderr, qr{
        \e\[0m                  # end of coloring
        $        
    }x, "$level with custom format ends with end of color";

    my $plain = colorstrip($stderr);
    chomp $plain;    # all levels have one newline
    chomp $plain;    # fatal has one more

    is $plain, $level, "... and the custom format is correct";
}

{
    $log->colors(
        {
            debug => "bold bright_white",
            warn  => "bold green",
            fatal => "bold yellow on_red",
        }
    );
    $log->format( sub { $_[1] } );
    my $stderr = capture_stderr { $log->$_($_) for qw/debug info warn error fatal/ };

    #<<< do not tidy
    is(
        $stderr,
        (
                  ( "\e[1;97m" . "debug" . "\e\[0m" )
                . "info"
                . ( "\e[1;32m" . "warn" . "\e\[0m" )
                . "error"
                . ( "\e[1;33;41m" . "fatal" . "\e\[0m" )
        ),
        "levels without color are not colored"
    );
    #>>>
}

done_testing;
