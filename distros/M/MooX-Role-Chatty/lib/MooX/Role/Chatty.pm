#!perl
#

use 5.010;
use strict;
use warnings;

package MooX::Role::Chatty;

our ($VERSION) = '1.01';

use Scalar::Util;
use Type::Tiny::Duck;

use Moo::Role 2;

sub _prefix_message {
    my ( $category, $level, $message ) = @_;
    my ( $sec, $min, $hr, $mday, $mon, $yr ) = localtime;
    state $months = [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )];
    $yr += 1900;
    $mon = $months->[$mon];
    $message = '' unless defined $message;
    my @lines = split /\n/, $message;

    return join(
        "\n",
        map {
            sprintf '%04d-% 3s-%02d %02d:%02d:%02d :: %s',
              $yr, $mon, $mday, $hr, $min, $sec, $_
        } @lines
    );
}

has 'verbose' => (
    is      => 'rw',
    isa     => sub { shift =~ /^\d+$/; },
    default => 0,
    trigger => 1
);

sub _verbose_to_log_level {
    my $self    = shift;
    my $verbose = $self->verbose;

    return 0 unless $verbose;

    require Log::Any::Adapter::Util;
    state $base_level = Log::Any::Adapter::Util::numeric_level('notice');

    return $verbose + $base_level - !!( $verbose > 0 );
}

sub _trigger_verbose {
    my $self = shift;
    return unless $self->_internal_logger;
    my $category = Scalar::Util::blessed($self) || $self;
    my $my_adapter = $self->_internal_logger->adapter ==
      Log::Any->get_logger( category => $category )->adapter;
    Log::Any::Adapter->remove( $self->_internal_logger->adapter );

    # If the current adapter is the one we installed, replace it.
    # If the user installed their own, don't get in its way.
    # Unfortunately, Log::Any doesn't provide a way to install our own
    # fallback logger behind the user's
    if ($my_adapter) {
        Log::Any::Adapter->set(
            { category => $category }, 'Carp',
            no_trace  => 1,
            log_level => $self->_verbose_to_log_level
        );
    }
}

has '_internal_logger' => ( is => 'rw', init_arg => undef, default => 0 );

has 'logger' => (
    is      => 'rw',
    lazy    => 1,
    isa     => Type::Tiny::Duck->new( methods => [qw/info warn/] ),
    builder => '_build_logger',
    clearer => 'clear_logger',
    trigger => 1
);

sub _build_logger {
    my $self = shift;
    my $category = Scalar::Util::blessed($self) || $self;
    require Log::Any;
    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        { category => $category }, 'Carp',
        no_trace  => 1,
        log_level => $self->_verbose_to_log_level
    );
    $self->_internal_logger(
        Log::Any->get_logger(
            category => $category,
            filter   => \&_prefix_message
        )
    );
}

sub _trigger_logger {
    my $self = shift;
    if ( $self->_internal_logger ) {
        Log::Any::Adapter->remove( $self->_internal_logger->adapter );
        $self->_internal_logger(0);
    }
}

before 'clear_logger' => sub {
    my $self = shift;
    if ( $self->_internal_logger ) {
        Log::Any::Adapter->remove( $self->_internal_logger );
        $self->_internal_logger(0);
    }
};

# Alias to mimic Log::Any API
sub get_logger { shift->logger(@_); }

sub remark {
    my ( $self, $msg ) = @_;

    return unless $self->verbose;

    my $logger = $self->logger;

    if ( ( Scalar::Util::reftype($msg) || '' ) eq 'HASH' ) {
        return if $self->verbose < ( $msg->{level} // -5 );
        $msg = $msg->{message};
    }

    # Log::Log4perl doesn't support 'notice', and Log::Dispatch
    # supports 'notice' but not 'noticef', so do crude duck typing and
    # go through some contortions for compatibility
    if ( ( Scalar::Util::reftype($msg) || '' ) eq 'ARRAY' ) {
        if ( $logger->can('noticef') ) { $logger->noticef(@$msg); }
        else {
            my $formatted = sprintf $msg->[0], @$msg[ 1 .. $#{$msg} ];
            if   ( $logger->can('notice') ) { $logger->notice($formatted) }
            else                            { $logger->info($formatted) }
        }
    }
    else {
        if   ( $logger->can('notice') ) { $logger->notice($msg); }
        else                            { $logger->info($msg); }
    }
}

1;

__END__

=head1 NAME

MooX::Role::Chatty - Simple way to generate progress messages

=head1 SYNOPSIS

  package My::Worker;
  use Moo 2;
  with 'MooX::Role::Chatty';

  sub munge_widget {
    ...
    # Produce informational message
    $self->remark("Starting to munge widget #$ct\n") if $self->verbose;
    ...
    # More detailed trace; output only if $self->verbose >= 2
    $self->remark({ level => 2,
                    message => "Munging step 3 yielded $result\n" });
    # Ditto for level 3, with simple formatting
    $self->remark({ level => 3,
                    message => [ "Munging params: %d, %d, %s\n",
                                 $gain, $threshold, $algorithm ] });
  }

  # Or use Log::Any-style API with compatible logger
  sub munge_widget_more {
    ...
    $self->logger->notice("Starting to munge widget #$ct\n");
    ...
    $self->logger->info("Munging step 3 yielded $result\n");
    $self->logger->debugf("Munging params: %d, %d, %s\n",
                           $gain, $threshold, $algorithm);
    # Logs even when $self->verbose == 0
    $self->logger->emergency("The sky is falling!")
  }

  # Elsewhere
  my $worker = My::Worker->new(verbose => 2, ...);
  $worker->munge_widget(...);  # Sit back and watch log

=head1 DESCRIPTION

One of the common uses for logging packages is providing feedback to
the user about the progress of long-running operations, or about
details of what the program is doing to aid in debugging.
L<MooX::Role::Chatty> aims to provide a few simple, lightweight tools
you can use to make this job a bit easier.  It does not provide
logging facilities itself, just a way to connect to them, and to let
the user specify how much information she wants to see.

In keeping with the idea of TMTOWTDI, there are a few different ways
to use L<MooX::Role::Chatty>.  The simplest is to examine the
L</verbose> attribute directly in your code, and call L</remark>
whenever you want to say something based on the current verbosity
level.  If you prefer labelling your logging calls by name, you can
also call L</logger> to get at the logging engine, on which
you can call any of the logging methods it supports.

=head2 MANAGING LOGGERS

L<MooX::Role::Chatty> tries to make the common cases easy.  To that
end, you don't need to worry about setting up L</logger> if you don't
want to.  If you haven't explicitly set this attribute, the first time
you need it (by calling L</logger> or L</remark>) a default logger
will be instantiated for you.  This logger is a L<Log::Any::Proxy>, so
you can call any of the methods supported by L<Log::Any> to generate
messages.  A corollary of this behavior is that you have to have
L<Log::Any> installed, or a fatal error occurs.

A brief timestamp is prepended to each line of the message.  The
logger is connected to a L<Log::Any::Adapter::Carp> adapter that passes
on logged messages but suppresses file/line information.  The result
is that log messages are sent to F<STDERR>, though you can redirect
them via C<$SIG{__WARN__}> if you want.

The L</verbose> attribute determines the level of logging: a
level of C<1> corresponds to a log level of C<notice>, C<2> to
C<info>, and so on.  Although less common, you can also go the other
way: C<-1> corresponds to C<warn>, C<-2> to C<error>, etc.  A
L</verbose> level of 0 is special: it suppresses any output from
L</remark>, and of the L<Log::Any> levels only C<emergency> will
produce output.

If you want to use the default L<Log::Any::Proxy>, but not the default
output adapter, you're free to register your own adapter to deal with
the L<MooX::Role::Chatty> category.  If you do, though, you need to
manage the adapter if you change L</verbose>, since L<Log::Any>
doesn't provide an API to update the C<log_level> of an existing
adapter.

Finally, if L<Log::Any> isn't your favorite among the plethora of
logging packages available, you can set L</logger> yourself, to any
object that responds to C<info> and C<warn> methods.  Most of the more
established Perl logging packages fill the bill, like L<Log::Dispatch>
or L<Log::Log4perl>, in addition to L<Log::Any>.  For that matter, if
you like the behavior of L<Log::Any> but want output from your module
to be different from L<MooX::Role::Chatty> logging elsewhere in your
application, you can use an instance of an adapter class directly.
Again, if you set L</logger> directly, it's your responsibility to
update the logger's behavior as appropriate if you reset L</verbose>.

=head2 ATTRIBUTES

=over 4

=item verbose

The level of output logged.  Higher values typically indicate
that more detailed information should be provided.

For the behavior of the default logger in response to different
L</verbose> settings, see L</MANAGING LOGGERS>.

Defaults to C<0>, and can be updated.

=item logger

=item get_logger

The logging engine to be used for output.

The default is described above in L<MANAGING LOGGERS>.

Although you usually won't want to, you can update L</logger>, or
clear it via C<clear_logger>.  In the latter case, if you output a
message before setting L</logger>, a new default logger will be
instantiated.

The L</get_logger> alias is provided for ease of use by writers
accustomed to L<Log::Any>; it is identical to L</logger>.

=back

=head2 METHODS

In addition to the attribute accessors, one method is provided:

=over 4

=item remark(I<$info>)

If L</verbose> is non-zero, produce a log message, based on the
contents of I<$info> as described below.  This message is output
output at the C<notice> log level (or C<info> if L</logger> doesn't
respond to C<notice>).

=over 4

=item *

If I<$info> is a hash reference, check the value associated with the
C<level> key against L</verbose>.  If C<level> is less than
L</verbose>, do nothing.  Otherwise, use the value associated with the
C<message> key as the log message in place of I<$info> (subject to the
two rules below).

B<Note:> It's important, but sometimes confusing, to keep in mind the
difference between the target verbosity level (which is what C<level>
specifies), and the actual call to the logger, which is always at the
C<notice> (or C<info>) log level.  In other words, saying C<< level =>
-3 >> does NOT get you a call to C<critical>.

=item *

If I<$info> is a simple scalar, use it as the log message.

=item *

If I<$info> is an array reference, use the contents as arguments to
format a message.  For a L<Log::Any>-based logger, they're simply
passed to C<noticef>.  Otherwise, they're passed to
L<perfunc/sprintf>, and the result passed to C<notice> (or C<info>).

=back

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<MooX::Role::Logger>, an even more lightweight way for your code to
use L<Log::Any>.

L<Log::Any>, L<Log::Any::Adapter::Carp>

=head1 BUGS AND CAVEATS

Are there, for certain, but have yet to be cataloged.

=head1 VERSION

version 1.01

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Charles Bailey

This software may be used under the terms of the Artistic License
version 2 or the GNU Lesser General Public License version 3, as the
user prefers.

=cut
