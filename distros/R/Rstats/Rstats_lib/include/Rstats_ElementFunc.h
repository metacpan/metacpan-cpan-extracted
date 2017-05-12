#ifndef PERL_RSTATS_ELEMENTFUNC_H
#define PERL_RSTATS_ELEMENTFUNC_H

#include <complex>
#include <cmath>

#include "Rstats_Util.h"

namespace Rstats {
  namespace ElementFunc {

    Rstats::Complex add(Rstats::Complex, Rstats::Complex);
    Rstats::Double add(Rstats::Double, Rstats::Double);
    Rstats::Integer add(Rstats::Integer, Rstats::Integer);
    Rstats::Integer add(Rstats::Logical, Rstats::Logical);

    Rstats::Complex subtract(Rstats::Complex, Rstats::Complex);
    Rstats::Double subtract(Rstats::Double, Rstats::Double);
    Rstats::Integer subtract(Rstats::Integer, Rstats::Integer);
    Rstats::Integer subtract(Rstats::Logical, Rstats::Logical);

    Rstats::Complex multiply(Rstats::Complex, Rstats::Complex);
    Rstats::Double multiply(Rstats::Double, Rstats::Double);
    Rstats::Integer multiply(Rstats::Integer, Rstats::Integer);
    Rstats::Integer multiply(Rstats::Logical, Rstats::Logical);

    Rstats::Complex divide(Rstats::Complex, Rstats::Complex);
    Rstats::Double divide(Rstats::Double, Rstats::Double);
    Rstats::Double divide(Rstats::Integer, Rstats::Integer);
    Rstats::Double divide(Rstats::Logical, Rstats::Logical);

    Rstats::Complex pow(Rstats::Complex, Rstats::Complex);
    Rstats::Double pow(Rstats::Double, Rstats::Double);
    Rstats::Double pow(Rstats::Integer, Rstats::Integer);
    Rstats::Double pow(Rstats::Logical, Rstats::Logical);

    Rstats::Complex remainder(Rstats::Complex, Rstats::Complex);
    Rstats::Double remainder(Rstats::Double, Rstats::Double);
    Rstats::Double remainder(Rstats::Integer, Rstats::Integer);
    Rstats::Double remainder(Rstats::Logical, Rstats::Logical);

    Rstats::Double Re(Rstats::Complex);
    Rstats::Double Re(Rstats::Double);
    Rstats::Double Re(Rstats::Integer);
    Rstats::Double Re(Rstats::Logical);

    Rstats::Double Im(Rstats::Complex);
    Rstats::Double Im(Rstats::Double);
    Rstats::Double Im(Rstats::Integer);
    Rstats::Double Im(Rstats::Logical);

    Rstats::Complex Conj(Rstats::Complex);
    Rstats::Double Conj(Rstats::Double);
    Rstats::Double Conj(Rstats::Integer);
    Rstats::Double Conj(Rstats::Logical);

    Rstats::Complex sin(Rstats::Complex);
    Rstats::Double sin(Rstats::Double);
    Rstats::Double sin(Rstats::Integer);
    Rstats::Double sin(Rstats::Logical);
    
    Rstats::Complex cos(Rstats::Complex);
    Rstats::Double cos(Rstats::Double);
    Rstats::Double cos(Rstats::Integer);
    Rstats::Double cos(Rstats::Logical);

    Rstats::Complex tan(Rstats::Complex);
    Rstats::Double tan(Rstats::Double);
    Rstats::Double tan(Rstats::Integer);
    Rstats::Double tan(Rstats::Logical);

    Rstats::Complex sinh(Rstats::Complex);
    Rstats::Double sinh(Rstats::Double);
    Rstats::Double sinh(Rstats::Integer);
    Rstats::Double sinh(Rstats::Logical);

    Rstats::Complex cosh(Rstats::Complex);
    Rstats::Double cosh(Rstats::Double);
    Rstats::Double cosh(Rstats::Integer);
    Rstats::Double cosh(Rstats::Logical);

    Rstats::Complex tanh (Rstats::Complex z);
    Rstats::Double tanh(Rstats::Double);
    Rstats::Double tanh(Rstats::Integer);
    Rstats::Double tanh(Rstats::Logical);

    Rstats::Double abs(Rstats::Complex);
    Rstats::Double abs(Rstats::Double);
    Rstats::Double abs(Rstats::Integer);
    Rstats::Double abs(Rstats::Logical);

    Rstats::Double Mod(Rstats::Complex);
    Rstats::Double Mod(Rstats::Double);
    Rstats::Double Mod(Rstats::Integer);
    Rstats::Double Mod(Rstats::Logical);

    Rstats::Complex log(Rstats::Complex);
    Rstats::Double log(Rstats::Double);
    Rstats::Double log(Rstats::Integer);
    Rstats::Double log(Rstats::Logical);

    Rstats::Complex logb(Rstats::Complex);
    Rstats::Double logb(Rstats::Double);
    Rstats::Double logb(Rstats::Integer);
    Rstats::Double logb(Rstats::Logical);

    Rstats::Complex log10(Rstats::Complex);
    Rstats::Double log10(Rstats::Double);
    Rstats::Double log10(Rstats::Integer);
    Rstats::Double log10(Rstats::Logical);

    Rstats::Complex log2(Rstats::Complex);
    Rstats::Double log2(Rstats::Double);
    Rstats::Double log2(Rstats::Integer);
    Rstats::Double log2(Rstats::Logical);
    
    Rstats::Complex expm1(Rstats::Complex);
    Rstats::Double expm1(Rstats::Double);
    Rstats::Double expm1(Rstats::Integer);
    Rstats::Double expm1(Rstats::Logical);

    Rstats::Double Arg(Rstats::Complex);
    Rstats::Double Arg(Rstats::Double);
    Rstats::Double Arg(Rstats::Integer);
    Rstats::Double Arg(Rstats::Logical);

    Rstats::Complex exp(Rstats::Complex);
    Rstats::Double exp(Rstats::Double);
    Rstats::Double exp(Rstats::Integer);
    Rstats::Double exp(Rstats::Logical);

    Rstats::Complex sqrt(Rstats::Complex);
    Rstats::Double sqrt(Rstats::Double);
    Rstats::Double sqrt(Rstats::Integer);
    Rstats::Double sqrt(Rstats::Logical);

    Rstats::Complex atan(Rstats::Complex);
    Rstats::Double atan(Rstats::Double);
    Rstats::Double atan(Rstats::Integer);
    Rstats::Double atan(Rstats::Logical);

    Rstats::Complex asin(Rstats::Complex);
    Rstats::Double asin(Rstats::Double);
    Rstats::Double asin(Rstats::Integer);
    Rstats::Double asin(Rstats::Logical);

    Rstats::Complex acos(Rstats::Complex);
    Rstats::Double acos(Rstats::Double);
    Rstats::Double acos(Rstats::Integer);
    Rstats::Double acos(Rstats::Logical);

    Rstats::Complex asinh(Rstats::Complex);
    Rstats::Double asinh(Rstats::Double);
    Rstats::Double asinh(Rstats::Integer);
    Rstats::Double asinh(Rstats::Logical);

    Rstats::Complex acosh(Rstats::Complex);
    Rstats::Double acosh(Rstats::Double);
    Rstats::Double acosh(Rstats::Integer);
    Rstats::Double acosh(Rstats::Logical);

    Rstats::Complex atanh(Rstats::Complex);
    Rstats::Double atanh(Rstats::Double);
    Rstats::Double atanh(Rstats::Integer);
    Rstats::Double atanh(Rstats::Logical);
    
    Rstats::Complex negate(Rstats::Complex);
    Rstats::Double negate(Rstats::Double);
    Rstats::Integer negate(Rstats::Integer);
    Rstats::Integer negate(Rstats::Logical);

    Rstats::Complex atan2(Rstats::Complex, Rstats::Complex);
    Rstats::Double atan2(Rstats::Double, Rstats::Double);
    Rstats::Double atan2(Rstats::Integer, Rstats::Integer);
    Rstats::Double atan2(Rstats::Logical, Rstats::Logical);

    Rstats::Logical And(Rstats::Character, Rstats::Character);
    Rstats::Logical And(Rstats::Complex, Rstats::Complex);
    Rstats::Logical And(Rstats::Double, Rstats::Double);
    Rstats::Logical And(Rstats::Integer, Rstats::Integer);
    Rstats::Logical And(Rstats::Logical, Rstats::Logical);

    Rstats::Logical Or(Rstats::Character, Rstats::Character);
    Rstats::Logical Or(Rstats::Complex, Rstats::Complex);
    Rstats::Logical Or(Rstats::Double, Rstats::Double);
    Rstats::Logical Or(Rstats::Integer, Rstats::Integer);
    Rstats::Logical Or(Rstats::Logical, Rstats::Logical);
    
    Rstats::Logical equal(Rstats::Character, Rstats::Character);
    Rstats::Logical equal(Rstats::Complex, Rstats::Complex);
    Rstats::Logical equal(Rstats::Double, Rstats::Double);
    Rstats::Logical equal(Rstats::Integer, Rstats::Integer);
    Rstats::Logical equal(Rstats::Logical, Rstats::Logical);

    Rstats::Logical not_equal(Rstats::Character, Rstats::Character);
    Rstats::Logical not_equal(Rstats::Complex, Rstats::Complex);
    Rstats::Logical not_equal(Rstats::Double, Rstats::Double);
    Rstats::Logical not_equal(Rstats::Integer, Rstats::Integer);
    Rstats::Logical not_equal(Rstats::Logical, Rstats::Logical);

    Rstats::Logical more_than(Rstats::Character, Rstats::Character);
    Rstats::Logical more_than(Rstats::Complex, Rstats::Complex);
    Rstats::Logical more_than(Rstats::Double, Rstats::Double);
    Rstats::Logical more_than(Rstats::Integer, Rstats::Integer);
    Rstats::Logical more_than(Rstats::Logical, Rstats::Logical);

    Rstats::Logical less_than(Rstats::Character, Rstats::Character);
    Rstats::Logical less_than(Rstats::Complex, Rstats::Complex);
    Rstats::Logical less_than(Rstats::Double, Rstats::Double);
    Rstats::Logical less_than(Rstats::Integer, Rstats::Integer);
    Rstats::Logical less_than(Rstats::Logical, Rstats::Logical);

    Rstats::Logical more_than_or_equal(Rstats::Character, Rstats::Character);
    Rstats::Logical more_than_or_equal(Rstats::Complex, Rstats::Complex);
    Rstats::Logical more_than_or_equal(Rstats::Double, Rstats::Double);
    Rstats::Logical more_than_or_equal(Rstats::Integer, Rstats::Integer);
    Rstats::Logical more_than_or_equal(Rstats::Logical, Rstats::Logical);

    Rstats::Logical less_than_or_equal(Rstats::Character, Rstats::Character);
    Rstats::Logical less_than_or_equal(Rstats::Complex, Rstats::Complex);
    Rstats::Logical less_than_or_equal(Rstats::Double, Rstats::Double);
    Rstats::Logical less_than_or_equal(Rstats::Integer, Rstats::Integer);
    Rstats::Logical less_than_or_equal(Rstats::Logical, Rstats::Logical);

    Rstats::Logical is_infinite(Rstats::Character);
    Rstats::Logical is_infinite(Rstats::Complex);
    Rstats::Logical is_infinite(Rstats::Double);
    Rstats::Logical is_infinite(Rstats::Integer);
    Rstats::Logical is_infinite(Rstats::Logical);

    Rstats::Logical is_finite(Rstats::Character);
    Rstats::Logical is_finite(Rstats::Complex);
    Rstats::Logical is_finite(Rstats::Double);
    Rstats::Logical is_finite(Rstats::Integer);
    Rstats::Logical is_finite(Rstats::Logical);

    Rstats::Logical is_nan(Rstats::Character);
    Rstats::Logical is_nan(Rstats::Complex);
    Rstats::Logical is_nan(Rstats::Double);
    Rstats::Logical is_nan(Rstats::Integer);
    Rstats::Logical is_nan(Rstats::Logical);

    Rstats::Character as_character(Rstats::Character);
    Rstats::Character as_character(Rstats::Complex);
    Rstats::Character as_character(Rstats::Double);
    Rstats::Character as_character(Rstats::Integer);
    Rstats::Character as_character(Rstats::Logical);

    Rstats::Double as_double(Rstats::Character);
    Rstats::Double as_double(Rstats::Complex);
    Rstats::Double as_double(Rstats::Double);
    Rstats::Double as_double(Rstats::Integer);
    Rstats::Double as_double(Rstats::Logical);

    Rstats::Complex as_complex(Rstats::Character);
    Rstats::Complex as_complex(Rstats::Complex);
    Rstats::Complex as_complex(Rstats::Double);
    Rstats::Complex as_complex(Rstats::Integer);
    Rstats::Complex as_complex(Rstats::Logical);

    Rstats::Integer as_integer(Rstats::Character);
    Rstats::Integer as_integer(Rstats::Complex);
    Rstats::Integer as_integer(Rstats::Double);
    Rstats::Integer as_integer(Rstats::Integer);
    Rstats::Integer as_integer(Rstats::Logical);

    Rstats::Logical as_logical(Rstats::Character);
    Rstats::Logical as_logical(Rstats::Complex);
    Rstats::Logical as_logical(Rstats::Double);
    Rstats::Logical as_logical(Rstats::Integer);
    Rstats::Logical as_logical(Rstats::Logical);
  }
}

#endif
