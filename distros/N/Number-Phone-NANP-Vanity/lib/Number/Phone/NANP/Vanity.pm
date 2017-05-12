package Number::Phone::NANP::Vanity;

use Moose;
use Locale::Maketext::Simple;
use true;

our $VERSION = '0.06';

#
# ATTRIBUTES
#

has 'number'   => (
    is         => 'ro',
    isa        => 'Num',
    required   => 1,
);

has [qw/npa nxx sub nxx_sub sub1 sub2/] => (
    is         => 'ro',
    isa        => 'Num',
    lazy_build => 1,
);

has 'dictionary' => (
    is         => 'ro',
    isa        => 'ArrayRef[Str|CodeRef]',
    traits     => ['Array'],
    default    => sub { [] },
    handles    => {
        'add_to_dictionary' => 'push',
    }
);

has 'keypad_layout' => (
    is         => 'rw',
    isa        => 'HashRef[Num]',
    traits     => ['Hash'],
    default    => sub { +{ # force array context
        split(//, uc('a2b2c2d3e3f3g4h4i4j5k5l5m6n6o6p7q7r7s7t8u8v8w9x9y9z9'))
    }},
);

has 'score' => (
    is         => 'rw',
    isa        => 'HashRef[ArrayRef]',
    traits     => ['Hash'],
    default    => sub { {} },
    handles    => {
        '_add_to_score' => 'set',
        'score_values' => 'values',
    },
);

# Moose::Meta::Attribute::Native::Trait::Array
has 'rules' => (
    is         => 'ro',
    isa        => 'ArrayRef[Str|CodeRef]',
    traits     => ['Array'],
    default    => sub {
        [qw/
            npa_eq_nxx
            sub1_eq_sub2
            nxx_repeats
            sub_repeats
            nxx_sub_repeats
            sub1_repeats
            sub2_repeats
            nxx_sub_is_sequential_asc
            nxx_sub_is_sequential_desc
            sub_is_sequential_asc
            sub_is_sequential_desc
            last_three_pairs_repeat
            matches_dictionary
            digit_repeats
        /]
    },
    handles    => {
        'add_rule' => 'push',
    }
);

#
# ATTRIBUTE BUILDERS
#

sub _build_npa {
    return substr($_[0]->number, 0, 3);
}

sub _build_nxx {
    return substr($_[0]->number, 3, 3);
}

sub _build_sub {
    return substr($_[0]->number, 6, 4);
}

sub _build_nxx_sub {
    return $_[0]->nxx . $_[0]->sub;
}

sub _build_sub1 {
    return substr($_[0]->sub, 0, 2);
}

sub _build_sub2 {
    return substr($_[0]->sub, 2, 2);
}

#
# METHODS
#

sub from_string {
    my ($class, $string, @new) = @_;
    
    # remove all non-numeric chars
    $string =~ s/\D//g;
    # strip leading 1 (country code)
    $string =~ s/^1//;
    
    die "Does not look like a valid NANP number ($string)"
        unless length($string) == 10;
    
    return $class->new(number => $string, @new);
}

sub number_formatted {
    my ($self, $format) = @_;
    $format ||= '%s-%s-%s%s';
    return sprintf($format, $self->npa, $self->nxx, $self->sub1, $self->sub2);
}

sub calculate_score {
    my $self = shift;
    
    # run every rule and calculate the score
    foreach my $rule (@{$self->rules}) {
        my $method = ref $rule eq 'CODE' ? $rule : '_rule_' . $rule;
        my ($score, $description) = $self->$method;
        
        # do not record zero scores
        next unless $score;
        
        # get default message if one is not returned by _rule sub
        #                         [_1]    [_2]        [_3]        [_4]        [_5]         [_6]
        $description = loc($rule, $score, $self->npa, $self->nxx, $self->sub, $self->sub1, $self->sub2)
            if !$description;
        
        $self->_add_to_score($rule => [$score, $description]);
    }

    return $self->_total_score;
}

sub _total_score {
    my $self = shift;
    
    my $total_score = 0;
    foreach my $score ($self->score_values) {
        $total_score += $score->[0];
    }
    
    return $total_score;
}

#
# RULES
#

sub _rule_npa_eq_nxx {
    return $_[0]->npa eq $_[0]->nxx ? 1 : 0;
}

sub _rule_sub1_eq_sub2 {
    return $_[0]->sub1 eq $_[0]->sub2 ? 1 : 0;
}

sub _rule_nxx_repeats {
    return $_[0]->_do_digits_repeat($_[0]->nxx) ? 2 : 0;
}

sub _rule_sub_repeats {
    return $_[0]->_do_digits_repeat($_[0]->sub) ? 3 : 0;
}

sub _rule_nxx_sub_repeats {
    return $_[0]->_do_digits_repeat($_[0]->nxx_sub) ? 5 : 0;
}

sub _rule_sub1_repeats {
    return $_[0]->_do_digits_repeat($_[0]->sub1) ? 1 : 0;
}

sub _rule_sub2_repeats {
    return $_[0]->_do_digits_repeat($_[0]->sub2) ? 1 : 0;
}

sub _rule_nxx_sub_is_sequential_asc {
    return $_[0]->_is_sequential_asc($_[0]->nxx_sub) ? 3 : 0;
}

sub _rule_nxx_sub_is_sequential_desc {
    return $_[0]->_is_sequential_desc($_[0]->nxx_sub) ? 2 : 0;
}

sub _rule_sub_is_sequential_asc {
    return $_[0]->_is_sequential_asc($_[0]->sub) ? 1 : 0;
}

sub _rule_sub_is_sequential_desc {
    return $_[0]->_is_sequential_desc($_[0]->sub) ? 1 : 0;
}

sub _rule_last_three_pairs_repeat {
    return $_[0]->nxx_sub =~ m|(\d{2})(\1{2})$| ? 2 : 0;
}

sub _rule_digit_repeats {
    my $self = shift;

    my $num = $self->number;
    my $score = 0;
    my @desc;

    while ($num =~ m|(\d)(\1{2,})|g) {
        my $digit = $1;
        my $size  = length($2) + 1;

        # skip if match found inside repeating nxx as it has it's own rule
        next if
            $size == 3 &&
            $digit eq substr($self->nxx, 0 , 1) &&
            $self->_rule_nxx_repeats;
        
        $score += $size - 1;
        push @desc, loc('Digit [_1] repeats [_2] times for [quant,_3,point].',
            $digit, $size, $score);
    }
    
    return ($score, join(' ', @desc));
}

sub _rule_matches_dictionary {
    my $self = shift;
    
    my @dict = @{$self->dictionary};
    return 0 unless @dict;
    
    my %keypad = %{$self->keypad_layout};
    my $chars = join('', keys %keypad);
    my $regex = qr/^[$chars]+$/i;
    
    my $word;
    my $score = 0;
    while ($word = shift @dict) {
        my $word_length = length($word);
        next if $word_length > 7;
        next if $word !~ $regex;
        
        my $number = $self->_word_to_digits($word);
        if (substr($self->nxx_sub, -$word_length) eq $number) {
            $score = $word_length - 2;
        }
        
        last if $score;
    }
    
    return 0 unless $score;
    return (
        $score,
        loc('Matches word "[_1]" for [quant,_2,point]', uc($word), $score)
    );
}

#
# RULE HELPERS
#

sub _do_digits_repeat {
    return $_[1] =~ m|^(\d)(\1+)$| ? 1 : 0;
}

sub _is_sequential_asc {
    return index('01234567890', $_[1]) > -1 ? 1 : 0;
}

sub _is_sequential_desc {
    return index('09876543210', $_[1]) > -1 ? 1 : 0;
}

sub _word_to_digits {
    my $self = shift;
    my $word = uc(shift);
    my %keypad = %{$self->keypad_layout};
    return join('', map { $keypad{$_} } split(//, $word));
}

=head1 NAME

Number::Phone::NANP::Vanity - Calculate vanity score of a NANP phone number

=head1 VERSION

0.04

=head1 SYNOPSIS

 use Number::Phone::NANP::Vanity;
 
 # simple case
 my $number = Number::Phone::NANP::Vanity->new(number => '8005551234');
 my $score  = $number->calculate_score;
 
 # check against a list of words as well
 my $number = Number::Phone::NANP::Vanity->new(
    number     => '8005551234',
    dictionary => [qw/flowers florist roses/],
 );
 my $score  = $number->calculate_score;
 
 # parses formatted numbers too
 my $number = Number::Phone::NANP::Vanity->from_string('+1-800-555-1234');
 
 # print formatted number
 print $number->number_formatted; # 800-555-1234
 
 # custom format
 print $number->number_formatted('(%s) %s-%s%s'); # (800) 555-1234

=head1 METHODS

=head2 new(%options)

=over 4

=item C<number>: a full, clean, 10 digit number

=item C<dictionary>: pass a reference to array containing a list of words you'd
like to check the number against. I<(optional)>

=item C<keypad_layout>: pass a reference to hash containing an alternative
keypad mapping. By default it uses International Standard layout. I<(optional)>

=back 

=head2 calculate_score()

Calculates and returns an integer score for the given number.

=head2 number_formatted($format)

Returns the number in a provided format. The format is the same as sprintf.
Default format is "%s-%s-%s%s" (800-555-1234).

=head1 RULES

First of all, some terminology:

=over 4

=item B<NPA>: area code, first 3 digits

=item B<NXX>: exchange, the 3 digits following NPA

=item B<sub>: subscriber part of the number, the last 4 digits

=item B<sub1>: first 2 digits of the subscriber part

=item B<sub2>: last 2 digits of the subscriber part

=back

=head2 npa_eq_nxx

NPA (area code) portion of the number equals NXX (exchange) portion of the
number.

E.g. B<800-800>-1234.

Gets 1 point.

=head2 sub1_eq_sub2

Subscriber parts repeat.

E.g. 800-745-B<1212>

Gets 1 point.

=head2 nxx_repeats

NXX portion has all repeating numbers.

E.g. 800-B<555>-5678

Gets 2 points.

=head2 sub_repeats

Subscriber portion has all repeating numbers.

E.g. 800-478-B<5555>

Gets 3 points.

=head2 nxx_sub_repeats

Both NXX and subscriber portions repeat.

E.g. 800-B<555>-B<5555>

Gets 5 points.

=head2 sub1_repeats

Sub1 has repeating numbers.

E.g. 800-478-B<22>32

Gets 1 point.

=head2 sub2_repeats

Sub2 has repeating numbers.

E.g. 800-478-32B<22>

Gets 1 point.

=head2 nxx_sub_is_sequential_asc

NXX and subscriber follow an ascending sequential number pattern.

E.g. 800-B<234>-B<5678>

Gets 3 points.

=head2 nxx_sub_is_sequential_desc

NXX and subscriber follow a descending sequential number pattern.

E.g. 800-B<765>-B<4321>

Gets 2 points.

=head2 sub_is_sequential_asc

Subscriber follows an ascending sequential number pattern.

E.g. 800-478-B<1234>

Gets 1 point.

=head2 sub_is_sequential_desc

Subscriber follows a descending sequential number pattern.

E.g. 800-478-B<4321>

Gets 1 point. I'd give it half, but don't want to get into decimals.

=head2 last_three_pairs_repeat

The last 3 pairs of digits repeat.

E.g. 800-5-B<121212>

Gets 2 points.

=head2 digit_repeats

Checks the entire number for 3 or more consequitive repeating digits.

E.g. 800-22B<7-777>1

There are 4 consequitive digits 7.

Gets 1 point for each repetition over 2 digits long. E.g. 1 point for 3 digits,
2 points for 4 digits.

=head2 matches_dictionary

The number matches a word provided via dictionary attribute. The words are
checked in the order provided.

Score will be recorded upon first successful match. No further matching will be
performed.

Matching is performed against the tail part of the word only. 

Words with more than 7 letters are skipped.

Words with characters not contained in the keypad_layout are skipped.

Score is assigned based on the length of the word matched. One point is assigned
for every letter matched above, and including a 3 character word. E.g.:

800-555-2FUN - 1 point (3 letter word matches)

800-555-PERL - 2 points (4 letter word matches)

800-55-LLAMA - 3 points (5 letter word matches)

=head1 CUSTOM RULES

You can also define your own custom rules by passing an anonymous sub to the
C<add_rule> method. The sub must return a score (int) equal or greater than
zero. An optional second parameter can be returned as a string describing why 
the score was assigned.

 my $number = Number::Phone::NANP::Vanity->new(number => '8003141592');
 $number->add_rule(sub {
     return (10, "Toll Free Pi")
        if shift->number eq '8003141592';
 });
 my $score = $number->calculate_score;

=head1 EXTENDING

Traits?

=head1 CAVEATS

Due to the fluid nature of this module, the rules might be changed at any time.
New rules might be added later on. Therefore you should not rely on the score
being fair across multiple sessions. The score should be used to compare the
number vanity during one session run. In other words, the score shall not be
recorded and compared against in the future.

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Roman F.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;