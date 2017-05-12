#
#===============================================================================
#
#         FILE: 01-package.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Rao Chenlin (chenryn), chenlin7@staff.sina.com.cn
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2014/07/04 16时55分48秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Rex::Test::Spec;

describe "test desc", sub {
  context run("w"), sub {
    like its('stdout'), qr/load/;
  };
};

done_testing;
