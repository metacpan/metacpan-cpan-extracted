
public class CallbackTest extends Callback {
    static {
 	CallbackTest c = new CallbackTest();
 	c.callback("receive_callback", "This is a test.");
    }
}
