#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::Alarm;
{
    $Riak::Light::Timeout::Alarm::VERSION = '0.12';
}
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use Time::HiRes qw(alarm);
use Riak::Light::Util qw(is_windows);
use Carp;
use Moo;
use Types::Standard -types;
with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using Alarm as a timeout provider ( Not Safe: can clobber previous alarm )

has socket      => ( is => 'ro', required => 1 );
has in_timeout  => ( is => 'ro', isa      => Num, default => sub {0.5} );
has out_timeout => ( is => 'ro', isa      => Num, default => sub {0.5} );
has is_valid    => ( is => 'rw', isa      => Bool, default => sub {1} );

sub BUILD {

# from perldoc perlport
# alarm:
#  Emulated using timers that must be explicitly polled whenever
#  Perl wants to dispatch "safe signals" and therefore cannot
#  interrupt blocking system calls (Win32)

    croak "Alarm cannot interrupt blocking system calls in Win32!"
      if is_windows();

    carp "Not Safe: can clobber previous alarm";
}

sub clean {
    $_[0]->socket->close;
    $_[0]->is_valid(0);
}

sub sysread {
    my $self = shift;
    $self->is_valid
      or $! = ECONNRESET,
      return;    ## no critic (RequireLocalizedPunctuationVars)

    my $buffer;
    my $seconds = $self->in_timeout;

    my $result = eval {
        local $SIG{'ALRM'} = sub { croak 'Timeout !' };
        alarm($seconds);

        my $readed = $self->socket->sysread(@_);

        alarm(0);

        $buffer = $_[0];    # NECESSARY, timeout does not map the alias @_ !!
        $readed;
    };
    if ($@) {
        $self->clean();
        $! = ETIMEDOUT;     ## no critic (RequireLocalizedPunctuationVars)
    }
    else {
        $_[0] = $buffer;
    }

    $result;
}

sub syswrite {
    my $self = shift;
    $self->is_valid
      or $! = ECONNRESET,
      return;    ## no critic (RequireLocalizedPunctuationVars)

    my $seconds = $self->out_timeout;
    my $result  = eval {
        local $SIG{'ALRM'} = sub { croak 'Timeout !' };
        alarm($seconds);

        my $readed = $self->socket->syswrite(@_);

        alarm(0);

        $readed;
    };
    if ($@) {
        $self->clean();
        $! = ETIMEDOUT;    ## no critic (RequireLocalizedPunctuationVars)
    }

    $result;
}

1;


=pod

=head1 NAME

Riak::Light::Timeout::Alarm - proxy to read/write using Alarm as a timeout provider ( Not Safe: can clobber previous alarm )

=head1 VERSION

version 0.12

=head1 DESCRIPTION

  Internal class

=head1 AUTHORS

=over 4

=item *

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=item *

Damien Krotkine <dams@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
