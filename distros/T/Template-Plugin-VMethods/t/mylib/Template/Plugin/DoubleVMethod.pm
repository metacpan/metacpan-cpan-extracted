package Template::Plugin::DoubleVMethod;
use Template::Plugin::VMethods;
@ISA = qw(Template::Plugin::VMethods);
@SCALAR_OPS = ( double => \&double_string);
@LIST_OPS   = ( double => \&double_list);
sub double_string  { $_[0]x2             }
sub double_list    { [ (@{ $_[0] }) x 2] }
1;

