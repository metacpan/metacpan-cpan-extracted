package MojoX::Log::Dispatch::Simple;
# ABSTRACT: Simple Log::Dispatch replacement of Mojo::Log

use 5.016;
use strict;
use warnings;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::Util 'encode';

our $VERSION = '1.15'; # VERSION

has history          => sub { [] };
has level            => 'debug';
has max_history_size => 10;
has dispatch         => undef;
has format_cb        => undef;
has parent           => undef;

has 'path';
has color  => sub { $ENV{MOJO_LOG_COLOR} };
has short  => sub { $ENV{MOJO_LOG_SHORT} };
has handle => sub {
    return \*STDERR unless my $path = shift->path;
    return Mojo::File->new($path)->open('>>');
};

sub new {
    my $self = shift->SUPER::new(@_);
    $self->on( message => sub {
        my ( $self, $level ) = ( shift, shift );
        return unless ( $self->_active_level($level) );

        push( @{ $self->history }, [ time, $level, @_ ] );
        shift @{ $self->history } while ( @{ $self->history } > $self->max_history_size );

        ( $self->parent // $self )->dispatch->log(
            level   => $level,
            message => $_,
        ) for (@_);
    } );
    return $self;
}

sub _log {
    my ( $self, $level, @input ) = @_;
    $self->emit( 'message', $level, ref $input[0] eq 'CODE' ? $input[0]() : @input );
}

{
    my $levels = {
        debug => 1,
        info  => 2,
        warn  => 3,
        error => 4,
        fatal => 5,

        notice    => 2,
        warning   => 3,
        critical  => 4,
        alert     => 5,
        emergency => 5,
        emerg     => 5,

        err  => 4,
        crit => 4,
    };

    sub _active_level {
        my ( $self, $level ) = @_;
        return ( $levels->{$level} >= $levels->{ $ENV{MOJO_LOG_LEVEL} || $self->level } ) ? 1 : 0;
    }

    sub helpers {
        my ( $self, $c ) = ( shift, shift );

        for my $level ( (@_) ? @_ : keys %$levels ) {
            $c->helper( $level => sub {
                my ($self) = shift;
                $self->app->log->$level($_) for (@_);
                return;
            } );
        }

        return $self;
    }
}

sub context {
    my ( $self, $str ) = @_;
    return $self->new( parent => $self, context => $str, level => $self->level );
}

sub format {
    my ($self) = @_;
    return $self->format_cb || sub { localtime(shift) . ' [' . shift() . '] ' . join( "\n", @_, '' ) };
}

sub debug { shift->_log( 'debug',      @_ ) }
sub info  { shift->_log( 'info',       @_ ) }
sub warn  { shift->_log( 'warning',    @_ ) }
sub error { shift->_log( 'error',      @_ ) }
sub fatal { shift->_log( 'emergency',  @_ ) }

sub notice    { shift->_log( 'notice',    @_ ) }
sub warning   { shift->_log( 'warning',   @_ ) }
sub critical  { shift->_log( 'critical',  @_ ) }
sub alert     { shift->_log( 'alert',     @_ ) }
sub emergency { shift->_log( 'emergency', @_ ) }
sub emerg     { shift->_log( 'emergency', @_ ) }

sub err  { shift->_log( 'error',    @_ ) }
sub crit { shift->_log( 'critical', @_ ) }

sub is_debug { shift->_active_level('debug') }
sub is_info  { shift->_active_level('info')  }
sub is_warn  { shift->_active_level('warn')  }
sub is_error { shift->_active_level('error') }
sub is_fatal { shift->_active_level('fatal') }

sub is_notice    { shift->_active_level('notice')    }
sub is_warning   { shift->_active_level('warning')   }
sub is_critical  { shift->_active_level('critical')  }
sub is_alert     { shift->_active_level('alert')     }
sub is_emergency { shift->_active_level('emergency') }
sub is_emerg     { shift->_active_level('emergency') }

sub is_err  { shift->_active_level('err')  }
sub is_crit { shift->_active_level('crit') }

sub trace    { shift->_log( 'debug', @_ ) }
sub is_level { shift->_active_level(pop)  }

1;

=pod

=encoding UTF-8

=head1 NAME

MojoX::Log::Dispatch::Simple - Simple Log::Dispatch replacement of Mojo::Log

=head1 VERSION

version 1.15

=for markdown [![test](https://github.com/gryphonshafer/MojoX-Log-Dispatch-Simple/workflows/test/badge.svg)](https://github.com/gryphonshafer/MojoX-Log-Dispatch-Simple/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/MojoX-Log-Dispatch-Simple/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/MojoX-Log-Dispatch-Simple)

=head1 SYNOPSIS

    # from inside your startup() most likely...

    use Log::Dispatch;
    use MojoX::Log::Dispatch::Simple;

    my $mojo_logger = MojoX::Log::Dispatch::Simple->new(
        dispatch => Log::Dispatch->new,
        level    => 'debug'
    );

    my ($self) = @_; # Mojolicious object from inside startup()
    $self->log($mojo_logger);

    # ...then later inside a controller...

    $self->app->log->debug('Debug-level message');
    $self->app->log->info('Info-level message');

    # ...or back to your startup() to setup some helpers...

    $mojo_logger->helpers($self);
    $mojo_logger->helpers( $self, qw( debug info warn error ) );

    # ...so that in your controllers you can...

    $self->debug('Debug-level message');
    $self->info('Info-level message');

    # ...or do it all at once, in the startup() most likely...

    $self->log( MojoX::Log::Dispatch::Simple->new(
        dispatch => Log::Dispatch->new,
        level    => 'debug'
    )->helpers($self) );

=head1 DESCRIPTION

This module provides a really simple way to replace the built-in L<Mojo::Log>
with a L<Log::Dispatch> object, and yet still support all the L<Mojo::Log>
log levels and other functionality L<Mojolicious> assumes exists. To make it
even easier, you can install helpers to all the log levels, all from the same
single line of code.

    $self->log( MojoX::Log::Dispatch::Simple->new(
        dispatch => Log::Dispatch->new,
        level    => 'debug'
    )->helpers($self) );

The module tries not to make any assumptions about how you want to use
L<Log::Dispatch>. In fact, you can if desired use an alternate L<Log::Dispatch>
library so long as it offers a similar interface.

=head1 PRIMARY METHODS

These are methods that you would likely use from within your L<Mojolicious>
C<startup()> subroutine.

=head2 new

This method instantiates an object. It requires a "dispatch" parameter, which
should be a L<Log::Dispatch> object (or an object with a similar signature).
The method allow accepts an optional "level" parameter, which is used to set
the log level for your L<Mojolicious> application.

    my $mojo_logger = MojoX::Log::Dispatch::Simple->new(
        dispatch => Log::Dispatch->new,
        level    => 'debug'
    );

Optionally, you can also provide a "format_cb" value, which should be a
reference to a subroutine that will be used to provide custom formatting to
entries that appear on the L<Mojolicious> error reporting web page. This
formatting will have nothing at all to do with whatever your L<Log::Dispatch>
does; it only formats log entries that appear on the L<Mojolicious> error
reporting web page.

    my $mojo_logger = MojoX::Log::Dispatch::Simple->new(
        dispatch  => Log::Dispatch->new,
        level     => 'debug',
        format_cb => sub {
            localtime(shift) . ' [' . shift() . '] ' . join( "\n", @_, '' )
        },
    );

By default, when you're looking at one of these L<Mojolicious> error reporting
web pages, you'll see the past 10 log entries listed. You can change that
by passing in a "max_history_size" value.

    my $mojo_logger = MojoX::Log::Dispatch::Simple->new(
        dispatch         => Log::Dispatch->new,
        max_history_size => 20,
    );

=head2 helpers

You can optionally tell this library to create helpers to each of the log
levels, or to a selection of them. This method requires that you pass in
a reference to the L<Mojolicious> object. If that's all you pass in, the
method will create a helper for every log level.

    # from inside your startup()...
    $mojo_logger->helpers($mojo_obj);

    # now later from inside a controller...
    $c->debug('Debug message');

    $c->app->log->debug("This is what you'd have to type without the helper");

You can optionally pass in the names of the log levels you want helpers created
for, and the method will only create methods for those levels.

    $mojo_logger->helpers( $mojo_obj, qw( debug info warn ) );

=head1 LOG LEVELS

Unfortunately, L<Mojolicious> and L<Log::Dispatch> have somewhat different
ideas as to what log levels should exist. Since this module is a bridge between
them, it attempts to support all levels from both sides. That being said, when
calling log levels in your application, you will probably want to only use
the log levels from L<Log::Dispatch> if you use your L<Log::Dispatch> code
in non-Mojo-app areas of your ecosystem, thus keeping things uniform everywhere.

For the purposes of understanding log levels relative to each other, all log
levels are assigned a "rank" value. Since L<Mojolicious> has fewer levels than
L<Log::Dispatch> and there are 5 of them, a level's "rank" is an integer
between 1 and 5.

=head2 Log::Dispatch Log Levels

The following are L<Log::Dispatch> log levels along with their corresponding
"rank" integer and any supported aliases:

=over 4

=item *

debug (1)

=item *

info (2)

=item *

notice (2)

=item *

warning, warn (3)

=item *

error, err (4)

=item *

critical, crit (4)

=item *

alert (5)

=item *

emergency, emerg (5)

=back

=head2 Mojolicious Log Levels

The following are L<Mojolicious> log levels along with their corresponding
"rank" integer and any supported aliases:

=over 4

=item *

debug (1)

=item *

info (2)

=item *

warn (3)

=item *

error (4)

=item *

fatal (5)

=back

You can check what log level you're set at by either just reading C<$obj->level>
or by running an "is_*" method. For every log level, there's a corresponding
"is_*" method.

    my $log_level_at_or_above_notice = $obj->is_notice;

Note that this gets somewhat confusing when dealing with L<Log::Dispatch> log
levels because from the perspective of L<Log::Dispatch>, the "notice" level is
a unique level that's lower than a "warning" and higher than the "info" level.
However, from the perspective of L<Mojolicious>, there's no such log level.
It will assume you're set at the "info" log level. Ergo, if you call
C<is_notice()> or C<is_info()>, you'll get the same result.

=head1 POST-INSTANTIATION MEDDLING

Following the creation of the object from this library, you can still
manipulate various attributes, which are:

=over 4

=item *

dispatch (a L<Log::Dispatch> object)

=item *

level

=item *

max_history_size

=item *

format_cb (a subref)

=item *

history (an arrayref)

=back

So you can do things like:

    $obj->dispatch->remove('debug');

This also means you can manipulate the log history. Why you'd ever want to do
that, I can't say; but you can. Freedom is messy.

=head1 SEE ALSO

L<Mojolicious>, L<Log::Dispatch>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/MojoX-Log-Dispatch-Simple>

=item *

L<MetaCPAN|https://metacpan.org/pod/MojoX::Log::Dispatch::Simple>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/MojoX-Log-Dispatch-Simple/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/MojoX-Log-Dispatch-Simple>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/MojoX-Log-Dispatch-Simple>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/M/MojoX-Log-Dispatch-Simple.html>

=back

=for Pod::Coverage alert crit critical debug emerg emergency err fatal format info is_alert is_crit is_critical is_debug is_emerg is_emergency is_err is_error is_fatal is_info is_notice is_warn is_warning notice warn warning context is_level trace

=head1 GRATITUDE

Special thanks to the following for contributing to this module:

=over 4

=item *

Tomohiro Hosaka

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__ MojoX::Log::Dispatch::Simple MojoX-Log-Dispatch-Simple

