package Perinci::Sub::To::POD;

our $DATE = '2017-12-09'; # DATE
our $VERSION = '0.862'; # VERSION

use 5.010001;
use Log::ger;
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::Sub::To::FuncBase';

sub BUILD {
    my ($self, $args) = @_;
}

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

# because we need stuffs in parent's gen_doc_section_arguments() even to print
# the name, we'll just do everything in after_gen_doc().
sub after_gen_doc {
    require Data::Dump::SortKeys;
    local $Data::Dump::SortKeys::REMOVE_PRAGMAS = 1;

    my ($self) = @_;

    my $meta  = $self->meta;
    my $dres  = $self->{_doc_res};

    my $orig_meta = $self->{_orig_meta};

    my $has_args = !!keys(%{$dres->{args}});

    $self->add_doc_lines("=head2 $dres->{name}", "");

    $self->add_doc_lines(
        "Usage:",
        "",
        " " . $dres->{name} .
            ($has_args ? $dres->{args_plterm} : "()").' -> '.$dres->{human_ret},
        "");

    {
        my $pdres = $self->parent->{_doc_res};
        my $fnames = $pdres->{function_names_by_meta_addr}{"$orig_meta"};
        if ($fnames && @$fnames > 1) {
            $self->add_doc_lines(
                __("Alias for") . " C<$fnames->[0]>.",
                "",
            );
            return;
        }
    }

    $self->add_doc_lines(
        $dres->{summary}.($dres->{summary} =~ /\.$/ ? "":"."), "")
        if $dres->{summary};

    my $examples = $meta->{examples};
    my $orig_result_naked = $meta->{_orig_result_naked} // $meta->{result_naked};
    my $orig_args_as = $meta->{_orig_args_as} // 'hash';
    my $i = 0;
    my @eg_lines;
    my $arg_sorter = do {
        require Perinci::Sub::Util::Sort;
        require Sort::ByExample;
        my $sorter = Sort::ByExample::sbe(
            [ Perinci::Sub::Util::Sort::sort_args($meta->{args}) ]);
        sub {
            my $hash = shift;
            $sorter->(keys %$hash);
        };
    };
  EXAMPLE:
    for my $eg (@$examples) {
        $i++;
        my $argsdump;
        if ($eg->{args}) {
            local $Data::Dump::SortKeys::SORT_KEYS = $arg_sorter;
            if ($orig_args_as =~ /array/) {
                require Perinci::Sub::ConvertArgs::Array;
                my $cares = Perinci::Sub::ConvertArgs::Array::convert_args_to_array(
                    args => $eg->{args}, meta => $meta,
                );
                die "Can't convert args to argv in example #$i ".
                    "of function $dres->{name}): $cares->[0] - $cares->[1]"
                    unless $cares->[0] == 200;
                $argsdump = Data::Dump::SortKeys::dump($cares->[2]);
                unless ($orig_args_as =~ /ref/) {
                    $argsdump =~ s/\A\[\s*//s; $argsdump =~ s/,?\s*\]\s*\z//s;
                }
            } else {
                $argsdump = Data::Dump::SortKeys::dump($eg->{args});
                unless ($orig_args_as =~ /ref/) {
                    $argsdump =~ s/\A\{\s*//s; $argsdump =~ s/,?\s*\}\s*\z//s;
                }
            }
        } elsif ($eg->{argv}) {
            local $Data::Dump::SortKeys::SORT_KEYS = $arg_sorter;
            if ($orig_args_as =~ /hash/) {
                require Perinci::Sub::GetArgs::Argv;
                my $gares = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
                    argv => [@{ $eg->{argv} }],
                    meta => $meta,
                    per_arg_json => 1,
                    per_arg_yaml => 1,
                );
                die "Can't convert argv to args in example #$i ".
                    "of function $dres->{name}): $gares->[0] - $gares->[1]"
                    unless $gares->[0] == 200;
                $argsdump = Data::Dump::SortKeys::dump($gares->[2]);
                unless ($orig_args_as =~ /ref/) {
                    $argsdump =~ s/^\{\n*//; $argsdump =~ s/,?\s*\}\n?$//;
                }
            } else {
                $argsdump = Data::Dump::SortKey::dump($eg->{argv});
                unless ($orig_args_as =~ /ref/) {
                    $argsdump =~ s/^\[\n*//; $argsdump =~ s/,?\s*\]\n?$//;
                }
            }
        } else {
            # no argv or args, skip, probably not perl example
            next EXAMPLE;
        }
        my $example_code = join(
            "",
            $dres->{name}, "(",
            $argsdump =~ /\n/ ? "\n" : "",
            $argsdump,
            $argsdump =~ /\n/ ? "\n" : "",
            ");",
        );
        my $resdump;
      GET_RESULT:
        {
            last unless $eg->{'x.doc.show_result'} // 1;
            log_trace("result_naked: %s", $meta->{result_naked});
            log_trace("orig_result_naked: %s", $orig_result_naked);
            my $res;
            my $tff;
            if (exists $eg->{result}) {
                $res = $eg->{result};
                unless ($orig_result_naked) {
                    $tff = $res->[3]{'table.fields'};
                }
            } else {
                # XXX since we retrieve the result by calling through Riap,
                # the result will be json-cleaned.
                my %extra;
                if ($eg->{argv}) {
                    $extra{argv} = $eg->{argv};
                } elsif($eg->{args}) {
                    $extra{args} = $eg->{args};
                } else {
                    log_debug("Example does not provide args/argv, skipped trying to get result from calling function");
                    last GET_RESULT;
                }
                my $url;
                if ($self->{url} =~ /\A\w+\z/) {
                    $url = $self->parent->name . $self->{url};
                } else {
                    $url = $self->{url};
                }
                $res = $self->{_pa}->request(call => $url, \%extra);
                unless ($orig_result_naked) {
                    $tff = $res->[3]{'table.fields'};
                }
            }
            $res = $res->[2] unless $orig_result_naked;
            local $Data::Dump::SortKeys::SORT_KEYS = do {
                if ($tff) {
                    require Sort::ByExample;
                    my $sorter = Sort::ByExample::sbe($tff);
                    sub { $sorter->(keys %{$_[0]}) };
                } else {
                    undef;
                }
            };
            $resdump = Data::Dump::SortKeys::dump($res);
        }

        my $status = $eg->{status} // 200;
        my $comment;
        $example_code =~ s/^/ /mg;
        my @result_lines;
        # all fits on a single not-too-long line
        if ($argsdump !~ /\n/ &&
                (!defined($resdump) || $resdump !~ /\n/) &&
                length($argsdump) + length($resdump // "") < 80) {
            if ($status == 200) {
                $comment = "-> $resdump" if defined $resdump;
            } else {
                $comment = "ERROR $status";
            }
        } else {
            if (defined $resdump) {
                my @resdump = split /^/, $resdump;
                if (my $max_lines = $eg->{'x.doc.max_result_lines'}) {
                    $max_lines += 7; # to accomodate extra lines associated with envelopes and array enclosures
                    if (@resdump > $max_lines) {
                        my $n = int($max_lines/2);
                        my $num_remove = @resdump - $max_lines + 1;
                        splice @resdump, $n, $num_remove, "# ...snipped ".($num_remove > 1 ? "$num_remove lines" : "1 line")." for brevity...\n";
                        $resdump = join("", @resdump);
                    }
                }
                push @result_lines, "Result:", "", (map {" $_"} @resdump), "";
            }
        }
        my @summary_lines;
        {
            my $summary = $eg->{summary} //
                "Example #$i".(defined($eg->{name}) ? " ($eg->{name})" :"");
            push @summary_lines, ("=item * $summary" . ":", "");
        }

        my @description_lines;
        push @description_lines, $self->_md2pod($eg->{description}), ""
            if $eg->{description};

        push @eg_lines, (
            @summary_lines,
            $example_code . (defined($comment) ? " # $comment" : ""), "",
            @result_lines,
            @description_lines,
        );
    } # for each example
    if (@eg_lines) {
        $self->add_doc_lines(
            __("Examples") . ":", "",
            "=over", "",
            @eg_lines,
            "=back", "",
        );
    }

    $self->add_doc_lines($self->_md2pod($dres->{description}), "")
        if $dres->{description};

    {
        my $export = $self->{export};
        if (!defined($export)) {
            # unknown
        } elsif ($export == 0) {
            $self->add_doc_lines(__("This function is not exported by default, but exportable."), "");
        } elsif ($export == 1) {
            $self->add_doc_lines(__("This function is exported by default."), "");
        } elsif ($export == -1) {
            $self->add_doc_lines(__("This function is not exported."), "");
        }
    }

    my $feat = $meta->{features} // {};
    my @ft;
    my %spargs;
    if ($feat->{reverse}) {
        push @ft, __("This function supports reverse operation.");
        $spargs{-reverse} = {
            type => 'bool',
            summary => __("Pass -reverse=>1 to reverse operation."),
        };
    }
    # undo is deprecated now in Rinci 1.1.24+, but we still support it
    if ($feat->{undo}) {
        push @ft, __("This function supports undo operation.");
        $spargs{-undo_action} = {
            type => 'str',
            summary => __(
                "To undo, pass -undo_action=>'undo' to function. ".
                "You will also need to pass -undo_data. ".
                "For more details on undo protocol, ".
                "see L<Rinci::Undo>."),
        };
        $spargs{-undo_data} = {
            type => 'array',
            summary => __(
                "Required if you pass -undo_action=>'undo'. ".
                "For more details on undo protocol, ".
                "see L<Rinci::function::Undo>."),
        };
    }
    if ($feat->{dry_run}) {
        push @ft, __("This function supports dry-run operation.");
        $spargs{-dry_run} = {
            type => 'bool',
            summary=>__("Pass -dry_run=>1 to enable simulation mode."),
        };
    }
    push @ft, __("This function is pure (produce no side effects).")
        if $feat->{pure};
    push @ft, __("This function is immutable (returns same result ".
                     "for same arguments).")
        if $feat->{immutable};
    push @ft, __("This function is idempotent (repeated invocations ".
                     "with same arguments has the same effect as ".
                         "single invocation).")
        if $feat->{idempotent};
    if ($feat->{tx}) {
        die "Sorry, I only support transaction protocol v=2"
            unless $feat->{tx}{v} == 2;
        push @ft, __("This function supports transactions.");
        $spargs{$_} = {
            type => 'str',
            summary => __(
                "For more information on transaction, see ".
                "L<Rinci::Transaction>."),
        } for qw(-tx_action -tx_action_id -tx_v -tx_rollback -tx_recovery),
    }
    $self->add_doc_lines(join(" ", @ft), "", "") if @ft;

    if ($has_args) {
        $self->add_doc_lines(
            __("Arguments") .
                ' (' . __("'*' denotes required arguments") . '):',
            "",
            "=over 4",
            "",
        );
        use experimental 'smartmatch';
        for my $name (sort keys %{$dres->{args}}) {
            my $ra = $dres->{args}{$name};
            next if 'hidden'     ~~ @{ $ra->{arg}{tags} // [] };
            next if 'hidden-mod' ~~ @{ $ra->{arg}{tags} // [] };
            $self->add_doc_lines(join(
                "",
                "=item * B<".(($orig_args_as =~ /array/ ? '$' : '').$name).">",
                ($ra->{arg}{req} ? '*' : ''), ' => ',
                "I<", $ra->{human_arg}, ">",
                (defined($ra->{human_arg_default}) ?
                     " (" . __("default") .
                         ": $ra->{human_arg_default})" : "")
            ), "");
            $self->add_doc_lines(
                $ra->{summary} . ($ra->{summary} =~ /\.$/ ? "" : "."),
                "") if $ra->{summary};
            $self->add_doc_lines(
                $self->_md2pod($ra->{description}),
                "") if $ra->{description};
        }
        $self->add_doc_lines("=back", "");
    } else {
        $self->add_doc_lines(__("No arguments") . ".", "");
    }

    if (keys %spargs) {
        $self->add_doc_lines(
            __("Special arguments") . ":",
            "",
            "=over 4",
            "",
        );
        for my $name (sort keys %spargs) {
            my $spa = $spargs{$name};
            $self->add_doc_lines(join(
                "",
                "=item * B<", $name, ">",
                ' => ',
                "I<", $spa->{type}, ">",
                (defined($spa->{default}) ?
                     " (" . __("default") .
                         ": $spa->{default})" : "")
            ), "");
            $self->add_doc_lines(
                $spa->{summary} . ($spa->{summary} =~ /\.$/ ? "" : "."),
                "") if $spa->{summary};
        }
        $self->add_doc_lines("=back", "");
    }

    $self->add_doc_lines($self->_md2pod(__(
"Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.")), "")
         unless $orig_result_naked;

    $self->add_doc_lines(__("Return value") . ': ' .
                         ($dres->{res_summary} // "") . " ($dres->{human_res})",
                         "");
    $self->add_doc_lines("", $self->_md2pod($dres->{res_description}), "")
        if $dres->{res_description};

    # we only show See Also on a per-package basis
    #
    #if ($meta->{links} && @{ $meta->{links} }) {
    #    $self->add_doc_lines(__("See also") . ":", "", "=over", "");
    #    for my $link (@{ $meta->{links} }) {
    #        my $url = $link->{url};
    #        if ($url =~ m!\Apm:(.+)!) {
    #            my $mod = $1;
    #            $self->add_doc_lines("* L<$mod>", "");
    #        } else {
    #            $self->add_doc_lines("* L<$url>", "");
    #        }
    #        $self->add_doc_lines($link->{summary}.".", "") if $link->{summary};
    #        $self->add_doc_lines($self->_md2pod($link->{description}), "") if $link->{description};
    #    }
    #    $self->add_doc_lines("=back", "");
    #}
}

1;
# ABSTRACT: Generate POD documentation from Rinci function metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::To::POD - Generate POD documentation from Rinci function metadata

=head1 VERSION

This document describes version 0.862 of Perinci::Sub::To::POD (from Perl distribution Perinci-To-Doc), released on 2017-12-09.

=head1 SYNOPSIS

You can use the included L<peri-doc> script, or:

 use Perinci::Sub::To::POD;
 my $doc = Perinci::Sub::To::POD->new(url => "/Some/Module/somefunc");
 say $doc->gen_doc;

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-Doc>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-To-Doc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-To-Doc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::To::POD> to generate POD documentation for the whole package.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
