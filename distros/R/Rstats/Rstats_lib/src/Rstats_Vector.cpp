#include "Rstats_Vector.h"

namespace Rstats {

  template <>
  void Vector<Rstats::Character>::initialize(Rstats::Integer length) {
    this->values = new Rstats::Character[length];
    this->length = length;
    this->na_positions = NULL;
    for (Rstats::Integer i = 0; i < length; i++) {
      SV** value_ptr = (SV**)this->values;
      *(value_ptr + i) = &PL_sv_undef;
    }
  }

  template <>
  Vector<Rstats::Character>::Vector(Rstats::Integer length) {
    this->initialize(length);
  }

  template <>
  void Vector<Rstats::Character>::set_value(Rstats::Integer pos, Rstats::Character value) {
    SV* current_value = *(this->get_values() + pos);
    
    if (SvOK(current_value)) {
      SvREFCNT_dec(current_value);
    }
    
    *(this->get_values() + pos) = SvREFCNT_inc(value);
  }

  template<>
  Vector<Rstats::Character>::~Vector() {

    Rstats::Character* values = this->get_values();
    Rstats::Integer length = this->get_length();
    for (Rstats::Integer i = 0; i < length; i++) {
      if (*(values + i) != NULL) {
        SvREFCNT_dec(*(values + i));
      }
    }
    delete[] values;
    delete[] this->na_positions;
  }
}
