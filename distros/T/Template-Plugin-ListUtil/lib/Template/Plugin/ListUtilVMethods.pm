package Template::Plugin::ListUtilVMethods;
use Template::Plugin::VMethods;
@ISA = qw(Template::Plugin::VMethods);

use Template::Plugin::ListUtil;
$VMETHOD_PACKAGE = 'Template::Plugin::ListUtil';

@LIST_OPS = qw(largest largeststr smallest smalleststr
	       shuffle random
	       even odd total median mean mode
               anytrue alltrue nonetrue notalltrue
               anyfalse allfalse nonefalse notallfalse
               true false);
1;
