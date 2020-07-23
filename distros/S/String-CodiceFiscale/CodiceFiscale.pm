package String::CodiceFiscale;

$String::CodiceFiscale::VERSION = '0.02';

use strict;
use utf8;
no locale;
use base qw(Class::Data::Inheritable);
use Time::Piece;
use Carp;
use POSIX;

our %CRC = (
    A   =>  [0, 1],     B   =>  [1, 0],     C   =>  [2, 5],     
    D   =>  [3, 7],     E   =>  [4, 9],     F   =>  [5, 13],
    G   =>  [6, 15],    H   =>  [7, 17],    I   =>  [8, 19],
    J   =>  [9, 21],    K   =>  [10, 2],    L   =>  [11, 4],
    M   =>  [12, 18],   N   =>  [13, 20],   O   =>  [14, 11],
    P   =>  [15, 3],    Q   =>  [16, 6],    R   =>  [17, 8],
    S   =>  [18, 12],   T   =>  [19, 14],   U   =>  [20, 16],
    V   =>  [21, 10],   W   =>  [22, 22],   X   =>  [23, 25],
    Y   =>  [24, 24],   Z   =>  [25, 23],   0   =>  [0, 1],
    1   =>  [1, 0],     2   =>  [2, 5],     3   =>  [3, 7],
    4   =>  [4, 9],     5   =>  [5, 13],    6   =>  [6, 15],
    7   =>  [7, 17],    8   =>  [8, 19],    9   =>  [9, 21],
);

__PACKAGE__->mk_classdata('ERROR');

our ($MONTHS, @MONTHS, %MONTHS);    #code to/from month
@MONTHS[1..12] = qw(A B C D E H L M P R S T);
@MONTHS{@MONTHS[1..12]} = 1..12;
$MONTHS = join '', @MONTHS[1..12];

our ($XNUMS, @XNUMS, %XNUMS);       #coded numbers for rare collision cases
@XNUMS = qw(L M N P Q R S T U V);
@XNUMS{@XNUMS} = 0..9;  #not used anymore, but here "just in case"
$XNUMS = join '', @XNUMS;

our $CONSONANTS = 'BCDFGHJKLMNPQRSTVWXYZ';
our $VOWELS     = 'AEIOU';

our $RE_cf = qr/
    ^                       #start
    ([A-Z]{3})              #surname coded
    ([A-Z]{3})              #firstname coded
    ([\d$XNUMS]{2})         #year
    ([$MONTHS])             #month coded
    ([\d$XNUMS]{2})         #day and sex
    ([A-Z][\d$XNUMS]{3})    #birthplace coded
    ([A-Z])                 #crc
    $                       #end
/xo;

our $RE_nc = qr/^[$CONSONANTS]*[$VOWELS]*X*$/xo;

our %OPTS = map {$_ => 1} qw(
    sn sn_c fn fn_c date year year_c 
    month month_c day day_c sex bp bp_c
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    while (my ($k, $v) = splice(@_, 0, 2)) {
        $self->_croak(qq(Not such an options "$k")) unless $OPTS{$k};
        $self->$k($v);
    }
    return $self;
}

sub sn {
    my $self = shift;
    my ($sn) = @_;
    if (defined $sn) {
        $sn = uc($sn);
        $self->{sn} = $sn;
        $self->{sn_c} = undef;
        $self->{sn_re} = undef;
    }
    return $sn;
}

sub sn_c {
    my $self = shift;
    my ($sn_c) = @_;
    if (defined $sn_c) {
        $sn_c = uc($sn_c);
        unless ($sn_c =~ /$RE_nc/) {
            $self->error('Coded surname cannot contain ' .
                            'vowels followed by consonants');
            return;
        }
        unless (length($sn_c) == 3) {
            $self->error('Coded surname must be 3 chars in length');
            return;
        }
        $self->{sn_c} = $sn_c;
        $self->{sn} = undef;
        $self->{sn_re} = undef;
    }
    if (defined $self->{sn} and not defined $self->{sn_c}) {
        my $temp = '';
        OUTER: {
            while ($self->{sn} =~ /([$CONSONANTS])/go) {
                $temp .= $1;
                last OUTER if length $temp >= 3;
            }
            while ($self->{sn} =~ /([$VOWELS])/go) {
                $temp .= $1;
                last OUTER if length $temp >= 3;
            }
            while (length $temp < 3) {
                $temp .= 'X';
            }
        }
        $self->{sn_c} = $temp;
    }
    return $self->{sn_c};
}

sub sn_re {
    my $self = shift;
    return $self->_n_re('sn_c');
}


sub sn_match {
    my $self = shift;
    my ($tm) = @_;
    return unless defined $tm;
    $tm = uc $tm;
    $self->_fix_name($tm);
    if (defined(my $sn = $self->sn)) {
        $self->_fix_name($sn);
        return $tm eq $self->sn;
    }
    if (defined $self->sn_c) {
        return $tm =~ $self->sn_re;
    }
    return;
}

sub fn {
    my $self = shift;
    my ($fn) = @_;
    if (defined $fn) {
        $fn = uc($fn);
        $self->{fn} = $fn;
        $self->{fn_c} = undef;
        $self->{fn_re} = undef;
    }
    return $fn;
}

sub fn_c {
    my $self = shift;
    my ($fn_c) = @_;
    if (defined $fn_c) {
        $fn_c = uc($fn_c);
        unless ($fn_c =~ /$RE_nc/) {
            $self->error('Coded name cannot contain ' .
                            'vowels followed by consonants');
            return;
        }
        unless (length($fn_c) == 3) {
            $self->error('Coded name must be 3 chars in length');
            return;
        }
        $self->{fn_c} = $fn_c;
        $self->{fn} = undef;
        $self->{fn_re} = undef;
    }
    if (defined $self->{fn} and not defined $self->{fn_c}) {
        my $temp = '';
        my $skip = $self->_count_consonants($self->{fn}) > 3;
        OUTER: {
            while ($self->{fn} =~ /([$CONSONANTS])/go) {
                if ($skip and length($temp) == 1) {
                    $skip = 0;
                    next;
                }
                $temp .= $1;
                last OUTER if length $temp >= 3;
            }
            while ($self->{fn} =~ /([$VOWELS])/go) {
                $temp .= $1;
                last OUTER if length $temp >= 3;
            }
            while (length $temp < 3) {
                $temp .= 'X';
            }
        }
        $self->{fn_c} = $temp;
    }
    return $self->{fn_c};
}

sub fn_re {
    my $self = shift;
    return $self->_n_re('fn_c');
}

sub fn_match {
    my $self = shift;
    my ($tm) = @_;
    return unless defined $tm;
    $tm = uc $tm;
    $self->_fix_name($tm);
    if (defined(my $fn = $self->fn)) {
        $self->_fix_name($fn);
        return $tm eq $fn;
    }
    if (defined $self->fn_c) {
        return $tm =~ $self->fn_re;
    }
    return;
}


sub date {
    my $self = shift;
    my ($date) = @_;
    if (defined $date) {
        my $t;
        eval { $t = Time::Piece->strptime($date, '%Y-%m-%d') };
        if ($@) {
            $self->error("Invalid date");
            return;
        }
        my %date = (
            year    =>  $t->year,
            month   =>  $t->mon,
            day     =>  $t->mday,
        );
        for (qw(year month day)) {
            unless ( $self->$_($date{$_}) ) {
                $self->error("Couldn't parse $_");
                return;
            }
        }
    } else {
        my %date;
        for (qw(year month day)) {
            $date{$_} = $self->$_;
            unless (defined $date{$_}) {
                $self->error("Couldn't retrieve $_");
                return;
            }
        }
        return sprintf("%04d-%02d-%02d", @date{qw(year month day)});
    }
    return $date;
}

sub year {
    my $self = shift;
    my ($y) = @_;
    if (defined $y) {
        unless ($y =~ /^\d+$/) {
           $self->error('A year should be an unsigned integer');
           return;
        }
        $self->{year} = $y;
        $self->{year_c} = undef;
    }
    if (not defined $self->{year} and defined $self->{year_c}) {
        my $year = $self->_xnums($self->{year_c});
        my $this_year = (localtime(time))[5] + 1900;
        my $twodigits_year = $this_year % 100;    # this is making a guess
        my $century = floor($this_year/100);
        $self->{year} = sprintf "%d%02d",
                            $century - ($year > $twodigits_year ? 1 : 0),
                            $year;
    }
    return $self->{year};
}

sub year_c {
    my $self = shift;
    my ($ycx) = @_;
    if (defined $ycx) {
        my $yc = $self->_xnums($ycx);
        unless ($yc =~ /^\d\d$/) {
            $self->error('A year in Codice Fiscale is 2 digit long');
            return;
        }
        $self->{year_c} = $ycx;
        $self->{year} = undef;
    }
    if (not defined $self->{year_c} and defined $self->{year}) {
        $self->{year_c} = sprintf("%02d", $self->{year} % 100);
    }
    return $self->{year_c};
}

sub month {
    my $self = shift;
    my ($m) = @_;
    if (defined $m) {
        unless ($m =~ /^\d+$/ and $m >= 1 and $m <= 12) {
            $self->error('Month must be numeric and between 1 and 12');
            return;
        }
        $self->{month} = $m;
        $self->{month_c} = undef;
    }
    if (not defined $self->{month} and defined $self->{month_c}) {
        $self->{month} = $MONTHS{$self->{month_c}};
    }
    return $self->{month};
}

sub month_c {
    my $self = shift;
    my ($mc) = @_;
    if (defined $mc) {
        unless ($mc =~ /^[$MONTHS]$/o) {
            $self->error('Month not correctly encoded');
            return;
        }
        $self->{month_c} = $mc;
        $self->{month} = undef;
    }
    if (not defined $self->{month_c} and defined $self->{month}) {
        $self->{month_c} = $MONTHS[$self->{month}];
    }
    return $self->{month_c};
}

sub day {
    my $self = shift;
    my ($d) = @_;
    if (defined $d) {
        unless ($d =~ /^\d+$/ and 1 <= $d and $d <= 31) {
            $self->error('Day is out of range');
            return;
        }
        $self->{day} = $d;
        $self->{day_c} = undef;
    }
    if (not defined $self->{day} and defined $self->{day_c}) {
        my $dayx = $self->_xnums($self->{day_c});
        $self->{day} = $dayx > 40 ? $dayx - 40 : $dayx;
    }
    return $self->{day};
}

sub day_c {
    my $self = shift;
    my ($dcx) = @_;
    if (defined $dcx) {
        my $dc = $self->_xnums($dcx);
        unless ($dc =~ /^\d+$/) {
            $self->error('Invalid coding of day');
            return;
        }
        unless ($dc > 0 and not ($dc > 31 and $dc < 41) and $dc <= 71) {
            $self->error('Day out of range');
            return;
        }
        $self->{day_c} = $dcx;
        $self->{day} = undef;
        $self->{sex} = undef;
    }
    if (not defined $self->{day_c} and defined $self->{day}
                                    and defined $self->{sex}) {
        $self->{day_c} = $self->{day};
        $self->{day_c} += 40 if $self->{sex} eq 'F';
        $self->{day_c} = sprintf("%02d", $self->{day_c});
    }
    return $self->{day_c};
}

sub sex {
    my $self = shift;
    my ($sex) = @_;
    if (defined $sex) {
        unless ($sex =~ /^[MF]$/i) {
            $self->error('Sex can be either "M" or "F"');
            return;
        }
        $self->{sex} = $sex;
        $self->{day_c} = undef;
    }
    if (not defined $self->{sex} and defined $self->{day_c}) {
        my $dayx = $self->_xnums($self->{day_c});
        $self->{sex} = $dayx > 40 ? 'F' : 'M';
    }
    return $self->{sex};
}

sub bp {
    my $self = shift;
    my ($bp) = @_;
    if (defined $bp) {
        unless ($bp =~ /^[A-Z]\d\d\d$/) { # to improve further?
            $self->error('Invalid birthplace code');
            return;
        }
        $self->{bp} = $bp;
        $self->{bp_c} = undef;
    }
    if (not defined $self->{bp} and defined $self->{bp_c}) {
        my $bpc = $self->{bp_c};
        substr($bpc, 1) = $self->_xnums(substr($bpc, 1));
        $self->{bp} = $bpc;
    }
    return $self->{bp};
}

sub bp_c {
    my $self = shift;
    my ($bpcx) = @_;
    if (defined $bpcx) {
        my $bpc = $bpcx;
        substr($bpc, 1) = $self->_xnums(substr($bpc, 1));
        unless ($bpc =~ /^[A-Z]\d\d\d$/) { # to improve further?
            $self->error('Invalid birthplace code');
            return;
        }
        $self->{bp_c} = $bpcx;
        $self->{bp} = undef;
    }
    if (not defined $self->{bp_c} and defined $self->{bp}) {
        $self->{bp_c} = $self->{bp};
    }
    return $self->{bp_c};
}

sub bd_c {
    my $self = shift;
    my $bdc = '';
    for (qw(year_c month_c day_c)) {
        my $t = $self->$_;
        unless (defined $t) {
            $self->error("Could not produce $_: some data is missing");
            return;
        }
        $bdc .= $t;
    }
    return $bdc;
}

sub cf {
    my ($self, $dupe) = (@_);
    return $self->_crc(1, $dupe);
}

sub crc {
    my $self = shift;
    return $self->_crc(0);
}

sub cf_nocrc {
    my $self = shift;
    my $cf = '';
    for (qw(sn_c fn_c bd_c bp_c)) {
        my $t = $self->$_;
        unless (defined $t) {
            $self->error("Could not produce $_: some data is missing");
            return;
        }
        $cf .= $t;
    }
    
    return $cf;
}

sub _crc {
    my $self = shift;
    my ($cf_out, $dupe) = @_;
    my $cf = $self->cf_nocrc;
    unless ($cf) {
        $self->error("Cannot produce a Codice Fiscale: missing data");
        return;
    }
    if ($dupe) {
        $dupe %= 128;
        my @bitmap = split('', sprintf("%07b", _bmaker($dupe)));
        my ($tcf, $i) = ($cf, 0);
        while ($cf =~ /(\d)/g) {
            substr($tcf, pos($cf) - 1, 1, $XNUMS[$1]) if $bitmap[$i];
            $i++
        }
        $cf = $tcf;
    }
    my $count = 0;
    for (my $i = 0; $i <= 14; $i++) {
        $count += $CRC{substr($cf, $i, 1)}[($i + 1) % 2];
    }
    $count %= 26;
    return ($cf_out ? $cf : '') . chr(65 + $count);
}


sub parse {
    my $proto = shift;
    my ($cf) = @_;
    $cf = uc $cf;
    unless (length($cf) == 16) {
        $proto->error('A valid Codice Fiscale must be exactly 16 chars long');
        return;
    }
    my ($sn, $fn, $year, $month, $dayx, $born, $crc) = $cf =~ /$RE_cf/;
    unless ($crc) {
        $proto->error('Cannot parse: invalid format');
        return;
    }

    my $obj = $proto->new(
        sn_c    =>  $sn,
        fn_c    =>  $fn,
        year_c  =>  $year,
        month_c =>  $month,
        day_c   =>  $dayx,
        bp_c    =>  $born,
    );

    unless ($crc eq $obj->crc) {
        $proto->error('Invalid control character'); 
        return;
    }
    return $obj;
}

sub validate {
    my $proto = shift;
    my ($cf) = @_;
    my $obj = $proto->parse($cf);
    return 1 if $obj;
    return;
}


sub error {
    my $proto = shift;
    my ($err) = @_;
    if (ref $proto) {
        $proto->{_err} = $err if defined $err;
        return $proto->{_err};
    }
    
    $proto->ERROR($err) if defined $err;
    return $proto->ERROR;
}

{

my $tr_xnums = eval "sub {\$_[0] =~ tr/$XNUMS/0123456789/}";

sub _xnums {
    my $self = shift;
    my ($nums) = @_;
    return unless $nums =~ /^[\d$XNUMS]+$/o;
    $tr_xnums->($nums);
    return $nums;
}

}

sub _n_re {
    my $self = shift;
    my ($method) = @_;
    (my $attr = $method) =~ s/_c$/_re/;
    return $self->{$attr} if defined $self->{$attr};
    my $nc = $self->$method;
    unless ($nc) {
        $self->error('There is no coded ' . 
            ($method eq 'sn_c' ? 'sur' : '') . 'name set');
        return;
    }
    
    my ($c, $v, $x) = $nc =~ /^([$CONSONANTS]*)([$VOWELS]*)(X*)$/o;
    my $pat;

    if (3 == length $c) {
        my @c = split('', $c);
        if ($method eq 'fn_c') {
            $pat = qr/^(?:
                [$VOWELS]* $c[0] [$VOWELS]* 
                [$CONSONANTS] [$VOWELS]* 
                $c[1] [$VOWELS]*
                $c[2] [A-Z]*
                |
                [$VOWELS]* $c[0] [$VOWELS]*
                $c[1] [$VOWELS]*
                $c[2] [$VOWELS]*
            )$/xi;
        } else {
            $pat = qr/^
                [$VOWELS]* $c[0] [$VOWELS]* 
                $c[1] [$VOWELS]* 
                $c[2] [A-Z]*
            $/xi;
        }
    } elsif (2 == length($c) and 1 == length($v)) {
        my @c = split('', $c);
        $pat = qr/^(?:
            $v [$VOWELS]* $c[0] [$VOWELS]* $c[1] [$VOWELS]*
            |
            $c[0] $v [$VOWELS]* $c[1] [$VOWELS]*
            |
            $c[0] $c[1] $v [$VOWELS]*
        )$/xi;
    } elsif (1 == length($c) and 2 == length($v)) {
        my @v = split('', $v);
        $pat = qr/^(?:
            $c $v[0] $v[1] [$VOWELS]*
            |
            $v[0] $c $v[1] [$VOWELS]*
            |
            $v[0] $v[1] [$VOWELS]* $c [$VOWELS]*
        )$/xi;
    } elsif (3 == length $v) {
        $pat = qr/^ $v [$VOWELS]* $/xi;
    } elsif (1 == length $x) {
        if (1 == length($c)) {
            $pat = qr/^(?: $c $v | $v $c )$/xi;
        } else {
            $pat = qr/^ $v $/xi;
        }
    } elsif (2 == length $x) {
        $pat = qr/^ $v $/xi;
    } else {
        $pat = qr/^ .* $/xi;
    }
    
    return $self->{$attr} = $pat;
}

sub _fix_name {
    $_[1] =~ tr/àÀèéÈÉìÌòÒùÙ/AAEEEEIIOOUU/;
    $_[1] =~ tr/a-zA-Z//cd;
}

sub _bmaker {
    my ($value, $bit_length, $bits2use, $root, $c) = @_;
    unless (defined $c) {
        my $cc = 0;
        $c = \$cc;
    }
    $bits2use ||= 1;
    $root = 1 unless defined $root;
    $bit_length ||= 7;

    my $b = 0; my $sum = 0;

    while ($root) {  # the root function increases the number of encoded chars
        $sum = _bmaker($value, $bit_length, $bits2use, 0, $c);
        return $sum if $$c == $value;
        $bits2use++;
        croak("Something went terribly wrong") if $bits2use > $bit_length;
    }
    
    while ($b <= ($bit_length - $bits2use)) { #we recursively move the 
                                              #encoded chars to the left
        if ($bits2use > 1) {
            $sum = _bmaker($value, $bit_length - 1 - $b, $bits2use - 1, 0, $c);
        } else {
            $$c++;
        }
            #when we reach the desired value, we sum the "bits" in a number
            #to be used as a binary bitmap for which chars to substitute
        return 2 ** ($b+1) * $sum + 2 ** $b if $$c == $value;
        $b++;
    }
    
    return $sum;
}



{

my $count_consonants = eval "sub {\$_[0] =~ tr/$CONSONANTS/$CONSONANTS/}";

sub _count_consonants { return $count_consonants->($_[1]) }

}


sub _croak {
    my $self = shift;
    confess @_;
}

1;
__END__

=head1 NAME

String::CodiceFiscale - convert personal data into italian Codice Fiscale

=head1 SYNOPSIS

 use String::CodiceFiscale;
  
 $obj = String::CodiceFiscale->new(
     sn      =>  'Wall',         # surname
     fn      =>  'Larry',        # first name
     date    =>  '1987-12-18',   # Perl's birthday
     sex     =>  'M',            # M or F
     bp      =>  'Z404',         # birthplace, Codice Catastale code
 );
 
 print $obj->cf, "\n";           # prints Codice Fiscale
 
 # and the other way around
 
 $obj = String::CodiceFiscale->parse('WLLLRY87T18Z404B');
 
 unless ($obj) {                 # check for errors
    print "We have an error: " . String::CodiceFiscale->error;
 }
 
 print "This person identifies as " . 
    ($obj->sex eq 'M' ? 'male' : 'female') . 
    " and was born on " . $obj->date . " (unless he's more than 100)\n"; 

 for (qw(Wallace Wall Weeler Awalala)) {
     print "$_\t could be his surname\n" if $obj->sn_match($_);
 }

 for (qw(Ilary Elryk Larry Kilroy Leroy)) {
     print "$_\t could be his first name\n" if $obj->fn_match($_);
 }
 

=head1 DESCRIPTION

String::CodiceFiscale might help you in the tricky task of verifying
and/or producing a Codice Fiscale. It also gives you some utilities
to "reverse engineer" a given Codice Fiscale and find out what personal
data could have produce it.

For more info about the Codice Fiscale format see the Appendix.
Please note that [] "square brackets" in the following documentation
will mark optional parameters and not anonymous array references.

=head1 CLASS METHODS

=over 4

=item new([%PARAMS])

Creates a new object. It receives parameters in hash
fashion and will use every key of the hash as an object method called
with the respective value. See below for possible methods.

=item parse(CF)

Creates a new object from parsing the given STRING as a Codice Fiscale.
It won't return a valid object if the given Codice Fiscale won't pass
some validation checks. Please note that this method will try
to handle gently and accept Codice Fiscale which contain special
characters in the normally numeric fields (birth year and day, last
three digits of the codice catastale code) while the set methods below
will only accept numeric values in the same fields.


=item validate(CF)

Utility method. It will return a true value if STRING is a valid
Codice Fiscale. Unless it will return a false value.

=item error()

Returns a string containing a descriptive error of what went wrong 
during the last failed call to a class method.

=back

=head1 OBJECT METHODS

All get/set methods give you back the actual value of the attribute.
If you provide a STRING they will try to set the attribute after
some validation checks. If these checks fail the method will return
a false value. Otherwise it will return the value you provided.

=head2 GET/SET METHODS

=over 4

=item sn([SURNAME])

Get/set method to retrieve or set the surname.

=item fn([FIRST_NAME])

Get/set method to retrieve or set the first name.

=item date([YYYY-MM-DD])

Get/set the date of birth. It can parse only dates provided in the ISO 8601
format (YYYY-MM-DD). The year could have the same problems discussed 
in the year() method.

=item year([YEAR])

Get/set method for year. Please note that Codice Fiscale code HAS the 
Millenium Bug. So if you're asking for a year after parsing a codice
fiscale what you will get will be a guess about what the year of birth is:
this could be wrong for people older than 100.

=item month([MONTH])

Get/set method to retrieve or set the month.

=item day([DAY_OF_MONTH])

Get/set method to retrieve or set the day of month.

=item sex([SEX])

Get/set method for sex. Accept "M" for male and "F" for female.

=item bp([BIRTH_PLACE])

Get/set method for birthplace. The birthplace must be already encoded
in the codice catastale form and match /^[A-Z]\d\d\d$/ .
No lookup of city names is provided yet.

=back

=head2 ENCODING METHODS

=over 4

=item cf([DUPLICATE_NUMBER])

Try to give you a valid codice fiscale. It will return a false value
if some data is missing.
Note how the generated codice fiscale has no warranty to be unique.
By passing a DUPLICATE_NUMBER as an optional parameter,
the library will try to generate a Codice Fiscale using special
characters to avoid collisions. "0" will return the default
Codice Fiscale. From 1 onward the library will substitute special
characters to create unique codes. Please note that while the algorithm
to determine the default Codice Fiscale for the first 7 duplicates
is easily understood, after the 8th duplicate it's just guesswork
on my part. 

=item crc

Gives back just the control character. Return a false value on failure.

=back

=head2 REVERSE ENGINEERING METHODS

=over 4

=item sn_match(STRING)

Matches if STRING could be the surname that was used to generate the
codice fiscale previously acquired through the parse() method.
Please beware that there are infinite surnames
that could produce the same coding in codice fiscale.

=item fn_match(STRING)

Matches if STRING could be the first name that was used to generate the
codice fiscale previously acquired through the parse() method.
See sn_match() for more info.

=back

=head1 APPENDIX

Yet to be written. It would likely contain more info and caveats about
the codice fiscale algorithm.

=head1 TO DO

- Perfect the error handling 

- Write more documentation and clear up obscure points
 
- Create alias for methods whose names are less than obvious

- Italian documentation and italian aliases

=head1 AUTHOR

Giulio Motta, E<lt>giulienk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2020 by Giulio Motta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

