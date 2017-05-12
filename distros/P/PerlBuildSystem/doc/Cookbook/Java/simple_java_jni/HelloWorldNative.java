public class HelloWorldNative
{

      private native void print();

      public static void main (String [ ] args) {
		  new HelloWorldNative().print();
      }

      static {
            System.loadLibrary ("HelloWorldNative") ;
      }
}
