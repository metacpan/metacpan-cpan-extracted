public class HelloWorld
{
	public void printMessage(String message) {
		System.out.println(message);
	}
	
    public static void main(String[] args) {
        new HelloWorld().printMessage("Hello world!");
    }
}
