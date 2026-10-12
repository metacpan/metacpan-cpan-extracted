# CONTRIBUTING

Thank you for considering contributing to this distribution. This file
contains instructions that will help you work with the source code.

Please note that if you have any questions or difficulties, you can reach the
maintainer(s) through the bug queue described later in this document
(preferred), or by emailing the releaser directly. You are not required to
follow any of the steps in this document to submit a patch or bug report;
these are recommendations, intended to help you (and help us help you faster).


The distribution is managed with
[Minilla](https://metacpan.org/release/Minilla).

However, you can still compile and test the code with the `Build.PL` in the repository:

    perl Build.PL
    ./Build
    ./Build test

As well as:

    $ prove -bvr t

or

    $ perl -Mblib t/some_test_file.t

You may need to satisfy some dependencies. The easiest way to satisfy
dependencies is to install the last release. This is available at
https://metacpan.org/release/Mojolicious-Plugin-WithCSRFProtection

If you use cpanminus, you can do it without downloading the tarball first:

    $ cpanm --reinstall --installdeps --with-recommends Mojolicious::Plugin::WithCSRFProtection

The code for this distribution is [hosted at GitHub](https://github.com/charsbar/Mojolicious-Plugin-WithCSRFProtection).

You can submit code changes by forking the repository, pushing your code
changes to your clone, and then submitting a pull request. Detailed
instructions for doing that is available here:

https://help.github.com/articles/creating-a-pull-request

If you have found a bug, but do not have an accompanying patch to fix it, you
can submit an issue report [via the web](https://github.com/charsbar/Mojolicious-Plugin-WithCSRFProtection/issues)
.
This is a good place to send your questions about the usage of this distribution.

## Contributor Names

If you send a patch or pull request, your name and email address will be
included in the documentation as a contributor (using the attribution on the
commit or patch), unless you specifically request for it not to be. If you
wish to be listed under a different name or address, you should submit a pull
request to the .mailmap file to contain the correct mapping.
[Check here](https://github.com/git/git/blob/master/Documentation/mailmap.txt)
for more information on git's .mailmap files.
