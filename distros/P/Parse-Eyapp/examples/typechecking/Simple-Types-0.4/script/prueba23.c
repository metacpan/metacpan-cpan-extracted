int f(char a[10], int b) {
  return a[5];
}

int h(int x) {
  return x*2;
}

int g() {
  char x[5];
  int y[19][30];
  f(x,h(y[1][1]));
}
