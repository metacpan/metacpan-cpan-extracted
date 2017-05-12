#ifndef PERL_RSTATS_VECTOR_H
#define PERL_RSTATS_VECTOR_H

#include "Rstats_ElementFunc.h"

namespace Rstats {
  
  template <class T>
  class Vector {
    private:
    
    Rstats::NaPosition* na_positions;
    T* values;
    Rstats::Integer length;
    
    public:
    
    void initialize(Rstats::Integer);
    Vector<T>(Rstats::Integer);
    Vector<T>(Rstats::Integer, T);

    Rstats::Integer get_length();
    void init_na_positions();
    void add_na_position(Rstats::Integer);
    Rstats::Logical exists_na_position(Rstats::Integer);
    void merge_na_positions(Rstats::NaPosition*);
    Rstats::NaPosition* get_na_positions();
    Rstats::Integer get_na_positions_length();
    
    T* get_values();
    void set_value(Rstats::Integer, T); 
    T get_value(Rstats::Integer);
    
    ~Vector();
  };
  template <>
  void Vector<Rstats::Character>::initialize(Rstats::Integer);
  template<>
  Vector<Rstats::Character>::Vector(Rstats::Integer);
  template <>
  void Vector<Rstats::Character>::set_value(Rstats::Integer, Rstats::Character);
  template <>
  Vector<Rstats::Character>::~Vector();
}
#include "Rstats_Vector_impl.h"

#endif
