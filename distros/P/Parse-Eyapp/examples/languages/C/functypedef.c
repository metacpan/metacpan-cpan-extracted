// Solution using a typedef: Define a pointer to a function which is taking
// two floats and returns a float
typedef float(*pt2Func)(float, float);

// Function takes a char and returns a function pointer which is defined
// with the typedef above. <opCode> specifies which function to return
pt2Func GetPtr2(const char opCode)
{
   if(opCode == '+')
      return &Plus;
   else
      return &Minus; // default if invalid operator was passed
}

// Define a function pointer and initialize to NULL
int (*pointer2Function)(float, char, char) = NULL;    
