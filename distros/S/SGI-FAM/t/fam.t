use Test::Helper;
test {
  use SGI::FAM qw(FAM_DEBUG_ON FAM_DEBUG_OFF);
  ok +(FAM_DEBUG_ON != FAM_DEBUG_OFF);
  ok +(SGI::FAM::FAMChanged != SGI::FAM::FAMDeleted);
};
