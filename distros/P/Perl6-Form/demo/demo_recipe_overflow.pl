use Perl6::Form;

my $recipe = "Hecate's Broth of Avarice";

my $prep_time = "66.6 minutes";

my $ingredients = <<EOWHAT;
2 snakes (1 fenny, 1 adder)
2 lizards (1 legless, 1 legged)
3 eyes of newt (fresh or pickled)
2 toad toes (canned are fine)
2 cups of bat's wool
1 dog tongue
1 common or spotted owlet
EOWHAT

my $serves = "2 doomed souls";

my $method = <<EOHOW;
Remove the legs from the lizard, the wings from the owlet, and the tongue of the adder. Set them aside. Refrigerate the remains (they can be used to make a lovely white-meat stock). Drain the newts' eyes if using pickled. Wrap the toad toes in the bat's wool and immerse in half a pint of vegan stock in bottom of a preheated cauldron. (If you can't get a fresh vegan for the stock, a cup of boiling water poured over a vegetarian holding a sprouted onion will do). Toss in the fenny snake, then the legless lizard. Puree the tongues together and fold gradually into the mixture, stirring awithershins at all times.  Allow to bubble for 45 minutes then decant into two defiled onyx chalices.  Garnish each with an owlet wing, and serve immediately.
EOHOW


print form {bullet=>'*'},
	'=================[ {||||||||||||||||||||||||||} ]=================',
								  $recipe,
	'                                                                  ',
	'Preparation time:               Method:                           ',
	'   {<<<<<<<<<<<<<<<<<<<<}          {<<<<<<<<<<<<<<<<<<<<<<<<<<<<} ',
		$prep_time,                     $method,
	'                                   {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
	'Serves:                            {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
	'   {<<<<<<<<<<<<<<<<<<<<}          {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
		$serves,                        
	'                                   {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
	'Ingredients:                       {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
	'   * {[[[[[[[[[[[[[[[[[[}          {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
		$ingredients;
