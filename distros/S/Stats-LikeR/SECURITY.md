# Security policy

## Reporting a vulnerability

Please report security issues privately, by email to dec986@gmail.com,
rather than by opening an issue on the GitHub tracker, which is public.

It helps if you can include the version of Stats::LikeR, the output of
`perl -V` (or at least `nvtype`, `ivsize` and `useithreads` — much of this
module is C, and a memory bug there is often specific to an NV width or to a
32-bit `IV`), the platform, and a short script that shows the problem
together with any input file it needs.

Stats::LikeR is maintained by one person, unpaid, so there is no guaranteed
response time and no bounty. Reports are nevertheless taken seriously, and
you will be credited in `Changes` for anything that leads to a fix unless you
would rather not be.

## Which versions are supported

Only the most recent release on CPAN. Fixes are shipped as a new release
rather than as a patch to an older one.

## Scope

Most of Stats::LikeR is XS. The statistics are computed in C, over buffers
the module allocates and indexes itself, from data a caller may well have
taken from somewhere untrusted. So anything in that path is in scope: an
out-of-bounds read or write, a use-after-free, an integer overflow in a size
computation, an unbounded allocation, or an outright crash, reached either
from a Perl data structure handed to one of the functions or from a file read
by `read_table()`. Dying with a `croak` on malformed input is the designed
behaviour and is not a vulnerability; corrupting memory instead of croaking
is.

`read_table()` is the one place the module parses a file format, and it is
the most interesting surface here. A file whose name ends in `.xlsx` is read
as the ZIP archive it is, and the fast path walks the archive's central
directory and inflates the worksheet part with `Compress::Raw::Zlib`
directly rather than going through `IO::Uncompress::Unzip`, so a malformed
archive — impossible offsets, a local header whose sizes disagree with the
central directory's, a member that decompresses to far more than it claims —
is reaching code written here. Reports of that kind are welcome. Note that
nothing in a spreadsheet is ever evaluated: no formulas, no external
references, no `eval` of any kind on file content. A cell is data.

Out of scope:

- **The random numbers.** `sample()`, `runif()`, `rnorm()` and the rest draw
  from `Drand01()`, which is perl's own generator — the one behind `rand()` —
  so that `srand($seed)` makes a draw reproducible the way `set.seed()` does
  in R. That is deliberate and documented. It is not a cryptographic PRNG,
  and nothing here should be used to produce keys, tokens, salts, passwords
  or anything else that has to be unguessable.
- **Paths the caller supplies.** `read_table()` and `write_table()` open
  exactly the path they are given. A program that builds one out of untrusted
  data, or writes into a directory other users can write to, has the problem
  in the *calling* program, and Stats::LikeR will faithfully open whatever
  comes out of it.
- **Resource use proportional to the input.** A frame that is large because
  the caller asked for a large file to be read is not a denial of service.
  Memory that grows without bound on input that is *small* is, and is in
  scope.
