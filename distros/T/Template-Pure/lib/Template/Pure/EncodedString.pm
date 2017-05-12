package Template::Pure::EncodedString;
 
use strict;
use warnings;
 
use overload q{""} => sub { shift->as_string }, fallback => 1;
 
sub new {
  my ($klass, $str) = @_;
  bless \$str, $klass;
}
 
sub as_string {
  my $self = shift;
  $$self;
}
 
1;

