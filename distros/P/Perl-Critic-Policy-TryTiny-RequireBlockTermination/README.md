# NAME

Perl::Critic::Policy::TryTiny::RequireBlockTermination - Requires that
try/catch/finally blocks are properly terminated.

# DESCRIPTION

A common problem with [Try::Tiny](https://metacpan.org/pod/Try::Tiny) is forgetting to put a semicolon after the
try/catch/finally block which can lead to difficul to debug issues.  While
[Try::Tiny](https://metacpan.org/pod/Try::Tiny) does do its best to detect this issue it cannot if the code after
the block returns an empty list.

For example, this will fail:

    try { } catch { }
    my $foo = 2;

Since the `my $foo=2` returns `2` and `try` throws an exception that an
unexpected argument was passed.

But this will not fail:

    try { } catch { }
    grep { ... } @some_empty_list;

With the above the code after the try blocks produces an empty list.  Lots of
different things produce empty lists.  When this happens the code after the try
blocks is executed BEFORE the try blocks are executed since they are evaluated
as arguments to the try function!

And this also does not fail:

    try { } catch { }
    return()

Flow control logic after the try blocks will execute before the try blocks are executed
for the same reason as the previous example.

There is one situation (that the author is aware of) where non-terminated try blocks
makes sense.

    try { } catch { } if ...;

In this case the code will run as expected, the if, when evaluating to true, will
cause the try blocks to be run, and if false they will not be run.  Despite this
working this module fails on it.  If this is something that you think is important
to support the author is happy to accept requests and patches.

Note that this policy should be just as useful with other similar modules such as
[Try::Catch](https://metacpan.org/pod/Try::Catch) and [TryCatch](https://metacpan.org/pod/TryCatch).

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
