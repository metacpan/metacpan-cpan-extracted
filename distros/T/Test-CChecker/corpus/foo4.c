int
main(int argc, char *argv[])
{
#if FOO_BAR_BAZ
  return 0;
#else
  this constitutes a synatax error
#endif
}
