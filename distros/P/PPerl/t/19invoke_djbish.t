#!perl
use strict;
use Test;
plan tests => 2;

`$^X t/invoke_djbish.plx`;
ok($? >> 8, 20);

`./pperl -Iblib/lib -Iblib/arch t/invoke_djbish.plx`;
my $skip = 0;
skip($skip ? "skipping for now, see below" : 0, $? >> 8, 20);

`./pperl -k t/invoke_djbish.plx`;

__END__

=head1 Bug

There's a problem here that this test is trying to cover.

The issue is what happens when a pperl backend process calls
C<exec()>?

Before that happens you have this sort of process layout:

 8930   pperl backend parent
 8931   \ pperl backend child 1
 8932   \ pperl backend child 2

And along comes a pperl process that connects to I<pperl child 2>
which has pid 8932. Now the pperl process is a lightweight C stub
that only hangs around for one thing: To see what exit code comes
back from the backend.

But if the backend C<exec()>s another process, you get:

 8930   pperl backend parent
 8931   \ pperl backend child 1
 8940   \ execed process

And here the C<exec()>ed process won't communicate it's exit code back
to the pperl process, because frankly it doesn't give a damn. In
fact when it finishes, it will exit fully, and we'll have:

 8930   pperl backend parent
 8931   \ pperl backend child 1

So what can we do about this? We play a trick on perl. Instead
of *really* calling C<exec()>, we call C<system()> and then return the
results of the C<system()> call back to the pperl C stub.

This makes this test pass. But it also makes exec not really exec. This
might bum some people out. If so, feel free to comment out the overload
of C<exec()> in F<pperl.h.header>.

=cut
