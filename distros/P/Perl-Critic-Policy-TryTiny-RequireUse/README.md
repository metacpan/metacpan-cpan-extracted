# NAME

Perl::Critic::Policy::TryTiny::RequireUse - Requires that code which utilizes
Try::Tiny actually use()es it.

# DESCRIPTION

A common problem with [Try::Tiny](https://metacpan.org/pod/Try::Tiny) is forgetting to use the module in the first
place.  For example:

    perl -e 'try { print "hello" } catch { print "world" }'
    Can't call method "catch" without a package or object reference at -e line 1.
    helloworld

If you forget this then both code blocks will be run and an exception will be thrown.
While this seems like a rare issue, when I first implemented this policy I found
several cases of this issue in real live code and due to layers of exception handling
it had gotten lost and nobody realized that there was a bug happening due to the missing
use statements.

This policy is OK if you use [Error](https://metacpan.org/pod/Error), [Syntax::Feature::Try](https://metacpan.org/pod/Syntax::Feature::Try), [Try](https://metacpan.org/pod/Try), [Try::Catch](https://metacpan.org/pod/Try::Catch),
and [TryCatch](https://metacpan.org/pod/TryCatch) modules which also export the `try` function.

# SEE ALSO

- The [Perl::Critic::Policy::Dynamic::NoIndirect](https://metacpan.org/pod/Perl::Critic::Policy::Dynamic::NoIndirect) policy provides a more generic
solution to this problem (as the author has reported to me).  Consider it as an
alternative to this policy.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# CONTRIBUTORS

- Graham TerMarsch <graham@howlingfrog.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
