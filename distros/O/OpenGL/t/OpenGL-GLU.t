use strict;
use warnings;

use OpenGL::GLU ':constants';
use Test::More;

foreach my $constname (qw(
	GLU_AUTO_LOAD_MATRIX GLU_BEGIN GLU_CCW GLU_CULLING GLU_CW
	GLU_DISPLAY_MODE GLU_DOMAIN_DISTANCE GLU_EDGE_FLAG GLU_END GLU_ERROR
	GLU_EXTENSIONS GLU_EXTERIOR
	GLU_VERSION_1_1 GLU_VERSION_1_2 GLU_VERTEX GLU_V_STEP)) {
  eval "my \$a = $constname";
  is $@, '';
}

pass 'non-zero tests needed';

done_testing;
