
# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |20.03.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------


# pragmata
use strict;

# declare a helper package to declare tags
package PerlPoint::Tags::_macros;

# declare base "class"
use base qw(PerlPoint::Tags);

# declare global
use vars qw(%tags %sets);

# load modules
use PerlPoint::Constants qw(:tags);

# declare tags
%tags=(
       B    => {body => TAGS_MANDATORY,},
       I    => {body => TAGS_MANDATORY,},

       FONT => {
                 options => TAGS_MANDATORY,
                 body    => TAGS_MANDATORY,
               },
      );

# flag success
1;
