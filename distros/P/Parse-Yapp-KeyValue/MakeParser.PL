use Parse::Yapp;

my $path	= 'blib/lib/Parse/Yapp/KeyValue';
my $file	= "$path/Parser.pm";
my $parser	= new Parse::Yapp(inputfile => 'grammar.yp');

mkdir $path || die "could not create directory $path: $!";
die "unable to create Yapp parser for grammar.yp: $!" if not defined $parser;

open(FILE, ">$file") || die "unable to open $file: $!";
print FILE $parser->Output(classname => 'Parse::Yapp::KeyValue::Parser');
close FILE;

