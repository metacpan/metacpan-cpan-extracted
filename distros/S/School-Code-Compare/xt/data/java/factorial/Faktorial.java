public class Faktorial
{
    /*  Bla
     *  bli
     *  blubb
     */
	public static void main(String[] args)
	{
		final int NUM_FAKTS = 100;
		for(int i = 0; i < NUM_FAKTS; i++) {
			System.out.println( i + "! is " + faktorial(i));
        }
	}
	
    // Kommentar
	public static int faktorial(int n)
	{
		int resultat = 1;
		for(int i = 2; i <= n; i++) {
			resultat *= i;
		}
		return resultat;
	}
}
