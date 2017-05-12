int f(char a[10], int b[20]) {
  return a[5];
}

int g() {
  char x[5];
  int y[20];
  return f(x,y);
}
