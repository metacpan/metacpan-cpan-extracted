#include "xshelper.h"

#include "foo.h"
#include "foo/bar.h"
#include "foo/baz.h"

X(bar_is_ok)(
	X(a), X(b), X(c)
){
	return a + b + c;
}

