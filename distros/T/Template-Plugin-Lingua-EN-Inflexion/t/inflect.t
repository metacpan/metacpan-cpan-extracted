#
#===============================================================================
#
#         FILE: inflect.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 13/08/19 22:30:54
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Template::Test;

test_expect (\*DATA);

__END__
--test--
[%- # testing inflect filter with a block
    USE Lingua.EN.Inflexion;
	count = 42;
	FILTER inflect(); -%]
There <#d:[% count %]> <V:were> [% count %] <N:error>.
<A:This> <N:error> <V:was> fatal.
[%
		    END;
-%]
--expect--
There were 42 errors.
These errors were fatal.

--test--
[% USE Lingua.EN.Inflexion -%]
[% "<#:3> <N:error>." | inflect -%]
--expect--
3 errors.

--test--
[% USE Lingua.EN.Inflexion -%]
[% "<#d:0>There <V:was> <#n:0> <N:error>." | inflect -%]
--expect--
There were no errors.

--test--
[%  # testing inflect
    USE Lingua.EN.Inflexion;
    "<#d:1>There <V:was> <#n:1> <N:error>." | inflect;
 -%]
--expect--
There was 1 error.

--test--
[%- # testing inflect
    USE Lingua.EN.Inflexion;
	n = 3;
    "<#d:$n>There <V:was> <#n:$n> <N:error>." | inflect;
 -%]
--expect--
There were 3 errors.

--test--
[%  # testing NO equiv
    USE Lingua.EN.Inflexion;
    FOREACH n IN [ 0, 1, 2, 3, 42 ];
        #Lingua.EN.Inflexion.inflect.("<#n:2> <N:cat>");
        "<#n:$n> <N:cat>" | inflect;
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
no cats, 1 cat, 2 cats, 3 cats, 42 cats

# Uncomment these when you have new enough Inflexion
--test--
[%  # testing cardinal() for 1, 2, 3, ...
    USE i = Lingua.EN.Inflexion;
    FOREACH n IN [ 1, 2, 3, 4, 42, 1000 ];
        i.noun(n).cardinal;
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
one, two, three, four, forty-two, one thousand

--test--
[%  # testing ordinal()
    USE Lingua.EN.Inflexion;
    FOREACH n IN [ 1, 2, 3, 4, 5, 100 ];
        Lingua.EN.Inflexion.noun(n).ordinal(0);
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
1st, 2nd, 3rd, 4th, 5th, 100th

--test--
[%  # testing verb()
    USE Lingua.EN.Inflexion;
    FOREACH v IN [ 'has', 'sit', 'eat' ];
        Lingua.EN.Inflexion.verb(v).past; ', ';
        Lingua.EN.Inflexion.verb(v).pres_part; ', ';
        Lingua.EN.Inflexion.verb(v).past_part;
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
had, having, had, sat, sitting, sat, ate, eating, eaten

--test--
[%  # testing adj()
    USE Lingua.EN.Inflexion;
    FOREACH v IN [ 1, 2, 3 ];
        Lingua.EN.Inflexion.adj('our').singular(v); ', ';
        Lingua.EN.Inflexion.adj('our').plural(v);
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
my, our, your, your, its, their

