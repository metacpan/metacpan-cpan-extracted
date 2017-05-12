#
#===============================================================================
#
#         FILE: 02-file.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Rao Chenlin (chenryn), chenlin7@staff.sina.com.cn
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2014/07/31 18时55分48秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Rex::Test::Spec;
use Rex::Test::Spec::file;

describe "test desc", sub {
  context file("t/pod.t"), sub {
    is its('ensure'), 'file';
  };
  context file("t/symlink.target"), sub {
    is its('ensure'), 'symlink';
  };
};

done_testing;
