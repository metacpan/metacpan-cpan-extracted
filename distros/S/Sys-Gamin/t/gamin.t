use Test;
use SGI::FAM;

plan tests => 1;

ok (SGI::FAM::FAMChanged != SGI::FAM::FAMDeleted);
