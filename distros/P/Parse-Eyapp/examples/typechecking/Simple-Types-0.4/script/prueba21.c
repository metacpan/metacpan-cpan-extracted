int f(char a[10], int b[20][30]) {
  return a[5];
}

int g() {
  char x[5];
  int y[19][40];
  f(x,y);
}
