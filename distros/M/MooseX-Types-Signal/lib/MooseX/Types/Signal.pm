package MooseX::Types::Signal;
BEGIN {
  $MooseX::Types::Signal::VERSION = '1.101932';
}
# ABSTRACT: a type to represent valid UNIX or Perl signals

use MooseX::Types -declare => ['Signal', 'UnixSignal', 'PerlSignal'];
use MooseX::Types::Moose qw(Str Int);

use Scalar::Util qw(looks_like_number);

use Config qw(%Config);
{ package _MXTS::Signals;
BEGIN {
  $_MXTS::Signals::VERSION = '1.101932';
}
  use POSIX 'signal_h';
}

sub get_unix_signal_number($) {
    my $sig = shift;
    # so apparently POSIX works differently on 5.8 vs. 5.10/5.12.
    # fucking POSIX!

    return eval {
        my $glob = $_MXTS::Signals::{$sig};
        ref $glob eq 'SCALAR' ? $$glob : $glob->();
    };
}

# patch welcome.
sub calc_unix_signals {

    my @keys = grep { get_unix_signal_number $_ }
               grep { /^SIG[A-Za-z]/i } keys %_MXTS::Signals::;

    my $signals = { map { (uc $_) => get_unix_signal_number $_ } @keys };

    my $sigrtmin = $signals->{SIGRTMIN};
    my $sigrtmax = $signals->{SIGRTMAX};

    if ($sigrtmin && $sigrtmax && $sigrtmax > $sigrtmin){
        # on my machine, kill thinks there is:
        # SIGRTMIN, SIGRTMIN+1, ..., SIGRTMIN+15, SIGRTMAX-15, ...
        #
        # we are going to do +everything and -everyting instead and
        # deal with "reversing" never.

        # first the plusses
        my $i = 1;
        for my $number ($sigrtmin+1..$sigrtmax-1){
            $signals->{"SIGRTMIN+$i"} = $number;
            $i++;
        }

        # then the minuses
        $i = 1;
        for my $number (reverse $sigrtmin+1..$sigrtmax-1){
            $signals->{"SIGRTMAX-$i"} = $number;
            $i++;
        }
    }

    return $signals;
}

sub calc_perl_signals {
    my @numbers = split /\s+/, $Config{sig_num};
    my @names   = split /\s+/, $Config{sig_name};

    my %result;
    my $i = 0;
    for my $number (@numbers) {
        my $name = $names[$i++] || $number;
        $result{uc "SIG$name"} = $number;
    }
    return \%result;
}

my $unix_signals = calc_unix_signals();
my $perl_signals = calc_perl_signals();

sub unix_signals { $unix_signals }
sub perl_signals { $perl_signals }

sub validate_unix_signal {
    my $sig = shift;

    eval { $sig = $sig->{error} if looks_like_number($sig->{error}) };

    return $sig->{error}. ' could not be coerced to a unix signal'
        if ref $sig && ref $sig eq 'HASH' && exists $sig->{error};

    return 'undef is not a signal (or your coercion failed)'
      if !defined $sig;

    return 'signal #0 is not a meaningful UNIX signal'
      if $sig == 0;

    return "signal $sig is not listed in your signal.h header file"
        if !exists { reverse %{unix_signals()} }->{$sig};

    return;
}

sub validate_perl_signal {
    my $sig = shift;

    eval { $sig = $sig->{error} if looks_like_number($sig->{error}) };

    return $sig->{error}. ' could not be coerced to a perl signal'
        if ref $sig && ref $sig eq 'HASH' && exists $sig->{error};

    return 'undef is not a signal (or your coercion failed)'
      if !defined $sig;

    return if $sig == 0; # this is somewhat allowable

    return "signal $sig is not mentioned in perl's \%Config hash"
        if !exists { reverse %{perl_signals()} }->{$sig};

    return;
}

sub validate_signal {
    my $sig = shift;
    my $unix_error = validate_unix_signal($sig);
    my $perl_error = validate_perl_signal($sig);

    return undef if !$unix_error || !$perl_error;
    return $unix_error || $perl_error;
}

sub coerce_unix_signal {
    my $sig = shift;
    my $signals = unix_signals();
    return $signals->{uc $sig} || $signals->{uc "SIG$sig"} || { error => $sig };
}

sub coerce_perl_signal {
    my $sig = shift;
    my $signals = perl_signals();
    return $signals->{uc $sig} || $signals->{uc "SIG$sig"} || { error => $sig };
}

sub coerce_signal {
    my $sig = shift;
    return coerce_unix_signal($sig) || coerce_perl_signal($sig);
}

subtype UnixSignal, as Int,
    where { !validate_unix_signal($_) },
    message { validate_unix_signal($_) };

subtype PerlSignal, as Int,
    where { !validate_perl_signal($_) },
    message { validate_perl_signal($_) };

subtype Signal, as PerlSignal|UnixSignal,
    where   { !validate_signal($_) },
    message { validate_signal($_) };

coerce UnixSignal, from Str, via { coerce_unix_signal($_) };
coerce PerlSignal, from Str, via { coerce_perl_signal($_) };
coerce Signal, from Str, via { coerce_signal($_) };

1;



=pod

=head1 NAME

MooseX::Types::Signal - a type to represent valid UNIX or Perl signals

=head1 VERSION

version 1.101932

=head1 SYNOPSIS

Often times you want to send a configurable signal, but you don't want
someone specifying SIGLOLCAT or 1234, because those aren't valid
signals.  Or are they?

With this module, you don't have to know; it will figure out what is
valid and what isn't, and what names map to what numbers.

Just use the C<Signal> type, and signal numbers are validated.  Use
the coercion, and you can refer to signals by name, too.

   package Example;
   use MooseX::Types::Signal qw(Signal);
   use Moose;

   has 'kill_with' => (
       is     => 'rw',
       isa    => Signal,
       coerce => 1,
   );

   my $example = Example->new;

   # kill with SIGKILL
   $example->kill_with(9);
   $example->kill_with('KILL');
   $example->kill_with('SIGKILL');

   # in any case, the reader C<kill_with> will always return 9, or
   # whatever your system thinks the number for SIGKILL is

=head1 DESCRIPTION

C<MooseX::Types::Signal> exports a type, C<Signal>, that recognizes
valid signals on your platform.  The underlying type is a non-negative
number, but there is a coercion from strings to numbers that
recognizes signals by name.

There are also more restrictive types, C<PerlSignal> and
C<UnixSignal>.  C<UnixSignal> only understands signals that are in
your system's C<signal.h> header file.  C<PerlSignal> only understands
signals that are in Perl's C<%Config> hash.  C<Signal> is either/or,
with preference to C<UnixSignal> over C<PerlSignal> when coercing.

=head1 EXPORTS

The exports C<Signal>, C<UnixSignal>, and C<PerlSignal> are exported
by L<Sub::Exporter|Sub::Exporter>, so you must explicitly request
them, and you can use any of Sub::Exporter's magic when doing so.
This is true in general of C<MooseX::Types> modules.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

