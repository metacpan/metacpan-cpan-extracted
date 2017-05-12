namespace Rstats {
  namespace Func {
    template <class T>
    SV* new_vector(SV* sv_r, Rstats::Vector<T>* v1) {
      SV* sv_x_out = Rstats::Func::new_vector<T>(sv_r);
      Rstats::Func::set_vector<T>(sv_r, sv_x_out, v1);
      
      return sv_x_out;
    }
  }

}
