test (int n, int m)
{
  while (n > 0) {
    if (n>m) {
      break;
    }
    else if (m>n){
      continue;
    }
    n = n-1;
  }
}
