package Template::Plugin::GoSplatVMethod;
use Template::Plugin::VMethods;
@ISA = (Template::Plugin::VMethods);

$VMETHOD_PACKAGE = 'Template::Plugin::GoSplat';

@SCALAR_OPS = ("gosplat");
1;
