package QBit::Validator::Type::scalar;
$QBit::Validator::Type::scalar::VERSION = '0.012';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator;
use Exception::Validator::FailedField;

#order is important
sub get_options_name {
    qw(type eq regexp min max len_min len len_max in);
}

sub type {
    my ($qv, $types) = @_;

    return sub {
        throw FF gettext('Data must be SCALAR') if ref($_[1]);

        return TRUE;
      }
}

sub eq {
    my ($qv, $val) = @_;

    if (defined($val)) {
        throw Exception::Validator gettext('Option "%s" must be numeric', 'eq')
          unless looks_like_number($val);

        return sub {
            throw FF gettext('Data must be defined') unless defined($_[1]);

            throw FF gettext('Data must be numeric, but got "%s"', $_[1])
              unless looks_like_number($_[1]);

            throw FF gettext('Got value "%s" not equal "%s"', $_[1], $val) unless $_[1] == $val;

            return TRUE;
        };
    } else {
        return sub {
            throw FF gettext('Data must be null') if defined($_[1]);

            return TRUE;
          }
    }
}

sub regexp {
    my ($qv, $regexp) = @_;

    throw Exception::Validator gettext('Option "%s" must be type "Regexp"', 'regexp')
      if !defined($regexp) || ref($regexp) ne 'Regexp';

    return sub {
        throw FF gettext('Got value "%s" do not fit the regular expression', $_[1]) if $_[1] !~ $regexp;

        return TRUE;
    };
}

sub min {
    my ($qv, $min) = @_;

    throw Exception::Validator gettext('Option "%s" must be numeric', 'min')
      unless looks_like_number($min);

    return sub {
        throw FF gettext('The data must be numeric, but got "%s"', $_[1]) unless looks_like_number($_[1]);

        throw FF gettext('Got value "%s" less then "%s"', $_[1], $min) if $_[1] < $min;

        return TRUE;
      }
}

sub max {
    my ($qv, $max) = @_;

    throw Exception::Validator gettext('Option "%s" must be numeric', 'max')
      unless looks_like_number($max);

    return sub {
        throw FF gettext('The data must be numeric, but got "%s"', $_[1]) unless looks_like_number($_[1]);

        throw FF gettext('Got value "%s" more than "%s"', $_[1], $max) if $_[1] > $max;

        return TRUE;
      }
}

sub len_min {
    my ($qv, $len_min) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', 'len_min')
      if !defined($len_min) || $len_min !~ /\A[0-9]+\z/;

    return sub {
        throw FF gettext('Length "%s" less then "%s"', $_[1], $len_min) if length($_[1]) < $len_min;

        return TRUE;
      }
}

sub len {
    my ($qv, $len) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', 'len_max')
      if !defined($len) || $len !~ /\A[0-9]+\z/;

    return sub {
        throw FF gettext('Length "%s" not equal "%s"', $_[1], $len) unless length($_[1]) == $len;

        return TRUE;
    };
}

sub len_max {
    my ($qv, $len_max) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', 'len_max')
      if !defined($len_max) || $len_max !~ /\A[0-9]+\z/;

    return sub {
        throw FF gettext('Length "%s" more than "%s"', $_[1], $len_max) if length($_[1]) > $len_max;

        return TRUE;
      }
}

sub in {
    my ($qv, $in) = @_;

    throw Exception::Validator gettext('Key "%s" must be defined', 'in') unless defined($in);

    if (ref($in) eq '') {
        return sub {
            throw FF gettext('Got value "%s" not in array: %s', $_[1], $in) unless $_[1] eq $in;

            return TRUE;
        };
    } elsif (ref($in) eq 'ARRAY') {
        my %dictionary = ();
        my $dictionary_str = join(', ', map {$dictionary{$_} = TRUE; $_} @$in);

        sub {
            throw FF gettext('Got value "%s" not in array: %s', $_[1], $dictionary_str) unless $dictionary{$_[1]};

            return TRUE;
          }
    } else {
        throw Exception::Validator gettext('Key "%s" must be SCALAR or ARRAY', 'in') unless defined($in);
    }
}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    foreach ($self->get_options_name) {
        $self->{$_} = \&$_;
    }
}

TRUE;
