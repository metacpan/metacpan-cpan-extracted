package Template::Plugin::Reverse2VMethod;
use Template::Plugin::VMethods;
@ISA = qw(Template::Plugin::VMethods);
@SCALAR_OPS = ( reverse => \&reverse_string);
@LIST_OPS   = ( reverse => \&reverse_list);
sub reverse_string  { scalar reverse $_[0] }
sub reverse_list    { [ reverse map { scalar reverse $_ } @{ $_[0] } ] }
1;

