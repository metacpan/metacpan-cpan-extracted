package Rstats::Util;

use strict;
use warnings;
use Carp 'croak';

require Rstats::Element::NA;
require Rstats::Element::Logical;
require Rstats::Element::Complex;
require Rstats::Element::Character;
require Rstats::Element::Integer;
require Rstats::Element::Double;
use Scalar::Util ();
use B ();
use Math::Complex ();
use POSIX ();

# Special values
my $na = Rstats::Element::NA->new;
my $nan = Rstats::Element::Double->new(flag => 'nan');
my $inf = Rstats::Element::Double->new(flag => 'inf');
my $negative_inf = Rstats::Element::Double->new(flag => '-inf');
my $true = logical(1);
my $false = logical(0);

# Address
my $true_ad = Scalar::Util::refaddr $true;
my $false_ad = Scalar::Util::refaddr $false;
my $na_ad = Scalar::Util::refaddr $na;
my $nan_ad = Scalar::Util::refaddr $nan;
my $inf_ad = Scalar::Util::refaddr $inf;
my $negative_inf_ad = Scalar::Util::refaddr $negative_inf;

sub TRUE { $true }
sub FALSE { $false }
sub NA { $na }
sub NaN { $nan }
sub Inf { $inf }
sub negativeInf { $negative_inf }

sub is_nan { ref $_[0] && (Scalar::Util::refaddr $_[0] == $nan_ad) }
sub is_na { ref $_[0] && (Scalar::Util::refaddr $_[0] == $na_ad) }
sub is_infinite { is_positive_infinite($_[0]) || is_negative_infinite($_[0]) }
sub is_positive_infinite { ref $_[0] && (Scalar::Util::refaddr $_[0] == $inf_ad) }
sub is_negative_infinite { ref $_[0] && (Scalar::Util::refaddr $_[0] == $negative_inf_ad) }
sub is_finite {
  return is_integer($_[0]) || (is_double($_[0]) && defined $_[0]->value);
}

sub is_character { ref $_[0] eq 'Rstats::Element::Character' }
sub is_complex { ref $_[0] eq 'Rstats::Element::Complex' }
sub is_double { ref $_[0] eq 'Rstats::Element::Double' }
sub is_integer { ref $_[0] eq 'Rstats::Element::Integer' }
sub is_logical { ref $_[0] eq 'Rstats::Element::Logical' }

sub character { Rstats::Element::Character->new(value => shift) }
sub complex {
  my ($re_value, $im_value) = @_;
  
  my $re = double($re_value);
  my $im = double($im_value);
  my $z = complex_double($re, $im);
  
  return $z;
}
sub complex_double {
  my ($re, $im) = @_;
  
  my $z = Rstats::Element::Complex->new(re => $re, im => $im);
}
sub double { Rstats::Element::Double->new(value => shift, flag => shift || 'normal') }
sub integer { Rstats::Element::Integer->new(value => int(shift)) }
sub logical { Rstats::Element::Logical->new(value => shift) }

sub looks_like_number {
  my $value = shift;
  
  return if !defined $value || !CORE::length $value;
  $value =~ s/^ +//;
  $value =~ s/ +$//;
  
  if (Scalar::Util::looks_like_number $value) {
    return $value + 0;
  }
  else {
    return;
  }
}

sub looks_like_complex {
  my $value = shift;
  
  return if !defined $value || !CORE::length $value;
  $value =~ s/^ +//;
  $value =~ s/ +$//;
  
  my $re;
  my $im;
  
  if ($value =~ /^([\+\-]?[^\+\-]+)i$/) {
    $re = 0;
    $im = $1;
  }
  elsif($value =~ /^([\+\-]?[^\+\-]+)(?:([\+\-][^\+\-i]+)i)?$/) {
    $re = $1;
    $im = $2;
    $im = 0 unless defined $im;
  }
  else {
    return;
  }
  
  if (defined Rstats::Util::looks_like_number($re) && defined Rstats::Util::looks_like_number($im)) {
    return {re => $re + 0, im => $im + 0};
  }
  else {
    return;
  }
}

sub element {
  my $value = shift;
  
  if (!ref $value) {
    if (is_perl_number($value)) {
      return double($value);
    }
    else {
      return character($value);
    }
  }
  else {
    return $value;
  }
  if (is_character($value) || is_integer($value) || is_double($value)) {
    return $value->value;
  }
  else {
    return $value;
  }
}

sub value {
  my $element = shift;
  
  if (is_character($element)
    || is_integer($element)
    || (is_double($element) && !is_nan($element) && !is_infinite($element))
  ) {
    return $element->value;
  }
  elsif (is_complex($element)) {
    return {
      re => value($element->re),
      im => value($element->im)
    };
  }
  else {
    return $element;
  }
}

sub is_perl_number {
  my ($value) = @_;
  
  return unless defined $value;
  
  return B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK) 
        && 0 + $value eq $value
        && $value * 0 == 0
}

sub to_string {
  my $element = shift;
  
  if (is_na($element)) {
    return 'NA';
  }
  elsif (is_character($element)) {
    return $element->value . "";
  }
  elsif (is_complex($element)) {
    my $re = to_string($element->re);
    my $im = to_string($element->im);
    
    my $str = "$re";
    $str .= '+' if $im >= 0;
    $str .= $im . 'i';
  }
  elsif (is_double($element)) {
    
    my $flag = $element->flag;
    
    if (defined $element->value) {
      return $element->value . "";
    }
    elsif ($flag eq 'nan') {
      return 'NaN';
    }
    elsif ($flag eq 'inf') {
      return 'Inf';
    }
    elsif ($flag eq '-inf') {
      return '-Inf';
    }
  }
  elsif (is_integer($element)) {
    return $element->value . "";
  }
  elsif (is_logical($element)) {
    return $element->value ? 'TRUE' : 'FALSE'
  }
  else {
    croak "Invalid type";
  }
}

sub negation {
  my $element1 = shift;
  
  if (is_na($element1)) {
    return NA;
  }
  elsif (is_character($element1)) {
    croak 'argument is not interpretable as logical'
  }
  elsif (is_complex($element1)) {
    return complex_double(negation($element1->re), negation($element1->im));
  }
  elsif (is_double($element1)) {
    
    my $flag = $element1->flag;
    if (defined $element1->value) {
      return double(-$element1->value);
    }
    elsif ($flag eq 'nan') {
      return NaN;
    }
    elsif ($flag eq 'inf') {
      return negativeInf;
    }
    elsif ($flag eq '-inf') {
      return Inf;
    }
  }
  elsif (is_integer($element1) || is_logical($element1)) {
    return integer(-$element1->value);
  }
  else {
    croak "Invalid type";
  }  
}

sub bool {
  my $element1 = shift;
  
  if (is_na($element1)) {
    croak "Error in bool context (a) { : missing value where TRUE/FALSE needed"
  }
  elsif (is_character($element1) || is_complex($element1)) {
    croak 'Error in -a : invalid argument to unary operator ';
  }
  elsif (is_double($element1)) {

    if (defined $element1->value) {
      return $element1->value;
    }
    else {
      if (is_infinite($element1)) {
        1;
      }
      # NaN
      else {
        croak 'argument is not interpretable as logical'
      }
    }
  }
  elsif (is_integer($element1) || is_logical($element1)) {
    return $element1->value;
  }
  else {
    croak "Invalid type";
  }  
}

sub add {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    croak "Error in a + b : non-numeric argument to binary operator";
  }
  elsif (is_complex($element1)) {
    my $re = add($element1->{re}, $element2->{re});
    my $im = add($element1->{im}, $element2->{im});
    
    return complex($re->value, $im->value);
  }
  elsif (is_double($element1)) {
    return NaN if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return double($element1->value + $element2->value);
      }
      elsif (is_positive_infinite($element2)) {
        return Inf;
      }
      elsif (is_negative_infinite($element2)) {
        return negativeInf;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return Inf;
      }
      elsif (is_positive_infinite($element2)) {
        return Inf;
      }
      elsif (is_negative_infinite($element2)) {
        return NaN;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return negativeInf;
      }
      elsif (is_positive_infinite($element2)) {
        return NaN;
      }
      elsif (is_negative_infinite($element2)) {
        return negativeInf;
      }
    }
  }
  elsif (is_integer($element1)) {
    return integer($element1->value + $element2->value);
  }
  elsif (is_logical($element1)) {
    return integer($element1->value + $element2->value);
  }
  else {
    croak "Invalid type";
  }
}

sub subtract {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    croak "Error in a + b : non-numeric argument to binary operator";
  }
  elsif (is_complex($element1)) {
    my $re = subtract($element1->{re}, $element2->{re});
    my $im = subtract($element1->{im}, $element2->{im});
    
    return complex_double($re, $im);
  }
  elsif (is_double($element1)) {
    return NaN if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return double($element1->value - $element2->value);
      }
      elsif (is_positive_infinite($element2)) {
        return negativeInf;
      }
      elsif (is_negative_infinite($element2)) {
        return Inf;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return Inf;
      }
      elsif (is_positive_infinite($element2)) {
        return NaN;
      }
      elsif (is_negative_infinite($element2)) {
        return Inf;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return negativeInf;
      }
      elsif (is_positive_infinite($element2)) {
        return negativeInf;
      }
      elsif (is_negative_infinite($element2)) {
        return NaN;
      }
    }
  }
  elsif (is_integer($element1)) {
    return integer($element1->value + $element2->value);
  }
  elsif (is_logical($element1)) {
    return integer($element1->value + $element2->value);
  }
  else {
    croak "Invalid type";
  }
}

sub multiply {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    croak "Error in a + b : non-numeric argument to binary operator";
  }
  elsif (is_complex($element1)) {
    my $re = double($element1->re->value * $element2->re->value - $element1->im->value * $element2->im->value);
    my $im = double($element1->re->value * $element2->im->value + $element1->im->value * $element2->re->value);
    
    return complex_double($re, $im);
  }
  elsif (is_double($element1)) {
    return NaN if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return double($element1->value * $element2->value);
      }
      elsif (is_positive_infinite($element2)) {
        if ($element1->value == 0) {
          return NaN;
        }
        elsif ($element1->value > 0) {
          return Inf;
        }
        elsif ($element1->value < 0) {
          return negativeInf;
        }
      }
      elsif (is_negative_infinite($element2)) {
        if ($element1->value == 0) {
          return NaN;
        }
        elsif ($element1->value > 0) {
          return negativeInf;
        }
        elsif ($element1->value < 0) {
          return Inf;
        }
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        if ($element2->value == 0) {
          return NaN;
        }
        elsif ($element2->value > 0) {
          return Inf;
        }
        elsif ($element2->value < 0) {
          return negativeInf;
        }
      }
      elsif (is_positive_infinite($element2)) {
        return Inf;
      }
      elsif (is_negative_infinite($element2)) {
        return negativeInf;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        if ($element2->value == 0) {
          return NaN;
        }
        elsif ($element2->value > 0) {
          return negativeInf;
        }
        elsif ($element2->value < 0) {
          return Inf;
        }
      }
      elsif (is_positive_infinite($element2)) {
        return negativeInf;
      }
      elsif (is_negative_infinite($element2)) {
        return Inf;
      }
    }
  }
  elsif (is_integer($element1)) {
    return integer($element1->value * $element2->value);
  }
  elsif (is_logical($element1)) {
    return integer($element1->value * $element2->value);
  }
  else {
    croak "Invalid type";
  }
}

sub divide {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    croak "Error in a + b : non-numeric argument to binary operator";
  }
  elsif (is_complex($element1)) {
    my $v3 = multiply($element1, conj($element2));
    my $abs2 = double(value($element2->re) ** 2 + value($element2->im) ** 2);
    my $re = divide($v3->re, $abs2);
    my $im = divide($v3->im, $abs2);
    
    return complex_double($re, $im);
  }
  elsif (is_double($element1)) {
    return NaN if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if ($element1->value == 0) {
        if (defined $element2) {
          if ($element2->value == 0) {
            return NaN;
          }
          else {
            return double(0)
          }
        }
        elsif (is_infinite($element2)) {
          return double(0);
        }
      }
      elsif ($element1->value > 0) {
        if (defined $element2) {
          if ($element2->value == 0) {
            return Inf;
          }
          else {
            return double($element1->value / $element2->value);
          }
        }
        elsif (is_infinite($element2)) {
          return double(0);
        }
      }
      elsif ($element1->value < 0) {
        if (defined $element2) {
          if ($element2->value == 0) {
            return negativeInf;
          }
          else {
            return double($element1->value / $element2->value);
          }
        }
        elsif (is_infinite($element2)) {
          return double(0);
        }
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        if ($element2->value >= 0) {
          return Inf;
        }
        elsif ($element2->value < 0) {
          return negativeInf;
        }
      }
      elsif (is_infinite($element2)) {
        return NaN;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        if ($element2->value >= 0) {
          return negativeInf;
        }
        elsif ($element2->value < 0) {
          return Inf;
        }
      }
      elsif (is_infinite($element2)) {
        return NaN;
      }
    }
  }
  elsif (is_integer($element1)) {
    if ($element1->value == 0) {
      if ($element2->value == 0) {
        return NaN;
      }
      else {
        return double(0);
      }
    }
    elsif ($element1->value > 0) {
      if ($element2->value == 0) {
        return Inf;
      }
      else  {
        return double($element1->value / $element2->value);
      }
    }
    elsif ($element1->value < 0) {
      if ($element2->value == 0) {
        return negativeInf;
      }
      else {
        return double($element1->value / $element2->value);
      }
    }
  }
  elsif (is_logical($element1)) {
    if ($element1->value == 0) {
      if ($element2->value == 0) {
        return NaN;
      }
      elsif ($element2->value == 1) {
        return double(0);
      }
    }
    elsif ($element1->value == 1) {
      if ($element2->value == 0) {
        return Inf;
      }
      elsif ($element2->value == 1)  {
        return double(1);
      }
    }
  }
  else {
    croak "Invalid type";
  }
}

sub raise {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    croak "Error in a + b : non-numeric argument to binary operator";
  }
  elsif (is_complex($element1)) {
    my $element1_c = Math::Complex->make(Rstats::Util::value($element1->re), Rstats::Util::value($element1->im));
    my $element2_c = Math::Complex->make(Rstats::Util::value($element2->re), Rstats::Util::value($element2->im));
    
    my $v3_c = $element1_c ** $element2_c;
    my $re = Math::Complex::Re($v3_c);
    my $im = Math::Complex::Im($v3_c);
    
    return complex($re, $im);
  }
  elsif (is_double($element1)) {
    return NaN if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if ($element1->value == 0) {
        if (defined $element2) {
          if ($element2->value == 0) {
            return double(1);
          }
          elsif ($element2->value > 0) {
            return double(0);
          }
          elsif ($element2->value < 0) {
            return Inf;
          }
        }
        elsif (is_positive_infinite($element2)) {
          return double(0);
        }
        elsif (is_negative_infinite($element2)) {
          return Inf
        }
      }
      elsif ($element1->value > 0) {
        if (defined $element2) {
          if ($element2->value == 0) {
            return double(1);
          }
          else {
            return double($element1->value ** $element2->value);
          }
        }
        elsif (is_positive_infinite($element2)) {
          if ($element1->value < 1) {
            return double(0);
          }
          elsif ($element1->value == 1) {
            return double(1);
          }
          elsif ($element1->value > 1) {
            return Inf;
          }
        }
        elsif (is_negative_infinite($element2)) {
          if ($element1->value < 1) {
            return double(0);
          }
          elsif ($element1->value == 1) {
            return double(1);
          }
          elsif ($element1->value > 1) {
            return double(0);
          }
        }
      }
      elsif ($element1->value < 0) {
        if (defined $element2) {
          if ($element2->value == 0) {
            return double(-1);
          }
          else {
            return double($element1->value ** $element2->value);
          }
        }
        elsif (is_positive_infinite($element2)) {
          if ($element1->value > -1) {
            return double(0);
          }
          elsif ($element1->value == -1) {
            return double(-1);
          }
          elsif ($element1->value < -1) {
            return negativeInf;
          }
        }
        elsif (is_negative_infinite($element2)) {
          if ($element1->value > -1) {
            return Inf;
          }
          elsif ($element1->value == -1) {
            return double(-1);
          }
          elsif ($element1->value < -1) {
            return double(0);
          }
        }
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        if ($element2->value == 0) {
          return double(1);
        }
        elsif ($element2->value > 0) {
          return Inf;
        }
        elsif ($element2->value < 0) {
          return double(0);
        }
      }
      elsif (is_positive_infinite($element2)) {
        return Inf;
      }
      elsif (is_negative_infinite($element2)) {
        return double(0);
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        if ($element2->value == 0) {
          return double(-1);
        }
        elsif ($element2->value > 0) {
          return negativeInf;
        }
        elsif ($element2->value < 0) {
          return double(0);
        }
      }
      elsif (is_positive_infinite($element2)) {
        return negativeInf;
      }
      elsif (is_negative_infinite($element2)) {
        return double(0);
      }
    }
  }
  elsif (is_integer($element1)) {
    if ($element1->value == 0) {
      if ($element2->value == 0) {
        return double(1);
      }
      elsif ($element2->value > 0) {
        return double(0);
      }
      elsif ($element2->value < 0) {
        return Inf;
      }
    }
    elsif ($element1->value > 0) {
      if ($element2->value == 0) {
        return double(1);
      }
      else {
        return double($element1->value ** $element2->value);
      }
    }
    elsif ($element1->value < 0) {
      if ($element2->value == 0) {
        return double(-1);
      }
      else {
        return double($element1->value ** $element2->value);
      }
    }
  }
  elsif (is_logical($element1)) {
    if ($element1->value == 0) {
      if ($element2->value == 0) {
        return double(1);
      }
      elsif ($element2->value == 1) {
        return double(0);
      }
    }
    elsif ($element1->value ==  1) {
      if ($element2->value == 0) {
        return double(1);
      }
      elsif ($element2->value == 1) {
        return double(1);
      }
    }
  }
  else {
    croak "Invalid type";
  }
}

sub remainder {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    croak "Error in a + b : non-numeric argument to binary operator";
  }
  elsif (is_complex($element1)) {
    croak "unimplemented complex operation";
  }
  elsif (is_double($element1)) {
    return NaN if is_nan($element1) || is_nan($element2) || is_infinite($element1) || is_infinite($element2);
    
    if ($element2->value == 0) {
      return NaN;
    }
    else {
      my $v3_value = $element1->value - POSIX::floor($element1->value/$element2->value) * $element2->value;
      return double($v3_value);
    }
  }
  elsif (is_integer($element1)) {
    if ($element2->value == 0) {
      return NaN;
    }
    else {
      return double($element1 % $element2);
    }
  }
  elsif (is_logical($element1)) {
    if ($element2->value == 0) {
      return NaN;
    }
    else {
      return double($element1->value % $element2->value);
    }
  }
  else {
    croak "Invalid type";
  }
}

sub conj {
  my $value = shift;
  
  if (is_complex($value)) {
    return complex_double($value->re, Rstats::Util::negation($value->im));
  }
  else {
    croak 'Invalid type';
  }
}

sub abs {
  my $element = shift;
  
  if (is_complex($element)) {
    return double(
      sqrt(Rstats::Util::value($element)->{re} ** 2 + Rstats::Util::value($element)->{im} ** 2)
    );
  }
  else {
    croak 'Not implemented';
  }
}

sub more_than {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    return $element1->value gt $element2->value ? TRUE : FALSE;
  }
  elsif (is_complex($element1)) {
    croak "invalid comparison with complex values";
  }
  elsif (is_double($element1)) {
    return NA if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return $element1->value > $element2->value ? TRUE : FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return TRUE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
  }
  elsif (is_integer($element1)) {
    return $element1->value > $element2->value ? TRUE : FALSE;
  }
  elsif (is_logical($element1)) {
    return $element1->value > $element2->value ? TRUE : FALSE;
  }
  else {
    croak "Invalid type";
  }
}

sub more_than_or_equal {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    return $element1->value ge $element2->value ? TRUE : FALSE;
  }
  elsif (is_complex($element1)) {
    croak "invalid comparison with complex values";
  }
  elsif (is_double($element1)) {
    return NA if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return $element1->value >= $element2->value ? TRUE : FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return TRUE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
  }
  elsif (is_integer($element1)) {
    return $element1->value >= $element2->value ? TRUE : FALSE;
  }
  elsif (is_logical($element1)) {
    return $element1->value >= $element2->value ? TRUE : FALSE;
  }
  else {
    croak "Invalid type";
  }
}

sub less_than {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    return $element1->value lt $element2->value ? TRUE : FALSE;
  }
  elsif (is_complex($element1)) {
    croak "invalid comparison with complex values";
  }
  elsif (is_double($element1)) {
    return NA if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return $element1->value < $element2->value ? TRUE : FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return TRUE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
  }
  elsif (is_integer($element1)) {
    return $element1->value < $element2->value ? TRUE : FALSE;
  }
  elsif (is_logical($element1)) {
    return $element1->value < $element2->value ? TRUE : FALSE;
  }
  else {
    croak "Invalid type";
  }
}

sub less_than_or_equal {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    return $element1->value le $element2->value ? TRUE : FALSE;
  }
  elsif (is_complex($element1)) {
    croak "invalid comparison with complex values";
  }
  elsif (is_double($element1)) {
    return NA if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return $element1->value <= $element2->value ? TRUE : FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return TRUE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
  }
  elsif (is_integer($element1)) {
    return $element1->value <= $element2->value ? TRUE : FALSE;
  }
  elsif (is_logical($element1)) {
    return $element1->value <= $element2->value ? TRUE : FALSE;
  }
  else {
    croak "Invalid type";
  }
}

sub equal {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    return $element1->value eq $element2->value ? TRUE : FALSE;
  }
  elsif (is_complex($element1)) {
    return $element1->re->value == $element2->re->value && $element1->im->value == $element2->im->value ? TRUE : FALSE;
  }
  elsif (is_double($element1)) {
    return NA if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return $element1->value == $element2->value ? TRUE : FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
  }
  elsif (is_integer($element1)) {
    return $element1->value == $element2->value ? TRUE : FALSE;
  }
  elsif (is_logical($element1)) {
    return $element1->value == $element2->value ? TRUE : FALSE;
  }
  else {
    croak "Invalid type";
  }
}

sub not_equal {
  my ($element1, $element2) = @_;
  
  return NA if is_na($element1) || is_na($element2);
  
  if (is_character($element1)) {
    return $element1->value ne $element2->value ? TRUE : FALSE;
  }
  elsif (is_complex($element1)) {
    return !($element1->re->value == $element2->re->value && $element1->im->value == $element2->im->value) ? TRUE : FALSE;
  }
  elsif (is_double($element1)) {
    return NA if is_nan($element1) || is_nan($element2);
    if (defined $element1->value) {
      if (defined $element2) {
        return $element1->value != $element2->value ? TRUE : FALSE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
    elsif (is_positive_infinite($element1)) {
      if (defined $element2) {
        return TRUE;
      }
      elsif (is_positive_infinite($element2)) {
        return FALSE;
      }
      elsif (is_negative_infinite($element2)) {
        return TRUE;
      }
    }
    elsif (is_negative_infinite($element1)) {
      if (defined $element2) {
        return TRUE;
      }
      elsif (is_positive_infinite($element2)) {
        return TRUE;
      }
      elsif (is_negative_infinite($element2)) {
        return FALSE;
      }
    }
  }
  elsif (is_integer($element1)) {
    return $element1->value != $element2->value ? TRUE : FALSE;
  }
  elsif (is_logical($element1)) {
    return $element1->value != $element2->value ? TRUE : FALSE;
  }
  else {
    croak "Invalid type";
  }
}

1;
