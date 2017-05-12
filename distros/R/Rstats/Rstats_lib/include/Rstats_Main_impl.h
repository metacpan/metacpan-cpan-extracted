namespace Rstats {
  template <class T> T pl_object_unwrap(SV* sv_object, const char* class_name) {

    if (sv_isobject(sv_object) && sv_derived_from(sv_object, class_name)) {
      SV* perl_obj = SvRV(sv_object);
      IV obj_addr = SvIV(perl_obj);
      T c_obj = INT2PTR(T, obj_addr);
      
      return c_obj;
    }
    else {
      croak("Can't unwrap not %s object(Rstats::pl_object_unwrap)", class_name);
    }
  }

  template <class T> SV* pl_object_wrap(T ptr, const char* class_name) {
    IV obj_addr = PTR2IV(ptr);
    SV* sv_obj_addr = pl_new_sv_iv(obj_addr);
    SV* sv_obj_addr_ref = pl_new_rv(sv_obj_addr);
    SV* perl_obj = sv_bless(sv_obj_addr_ref, gv_stashpv(class_name, 1));
    
    return perl_obj;
  }
}
