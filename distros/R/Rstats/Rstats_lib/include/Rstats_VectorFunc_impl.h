namespace Rstats {
  namespace VectorFunc {
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_unary_math(T_OUT (*func)(T_IN), Rstats::Vector<T_IN>* v1) {
      
      Rstats::Integer length = v1->get_length();
      
      Rstats::Vector<T_OUT>* v_out = new Rstats::Vector<T_OUT>(length);
      
      Rstats::clear_warn();
      for (Rstats::Integer i = 0; i < length; i++) {
        v_out->set_value(i, (*func)(v1->get_value(i)));
      }
      if (Rstats::get_warn()) {
        Rstats::print_warn_message();
      }
      
      v_out->merge_na_positions(v1->get_na_positions());
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* operate_unary_is(Rstats::Logical (*func)(T_IN), Rstats::Vector<T_IN>* v1) {
      
      Rstats::Integer length = v1->get_length();
      
      Rstats::Vector<Rstats::Logical>* v_out = new Rstats::Vector<Rstats::Logical>(length);

      Rstats::clear_warn();
      for (Rstats::Integer i = 0; i < length; i++) {
        if (v1->exists_na_position(i)) {
          v_out->set_value(i, 0);
        }
        else {
          v_out->set_value(i, (*func)(v1->get_value(i)));
        }
      }
      if (Rstats::get_warn()) {
        Rstats::print_warn_message();
      }
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_unary_as(T_OUT (*func)(T_IN), Rstats::Vector<T_IN>* v1) {
      
      Rstats::Integer length = v1->get_length();
      
      Rstats::Vector<T_OUT>* v_out = new Rstats::Vector<T_OUT>(length);
      
      Rstats::clear_warn();
      for (Rstats::Integer i = 0; i < length; i++) {
        try {
          v_out->set_value(i, (*func)(v1->get_value(i)));
        }
        catch (...) {
          v_out->add_na_position(i);
        }
      }
      if (Rstats::get_warn()) {
        Rstats::print_warn_message();
      }
      
      v_out->merge_na_positions(v1->get_na_positions());
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* operate_binary_math(T_OUT (*func)(T_IN, T_IN), Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {

      Rstats::Integer length = v1->get_length();
      Rstats::Vector<T_OUT>* v_out = new Rstats::Vector<T_OUT>(length);

      Rstats::clear_warn();
      for (Rstats::Integer i = 0; i < length; i++) {
        v_out->set_value(
          i,
          (*func)(
            v1->get_value(i),
            v2->get_value(i)
          )
        );
      }
      if (Rstats::get_warn()) {
        Rstats::print_warn_message();
      }
      
      v_out->merge_na_positions(v1->get_na_positions());
      v_out->merge_na_positions(v2->get_na_positions());
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* operate_binary_compare(Rstats::Logical (*func)(T_IN, T_IN), Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {

      Rstats::Integer length = v1->get_length();
      Rstats::Vector<Rstats::Logical>* v_out = new Rstats::Vector<Rstats::Logical>(length);

      Rstats::clear_warn();
      for (Rstats::Integer i = 0; i < length; i++) {
        try {
          v_out->set_value(
            i,
            (*func)(
              v1->get_value(i),
              v2->get_value(i)
            )
          );
        }
        catch (...) {
          v_out->add_na_position(i);
        }
      }
      if (Rstats::get_warn()) {
        Rstats::print_warn_message();
      }
      
      v_out->merge_na_positions(v1->get_na_positions());
      v_out->merge_na_positions(v2->get_na_positions());
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* equal(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::equal;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* not_equal(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::not_equal;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* more_than(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::more_than;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* more_than_or_equal(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::more_than_or_equal;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* less_than(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::less_than;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* less_than_or_equal(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::less_than_or_equal;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* And(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::And;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* Or(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      Rstats::Logical (*func)(T_IN, T_IN) = &Rstats::ElementFunc::Or;
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_binary_compare(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* add(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::add;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* subtract(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::subtract;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* multiply(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::multiply;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* divide(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::divide;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* pow(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::pow;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* atan2(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::atan2;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }
    
    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* remainder(Rstats::Vector<T_IN>* v1, Rstats::Vector<T_IN>* v2) {
      T_OUT (*func)(T_IN, T_IN) = &Rstats::ElementFunc::remainder;
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_binary_math(func, v1, v2);
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_character(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::as_character;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_as(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_double(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::as_double;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_as(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_complex(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::as_complex;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_as(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_integer(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::as_integer;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_as(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* as_logical(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::as_logical;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_as(func, v1);
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_na(Rstats::Vector<T_IN>* v1) {
      
      Rstats::Integer length = v1->get_length();
      
      Rstats::Vector<Rstats::Logical>* v_out = new Rstats::Vector<Rstats::Logical>(length);
      
      for (Rstats::Integer i = 0; i < length; i++) {
        if (v1->exists_na_position(i)) {
          v_out->set_value(i, 1);
        }
        else {
          v_out->set_value(i, 0);
        }
      }
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* sin(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::sin;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* tanh(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::tanh;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* cos(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::cos;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* tan(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::tan;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* sinh(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::sinh;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* cosh(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::cosh;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* log(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::log;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* logb(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::logb;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* log10(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::log10;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* log2(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::log2;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* acos(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::acos;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* acosh(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::acosh;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* asinh(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::asinh;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* atanh(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::atanh;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Conj(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::Conj;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* asin(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::asin;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* atan(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::atan;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* sqrt(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::sqrt;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* expm1(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::expm1;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* exp(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::exp;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* negate(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::negate;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Arg(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::Arg;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* abs(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::abs;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Mod(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::Mod;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Re(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::Re;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN, class T_OUT>
    Rstats::Vector<T_OUT>* Im(Rstats::Vector<T_IN>* v1) {
      T_OUT (*func)(T_IN) = &Rstats::ElementFunc::Im;
      
      Rstats::Vector<T_OUT>* v_out = Rstats::VectorFunc::operate_unary_math(func, v1);
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_infinite(Rstats::Vector<T_IN>* v1) {
      Rstats::Logical (*func)(T_IN) = &Rstats::ElementFunc::is_infinite;
      
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_unary_is(func, v1);
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_nan(Rstats::Vector<T_IN>* v1) {
      Rstats::Logical (*func)(T_IN) = &Rstats::ElementFunc::is_nan;
      
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_unary_is(func, v1);
      
      return v_out;
    }

    template <class T_IN>
    Rstats::Vector<Rstats::Logical>* is_finite(Rstats::Vector<T_IN>* v1) {
      Rstats::Logical (*func)(T_IN) = &Rstats::ElementFunc::is_finite;
      
      Rstats::Vector<Rstats::Logical>* v_out = Rstats::VectorFunc::operate_unary_is(func, v1);
      
      return v_out;
    }
  }
}
