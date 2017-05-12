package Net::Whois::Info;

use Class::Easy;

1;

# package code below is included because Claus Färber does stupid
# things like «developer» module versions, which can't be installed
# automatically via cpan.

# more info at: http://search.cpan.org/perldoc?Net%3A%3AIDN%3A%3AEncode

package Net::IDN::Punycode;

use strict;
use utf8;
use warnings;
require 5.006_000;

use integer;

our $DEBUG = 0;

use constant BASE => 36;
use constant TMIN => 1;
use constant TMAX => 26;
use constant SKEW => 38;
use constant DAMP => 700;
use constant INITIAL_BIAS => 72;
use constant INITIAL_N => 128;

my $Delimiter = chr 0x2D;
my $BasicRE   = qr/[\x00-\x7f]/;

sub _digit_value {
    my $code = shift;
    return ord($code) - ord("A") if $code =~ /[A-Z]/;
    return ord($code) - ord("a") if $code =~ /[a-z]/;
    return ord($code) - ord("0") + 26 if $code =~ /[0-9]/;
    return;
}

sub _code_point {
    my $digit = shift;
    return $digit + ord('a') if 0 <= $digit && $digit <= 25;
    return $digit + ord('0') - 26 if 26 <= $digit && $digit <= 36;
    die 'NOT COME HERE';
}

sub _adapt {
    my($delta, $numpoints, $firsttime) = @_;
    $delta = $firsttime ? $delta / DAMP : $delta / 2;
    $delta += $delta / $numpoints;
    my $k = 0;
    while ($delta > ((BASE - TMIN) * TMAX) / 2) {
	$delta /= BASE - TMIN;
	$k += BASE;
    }
    return $k + (((BASE - TMIN + 1) * $delta) / ($delta + SKEW));
}

sub decode_punycode {
    my $code = shift;

    my $n      = INITIAL_N;
    my $i      = 0;
    my $bias   = INITIAL_BIAS;
    my @output;

    if ($code =~ s/(.*)$Delimiter//o) {
	push @output, map ord, split //, $1;
	return die ('non-basic code point') unless $1 =~ /^$BasicRE*$/o;
    }

    while ($code) {
	my $oldi = $i;
	my $w    = 1;
    LOOP:
	for (my $k = BASE; 1; $k += BASE) {
	    my $cp = substr($code, 0, 1, '');
	    my $digit = _digit_value($cp);
	    defined $digit or return die ("invalid punycode input");
	    $i += $digit * $w;
	    my $t = ($k <= $bias) ? TMIN
		: ($k >= $bias + TMAX) ? TMAX : $k - $bias;
	    last LOOP if $digit < $t;
	    $w *= (BASE - $t);
	}
	$bias = _adapt($i - $oldi, @output + 1, $oldi == 0);
	warn "bias becomes $bias" if $DEBUG;
	$n += $i / (@output + 1);
	$i = $i % (@output + 1);
	splice(@output, $i, 0, $n);
	warn join " ", map sprintf('%04x', $_), @output if $DEBUG;
	$i++;
    }
    return join '', map chr, @output;
}

sub encode_punycode {
    my $input = shift;
    # my @input = split //, $input; # doesn't work in 5.6.x!
    my @input = map substr($input, $_, 1), 0..length($input)-1;

    my $n     = INITIAL_N;
    my $delta = 0;
    my $bias  = INITIAL_BIAS;

    my @output;
    my @basic = grep /$BasicRE/, @input;
    my $h = my $b = @basic;
    push @output, @basic, $Delimiter if $b > 0;
    warn "basic codepoints: (@output)" if $DEBUG;

    while ($h < @input) {
	my $m = _min(grep { $_ >= $n } map ord, @input);
	warn sprintf "next code point to insert is %04x", $m if $DEBUG;
	$delta += ($m - $n) * ($h + 1);
	$n = $m;
	for my $i (@input) {
	    my $c = ord($i);
	    $delta++ if $c < $n;
	    if ($c == $n) {
		my $q = $delta;
	    LOOP:
		for (my $k = BASE; 1; $k += BASE) {
		    my $t = ($k <= $bias) ? TMIN :
			($k >= $bias + TMAX) ? TMAX : $k - $bias;
		    last LOOP if $q < $t;
		    my $cp = _code_point($t + (($q - $t) % (BASE - $t)));
		    push @output, chr($cp);
		    $q = ($q - $t) / (BASE - $t);
		}
		push @output, chr(_code_point($q));
		$bias = _adapt($delta, $h + 1, $h == $b);
		warn "bias becomes $bias" if $DEBUG;
		$delta = 0;
		$h++;
	    }
	}
	$delta++;
	$n++;
    }
    return join '', @output;
}

sub _min {
    my $min = shift;
    for (@_) { $min = $_ if $_ <= $min }
    return $min;
}

1;

package Net::IDN::Encode;

use strict;
use utf8;
use warnings;
require 5.006_000;

our $VERSION = '0.99_20080919';
$VERSION = eval $VERSION;

our $IDNA_prefix = 'xn--';

sub _to_ascii {
  use bytes;
  no warnings qw(utf8); # needed for perl v5.6.x

  my ($label,%param) = @_;

  if($label =~ m/[^\x00-\x7F]/) {
    $label = Net::IDN::Nameprep::nameprep ($label);
  }

  if($param{'UseSTD3ASCIIRules'}) {
    die 'Invalid domain name (toASCII, step 3)' if 
      $label =~ m/^-/ ||
      $label =~ m/-$/ || 
      $label =~ m/[\x00-\x2C\x2E-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F]/;
  }

  if($label =~ m/[^\x00-\x7F]/) {
    die 'Invalid label (toASCII, step 5)' if $label =~ m/^$IDNA_prefix/;
    return $IDNA_prefix.Net::IDN::Punycode::encode_punycode ($label);
  } else {
    return $label;
  }
}

sub _to_unicode {
  use bytes;

  my ($label,%param) = @_;
  my $orig = $label;

  return eval {
    if($label =~ m/[^\x00-\x7F]/) {
      $label = Net::IDN::Nameprep::nameprep ($label);
    }

    my $save3 = $label;
    die unless $label =~ s/^$IDNA_prefix//;

    $label = Net::IDN::Punycode::decode_punycode ($label);
    
    my $save6 = _to_ascii($label,%param);

    die unless uc($save6) eq uc($save3);

    $label;
  } || $orig;
}

sub _domain {
  use utf8;
  my ($domain,$_to_function,@param) = @_;
  return undef unless $domain;
  return join '.',
    grep { die 'Invalid domain name' if length($_) > 63 && !m/[^\x00-\x7F]/; 1 }
      map { $_to_function->($_, @param, 'UseSTD3ASCIIRules' => 1) }
        split /[\.。．｡]/, $domain;
}

sub _email {
  use utf8;
  my ($email,$_to_function,@param) = @_;
  return undef unless $email;

  $email =~ m/^([^"\@＠]+|"(?:(?:[^"]|\\.)*[^\\])?")(?:[\@＠]
    (?:([^\[\]]*)|(\[.*\]))?)?$/x || die "Invalid email address";
  my($local_part,$domain,$domain_literal) = ($1,$2,$3);

  $local_part =~ m/[^\x00-\x7F]/ && die "Invalid email address";
  $domain_literal =~ m/[^\x00-\x7F]/ && die "Invalid email address" if $domain_literal;

  $domain = _domain($domain,$_to_function,@param) if $domain;

  return ($domain || $domain_literal)
    ? ($local_part.'@'.($domain || $domain_literal))
    : ($local_part);
}

sub domain_to_ascii { _domain(shift,\&_to_ascii) }
sub domain_to_unicode { _domain(shift,\&_to_unicode) }

sub email_to_ascii { _email(shift,\&_to_ascii) }
sub email_to_unicode { _email(shift,\&_to_unicode) }

1;

package Net::IDN::Nameprep;

use strict;
use utf8;
use warnings;
require 5.006_000;

use Unicode::Stringprep;

use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;

*nameprep = Unicode::Stringprep->new(
  3.2,
  [ 
    @Unicode::Stringprep::Mapping::B1, 
    @Unicode::Stringprep::Mapping::B2 
  ],
  'KC',
  [
    @Unicode::Stringprep::Prohibited::C12,
    @Unicode::Stringprep::Prohibited::C22,
    @Unicode::Stringprep::Prohibited::C3,
    @Unicode::Stringprep::Prohibited::C4,
    @Unicode::Stringprep::Prohibited::C5,
    @Unicode::Stringprep::Prohibited::C6,
    @Unicode::Stringprep::Prohibited::C7,
    @Unicode::Stringprep::Prohibited::C8,
    @Unicode::Stringprep::Prohibited::C9
  ],
  1,
);

1;