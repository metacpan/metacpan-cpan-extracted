package Sys::Signals::Block;
$Sys::Signals::Block::VERSION = '0.11';
# ABSTRACT: Simple interface to block delivery of signals

use 5.008;
use strict;
use warnings;

use Moo;
use MooX::ClassAttribute;
use strictures 2;
use Carp qw(croak);
use POSIX qw(sigprocmask SIG_BLOCK SIG_UNBLOCK);
use namespace::clean;

# maps signal names to signal numbers
class_has signal_numbers => (is => 'lazy');


has sigset => (is => 'rw');


has is_blocked => (is => 'rw', default => sub { 0 });

sub import {
    my $class = shift;

    if (@_) {
        my $instance = $class->instance;

        my $sigset = $instance->_parse_signals(@_)
            or croak "no valid signals listed on import line";

        $instance->sigset($sigset);
    }
}


around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    if (@args and !ref $args[0]) {
        my $sigset = $class->_parse_signals(@args)
            or croak "No valid signals given to constructor\n";

        return $class->$orig({sigset => $sigset});
    }
    else {
        return $class->$orig(@args);
    }
};


my $Instance;

sub instance {
    my $class = shift;

    unless ( defined $Instance ) {
        $Instance = $class->new;
    }

    return $Instance;
}


sub block {
    my $self = __self_or_instance(@_);

    return if $self->is_blocked;

    my $retval = sigprocmask(SIG_BLOCK, $self->sigset);

    if ($retval) {
        $self->is_blocked(1);
    }

    return $retval;
}


sub unblock {
    my $self = __self_or_instance(@_);

    return unless $self->is_blocked;

    my $retval = sigprocmask(SIG_UNBLOCK, $self->sigset);

    if ($retval) {
        $self->is_blocked(0);
    }

    return $retval;
}

# parse a list of signal names and return a POSIX::SigSet object representing
# the set of signals.  Return nothing if no valid signals were parsed.  Will
# croak if an invalid signal name is given.
sub _parse_signals {
    my ($class, @signals) = @_;

    my @nums;

    for my $signal (@signals) {
        unless ($signal =~ /\D/) {
            push @nums, $signal;
        }
        else {
            $signal =~ s/^SIG//;

            my $num = $class->signal_numbers->{$signal};

            unless (defined $num) {
                croak "invalid signal name: 'SIG${signal}'";
            }

            push @nums, $num;
        }
    }

    # no valid signals, just return.
    unless (@nums) {
        return;
    }

    return POSIX::SigSet->new(@nums);
}

sub _build_signal_numbers {
    my $self = shift;

    require Config;

    my @names = split /\s+/, $Config::Config{sig_name};
    my @nums  = split /[\s,]+/, $Config::Config{sig_num};

    my %sigs;

    @sigs{@names} = @nums;

    return \%sigs;
}

sub __self_or_instance {
    my $self = shift;

    unless (ref $self) {
        $self = $self->instance;
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

Sys::Signals::Block - Simple interface to block delivery of signals

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  #
  # Method 1: use signal names on import line, block using class method
  #
  use Sys::Signals::Block qw(TERM INT);

  Sys::Signals::Block->block;
  # critical section.
  # SIGINT, SIGTERM will not be delivered
  Sys::Signals::Block->unblock;
  # signals sent during critical section will be delivered here

  #
  # Method 2: Same as method 1, but use singleton object instead of class method
  #
  use Sys::Signals::Block qw(TERM INT);

  my $sigs = Sys::Signals::Block->instance;

  $sigs->block;
  # critical section
  $sigs->unblock;

  #
  # Method 3: Specify the signals you want to block in the constructor
  #
  use Sys::Signals::Block;

  my $sigs = Sys::Signals::Block->new('SIGTERM', 'SIGINT');

  $sigs->block;
  # critical section
  $sigs->unblock;

=head1 DESCRIPTION

This module provides an easy way to block the delivery of certain signals.
This is essentially just a wrapper around C<POSIX::sigprocmask(SIG_BLOCK, ...)>
and C<POSIX::sigprocmask(SIG_UNBLOCK, ...)>, but with a much simpler API.

The set of signals that should be blocked can given in the import list (the
parameters in the C<use> line for the module), or, can be specified in the call
to C<new()>.  The signal values can be either numeric, or string names.  If
names are given, they may be given either with or without the C<SIG> prefix.
For example, the following are all equivalent:

 # names, no SIG prefix
 use Sys::Signals::Block qw(TERM INT);
 my $sigs = Sys::Signals::Block->new(qw(TERM INT));

 # names with SIG prefix
 use Sys::Signals::Block qw(SIGTERM SIGINT);
 my $sigs = Sys::Signals::Block->new(qw(SIGTERM SIGINT));

 # integers, using POSIX constants
 use Sys::Signals::Block (POSIX::SIGTERM, POSIX::SIGINT);
 my $sigs = Sys::Signals::Block->new(POSIX::SIGTERM, POSIX::SIGINT);

All methods can be called either as class methods, or as object methods on the
C<<Sys::Signals::Block->instance>> object if using the C<import()> method.  If
using the constructor syntax, you must call block on the object you created
with C<new()>.

=head1 METHODS

=head2 sigset(): POSIX::SigSet

Get the set of signals that will be blocked.

=head2 is_blocked(): bool

Return C<true> if the set of signals are currently blocked, C<false> otherwise.

=head2 new(@signals): object

Construct a new L<Sys::Signals::Block> object with the given list of signals to
be blocked.  C<@signals> can be a list of signal names or integer signal
numbers.

For example, the following are all equivalent:

 $sigs = Sys::Signals::Block->new(qw(SIGINT SIGTERM));
 $sigs = Sys::Signals::Block->new(qw(INT TERM));
 $sigs = Sys::Signals::Block->new(2, 15);

=head2 instance(): scalar

Returns the instance of this module.

=head2 block(): void

Blocks the set of signals given in the C<use> line.  Returns true if
successful, false otherwise.

=head2 unblock(): void

Unblocks the set of signals given in the C<use> line.  Any signals that were
not delivered while signals were blocked will be delivered once the signals
are unblocked.  Returns true if successful, false otherwise.

=for Pod::Coverage BUILDARGS signal_numbers

=head1 SEE ALSO

L<POSIX/SigSet>, L<POSIX/sigprocmask>

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/sys-signals-block>
and may be cloned from L<git://https://github.com/mschout/sys-signals-block.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/sys-signals-block/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
