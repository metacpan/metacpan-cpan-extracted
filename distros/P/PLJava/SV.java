/*******************************************************************************
## Name:        SV.java
## Purpose:     Java representation of a Perl SV
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/07/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
*******************************************************************************/

/*

  Perl SV are the internal objects for data in Perl, and can hold a SCALAR,
  ARRAY, HASH, GLOB, CODE and objects (blessed references).

*/

package perl5 ;

public class SV {

  private int ID ;

  public SV( int id ) {
    _new(id) ;
  }
  
  public SV( String id ) {
    _new( Perl.Str2Int(id) ) ;
  }
  
  private void _new( int id ) {
    ID = id ;  
  }
  
  public int id() { return ID ;}

  public String Str() {
    return Perl.eval("PLJava::SV_val("+ ID +")") ;
  }
  
  public String str() { return Str() ;}
  
  public String type() {
    return Perl.eval("PLJava::SV_type("+ ID +")") ;
  }
                    
  public String dump() {
    return Perl.eval("PLJava::SV_dump("+ ID +")") ;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  public int size() {
  	return Perl.Str2Int( Perl.eval("PLJava::SV_size("+ ID +")") ) ;
  }
  
  public String elem(int x) {
    return Perl.eval("PLJava::SV_elem("+ ID +" , "+ x +")") ;
  }
  
  public SV elem_sv(int x) {
    return Perl.eval_sv("PLJava::SV_elem("+ ID +" , "+ x +")") ;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  public String key(String k) {
    return Perl.eval("PLJava::SV_key("+ ID +" , "+ Perl.quoteit(k) +")") ;
  }
    
  public SV key_sv(String k) {
    return Perl.eval_sv("PLJava::SV_key("+ ID +" , "+ Perl.quoteit(k) +")") ;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  public String get(String path) {
    return Perl.eval("PLJava::SV_get("+ ID +" , "+ Perl.quoteit(path) +")") ;
  }
  
  public SV get_sv(String path) {
    return Perl.eval_sv("PLJava::SV_get("+ ID +" , "+ Perl.quoteit(path) +")") ;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  public String set(String path , String args) {
    return Perl.eval("PLJava::SV_set("+ ID +" , "+ Perl.quoteit(path) + "," + args +")") ;
  }
  
  public SV set_sv(String path , String args) {
    return Perl.eval_sv("PLJava::SV_set("+ ID +" , "+ Perl.quoteit(path) + "," + args +")") ;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  public String call(String method) {
    return Perl.eval("PLJava::SV_call("+ ID +" , "+ Perl.quoteit(method) +")") ;
  }
  
  public String call(String method , String args) {
    return Perl.eval("PLJava::SV_call("+ ID +" , "+ Perl.quoteit(method) +" , "+ args +")") ;
  }
  
  public SV call_sv(String method) {
    return Perl.eval_sv("PLJava::SV_call("+ ID +" , "+ Perl.quoteit(method) +")") ;
  }
  
  public SV call_sv(String method , String args) {
    return Perl.eval_sv("PLJava::SV_call("+ ID +" , "+ Perl.quoteit(method) +" , "+ args +")") ;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  public String evalid() {
    return "PLJava::get_SV("+ ID +")" ;
  }
  
  public void undef() {
    Perl.eval("PLJava::SV_destroy("+ ID +")") ;
  }
  
  public String toString() { return this.Str() ;}
  public static String toString(SV sv)   { return sv.Str() ;}
  
  //protected void finalize() throws Throwable { undef() ;}

}


