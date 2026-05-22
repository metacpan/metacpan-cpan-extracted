use v5.20;
use warnings;
use experimental qw(signatures postderef);

package String::Obfuscate 0.01 {
  use Math::Random::ISAAC ();
  use constant STD_CHARS => ['a'..'z', 'A'..'Z', 0..9];

  my $pp_shuffle = eval {
    require List::Util::XS;
    $List::Util::XS::VERSION >= 1.54;
  } ? undef : sub ($rand_func, @array) {
    for (my $idx = scalar @array; $idx > 1;) {
      my $swap_idx      = int($rand_func->() * $idx--);
      my $tmp_val       = $array[$swap_idx];
      $array[$swap_idx] = $array[$idx];
      $array[$idx]      = $tmp_val;
    }
    return @array;
  };

  sub new ($class, %params) {
    my $seed    = delete $params{'seed'};  # optional seed
    my $chars   = delete $params{'chars'}; # optional char list
    my $passph  = delete $params{'passphrase'};
    my $rtn_src = delete $params{'retain_source'};

    die 'unexpected param(s): ' . join(', ', keys %params)
      if keys %params;
    die 'cannot use both a seed and a passphrase'
      if defined $seed and defined $passph;
    die 'chars param must be a reference'
      if defined $chars and not ref $chars;

    $chars = [ split '', $$chars ] if $chars and ref $chars eq 'SCALAR';
    $seed  = [length $passph, unpack('L*', $passph)] if $passph;
    $seed  = make_seed() if !defined $seed;
    $seed  = [$seed] if !ref $seed;

    my $self = bless {
      chars => $chars // STD_CHARS,
      seed  => $seed,
      $rtn_src ? (rtn_src => !!1) : (),
    }, $class;

    $self->make_codec;
    return $self;
  }

  sub chars_shuffled ($self) {
    my $rng     = Math::Random::ISAAC->new($self->seed->@*);
    my $rand_fn = sub { $rng->rand() };
    my @chars_s = my_shuffle($rand_fn, $self->chars);
    return \@chars_s;
  }

  sub make_codec ($self) {
    my $fr_chars = quotemeta(join '', $self->chars->@*         );
    my $to_chars = quotemeta(join '', $self->chars_shuffled->@*);

    my ($enc_src, $dec_src);

    $self->{encode} = eval($enc_src = qq`sub { \$_[0] =~ tr|$fr_chars|$to_chars|r }`) or die $@;
    $self->{decode} = eval($dec_src = qq`sub { \$_[0] =~ tr|$to_chars|$fr_chars|r }`) or die $@;

    $self->{src} = [$enc_src, $dec_src] if $self->{rtn_src};
    return;
  }

  sub my_shuffle ($rand_func, $arrayref) {
    return $pp_shuffle->($rand_func, @$arrayref) if $pp_shuffle;
    local $List::Util::RAND = $rand_func;
    return List::Util::shuffle(@$arrayref);
  }

  sub dump_source ($self) {
    unless ($self->{src}) {
      $self->{rtn_src} = 1;
      $self->make_codec;
    }
    return @{$self->{src}};
  }

  sub make_seed   ()               { [time(), $$]    }
  sub seed        ($self)          { $self->{'seed'} }
  sub chars       ($self)          { $self->{chars}  }
  sub obfuscate   ($self, $string) { $self->{encode}->($string) }
  sub deobfuscate ($self, $string) { $self->{decode}->($string) }
  sub using_list_util_xs           { not $pp_shuffle }
}

1;

=head1 NAME

String::Obfuscate - Reversibly obfuscate a string with a substitution cipher.


=head1 VERSION

version 0.01


=head1 SYNOPSIS

    use String::Obfuscate;
    my $obf = String::Obfuscate->new(seed => 123);
    $obf->obfuscate('hello');   # 'xn88Y'
    $obf->deobfuscate('xn88Y'); # 'hello'


=head1 DESCRIPTION

String::Obfuscate implements a substitution type cipher adequate to obfuscate
a string without being cryptographically secure. The cipher mapping is
dynamically generated based on a seed or seeds which are fed to a random number
generator.

Specify seed(s) yourself to get a predictable result. Otherwise, the order will
be different with each String::Obfuscate object, but obfuscated strings can
still be reversed with the same object, or by asking the object for the seed and
and re-using the same seed.

If no seed is supplied, this module will create one based on the time and PID,
however this method may change in the future.

Randomness is supplied by the Math::Random::ISAAC, module which has both XS
and pure-perl implementations. This has several advantages:
 - The XS module is very fast while the PP module can be used as a fallback
 - Using a discrete RNG prevents alterating the state of perl's built-in RNG
 - The same algorithm can be implemented in another language if desired

If version 1.54 or greater of List::Util::XS is not available, a pure-perl
implementation of the same shuffle algorithm will be used (not List::Util::PP
which uses a different shuffle algorithm). Again, this ensures reproducibility.

Only ASCII letters and numbers are scrambled, but you can specify your own
character set to the new constructor with the chars param, which takes a
reference (to a string or an array of characters). This is done to prevent
excessive string copying and for a possible future feature where a plain string
might have a special meaning, such as the name of a character set.

Internally, this module generates a pair of encoding/decoding subroutines that
use a translation regex. Once the object is created, encoding and decoding is
very fast. However, if desired, you can dump the source code of the generated
subroutines/regexes.

Included in this distribution are String::Obfuscate::Base64 and
String::Obfuscate::Base64::URL which will convert the string to base 64 using
the standard or URL encoding, respectively, then obfuscate it. These subclasses
do not let you specify a character set. If the string you desire to obfuscate
contains binary data or UTF-8 characters, it is recommended you use one of
these Base64 subclasses.


=head1 REQUIREMENTS

    Math::Random::ISAAC (::XS or ::PP)

    perl v5.20 or greater

A minimum perl version of 5.20 is required as this module uses subroutine
signatures and postfix dereferencing. As of this writing, this version is
approximately 12 years old. You are encouraged to upgrade.


=head1 RECOMMENDATIONS

    List::Util::XS version 1.54 or greater

Older versions of List::Util do not allow you to specify a custom RNG.


=head1 RATIONALE

This module can be used to obscure non-security-sensitive data in a way that
is several orders of magnitude faster than encrypting it, while using a more
complex cipher than one with a fixed rotation (such as Crypt::Cipher::Rot47,
which is only slightly faster than this module).


=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Returns a new L<String::Obfuscate> object constructed according to PARAMS,
where PARAMS are name/value pairs. All PARAMS are optional. If a seed is not
specified, one will be created.

    $ob = String::Obfuscate->new;
    $ob = String::Obfuscate->new(seed => 123);
    $ob = String::Obfuscate->new(chars => ['a'..'f',0..9]);
    $ob = String::Obfuscate->new(passphrase => 'abcdefg');

=item chars

The characters used to generate the cipher, specified as an arrayref or stringref.

=item seed

The seed or seed(s). May be specified as a number or an arrayref of multiple
seeds. The random number generator can take up to 255 seeds.

=item passphrase

Instead of specifying a seed, you can specify a string passphrase which will
be converted to a series of seeds. The first seed is the length of the string,
then four-character groups are converted to 32-bit integers using unpack.

=item retain_source

Set to a true value, the source code of the generated encoding/decoding
subroutines will be saved before being eval-ed.

=back


=head1 OBJECT METHODS

=over 4

=item B<seed()>

Returns the seed. Regardless of how the seed was originally supplied, this
method will always return an arrayref.

Note the seed is set at object creation and cannot be changed later.

=item B<chars()>

=item B<chars_shuffled()>

Returns the source or destination character list as an arrayref.

These are set at object creation and cannot be changed later.

=item B<dump_source()>

Returns a two-element array. The first element is a string representation of
the obfuscation subroutine; the second element is the deobfuscation subroutine.
If retain_source was not passed to new(), this method can still be called, but
the subroutines will be re-generated.

=item B<obfuscate($string)>

Returns the obfuscated version of $string without altering the original.

=item B<deobfuscate($string)>

Returns the deobfuscated version of $string without altering the original.

=back


=head1 AUTHOR

Dondi Michael Stroma <dstroma@gmail.com>


=head1 COPYRIGHT

Copyright (C) 2025 by Dondi Michael Stroma. All rights reserved.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
