package Fruit;
sub eat  { 'yum yum' }

package Banana;
use base 'Fruit';
sub peel { 'ready to eat' }

1;
