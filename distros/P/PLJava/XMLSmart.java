
package perl5.lib ;

import perl5.* ;

public class XMLSmart {

  SV XML ;
  
  static {
    if ( !Perl.use("XML::Smart") ) {
      System.err.println("XMLSmart - Error on loading Perl library:\n" + Perl.error() );	
    }
    
  }
  
  public XMLSmart() {
     XML = Perl.NEW("XML::Smart") ;
     Perl.dump_error() ;
  }
  
  public XMLSmart(SV sv) {
     XML = sv ;
  }
  
  public XMLSmart(String xml) {
     XML = Perl.NEW("XML::Smart" , Perl.quoteit(xml) ) ;
     Perl.dump_error() ;
  }
  
  public XMLSmart(String xml , String args) {
     XML = Perl.NEW("XML::Smart" , Perl.quoteit(xml) + "," + args) ;
     Perl.dump_error() ;
  }
  
  /////////////////////////////////////////////////////////////////////////////
  
  public XMLSmart key(String k) {
     return new XMLSmart( XML.key_sv(k) ) ;
  }
  
  public XMLSmart k(String k) { return key(k) ;}
  
  public XMLSmart elem(int x) {
     return new XMLSmart( XML.elem_sv(x) ) ;
  }
  
  public XMLSmart e(int x) { return elem(x) ;}
  
  public int size() { return XML.size() ;}
  
  /////////////////////////////////////////////////////////////////////////////
  
  public XMLSmart get(String path) { return new XMLSmart( XML.get_sv(path) ) ;}
  
  /////////////////////////////////////////////////////////////////////////////
  
  public XMLSmart set(String path , String args) { return new XMLSmart( XML.set_sv(path,args) ) ;}
  
  /////////////////////////////////////////////////////////////////////////////
  
  public String data() { return XML.call("data") ;}  
  public String data_pointer() { return XML.call("data_pointer") ;}  
  
  public String save(String path) { return XML.call("save" , Perl.quoteit(path) ) ;}  
  
  /////////////////////////////////////////////////////////////////////////////
  
  public String dump_tree() { return XML.call("dump_tree") ;}  
  public String dump_tree_pointer() { return XML.call("dump_tree_pointer") ;}  
  
  /////////////////////////////////////////////////////////////////////////////
  
  public SV SV() { return XML ;}
  
  public String Str() { return XML.Str() ;}
  public String str() { return Str() ;}
  
  public int Int() { return Perl.Str2Int( XML.Str() ) ;}
  
  public boolean Bool() { return (XML.Str().equals("0") || XML.Str().equals("")) ? false : true ;}
  
  /////////////////////////////////////////////////////////////////////////////
  
  public String toString() { return XML.Str() ;}
  public static String toString(XMLSmart xml)   { return xml.Str() ;}

}


