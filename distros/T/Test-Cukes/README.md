# NAME

Test::Cukes - A BBD test tool inspired by Cucumber

# SYNOPSIS

Write your test program like this:

    # test.pl
    use Test::Cukes;
    # use Test::Cukes tests => 3;

    feature(<<TEXT);
    Feature: writing behavior tests
      In order to make me happy
      As a test maniac
      I want to write behavior tests

      Scenario: Hello World
        Given the test program is running
        When it reaches this step
        Then it should pass
    TEXT

    Given qr/the (.+) program is (.+)/, sub {
        my ($program_name, $running_or_failing) = @_;
        assert "running program '$program_name'";
    };

    When qr/it reaches this step/, sub {
        assert "reaches";
    };

    Then qr/it should pass/, sub {
        assert "passes";
    };

    runtests;

When it runs, it looks like this:

    > perl test.pl
    1..3
    ok 1 - Given the test program is running
    ok 2 - When it reaches this step
    ok 3 - Then it should pass

# DESCRIPTION

Test::Cukes is a testing tool inspired by Cucumber
([http://cukes.info](http://cukes.info)). It lets your write your module test with
scenarios. It may be used with [Test::More](https://metacpan.org/pod/Test::More) or other family of
TAP `Test::*` modules. It uses [Test::Builder::note](https://metacpan.org/pod/Test::Builder::note) function
internally to print messages.

This module implements the Given-When-Then clause only in English. To
uses it in the test programs, feed the feature text into `feature`
function, defines your step handlers, and then run all the tests by
calling `runtests`. Step handlers may be defined in separate modules,
as long as those modules are included before `runtests` is called.
Each step may use either `assert` or standard TAP functions such as
`Test::Simple`'s `ok` or `Test::More`'s `is` to verify desired
result.  If you specify a plan explicitly, you should be aware that
each step line in your scenario runs an additional test, and will
therefore add to the number of tests you must indicate.

If any assertion in the Given block failed, the following `When` and
`Then` blocks are all skipped.

You don't need to specify the number of tests with `plan`. Each step
block itself is simply one test. If the block died, it's then
considered failed. Otherwise it's considered as passing.

In the call to [Test::Cukes::runtests](https://metacpan.org/pod/Test::Cukes::runtests), [done\_testing](https://metacpan.org/pod/done_testing) will automatically
be called for you if you didn't specify a plan.

Test::Cukes re-exports `assert` function from `Carp::Assert` for you
to use in the step block.

For more info about how to define feature and scenarios, please read
the documents from [http://cukes.info](http://cukes.info).

# AUTHOR

Kang-min Liu <gugod@gugod.org>

# CONTRIBUTORS

Tatsuhiko Miyagawa, Tristan Pratt

# SEE ALSO

The official Cucumber web-page, [http://cukes.info/](http://cukes.info/).

cucumber.pl, [http://search.cpan.org/dist/cucumber/](http://search.cpan.org/dist/cucumber/), another Perl
implementation of Cucumber tool.

[Carp::Assert](https://metacpan.org/pod/Carp::Assert)

# LICENSE

This is free software, licensed under:

    The MIT (X11) License

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
