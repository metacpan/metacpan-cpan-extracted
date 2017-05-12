use v6;

=begin Pod
	An example of Parametric roles
	Adopted from http://rakudo.org/2009/01/parametric-roles.html
=end Pod

role Greet[Str $greeting] {
    method greet() { say "$greeting!"; }
}

class EnglishMan does Greet["Hello"] { }

class Slovak does Greet["Ahoj"] { }

class Lolcat does Greet["OH HAI"] { }

# Hello
EnglishMan.new.greet();

# Ahoj
Slovak.new.greet();

# OH HAI
Lolcat.new.greet(); 