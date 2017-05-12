use strict;
use warnings;

package Number::Format::SouthAsian;
$Number::Format::SouthAsian::VERSION = '0.10';
use Carp;
use English qw(-no_match_vars);
use Scalar::Util qw(looks_like_number);

=head1 NAME

Number::Format::SouthAsian - format numbers in the South Asian style

=head1 VERSION

version 0.10

=head1 SYNOPSIS

Formats numbers in the South Asian style. You can read more on Wikipedia here:

    http://en.wikipedia.org/wiki/South_Asian_numbering_system

The format_number() method has a words parameter which tells it to use
words rather than simply separating the numbers with commas.

    my $formatter = Number::Format::SouthAsian->new();
    say $formatter->format_number(12345678);             # 1,23,45,678
    say $formatter->format_number(12345678, words => 1); # 1.2345678 crores

You can also specify words to new(), which has the effect of setting a
default value to be used.

    my $formatter = Number::Format::SouthAsian->new(words => 1);
    say $formatter->format_number(12345678);             # 1.2345678 crores
    say $formatter->format_number(12345678, words => 0); # 1,23,45,678

You can also specify "decimals" to either new() or format_number(), which has
the effect of rounding any decimals found. Note that this means slightly
different things depending on wordiness.

    my $rounding_formatter = Number::Format::SouthAsian->new(decimals => 2);
    say $rounding_formatter->format_number(1234.5678); # 1,234.57
    say $rounding_formatter->format_number(12345678, words => 1); # 1.23 crores

In India it is common to use lakhs and crores, but quite uncommon to see any of
the other larger number names. An "arab" is much more likely to be called "100
crores" and a "kharab" is more likely to be called a "lakh crore." This
behaviour can be enabled with the lakhs_and_crores_only parameter.

    my $lakhs_and_crores_only_formatter = Number::Format::SouthAsian->new(words => 1, lakhs_and_crores_only => 1);
    say $lakhs_and_crores_only_formatter->format_number(1_00_00_00_000); # 100 crores

=head1 METHODS

=head2 new

Optionally takes a named parameter 'words' which sets the default of the
'words' parameter to format_number.

    my $normal_formatter   = Number::Format::SouthAsian->new();
    my $wordy_formatter    = Number::Format::SouthAsian->new(words => 1);
    my $rounding_formatter = Number::Format::SouthAsian->new(decimals => 2);

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = bless {}, $class;

    $self->_init_defaults(%opts);

    return $self;
}

sub _init_defaults {
    my $self = shift;
    my %opts = @_;

    $self->{'defaults'}{'words'}    = $opts{'words'}    || 0;
    $self->{'defaults'}{'decimals'} = $opts{'decimals'} || 0;
    $self->{'defaults'}{'lakhs_and_crores_only'} = $opts{'lakhs_and_crores_only'} || 0;

    return;
}

=head2 format_number

Takes a positional parameter which should just be a number. Optionally takes
a named parameter 'words' which turns on or off the wordy behaviour. Returns
a string containing the number passed in formatted in the South Asian style.

    my $formatted_number = $formatter->format_number(12345678);

    my $formatted_number = $formatter->format_number(12345678, words => 1);

=cut

sub format_number {
    my $self   = shift;
    my $number = shift;
    my %opts   = @_;

    if (!defined($number) || !looks_like_number($number)) {
        croak "First parameter to format_number() must be a number";
    }

    my $want_words = exists($opts{'words'})
                   ? $opts{'words'}
                   : $self->{'defaults'}{'words'};

    my $result;

    if ($want_words) {
        return $self->_format_number_wordy($number, %opts);
    }
    else {
        return $self->_format_number_separators_only($number, %opts);
    }
}

my %zeroes_to_words = (
    '5'  => 'lakh',
    '7'  => 'crore',
    '9'  => 'arab',
    '11' => 'kharab',
    '13' => 'neel',
    '15' => 'padma',
    '17' => 'shankh',
    '19' => 'maha shankh',
    '21' => 'ank',
    '23' => 'jald',
    '25' => 'madh',
    '27' => 'paraardha',
    '29' => 'ant',
    '31' => 'maha ant',
    '33' => 'shisht',
    '35' => 'singhar',
    '37' => 'maha singhar',
    '39' => 'adant singhar',
);

my %zeroes_to_words_lakhs_and_crores_only = (
    '5'  => 'lakh',
    '7'  => 'crore',
    '12' => 'lakh crore'
);

sub _format_number_wordy {
    my $self = shift;
    my $number = shift;
    my %opts = @_;

    my $zeroes = length($number) - 1;

    # scientific notation kicks in at a certain size...
    # we have to get around that.
    if ($number =~ m/^ ( \d+ (?: [.]\d+)?) e[+] (\d+) $/msx) {
        my ($mantissa, $exponent) = ($1, $2);

        ## in MSWin32 the exponent has an extra 0 on the front...
        if ($OSNAME eq 'MSWin32') {
            $exponent =~ s/^0+//;
        }

        if ($mantissa <= 1) {
            $zeroes = $exponent;
        }
        else {
            $zeroes = $exponent + 1;
        }
    }

    my %z2w;
    if ($opts{lakhs_and_crores_only} || (!exists($opts{lakhs_and_crores_only}) && $self->{'defaults'}{lakhs_and_crores_only})) {
        %z2w = %zeroes_to_words_lakhs_and_crores_only;
    }
    else {
        %z2w = %zeroes_to_words;
    }

    if ($zeroes < 5) {
        return $self->_format_number_separators_only($number);
    }

    my $divisor = "1" . ("0" x $zeroes);

    while (!$z2w{$zeroes} || (($number / $divisor) < 1)) {
        $zeroes  -=  1;
        $divisor /= 10;
    }

    my $fraction = sprintf("%f", ($number / $divisor)); # force no scientific notation
    if ($fraction =~ m/[.]/) {
        $fraction =~ s/0+$//;
        $fraction =~ s/[.]$//;
    }

    my $word = $z2w{$zeroes};

    $fraction = $self->_correct_decimals($fraction, %opts);

    my $pluralization = $fraction eq '1' ? '' : 's';

    my $words = sprintf('%s %s%s', $fraction, $word, $pluralization);

    return $words;
}

sub _format_number_separators_only {
    my $self    = shift;
    my $number  = shift;
    my %opts    = @_;

    $number =~ s{
        (?:
            (?<= \d{2})
            (?= \d{3}$)
        )
        |
        (?:
            (?<= ^\d{1} )
            (?=   \d{3}$)
        )
    }{,}gmsx;

    1 while $number =~ s{
        (?<! ,     )
        (?<! ^     )
        (?=  \d{2},)
    }{,}gmsx;

    1 while $number =~ s{([.].*),}{$1}gmsx;

    $number = $self->_correct_decimals($number, %opts);

    return $number;
}

sub _correct_decimals {
    my ($self, $number, %opts) = @_;

    my $decimals = exists($opts{'decimals'})
                 ? $opts{'decimals'}
                 : $self->{'defaults'}{'decimals'};

    if ($decimals) {
        my $pattern = "%.${decimals}f";

        $number =~ s{
            (\d+[.]\d+)
        }{
            sprintf($pattern, $1);
        }egmsx;

        if ($number =~ m/[.]/) {
            $number =~ s/0+$//;
            $number =~ s/[.]$//;
        }
    }

    return $number;
}

=head1 Copyright

Copyright (C) 2010 Lokku Ltd.

=head1 Author

Alex Balhatchet (alex@lokku.com)

=cut

1;
