package Mojo::Log::Colored;
use Mojo::Base 'Mojo::Log';
use Term::ANSIColor 'colored';

use if $^O eq "MSWin32", "Win32::Console::ANSI";

our $VERSION = "0.02";

has 'colors' => sub {
    return {
        debug => "bold bright_white",
        info  => "bold bright_blue",
        warn  => "bold green",
        error => "bold yellow",
        fatal => "bold yellow on_red",
    };
};

has _format => sub {
    shift->format( \&_default_format );
};

sub format {
    return $_[0]->_format if @_ == 1;

    my ( $self, $format ) = @_;

    return $self->_format(
        sub {
            # only add colors if we have a color for this level
            exists $self->colors->{ $_[1] }
                ? colored( $format->(@_), $self->colors->{ $_[1] } )
                : $format->(@_);
        }
    )->_format;
}

sub _default_format {
    '[' . localtime(shift) . '] [' . shift() . '] ' . join "\n", @_, '';
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Log::Colored - Colored Mojo logging

=begin html

<p>
<a href="https://travis-ci.org/simbabque/Mojo-Log-Colored"><img src="https://travis-ci.org/simbabque/Mojo-Log-Colored.svg?branch=master"></a>
<a href='https://coveralls.io/github/simbabque/Mojo-Log-Colored?branch=master'><img src='https://coveralls.io/repos/github/simbabque/Mojo-Log-Colored/badge.svg?branch=master' alt='Coverage Status' /></a>
</p>

=end html

=head1 SYNOPSIS

    use Mojo::Log::Colored;

    # Log to STDERR
    $app->log(
        Mojo::Log::Colored->new(
            
            # optionally set the colors
            colors => {
                debug => "bold bright_white",
                info  => "bold bright_blue",
                warn  => "bold green",
                error => "bold yellow",
                fatal => "bold yellow on_red",
            }
        )
    );   
    
=head1 DESCRIPTION

Mojo::Log::Colored is a logger for Mojolicious with colored output for the terminal. It lets you define colors
for each log level based on L<Term::ANSIColor> and comes with sensible default colors. The full lines in the log
will be colored.

Since this inherits from L<Mojo::Log> you can still give it a C<file>, but the output would also be colored.
That does not make a lot of sense, so you don't want to do that. Use this for development, not production.

=head1 ATTRIBUTES

L<Mojo::Log::Colored> implements the following attributes.

=head2 colors

    my $colors = $log->colors;
    $log->colors(
        {
            debug => "bold bright_white",
            info  => "bold bright_blue",
            warn  => "bold green",
            error => "bold yellow",
            fatal => "bold yellow on_red",
        }
    );

Takes a hash reference with the five log levels as keys and strings of colors as values. Refer to
L<Term::ANSIColor> for more information about what kind of color you can use.

You can turn off coloring for specific levels by omitting them from the config hash.

    $log->colors(
        {
            fatal => "bold green on_red",
        }
    );

The above will only color fatal messages. All other levels will be in your default terminal color.

=head2 format

    my $cb = $log->format;
    $log   = $log->format( sub { ... } );

A callback for formatting log messages. Cannot be passed to C<new> at construction! See L<Mojo::Log> for more information.

=head1 METHODS

L<Mojo::Log::Colored> inherits all methods from L<Mojo::Log> and does not implement new ones.

=head1 SEE ALSO

L<Mojo::Log>, L<Term::ANSIColor>

=head1 ACKNOWLEDGEMENTS

This plugin was inspired by lanti asking about a way to easier find specific errors
in the Mojo log during unit test runs on L<Stack Overflow|https://stackoverflow.com/q/44965998/1331451>.

=head1 LICENSE

Copyright (C) simbabque.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

simbabque E<lt>simbabque@cpan.orgE<gt>

=cut

