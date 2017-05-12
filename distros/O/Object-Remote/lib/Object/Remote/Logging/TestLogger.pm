#During testing of Object::Remote this logger is connected
#to the router and runs at trace level but does not output anything.
#This lets the logging codeblocks get executed and included
#in the testing.

package Object::Remote::Logging::TestLogger;

use base qw ( Object::Remote::Logging::Logger );

#don't need to output anything
sub _output { }

1;
