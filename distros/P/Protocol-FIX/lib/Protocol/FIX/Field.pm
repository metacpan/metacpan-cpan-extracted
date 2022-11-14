package Protocol::FIX::Field;

use strict;
use warnings;

use Protocol::FIX;

our $VERSION = '0.07';    ## VERSION

=head1 NAME

Protocol::FIX::Field - FIX Message Field

=head1 Description

The following field types are known to the class. Validators are provided.

 AMT
 BOOLEAN
 CHAR
 COUNTRY
 CURRENCY
 DATA
 EXCHANGE
 FLOAT
 INT
 LENGTH
 LOCALMKTDATE
 MONTHYEAR
 MULTIPLEVALUESTRING
 NUMINGROUP
 PERCENTAGE
 PRICE
 PRICEOFFSET
 QTY
 SEQNUM
 STRING
 UTCDATEONLY
 UTCTIMEONLY
 UTCTIMESTAMP

=cut

# anyting defined and not containing delimiter
my $BOOLEAN_validator  = sub { defined($_[0]) && $_[0] =~ /^[YN]$/ };
my $STRING_validator   = sub { defined($_[0]) && $_[0] !~ /$Protocol::FIX::TAG_SEPARATOR/ };
my $INT_validator      = sub { defined($_[0]) && $_[0] =~ /^-?\d+$/ };
my $LENGTH_validator   = sub { defined($_[0]) && $_[0] =~ /^\d+$/ && $_[0] > 0 };
my $DATA_validator     = sub { defined($_[0]) && length($_[0]) > 0 };
my $FLOAT_validator    = sub { defined($_[0]) && $_[0] =~ /^-?\d+(\.?\d*)$/ };
my $CHAR_validator     = sub { defined($_[0]) && $_[0] =~ /^[^$Protocol::FIX::TAG_SEPARATOR]$/ };
my $CURRENCY_validator = sub { defined($_[0]) && $_[0] =~ /^[^$Protocol::FIX::TAG_SEPARATOR]{3}$/ };
my $COUNTRY_validator  = sub { defined($_[0]) && $_[0] =~ /^[A-Z]{2}$/ };

my $MONTHYEAR_validator = sub {
    my $d = shift;
    # YYYYMM
    # YYYYMMDD
    # YYYYMMWW
    my $ym_valid =
           defined($d)
        && $d =~ /^(\d{4})(\d{2})([w\d]\d)?$/
        && ($2 >= 1)
        && ($2 <= 12);

    return unless $ym_valid;

    my $r = $3;
    return 1 unless $r;

    return ($r =~ /^w[1-6]$/)
        || (($r =~ /^\d{2}$/) && ($r >= 1) && ($r <= 31));
};

my $LOCALMKTDATE_validator = sub {
    my $d = shift;
    # YYYYMMDD
    return
           defined($d)
        && $d =~ /^(\d{4})(\d{2})(\d{2})$/
        && ($2 >= 1)
        && ($2 <= 12)
        && ($3 >= 1)
        && ($3 <= 31);
};

my $UTCTIMESTAMP_validator = sub {
    my $t = shift;
    # YYYYMMDD-HH:MM:SS
    # YYYYMMDD-HH:MM:SS.sss
    if (defined($t) && $t =~ /^(\d{4})(\d{2})(\d{2})-(\d{2}):(\d{2}):(\d{2})(\.\d{3})?$/) {
        return
               ($2 >= 1)
            && ($2 <= 12)
            && ($3 >= 1)
            && ($3 <= 31)
            && ($4 >= 0)
            && ($4 <= 23)
            && ($5 >= 0)
            && ($5 <= 59)
            && ($6 >= 0)
            && ($5 <= 60);

    } else {
        return;
    }
};

my $UTCTIMEONLY_validator = sub {
    # HH:MM:SS
    # HH:MM:SS.sss
    my $t = shift;
    if (defined($t) && $t =~ /^(\d{2}):(\d{2}):(\d{2})(\.\d{3})?$/) {
        return
               ($1 >= 0)
            && ($1 <= 23)
            && ($2 >= 0)
            && ($2 <= 59)
            && ($3 >= 0)
            && ($3 <= 60);
    } else {
        return;
    }
};

my %per_type = (
    BOOLEAN             => $BOOLEAN_validator,
    CHAR                => $CHAR_validator,
    STRING              => $STRING_validator,
    MULTIPLEVALUESTRING => $STRING_validator,
    EXCHANGE            => $STRING_validator,
    INT                 => $INT_validator,
    SEQNUM              => $INT_validator,
    LENGTH              => $LENGTH_validator,
    NUMINGROUP          => $LENGTH_validator,
    DATA                => $DATA_validator,
    FLOAT               => $FLOAT_validator,
    AMT                 => $FLOAT_validator,
    PERCENTAGE          => $FLOAT_validator,
    PRICE               => $FLOAT_validator,
    QTY                 => $FLOAT_validator,
    PRICEOFFSET         => $FLOAT_validator,
    CURRENCY            => $CURRENCY_validator,
    UTCTIMESTAMP        => $UTCTIMESTAMP_validator,
    LOCALMKTDATE        => $LOCALMKTDATE_validator,
    UTCDATEONLY         => $LOCALMKTDATE_validator,
    MONTHYEAR           => $MONTHYEAR_validator,
    UTCTIMEONLY         => $UTCTIMEONLY_validator,
    COUNTRY             => $COUNTRY_validator,
);

=head1 METHODS (for protocol developers)

=head3 new

    new($class, $number, $name, $type, $values)

Creates new Field (performed by Protocol, when it parses XML definition)

=cut

sub new {
    my ($class, $number, $name, $type, $values) = @_;

    die "Unsupported field type '$type'"
        unless exists $per_type{$type};

    my $obj = {
        number => $number,
        name   => $name,
        type   => $type,
    };

    if ($values) {
        my $reverse_values = {};
        @{$reverse_values}{values %$values} = keys %$values;
        $obj->{values} = {
            by_id   => $values,
            by_name => $reverse_values,
        };
    }

    return bless $obj, $class;
}

=head3 check

    check($self, $value)

Returns C<true > or C<false> if the supplied value conforms type.

If type has enumeration (i.e. "B" for "BID" and "O" for "OFFER"),
then it expects that human-readable value ("BID" / "OFFER") will be
provided as C<$value>. The values "B" or "O" will not bypass
the check.

This method is used during message serialization L<Message/"serialize">.

=cut

sub check {
    my ($self, $value) = @_;

    my $result =
        $self->{values}
        ? (defined($value) && exists $self->{values}->{by_name}->{$value})
        : $per_type{$self->{type}}->($value);

    return $result;
}

=head3 has_mapping

    has_mapping($self)

returns true if field has enumeration

=cut

sub has_mapping {
    my $self = shift;
    return exists $self->{values};
}

=head3 check_raw

    check_raw($self, $value)

Returns C<true > or C<false> if the supplied value conforms type.

If type has enumeration (i.e. "B" for "BID" and "O" for "OFFER"),
then it expects that enum value ("B" / "O") will be
provided as C<$value>. The values "BID" or "OFFER" will not bypass
the check.

This method is used during message deserialization L<FIX/"parse">.

=cut

sub check_raw {
    my ($self, $value) = @_;

    my $result =
        $self->{values}
        ? (defined($value) && exists $self->{values}->{by_id}->{$value})
        : $per_type{$self->{type}}->($value);

    return $result;
}

=head3 serialize

    serialize($self, $values)

Serializes field value. If the value does not bypasses the type check,
an exception will be thrown.

=cut

sub serialize {
    my ($self, $value) = @_;

    my $packed_value = $self->{values}
        ? do {
        my $id = $self->{values}->{by_name}->{$value};
        die("The value '$value' is not acceptable for field " . $self->{name})
            unless defined $id;
        $id;
        }
        : $value;
    die("The value '$value' is not acceptable for field " . $self->{name})
        unless $self->check($value);

    return $self->{number} . '=' . $packed_value;
}

1;
