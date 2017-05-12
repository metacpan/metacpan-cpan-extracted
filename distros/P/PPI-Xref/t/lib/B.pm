package B;
use A;
sub b1 {}
no A;
sub b2 {}
package C;
sub c1 { package D; sub d1 {} }
require E;
package D { sub d2 {} }
1;
