#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout::TimeOut;
{
    $Riak::Light::Timeout::TimeOut::VERSION = '0.052';
}
## use critic

use POSIX qw(ETIMEDOUT ECONNRESET);
use Time::Out qw(timeout);
use Time::HiRes;
use Riak::Light::Util qw(is_windows);
use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw<Num Str Int Bool Object>;

with 'Riak::Light::Timeout';

# ABSTRACT: proxy to read/write using Time::Out as a timeout provider

has socket      => ( is => 'ro', required => 1 );
has in_timeout  => ( is => 'ro', isa      => Num, default => sub {0.5} );
has out_timeout => ( is => 'ro', isa      => Num, default => sub {0.5} );
has is_valid    => ( is => 'rw', isa      => Bool, default => sub {1} );

sub BUILD {

# from Time::Out documentation
# alarm(2) doesn't interrupt blocking I/O on MSWin32, so 'timeout' won't do that either.

    croak "Time::Out alarm(2) doesn't interrupt blocking I/O on MSWin32!"
      if is_windows();

    carp "Not Safe: can clobber previous alarm";
}

sub clean {
    my $self = shift;
    $self->socket->close;
    $self->is_valid(0);
}

around [qw(sysread syswrite)] => sub {
    my $orig = shift;
    my $self = shift;

    if ( !$self->is_valid ) {
        $! = ECONNRESET;    ## no critic (RequireLocalizedPunctuationVars)
        return;
    }

    $self->$orig(@_);
};

sub sysread {
    my $self = shift;

    my $buffer;
    my $seconds = $self->in_timeout;
    my $result = timeout $seconds, @_ => sub {
        my $readed = $self->socket->sysread(@_);
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

    my $seconds = $self->out_timeout;
    my $result = timeout $seconds, @_ => sub {
        $self->socket->syswrite(@_);
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

Riak::Light::Timeout::TimeOut - proxy to read/write using Time::Out as a timeout provider

=head1 VERSION

version 0.052

=head1 DESCRIPTION

  Internal class

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
