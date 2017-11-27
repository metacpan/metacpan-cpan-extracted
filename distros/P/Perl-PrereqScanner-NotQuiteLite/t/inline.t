use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

# DAVECROSS/Ogg-Vorbis-Header-0.05/Header.pm
test('Inline C', <<'END', {Inline => 0, 'Inline::C' => 0});
use Inline C => 'DATA',
                    LIBS => '-logg -lvorbis -lvorbisfile',
                    INC => '-I/inc',
                    AUTO_INCLUDE => '#include "inc/vcedit.h"',
                    AUTO_INCLUDE => '#include "inc/vcedit.c"',
                    VERSION => '0.05',
                    NAME => 'Ogg::Vorbis::Header';
END

# MIKFIRE/Tivoli-AccessManager-Admin-1.11/Admin.pm
test('Inline C with parenthesis', <<'END', {Inline => 0, 'Inline::C' => 0});
use Inline( C => 'DATA',
        NAME => 'Tivoli::AccessManager::Admin',
        VERSION => '1.11'
      );
END

# STURM/Tibco-Rv-1.15/Rv.pm
test('with option', <<'END', {Inline => 0, 'Inline::C' => 0, 'Tibco::Rv::Inline' => 0});
use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;
END

# PATL/Inline-Java-0.53/Java/PerlInterpreter/PerlInterpreter.pm
test('Inline::Java without VERSION', <<'END', {Inline => 0, 'Inline::Java' => 0});
use Inline (
    Java => 'STUDY',
    EMBEDDED_JNI => 1,
    STUDY => [],
    NAME => 'Inline::Java::PerlInterpreter',
) ;
END

# INGY/Inline-0.80/example/modules/Boo-2.01/lib/Boo/Far.pm
test('with Config', <<'END', {Inline => 0, 'Inline::C' => 0});
use Inline Config => NAME => 'Boo::Far' => VERSION => '2.01';

use Inline C => <<'EOC';

SV * boofar() {
  return(newSVpv("Hello from Boo::Far", 0));
}

EOC
END

done_testing;
