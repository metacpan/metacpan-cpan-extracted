int a,b;

int f(char c) {
  a[2] = 4;
  {
    int d;
    d = a + b;
  }
  c = d * 2;

  while (a < b) {
    if (4 == b) {
      continue;
    }
    else {
      break;
    }
  }
  {
    { {{continue;}}}
  }
  return c;
}

