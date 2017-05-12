#define x    3
#define f(a) f(x * (a))
#undef   x
#define x    2
#define g    f
#define z    z[0]
#define h    g(~
#define m(a) a(w)
#define w    0,1
#define t(a) a
#pragma start
f(y+1) + f(f(z)) % t(t(g)(0) + t)(1);
#pragma compare "f(2*(y+1))+f(2*(f(2*(z[0]))))%f(2*(0))+t(1);"
#pragma start
g(x+(3,4)-w) | h 5) & m (f)^m(m);
#pragma compare "f(2*(2+(3,4)-0,1))|f(2*(~5))&f(2*(0,1))^m(0,1);"
/*
f(2 * (y+1)) + f(2 * (f(2 * (z[0])))) % f(2 * (0)) + t(1);
f(2 * (2+(3,4)-0,1)) | f(2 * ( ~5)) & f(2 * (0,1))^m(0,1);
*/

