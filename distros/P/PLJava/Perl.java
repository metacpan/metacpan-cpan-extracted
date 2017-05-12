/*******************************************************************************
## Name:        Perl.java
## Purpose:     Perl embed into Java
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/07/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
*******************************************************************************/


package perl5 ;

import perl5.PLJava ;
import perl5.SV ;

public class Perl {

  private static boolean PLJAVASTOPED = false ;
  private static int REFCOUNT = 0 ;
  
  private static String LASTCODE = "" ;
  private static String THNOW = "" ;

  static {
    try {
      System.loadLibrary("PLJava");
      PLJava.PLJava_start() ;
    }
    catch (UnsatisfiedLinkError e) {
      System.err.println("PLJava - Native code library failed to load. See the chapter on Dynamic Linking Problems in the SWIG Java documentation for help.\n" + e);
      System.exit(1);
    }
  }
  
  ///////////////////////////////////////////////////////////
  
  public Perl() {
    //++REFCOUNT ;
  }
  
  public synchronized static String error() {
    return PLJava.PLJava_error() ;
  }
  
  public static boolean has_error() {
    if ( error().equals("") ) return false ;
    return true ;
  }
  
  public static String dump_error() {
     if ( has_error() ) {
       System.err.println( Perl.error() ) ;
     }
     return Perl.error() ;
  }
  
  public synchronized static void exit() {
    if (!PLJAVASTOPED) {
      eval("exit()") ;
      PLJAVASTOPED = true ;
      PLJava.PLJava_stop() ;
    }
  }
  
  public synchronized static void reset() {
    exit() ;
    PLJAVASTOPED = false ;
    PLJava.PLJava_start() ;
  }
  
  protected void finalize() throws Throwable {
    //--REFCOUNT ;
    //if ( REFCOUNT < 0 ) { REFCOUNT = 0 ;}
  }
  
  ///////////////////////////////////////////////////////////

  public synchronized static SV eval_sv( String code ) {
    SV ret = new SV(0) ;
  	LASTCODE = code ;
    thread_lock() ;
      try {
        ret = new SV( PLJava.PLJava_eval_sv(code) ) ;
      }
      catch (Exception ex) { }
    thread_unlock() ;
    return ret ;
  }
  
  public synchronized static String last_eval() { return LASTCODE ;}
  
  ///////////////////////////////////////////////////////////
  
  public synchronized static String eval( String code )    {
    String ret = "" ;
  	LASTCODE = code ;
    thread_lock() ;
      try {
        ret = PLJava.PLJava_eval(code) ;
      }
      catch (Exception ex) { }
    thread_unlock() ;
    return ret ;
  }
  
  public static String eval_str( String code )    { return eval(code) ;}
  public static byte   eval_byte( String code )   { return Str2Byte( eval(code) ) ;}
  public static int    eval_int( String code )    { return Str2Int( eval(code) ) ;}
  public static double eval_double( String code ) { return Str2Double( eval(code) ) ;}
  public static float  eval_float( String code )  { return Str2Float( eval(code) ) ;}
  public static long   eval_long( String code )   { return Str2Long( eval(code) ) ;}
  public static short  eval_short( String code )  { return Str2Short( eval(code) ) ;}
  
  ///////////////////////////////////////////////////////////
  
  public static void thread_lock() {
    while ( !thread_can() ) {
      try {
        Thread.sleep(50)  ;
      } catch (Exception ex) { }
    }
    THNOW = thread_id() ;
  }
  
  public static void thread_unlock() {
    THNOW = "" ;
  }
  
  private static String thread_id() {
    return "" + Thread.currentThread() ;
  }
  
  public static boolean thread_can() {
    if ( THNOW.equals("") || THNOW.equals( thread_id() ) ) return true ;
    return false ;
  }
  
  ///////////////////////////////////////////////////////////
  
  public static SV NEW(String pkg) {
    return eval_sv("new " + pkg + "()") ;
  }
  
  public static SV NEW(String pkg , String args) {
    return eval_sv("new " + pkg + "("+ args +")") ;
  }
  
  public static boolean use(String pkg) {
    eval("use " + pkg) ;
    return !has_error() ;
  }
  
  public static boolean use(String pkg , String args) {
    eval("use " + pkg + " ("+ args +")") ;
    return !has_error() ;
  }
  
  ///////////////////////////////////////////////////////////
  
  public static String quoteit(String s) {
    String S = "'" ;
    
    String t ;
    
    for(int i = 0 ; i < s.length() ; ++i) {
      t = s.substring(i,i+1) ;
      
      if ( t.equals("\\") || t.equals("'") ) {
        S += "\\" + t ;
      }
      else { S += t ;}
    }
    
    S += "'" ;
    
    return S ;
  }
  
  ///////////////////////////////////////////////////////////
  
  public static byte Str2Byte(String i) {
    if ( i.indexOf(".") >= 0 ) { int p = i.indexOf(".") ; i = i.substring(0,p) ;}
    
    byte o ;
    try { o = Byte.parseByte(i) ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static double Str2Double(String i) {
    double o ;
    try { o = Double.parseDouble(i) ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static float Str2Float(String i) {
    float o ;
    try { o = Float.parseFloat(i) ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static int Str2Int(String i) {
    if ( i.indexOf(".") >= 0 ) { int p = i.indexOf(".") ; i = i.substring(0,p) ;}
    
    int o ;
    try { o = Integer.parseInt(i) ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static long Str2Long(String i) {
    if ( i.indexOf(".") >= 0 ) { int p = i.indexOf(".") ; i = i.substring(0,p) ;}
    
    long o ;
    try { o = Long.parseLong(i) ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static short Str2Short(String i) {
    if ( i.indexOf(".") >= 0 ) { int p = i.indexOf(".") ; i = i.substring(0,p) ;}
    
    short o ;
    try { o = Short.parseShort(i) ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static String Byte2Str(byte i) {
    String o ;
    try { o = Byte.toString(i) ;}
    catch (Exception e) { o = "" ;}
    return o ;
  }

  public static double Byte2Double(byte i) {
    double o ;
    try { o = (double)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static float Byte2Float(byte i) {
    float o ;
    try { o = (float)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static int Byte2Int(byte i) {
    int o ;
    try { o = (int)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static long Byte2Long(byte i) {
    long o ;
    try { o = (long)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static short Byte2Short(byte i) {
    short o ;
    try { o = (short)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static String Double2Str(double i) {
    String o ;
    try { o = Double.toString(i) ;}
    catch (Exception e) { o = "" ;}
    
    if ( o.indexOf(".0") == (o.length()-2) ) { o = o.substring(0, (o.length()-2) ) ;}
    return o ;
  }

  public static byte Double2Byte(double i) {
    byte o ;
    try { o = new Double(i).byteValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static float Double2Float(double i) {
    float o ;
    try { o = new Double(i).floatValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static int Double2Int(double i) {
    int o ;
    try { o = new Double(i).intValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static long Double2Long(double i) {
    long o ;
    try { o = new Double(i).longValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static short Double2Short(double i) {
    short o ;
    try { o = new Double(i).shortValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static String Float2Str(float i) {
    String o ;
    try { o = Float.toString(i) ;}
    catch (Exception e) { o = "" ;}
    
    if ( o.indexOf(".0") == (o.length()-2) ) { o = o.substring(0, (o.length()-2) ) ;}
    return o ;
  }

  public static byte Float2Byte(float i) {
    byte o ;
    try { o = new Float(i).byteValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static double Float2Double(float i) {
    double o ;
    try { o = (double)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static int Float2Int(float i) {
    int o ;
    try { o = new Float(i).intValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static long Float2Long(float i) {
    long o ;
    try { o = new Float(i).longValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static short Float2Short(float i) {
    short o ;
    try { o = new Float(i).shortValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static String Int2Str(int i) {
    String o ;
    try { o = Integer.toString(i) ;}
    catch (Exception e) { o = "" ;}
    return o ;
  }

  public static byte Int2Byte(int i) {
    byte o ;
    try { o = new Integer(i).byteValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static double Int2Double(int i) {
    double o ;
    try { o = (double)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static float Int2Float(int i) {
    float o ;
    try { o = (float)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static long Int2Long(int i) {
    long o ;
    try { o = (long)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static short Int2Short(int i) {
    short o ;
    try { o = new Integer(i).shortValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static String Long2Str(long i) {
    String o ;
    try { o = Long.toString(i) ;}
    catch (Exception e) { o = "" ;}
    return o ;
  }

  public static byte Long2Byte(long i) {
    byte o ;
    try { o = new Long(i).byteValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static double Long2Double(long i) {
    double o ;
    try { o = (double)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static float Long2Float(long i) {
    float o ;
    try { o = (float)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static int Long2Int(long i) {
    int o ;
    try { o = new Long(i).intValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static short Long2Short(long i) {
    short o ;
    try { o = new Long(i).shortValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static String Short2Str(short i) {
    String o ;
    try { o = Short.toString(i) ;}
    catch (Exception e) { o = "" ;}
    return o ;
  }

  public static byte Short2Byte(short i) {
    byte o ;
    try { o = new Short(i).byteValue() ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static double Short2Double(short i) {
    double o ;
    try { o = (double)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static float Short2Float(short i) {
    float o ;
    try { o = (float)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static int Short2Int(short i) {
    int o ;
    try { o = (int)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

  public static long Short2Long(short i) {
    long o ;
    try { o = (long)i ;}
    catch (Exception e) { o = 0 ;}
    return o ;
  }

}


