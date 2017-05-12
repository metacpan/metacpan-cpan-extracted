import example4.*;
import example5.testclass;

/* This should be ignored, fixed in v1.03 */
/*
import nosuchclass;
*/

/* This should be ignored, fixed in v1.03 */
//import nosuchclass;


class example1.testclass
{
   function testclass()
   {
      var t = new example6.testclass();
      var tw = new Tween(); /* special case, fixed in v1.03 */
   }
   static function makeone()
   {
      return new testclass(); /* own class, fixed in v1.03 */
      return new no.such["class"](); /* obfuscated class, fixed in v1.03 */
   }
}
