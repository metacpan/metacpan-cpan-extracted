
import perl5.Perl ;
import perl5.SV ;

public class test {

  public static void main(String argv[]) {
     
     Perl.eval("print qq`Hello World!\n` ;") ;
     
     Perl.eval("print qq`TIME: ` . time() . qq`\n`;") ;
     Perl.eval("print q`\n@INC:\n` ;") ;
     Perl.eval("foreach my $INC_i ( @INC ) { print qq~  $INC_i\n~ ;}") ;
     
     Perl.eval("print q`\nERROR:\n` ;") ;
     Perl.eval("warn(q`This is a warning!`) ;") ;
     System.out.println( Perl.error() ) ;
     
     Perl.eval("print q`\nMATH:\n` ;") ;
     
     int i ;
     
     i = Perl.eval_int(" 2**10 ") ;
     System.out.println( i ) ;

     i = Perl.eval_int(" 10/3 ") ;
     System.out.println( i ) ;
     
     double d = Perl.eval_double(" 10/3 ") ;
     System.out.println( d ) ;
     
     System.out.println( "============================" ) ;
     
     SV sv = Perl.eval_sv("123456") ;
     System.out.println( "ID: " + sv.id() ) ;
     System.out.println( "Type: " + sv.type() ) ;
     System.out.println( "Val: " + sv.Str() ) ;
     
     System.out.println( "============================" ) ;
     
     SV sv1 = Perl.eval_sv("1111") ;
     System.out.println( "ID: " + sv1.id() ) ;
     System.out.println( "Type: " + sv1.type() ) ;
     System.out.println( "Val: " + sv1.Str() ) ;
     
     System.out.println( "============================" ) ;
     System.out.println( "ID: " + sv.id() ) ;
     System.out.println( "Type: " + sv.type() ) ;
     System.out.println( "Val: " + sv.Str() ) ;
     
     System.out.println( "============================" ) ;
     SV sv2 = Perl.eval_sv("[ 't' , time() ]") ;
     System.out.println( "ID: " + sv2.id() ) ;
     System.out.println( "Type: " + sv2.type() ) ;
     System.out.println( "Val: " + sv2.Str() ) ;
     System.out.println( "x: " + sv2.elem(1) ) ;
     
     System.out.println( "============================" ) ;
     
     System.out.println( "<<<<<<<<<<<<<<<" ) ;
 
     oo() ;
     
     System.out.println( ">>>>>>>>>>>>>>>" ) ;
          
     System.out.println( "============================" ) ;
     SV sv3 = Perl.eval_sv("{ 't' => time() }") ;
     System.out.println( "ID: " + sv3.id() ) ;
     System.out.println( "Type: " + sv3.type() ) ;
     System.out.println( "Val: " + sv3.Str() ) ;
     System.out.println( "k: " + sv3.key("t") ) ;
     System.out.println( "elem: " + sv3.elem(0) ) ;
     System.out.println( "call: " + sv3.call("null") ) ;
     
     System.out.println( "============================" + Perl.quoteit("This is a \\' quote 'test'\n!") ) ;

   }

   public static void oo() {
     
     Perl.eval("package foo ; sub new { bless {} ;} sub test { print qq`FOO>> @_\n` } sub DESTROY { print qq`DEST>> @_\n` ; }") ;
     
     SV foo = Perl.NEW("foo") ;
     
     System.out.println( "ID: " + foo.id() ) ;
     System.out.println( "Type: " + foo.type() ) ;
     System.out.println( "Val: " + foo.Str() ) ;
     System.out.println( "call: " + foo.call("test","123 , 456 ," + foo.evalid() ) ) ;
     System.out.println( "dump: " + foo.dump() ) ;
     
     foo.undef() ;

   }

}
