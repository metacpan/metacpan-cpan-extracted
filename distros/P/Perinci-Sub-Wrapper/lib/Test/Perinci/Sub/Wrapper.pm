package Test::Perinci::Sub::Wrapper;

our $DATE = '2021-08-01'; # DATE
our $VERSION = '0.852'; # VERSION

use 5.010;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone);
#use List::Util qw(shuffle);
use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.96;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(test_wrap);

sub test_wrap {
    my %test_args = @_;
    $test_args{wrap_args} or die "BUG: wrap_args not defined";
    my $test_name = $test_args{name} or die "BUG: test_name not defined";

    for my $wrapper_type (qw/dynamic embed/) {
        next if $wrapper_type eq 'dynamic' && $test_args{skip_dynamic};
        next if $wrapper_type eq 'embed'   && $test_args{skip_embed};
        subtest "$test_name ($wrapper_type)" => sub {

            if ($test_args{pretest}) {
                $test_args{pretest}->();
            }

            my $wrap_args = clone($test_args{wrap_args});
            die "BUG: embed must not be specified in wrap_args, test_wrap() ".
                "will always test dynamic (embed=0) *and* embed mode"
                    if exists $wrap_args->{embed};
            if ($wrapper_type eq 'embed') {
                $wrap_args->{embed} = 1;
                #diag explain $wrap_args->{meta};
            } else {
                $wrap_args->{embed} = 0;
            }

            my $wrap_res;
            eval { $wrap_res = wrap_sub(%$wrap_args) };
            my $wrap_eval_err = $@;
            if ($test_args{wrap_dies}) {
                ok($wrap_eval_err, "wrap dies");
                return;
            } else {
                ok(!$wrap_eval_err, "wrap doesn't die") or do {
                    diag $wrap_eval_err;
                    return;
                };
            }

            if (defined $test_args{wrap_status}) {
                is(ref($wrap_res), 'ARRAY', 'wrap res is array');
                is($wrap_res->[0], $test_args{wrap_status},
                   "wrap status is $test_args{wrap_status}")
                    or diag "wrap res: ", explain($wrap_res);
            }

            return unless $wrap_res->[0] == 200;

            my $sub;
            if ($wrapper_type eq 'embed') {
                my $src = $wrap_res->[2]{source};
                my $meta = $wrap_res->[2]{meta};
                my $args_as = $meta->{args_as};
                my $orig_args_as = $wrap_args->{meta}{args_as} // 'hash';
                my $sub_name = $wrap_res->[2]{sub_name};
                my $eval_src = join(
                    "\n",
                    $src->{presub1},
                    $src->{presub2},
                    'sub {',
                    '    my %args;',
                    ('    my @args;') x !!($orig_args_as eq 'array' || $args_as eq 'array'),
                    ('    my $args;') x !!($orig_args_as =~ /ref/ || $args_as =~ /ref/),
                    '    '.
                        ($args_as eq 'hash' ? '%args = @_;' :
                             $args_as eq 'hashref' ? '$args = $_[0] // {}; %args = %$args;' :
                                 $args_as eq 'array' ? '@args = @_;' :
                                     '$args = $_[0] // [];'),
                    $src->{preamble},
                    ($src->{postamble} ? '    $_w_res = do {' : ''),
                    $sub_name. ($sub_name =~ /\A\$/ ? '->':'').'('.
                        ($orig_args_as eq 'hash' ? '%args' :
                             $orig_args_as eq 'hashref' ? '$args' :
                                 $orig_args_as eq 'array' ? '@args' :
                                     '$args').');',
                    ($src->{postamble} ? '}; # do' : ''),
                    $src->{postamble},
                    '}; # sub',
                );
                $sub = eval $eval_src;
                my $eval_err = $@;
                ok(!$eval_err, "embed code compiles ok") or do {
                    diag "eval err: ", $eval_err;
                    diag "eval source: ", $eval_src;
                    return;
                };
                diag "eval source: ", $eval_src
                    if $ENV{LOG_PERINCI_WRAPPER_CODE};
            } else {

                # check that we don't generate comment after code (unless it
                # uses '##' instead of '#'), because this makes cutting comments
                # easier. XXX this is using a simple regex and misses some.
                for my $line (split /^/, $wrap_res->[2]{source}) {
                    if ($line =~ /(.*?)\s+#\s+(.*)/) {
                        my ($before, $after) = ($1, $2);
                        next unless $before =~ /\S/;
                        ok 0; diag "Source code contains comment line after some code '$line' (if you do this, you must use ## instead of # to help ease removing comment lines (e.g. in Dist::Zilla::Plugin::Rinci::Wrap))";
                    }
                }

                $sub = $wrap_res->[2]{sub};
            }

            # testing a single sub call
            my $call_argsr = $test_args{call_argsr};
            my $call_res;
            if ($call_argsr) {
                eval { $call_res = $sub->(@$call_argsr) };
                my $call_eval_err = $@;
                if ($test_args{call_dies}) {
                    ok($call_eval_err, "call dies");
                    if ($test_args{call_die_message}) {
                        like($call_eval_err, $test_args{call_die_message},
                             "call die message");
                    }
                    return;
                } else {
                    ok(!$call_eval_err, "call doesn't die")
                        or diag $call_eval_err;
                }

                if (defined $test_args{call_status}) {
                    is(ref($call_res), 'ARRAY', 'call res is array')
                        or diag "call res = ", explain($call_res);
                    is($call_res->[0], $test_args{call_status},
                       "call status is $test_args{call_status}")
                        or diag "call res = ", explain($call_res);
                }

                if (exists $test_args{call_res}) {
                    is_deeply($call_res, $test_args{call_res},
                              "call res")
                        or diag explain $call_res;
                }

                if (exists $test_args{call_actual_res}) {
                    is_deeply($call_res->[2], $test_args{call_actual_res},
                              "call actual res")
                        or diag explain $call_res->[2];
                }

                if (exists $test_args{call_actual_res_re}) {
                    like($call_res->[2], $test_args{call_actual_res_re},
                         "call actual res");
                }
            }

            # testing multiple sub calls
            if ($test_args{calls}) {
                my $i = 0;
                for my $call (@{$test_args{calls}}) {
                    $i++;
                    subtest "call #$i: ".($call->{name} // "") => sub {
                        my $res;
                        eval { $res = $sub->(@{$call->{argsr}}) };
                        my $eval_err = $@;
                        if ($call->{dies}) {
                            ok($eval_err, "dies");
                            if ($call->{die_message}) {
                                like($eval_err, $call->{die_message},
                                     "die message");
                            }
                            return;
                        } else {
                            ok(!$eval_err, "doesn't die")
                                or diag $eval_err;
                        }

                        if (defined $call->{status}) {
                            is(ref($res), 'ARRAY', 'res is array')
                                or diag "res = ", explain($res);
                            is($res->[0], $call->{status},
                               "status is $call->{status}")
                                or diag "res = ", explain($res);
                        }

                        if (exists $call->{res}) {
                            is_deeply($res, $call->{res}, "res")
                                or diag explain $res;
                        }

                        if (exists $call->{actual_res}) {
                            is_deeply($res->[2], $call->{actual_res}, "actual res")
                                or diag explain $res->[2];
                        }

                        if (exists $call->{actual_res_re}) {
                            like($res->[2], $call->{actual_res_re},
                                 "actual res re");
                        }
                    }; # subtest call #$i
                }
            } # if calls

            if ($test_args{posttest}) {
                $test_args{posttest}->($wrap_res, $call_res, $sub);
            }

            done_testing();

        }; # subtest
    } # for $wrapper_type
}

1;
# ABSTRACT: Provide test_wrap() to test wrapper

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Perinci::Sub::Wrapper - Provide test_wrap() to test wrapper

=head1 VERSION

This document describes version 0.852 of Test::Perinci::Sub::Wrapper (from Perl distribution Perinci-Sub-Wrapper), released on 2021-08-01.

=for Pod::Coverage test_wrap

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Wrapper>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Wrapper>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Wrapper>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
