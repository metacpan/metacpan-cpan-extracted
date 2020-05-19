package Test::Cukes;
use strict;
use warnings;
use Test::Cukes::Feature;
use Carp::Assert;
use Try::Tiny;

use base 'Test::Builder::Module';

our $VERSION = "0.11";
our @EXPORT = qw(feature runtests Given When Then assert affirm should shouldnt);

our @missing_steps = ();

my $steps = {};
my $feature = {};

sub feature {
    my $caller = caller;
    my $text = shift;

    $feature->{$caller} = Test::Cukes::Feature->new($text)
}

sub runtests {
    my $caller = caller;
    my $feature_text = shift;

    if ($feature_text) {
        $feature->{$caller} = Test::Cukes::Feature->new($feature_text);
    }

    my @scenarios_of_caller = @{$feature->{$caller}->scenarios};

    for my $scenario (@scenarios_of_caller) {
        my $skip = 0;
        my $skip_reason = "";
        my $gwt;


        for my $step_text (@{$scenario->steps}) {
            my ($pre, $step) = split " ", $step_text, 2;
            if ($skip) {
                Test::Cukes->builder->skip($step_text);
                next;
            }

            $gwt = $pre if $pre =~ /(Given|When|Then)/;

            my $found_step = 0;
            for my $step_pattern (keys %$steps) {
                my $cb = $steps->{$step_pattern}->{code};

                if (my (@matches) = $step =~ m/$step_pattern/) {
                    my $ok = 1;
                    try {
                        $cb->(@matches);
                    } catch {
                        $ok = 0;
                    };

                    Test::Cukes->builder->ok($ok, $step_text);

                    if ($skip == 0 && !$ok) {
                        Test::Cukes->builder->diag($@);
                        $skip = 1;
                        $skip_reason = "Failed: $step_text";
                    }

                    $found_step = 1;
                    last;
                }
            }

            unless($found_step) {
                $step_text =~ s/^And /$gwt /;
                push @missing_steps, $step_text;
            }
        }
    }

    # If the user doesn't specify tests explicitly when they use Test::Cukes;,
    # assume they had no plan and call done_testing for them.
    Test::Cukes->builder->done_testing if !Test::Cukes->builder->has_plan;

    report_missing_steps();

    return 0;
}

sub report_missing_steps {
    return if @missing_steps == 0;
    Test::Cukes->builder->note("There are missing step definitions, fill them in:");
    for my $step_text (@missing_steps) {
        my ($word, $text) = ($step_text =~ /^(Given|When|Then) (.+)$/);
        my $msg = "\n$word qr/${text}/ => sub {\n    ...\n};\n";
        Test::Cukes->builder->note($msg);
    }
}

sub _add_step {
    my ($step, $cb) = @_;
    my ($package, $filename, $line) = caller;

    $steps->{$step} = {
        definition => {
            package => $package,
            filename => $filename,
            line => $line,
        },
        code => $cb
    };
}

*Given = *_add_step;
*When = *_add_step;
*Then = *_add_step;

1;
__END__

=head1 NAME

Test::Cukes - A BBD test tool inspired by Cucumber

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Test::Cukes is a testing tool inspired by Cucumber
(L<http://cukes.info>). It lets your write your module test with
scenarios. It may be used with L<Test::More> or other family of
TAP C<Test::*> modules. It uses L<Test::Builder::note> function
internally to print messages.

This module implements the Given-When-Then clause only in English. To
uses it in the test programs, feed the feature text into C<feature>
function, defines your step handlers, and then run all the tests by
calling C<runtests>. Step handlers may be defined in separate modules,
as long as those modules are included before C<runtests> is called.
Each step may use either C<assert> or standard TAP functions such as
C<Test::Simple>'s C<ok> or C<Test::More>'s C<is> to verify desired
result.  If you specify a plan explicitly, you should be aware that
each step line in your scenario runs an additional test, and will
therefore add to the number of tests you must indicate.

If any assertion in the Given block failed, the following C<When> and
C<Then> blocks are all skipped.

You don't need to specify the number of tests with C<plan>. Each step
block itself is simply one test. If the block died, it's then
considered failed. Otherwise it's considered as passing.

In the call to L<Test::Cukes::runtests>, L<done_testing> will automatically
be called for you if you didn't specify a plan.

Test::Cukes re-exports C<assert> function from C<Carp::Assert> for you
to use in the step block.

For more info about how to define feature and scenarios, please read
the documents from L<http://cukes.info>.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 CONTRIBUTORS

Tatsuhiko Miyagawa, Tristan Pratt

=head1 SEE ALSO

The official Cucumber web-page, L<http://cukes.info/>.

cucumber.pl, L<http://search.cpan.org/dist/cucumber/>, another Perl
implementation of Cucumber tool.

L<Carp::Assert>

=head1 LICENSE

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

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

=cut
