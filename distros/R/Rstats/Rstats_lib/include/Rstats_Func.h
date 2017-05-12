#ifndef PERL_RSTATS_FUNC_H
#define PERL_RSTATS_FUNC_H

#include <vector>
#include "Rstats_Vector.h"
#include "Rstats_VectorFunc.h"

namespace Rstats {
  namespace Func {

    SV* to_object(SV*, SV*);

    SV* new_NULL(SV*); /* r->NULL */
    SV* new_NA(SV*); /* r->NA */
    SV* new_NaN(SV*); /* r->NaN */
    SV* new_Inf(SV*); /* r->Inf */
    SV* new_FALSE(SV*); /* r->FALSE */
    SV* new_TRUE(SV*); /* r->TRUE */

    SV* new_data_frame(SV*);
    SV* new_list(SV*);

    SV* c_(SV*, SV*);
    SV* c_character(SV*, SV*);
    SV* c_double(SV*, SV*);
    SV* c_integer(SV*, SV*);
    SV* c_logical(SV*, SV*);
    SV* c_complex(SV*, SV*);

    SV* pi(SV*);
    SV* is_null (SV*, SV*);
    SV* is_vector(SV*, SV*);
    SV* values(SV*, SV*);
    SV* is_matrix(SV*, SV*);
    SV* is_array(SV*, SV*);
    SV* is_numeric(SV*, SV*);
    SV* type(SV*, SV*);
    SV* Typeof(SV*, SV*); // r->typeof
    Rstats::Logical to_bool(SV*, SV*);
    SV* is_double(SV*, SV*);
    SV* is_integer(SV*, SV*);
    SV* is_complex(SV*, SV*);
    SV* is_character(SV*, SV*);
    SV* is_logical(SV*, SV*);
    SV* is_data_frame(SV*, SV*);
    SV* is_list(SV*, SV*);
    SV* is_finite(SV*, SV*);
    SV* is_infinite(SV*, SV*);
    SV* is_nan(SV*, SV*);
    SV* is_na(SV*, SV*);
    SV* is_factor(SV*, SV*);
    SV* is_ordered(SV*, SV*);

    SV* copy_attrs_to(SV*, SV*, SV*);
    SV* copy_attrs_to(SV*, SV*, SV*, SV*);

    SV* as_vector(SV*, SV*);
    SV* as_integer(SV*, SV*);
    SV* as_logical(SV*, SV*);
    SV* as_complex(SV*, SV*);
    SV* as_double(SV*, SV*);
    SV* as_numeric(SV*, SV*);
    SV* as_character(SV*, SV*);
    SV* as(SV*, SV*, SV*);

    SV* clone(SV*, SV*);
    SV* dim_as_array(SV*, SV*);
    SV* decompose(SV*, SV*);
    SV* compose(SV*, SV*, SV*);
    SV* array(SV*, SV*);
    SV* array(SV*, SV*, SV*);
    SV* array_with_opt(SV*, SV*);
    SV* args_h(SV*, SV*, SV*);
    SV* as_array(SV*, SV*);
    // class
    SV* Class(SV*, SV*);
    SV* Class(SV*, SV*, SV*);
    SV* levels(SV*, SV*);
    SV* levels(SV*, SV*, SV*);
    SV* mode(SV*, SV*);
    SV* mode(SV*, SV*, SV*);
    
    Rstats::Integer get_length(SV*, SV*);
    SV* get_length_sv(SV*, SV*);
    
    // dim
    SV* dim(SV*, SV*, SV*);
    SV* dim(SV*, SV*);
    
    SV* length(SV*, SV*);
    SV* names(SV*, SV*, SV*);
    SV* names(SV*, SV*);
    
    SV* tanh(SV*, SV*);
    SV* Mod(SV*, SV*);
    SV* Arg(SV*, SV*);
    SV* Conj(SV*, SV*);
    SV* Re(SV*, SV*);
    SV* Im(SV*, SV*);
    SV* abs(SV*, SV*);
    SV* acos(SV*, SV*);
    SV* acosh(SV*, SV*);
    SV* asin(SV*, SV*);
    SV* asinh(SV*, SV*);
    SV* atan(SV*, SV*);
    SV* atanh(SV*, SV*);
    SV* cos(SV*, SV*);
    SV* cosh(SV*, SV*);
    SV* cumsum(SV*, SV*);
    SV* cumprod(SV*, SV*);
    SV* exp(SV*, SV*);
    SV* expm1(SV*, SV*);
    SV* log(SV*, SV*);
    SV* logb(SV*, SV*);
    SV* log2(SV*, SV*);
    SV* log10(SV*, SV*);
    SV* prod(SV*, SV*);
    SV* sin(SV*, SV*);
    SV* sinh(SV*, SV*);
    SV* sqrt(SV*, SV*);
    SV* tan(SV*, SV*);
    SV* sin(SV*, SV*);
    SV* sum(SV*, SV*);
    SV* negate(SV*, SV*);
    
    SV* upgrade_type_avrv(SV*, SV*);
    void upgrade_type(SV*, Rstats::Integer, ...);
    SV* upgrade_length_avrv(SV*, SV*);
    void upgrade_length(SV*, Rstats::Integer, ...);

    char* get_type(SV*, SV*);
    SV* get_type_sv(SV*, SV*);
    char* get_object_type(SV*, SV*);

    SV* add(SV*, SV*, SV*);
    SV* subtract(SV*, SV*, SV*);
    SV* multiply(SV*, SV*, SV*);
    SV* divide(SV*, SV*, SV*);
    SV* remainder(SV*, SV*, SV*);
    SV* pow(SV*, SV*, SV*);
    SV* atan2(SV*, SV*, SV*);
    
    SV* less_than(SV*, SV*, SV*);
    SV* less_than_or_equal(SV*, SV*, SV*);
    SV* more_than(SV*, SV*, SV*);
    SV* more_than_or_equal(SV*, SV*, SV*);
    SV* equal(SV*, SV*, SV*);
    SV* not_equal(SV*, SV*, SV*);
    SV* And(SV*, SV*, SV*);
    SV* Or(SV*, SV*, SV*);

    SV* create_sv_value(SV*, SV*, Rstats::Integer);
    SV* create_sv_values(SV*, SV*);
    
    template <class T>
    void set_vector(SV*, SV*, Rstats::Vector<T>*);
    template <>
    void set_vector<Rstats::Character>(SV*, SV*, Rstats::Vector<Rstats::Character>*);
    template <>
    void set_vector<Rstats::Complex>(SV*, SV*, Rstats::Vector<Rstats::Complex>*);
    template <>
    void set_vector<Rstats::Double>(SV*, SV*, Rstats::Vector<Rstats::Double>*);
    template <>
    void set_vector<Rstats::Integer>(SV*, SV*, Rstats::Vector<Rstats::Integer>*);
    template <>
    void set_vector<Rstats::Logical>(SV*, SV*, Rstats::Vector<Rstats::Logical>* v1);
    
    template <class T>
    Rstats::Vector<T>* get_vector(SV*, SV*);
    template <>
    Rstats::Vector<Rstats::Character>* get_vector<Rstats::Character>(SV*, SV*);
    template <>
    Rstats::Vector<Rstats::Complex>* get_vector<Rstats::Complex>(SV*, SV*);
    template <>
    Rstats::Vector<Rstats::Double>* get_vector<Rstats::Double>(SV*, SV*);
    template <>
    Rstats::Vector<Rstats::Integer>* get_vector<Rstats::Integer>(SV*, SV*);
    template <>
    Rstats::Vector<Rstats::Logical>* get_vector<Rstats::Logical>(SV*, SV*);

    template <class T>
    SV* new_vector(SV*);
    template <>
    SV* new_vector<Rstats::Character>(SV*);
    template <>
    SV* new_vector<Rstats::Complex>(SV*);
    template <>
    SV* new_vector<Rstats::Double>(SV*);
    template <>
    SV* new_vector<Rstats::Integer>(SV*);
    template <>
    SV* new_vector<Rstats::Logical>(SV*);
    
    template <class T>
    SV* new_vector(SV*, Rstats::Vector<T>* v1);
  }
}
#include "Rstats_Func_impl.h"

#endif
