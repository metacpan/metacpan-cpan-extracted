#include <iostream>

// Test checking function names
double Farenheit()
{
	return -32.0;
}

int main()
{
	// Test camelCase variable names
	double farenheitTemp = 35.0;
	std::cout << "The temperature is "
		<< farenheitTemp << " degrees Farenheit"
		<< std::endl;
		
	// Test CAPS_WITH_UNDERSCORE names
	const double MIN_FARENHEIT = -459.67;
	
	// Test all lowercase names
	double farenheit = -32.0;
	
	// This shouldn't match "s t r a t"
	std::string s = "hotdog";
	std::string d = s.strAt(3);

	// This shouldn't match
	double farenheiten = 0.0;

	// Test adding custom words to the dictionray
	bool hootdog = true;
    
	// Test finding misspellings that overlap
	// another misspelling
	char farenheItnroduced = 'c';

	return 0;
}
