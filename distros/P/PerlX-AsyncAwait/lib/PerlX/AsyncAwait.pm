package PerlX::AsyncAwait;

use strictures 2;

our $VERSION = '0.001003';

=head1 NAME

PerlX::AsyncAwait - async/await keywords in pure perl

=head1 EXPERIMENTAL

This is batshit crazy, even for mst. No warranty, express or implied.

=head1 SYNOPSIS

First recommendation:

  use Future::AsyncAwait; # instead

because it's XS and does suspend/resume properly and will perform better.

This module, on the other hand, is an attempt to make it all work in pure
perl, by rewriting your code into a .pmc file that contains extra code to
handle suspend/resume at the pure perl level. Which is great if you want
fatpacking or support for older perls, but not the best solution otherwise.

That said:

  use PerlX::Generator::Runtime;
  use PerlX::Generator::Compiler;
  
  my $f = async_do {
    ...
    await some_future_returning_function();
    ...
    return ...;
  };
  
  my $result = $loop->await($f);

  my $sub = async_sub {
    ...
    await some_future_returning_function($_[0]);
    ...
    return ...;
  };
  
  my $result = $loop->await($sub->(...));

This will result in a .pmc file that depends only on
PerlX::AsyncAwait::Runtime. See the examples/ directory for what the
results end up looking like. Note that the order is important, you *must*
use the runtime *before* the compiler or weirdness will ensue.

Note that since the .pmc does not require the compiler, on the author side
you will need to depend on Module::Compile directly.

=head1 DESCRIPTION

There should be details here but I'm shipping this now so the YAPC::EU
crowd can play with it.

=head1 LIMITATIONS

We rewrite C<foreach> into a 3-arg C<for> so you *can* await inside a
foreach loop.

We do not handle 'local' in any way shape or form that. I'll add that later.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2017 the PerlX::AsyncAwait L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
