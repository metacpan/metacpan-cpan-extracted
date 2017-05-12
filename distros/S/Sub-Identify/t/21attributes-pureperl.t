#!perl

BEGIN { $ENV{PERL_SUB_IDENTIFY_PP} = 1; push @INC, '.' }

require("t/20attributes.t");
