#ifndef PERL_RSTATS_VECTORFUNC_H
#define PERL_RSTATS_VECTORFUNC_H

#include "Rstats_Vector.h"

namespace Rstats {
  namespace VectorFunc {

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_unary_math(T_OUT (*func)(T_IN), Rstats::Vector<T_IN>*);
    
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* operate_unary_is(Rstats::Logical (*func)(T_IN), Rstats::Vector<T_IN>*);
    
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_unary_as(T_OUT (*func)(T_IN), Rstats::Vector<T_IN>*);
    
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_binary_math(T_OUT (*func)(T_IN, T_IN), Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_binary_compare(T_OUT (*func)(T_IN, T_IN), Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* equal(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* not_equal(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* more_than(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* more_than_or_equal(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* less_than(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* less_than_or_equal(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* And(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* Or(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* add(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* subtract(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* multiply(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* divide(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* pow(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* atan2(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* remainder(Rstats::Vector<T_IN>*, Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_character(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_double(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_complex(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_integer(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_logical(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* sin(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* tanh(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* cos(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* tan(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* sinh(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* cosh(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* log(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* logb(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* log10(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* log2(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* acos(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* acosh(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* asinh(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* atanh(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Conj(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* asin(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* atan(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* sqrt(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* expm1(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* exp(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* negate(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Arg(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* abs(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Mod(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Re(Rstats::Vector<T_IN>*);
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Im(Rstats::Vector<T_IN>*);
    
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_na(Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_infinite(Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_nan(Rstats::Vector<T_IN>*);
    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_finite(Rstats::Vector<T_IN>*);
    
  }
}
#include "Rstats_VectorFunc_impl.h"

#endif
