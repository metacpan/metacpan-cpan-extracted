# NAME

`Regexp::N_Queens` - Solve the `N`-Queens problem by using a regular expression.

# VERSION

This is version `2023021701` of `Regexp::N_Queens`.

# SYNOPSIS

~~~~
use Regexp::N_Queens;

my $N       = 8;
my $solver  = Regexp::N_Queens:: -> new -> init (size => $N);
my $subject = $solver -> subject;
my $pattern = $solver -> pattern;
if ($subject =~ $pattern) {
    foreach my $x (1 .. $N) {
        foreach my $y (1 .. $N) {
            print $+ {"Q_${x}_${y}"} ? "Q" : ".";
        }
        print "\n";
    }
}
else {
    say "No solution for an $N x $N board"
}
~~~~

# DESCRIPTION

Solves the `N`-Queens problem using a regular expression. The `N`-Queens
problem asks you to place `N` Queens on an `N x N` chess board such that
no two Queens attack each other. There are solutions for each positive
`N`, except for `N == 2` and `N == 3`.

After creating the solver object with `new`, and initializing it with
`init` (which takes a `size` parameter indicating the size of the
board), the solver object can be queried by the methods `subject` and
`pattern`. Matching the pattern returned by `pattern` against the string
returned by `subject` solves the `N`-Queens problem: if there is a
match, the Queens can be placed, if there is no match, no solution
exists.

If there is a match, the content of the board can be found in the `%+`
hash: for each square `(x, y)` on the board, with `1 <= x, y <= N`, we
create a key `$key = "Q_${x}_${y}"`. We can now determine whether the
field contain a Queen: if `$+ {$key}` is true, there is a Queen on the
square, else, there is no Queen.

Note that it doesn't matter in which corner of the board you place the
square `(1, 1)`, nor which direction you give to `x` and `y`, as each
reflection and rotation of a solution to the `N`-Queens problem is also
a solution.

# BUGS

# TODO
* Perhaps sometime, write some tests.
* This isn't fast for larger `N`. On the machine this module was written
  on, it does sizes up to 17, and size 19 in less than 1 second, size 18
  in about 3 seconds, size 20 in about 20 seconds, size 21 in just over
  1 second, but it get pretty bad for size 22 and above.

  Some optimizations may be possible.

# SEE ALSO

# DEVELOPMENT

The current sources of this module are found on
[github](https://github.com/Abigail/Regexp-N_Queens).

# AUTHOR

[Abigail](mailto:cpan@abigail.freedom.nl).

# COPYRIGHT and LICENSE

Copyright &copy; 2023 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

# INSTALLATION
To install this module, run, after unpacking the tar-ball, the following
commands:

~~~~
perl Makefile.PL
make
make test
make install
~~~~
