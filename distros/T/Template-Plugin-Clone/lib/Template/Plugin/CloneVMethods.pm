package Template::Plugin::CloneVMethods;
use Template::Plugin::VMethods;
use base qw(Template::Plugin::VMethods);
use Template::Plugin::Clone;
$VMETHOD_PACKAGE = 'Template::Plugin::Clone';
@SCALAR_OPS = qw(clone);
@LIST_OPS   = qw(clone);
@HASH_OPS   = qw(clone);
1;
