BEGIN { print "1..1\n" }

eval { require OpenInteract::Startup };
if ( $@ ) {
 print "not ";
}
print "ok\n";
