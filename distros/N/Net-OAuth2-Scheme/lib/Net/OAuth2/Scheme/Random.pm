use strict;
use warnings;

package Net::OAuth2::Scheme::Random;
BEGIN {
  $Net::OAuth2::Scheme::Random::VERSION = '0.03';
}
# ABSTRACT: random number generator interface
use Carp;
use Thread::IID 'interpreter_id';

# default RNG class; needs to be something that can do
#   $rng = class->new(@ints)  # new rng seeded with @ints
#   $rng->irand;              # random 32/64-bit int
#
our $RNG_Class;

# stash seed so that we can keep re-using it for each new fork and
# interpreter clone, varying only the process_id and interpreter_id
my @seed;

# class setup methods
our %seeds = ();  # class -> @seeds if we trust their autoseeder
our %new = ();    # class -> (@seeds -> new or reseeded RNG)
our %ish = ();    # class -> 3 for 64bit, 2 for 32bit irand

sub import {
    my $class = shift;
    # set $RNG_Class
    if (@_) {
        $RNG_Class = shift;
    }
    else {
        my @classes = keys %{ +{ map {$_,1} keys %seeds, keys %new } };
        for my $c (@classes) {
            my $f = $c;
            $f =~ s|::|/|g;
            $f .= '.pm';
            next unless $INC{$f};
            $RNG_Class = $c;
            last;
        }
    }
    $RNG_Class = 'Math::Random::MT::Auto'
      unless defined $RNG_Class;
    eval "require $RNG_Class;" or die $@;
    # set @seed
    @seed = ($seeds{$RNG_Class} || \&_make_seed)->();
}

my %rng = ();   # class -> (singleton) RNG object of that class
my %bytes = (); # class -> leftover bytes
my %refs = ();  # class -> # of Net::OAuth2::Scheme::Random objects
my $p_id = -1;  # process id ($$)
my $i_id;       # interpreter id (see Thread::IID for explanation)

sub _reseed_for_new_thread {
    my $rng_class = shift;
    my $new = $new{$rng_class} || sub {
        my $class=shift;
        return $class->new(@_);
    };
    my $rng = $new->($rng_class, $seed[0]+time, $seed[1]+$p_id, $seed[2]+$i_id, @seed[3.. $#seed]);
    $rng{$rng_class} = $rng;
    $bytes{$rng_class} = '';
}

sub new {
    my $class = shift;
    my $rng_class = shift || $RNG_Class;

    # check for fork()
    $class->CLONE unless $$ == $p_id;

    unless ($rng{$rng_class}) {
        eval "use ${rng_class};";
        _reseed_for_new_thread($rng_class);
    }
    $refs{$rng_class}++;
    return bless \( $rng_class ), $class;
}

sub _rng {
    my $self = shift;

    # check for fork()
    ref($self)->CLONE unless $$ == $p_id;

    return $rng{$$self};
}

sub DESTROY {
    my $self = shift;
    --$refs{$$self};
    # this routine only exists for the sake of being able to detect
    # unused RNG classes upon interpreter clone or process fork.
    #
    # once a RNG of a given class is created with a given seed,
    # we need to keep it around forever within any given process/thread
    # otherwise, we will get repeats
}

sub CLONE {
    my $class = shift;
    return if $p_id == $$ && $i_id == interpreter_id;
    $p_id = $$;
    $i_id = interpreter_id;
    for my $rng_class (keys %rng) {
        if ($refs{$rng_class} <= 0) {
            # nobody is currently using it
            # therefore it has not been used yet in this thread
            # therefore we can safely get rid of it
            delete $rng{$rng_class};
            delete $bytes{$rng_class};
            delete $refs{$rng_class};
        }
        else {
            _reseed_for_new_thread($rng_class);
        }
    }
}

sub irand {
    my $self = shift;
    $self->_rng->irand();
}

sub bytes {
    my ($self, $nbytes) = @_;
    Carp::croak('non-negative integer expected')
        if $nbytes < 0;

    my $rng = $self->_rng;
    my $ish = $ish{$$self} || 2;
    my $imask = (1<<$ish)-1;
    my $L = $ish == 2 ? 'L' : 'Q';

    my @ints = ();
    push @ints, $rng->irand for (1..$nbytes>>$ish);

    unless (my $nrem = (${nbytes} & ${imask})) {
        return pack "${L}*", @ints;
    }
    else {
        my ($rest);
        my $extras = $bytes{$$self};
        if ($nrem == length($extras)) {
            ($rest,$bytes{$$self}) = ($extras,'');
        }
        else {
            ($rest,$bytes{$$self}) = unpack 'C/aa*',
              ($nrem > length($extras)
               ? pack "Ca*${L}", $nrem, $extras, $rng->irand
               : pack 'Ca*',  $nrem, $extras);
        }
        return pack "a*${L}*", $rest, @ints;
    }
}

sub _make_seed {
    # stolen from Math::Random::Secure
    my ($nbytes, $sizeofint) = @_;
    $nbytes ||= 64;
    $sizeofint ||= 4;
    my $source;
    if ($^O =~ /Win32/i) {
        # On Windows, there is apparently only one choice
        require Crypt::Random::Source::Strong::Win32;
        $source = Crypt::Random::Source::Strong::Win32->new();
    }
    else {
         require Crypt::Random::Source::Factory;
         my $factory = Crypt::Random::Source::Factory->new();
         $source = $factory->get;

         # Never allow rand() to be used as a source, it cannot possibly be
         # cryptographically strong with 15 or 32 bits for its seed.
         $source = $factory->get_strong
           if ($source->isa('Crypt::Random::Source::Weak::rand'));
    }
    return unpack(($sizeofint == 8 ? 'Q*' : 'L*'), $source->get($nbytes));
}

### Math::Random::ISAAC support ###########################

$new{'Math::Random::ISAAC'} = sub {
    my $class=shift;
    my $rng = $class->new(@_);

    # skip frontend of Math::Random::ISAAC,
    # unless Math::Random::ISAAC has changed
    # so that there is no {backend} anymore.
    $rng = $rng->{backend} if $rng->{backend};
    return $rng;
};

### Math::Random::MT::Auto support ###########################

my $mrma = 'Math::Random::MT::Auto';

use Config;
$ish{$mrma} = $Config{uvsize} == 8 ? 3 : 2;

$seeds{$mrma} = sub {
    Math::Random::MT::Auto->import unless defined $MRMA::PRNG;
    my @s = $MRMA::PRNG->get_seed;
    if (@s < 4) {
        # class was loaded with :noauto or auto-seeding failed;
        # try to seed it ourselves
        @s = _make_seed(2496, $Config{uvsize});
    }
    return @s;
};

$new{$mrma} = sub {
    my $class = shift;

    # RNG shared acrosss threads does not need reseeding
    return $rng{$class}
      if $Math::Random::MT::Auto::shared;

    return $class->new('SEED'=> \@_)
};

sub _SHUT_UP_SHUT_UP_used_once_diagnostics {
    [$MRMA::PRNG, $Math::Random::MT::Auto::shared];
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Random - random number generator interface

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 # use something (defaults to Math::Random::MT::Auto)
 use Net::OAuth2::Scheme::Random;

 # use Mersenne Twister
 use Net::OAuth2::Scheme::Random 'Math::Random::MT::Auto';

 # use ISAAC;
 use Net::OAuth2::Scheme::Random 'Math::Random::ISAAC';

 $rng = Net::OAuth2::Scheme::Random->new
 $rng->bytes(24) # return 24 random octets

=head1 DESCRIPTION

This provides an interface for using arbitrary random number
generator classes with Net::OAuth2::Scheme.

The generator is instantiated exactly once in each thread/interpreter
using the same randomly derived seed, the process ID,
the interpreter ID and the thread/interpreter-start time.
Repeated calls to new() in the same thread/interpreter
will simply return the same generator.

=head1 CONSTRUCTOR

=over

=item C<< $class-> >>B<new>()

=item C<< $class-> >>B<new>(C<< $rng_class >>)

Return the generator derived from the default class / C<$rng_class>
as instantiated for this thread/interpreter.

=back

=head1 METHODS

=over

=item B<bytes>($n)

Return a random string of $n octets.

=back

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

