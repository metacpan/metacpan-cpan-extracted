#!/usr/bin/env groovy

/*
The problem seems to be tht Groovy 'execute' method splits the string by spaces before it proceeds to the
command execution
*/

//"eyapp -b '' -B '' Calc.eyp".execute();

// There seems to ba a problem with quotes in the way Groovy strings are called
//tree = "/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -i -c 'a=2' 2>&1".execute().text; // this will fail
//tree = "/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -i -c a=2 2>&1".execute().text;   // this succeeds
//tree = "./Calc.pm -t -i -c a = 2 2>&1".execute().text;   // this produces the tree for 'a' and leaves = 2 
//tree = "/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -i -f entrada 2>&1".execute().text; // succeeds

//tree = "./hello.pl one 'two' 'a = 2' 'a=' four".execute().text  // Uncomment this to see what the groovy problem is

//tree = "/Users/casianorodriguezleon/LEyapp/examples/yaml/Calc.pm -t -i -c "a=2" 2>&1".execute().text; // this will fail

println "Salida: $tree"

/*
The easier solution will be to create an script without args
which wraps the true script and execute it
*/
