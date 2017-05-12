#line 1
package Test::Cukes;
use strict;
use warnings;
use Test::Cukes::Feature;
use Carp::Assert;
use Try::Tiny;

use base 'Test::Builder::Module';

our $VERSION = "0.10";
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

#line 252
