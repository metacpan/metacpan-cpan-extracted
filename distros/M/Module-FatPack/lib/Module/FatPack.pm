package Module::FatPack;

our $DATE = '2016-12-29'; # DATE
our $VERSION = '0.16'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(fatpack_modules);

our %SPEC;

my $mod_re    = qr/\A[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z0-9_]+)*\z/;
my $mod_pm_re = qr!\A[A-Za-z_][A-Za-z0-9_]*(/[A-Za-z0-9_]+)*\.pm\z!;

$SPEC{fatpack_modules} = {
    v => 1.1,
    summary => 'Generate source code that contains fatpacked modules',
    description => <<'_',

This routine provides the same core technique employed by `App::Fatpack` (which
is putting modules' source code inside Perl variables and loading them on-demand
via require hook) without all the other stuffs. All you need is supply the names
of modules (or the modules' source code themselves) and you'll get the output in
a file or string.

_
    args_rels => {
        req_one => ['module_names', 'module_srcs'],
        'dep_any&' => [
        ],
    },
    args => {
        module_names => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module_name',
            summary => 'Module names to search',
            schema  => ['array*', of=>['str*', match=>$mod_re], min_len=>1],
            tags => ['category:input'],
            pos => 0,
            greedy => 1,
            'x.schema.element_entity' => 'modulename',
            cmdline_aliases => {m=>{}},
        },
        module_srcs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module_src',
            summary => 'Module source codes (a hash, keys are module names)',
            schema  => ['hash*', {
                each_key=>['str*', match=>$mod_re],
                each_value=>['str*'],
                min_len=>1,
            }],
            tags => ['category:input'],
        },
        preamble => {
            summary => 'Perl source code to add before the fatpack code',
            schema => 'str*',
            tags => ['category:input'],
        },
        postamble => {
            summary => 'Perl source code to add after the fatpack code',
            schema => 'str*',
            tags => ['category:input'],
        },

        output => {
            summary => 'Output filename',
            schema => 'str*',
            cmdline_aliases => {o=>{}},
            tags => ['category:output'],
            'x.schema.entity' => 'filename',
        },
        overwrite => {
            summary => 'Whether to overwrite output if previously exists',
            'summary.alt.bool.yes' => 'Overwrite output if previously exists',
            schema => [bool => default => 0],
            tags => ['category:output'],
        },

        assume_strict => {
            summary => 'Assume code runs under stricture',
            schema => 'bool',
            default => 1,
        },
        line_prefix => {
            schema => ['str*', min_len => 1],
        },
        put_hook_at_the_end => {
            summary => 'Put the require hook at the end of @INC using "push" '.
                'instead of at the front using "unshift"',
            schema => ['bool*', is=>1],
        },
        add_begin_block => {
            summary => 'Surround the code inside BEGIN { }',
            schema => ['bool*'],
        },

        pm => {
            summary => "Make code suitable to put inside .pm file instead of script",
            schema => ['bool*', is=>1],
            description => <<'_',

This setting adjusts the code so it is suitable to put one or several instances
of the code inside one or more .pm files. Also sets default for --line-prefix
'#' --no-add-begin-block --put-hook-at-the-end.

_
        },
    },
    examples => [
        {
            summary => 'Fatpack two modules',
            src => 'fatpack-modules Text::Table::Tiny Try::Tiny',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub fatpack_modules {
    my %args = @_;

    my $pm = $args{pm};
    my $line_prefix = $args{line_prefix} // ($pm ? '#':'  ');
    my $add_begin_block = $args{add_begin_block} // ($pm ? 0:1);
    my $put_hook_at_the_end = $args{put_hook_at_the_end} // ($pm ? 1:0);

    my %module_srcs; # key: mod_pm
    my %fatpack_keys;
    if ($args{module_srcs}) {
        for my $mod (keys %{ $args{module_srcs} }) {
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm" unless $mod_pm =~ /\.pm\z/;
            $module_srcs{$mod_pm} = $args{module_srcs}{$mod};
            $fatpack_keys{$mod_pm}++;
        }
    } else {
        require Module::Path::More;
        for my $mod (@{ $args{module_names} }) {
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm" unless $mod_pm =~ /\.pm\z/;
            next if $module_srcs{$mod_pm};
            my $path = Module::Path::More::module_path(
                module => $mod, find_pmc=>0);
            die "Can't find module '$mod_pm'" unless $path;
            $module_srcs{$mod_pm} = do {
                local $/;
                open my($fh), "<", $path or die "Can't open $path: $!";
                ~~<$fh>;
            };
            $fatpack_keys{$mod_pm}++;
        }
    }

    if ($args{stripper}) {
        require Perl::Stripper;
        my $stripper = Perl::Stripper->new(
            maintain_linum => $args{stripper_maintain_linum} // 0,
            strip_ws       => $args{stripper_ws} // 1,
            strip_comment  => $args{stripper_comment} // 1,
            strip_pod      => $args{stripper_pod} // 1,
            strip_log      => $args{stripper_log} // 0,
        );
        for my $mod_pm (keys %module_srcs) {
            $module_srcs{$mod_pm} = $stripper->strip($module_srcs{$mod_pm});
        }
    }

    my @res;

    push @res, $args{preamble} if defined $args{preamble};
    if ($add_begin_block) {
        push @res, 'BEGIN {', "\n";
    } else {
        push @res, "# BEGIN FATPACK CODE: ".join(" ", sort keys %fatpack_keys)."\n";
        push @res, "{\n";
    }
    push @res, <<'_' if $args{assume_strict} // 1;
    no strict 'refs';
_
    for my $mod_pm (sort keys %module_srcs) {
        my $label = uc($mod_pm); $label =~ s/\W+/_/g; $label =~ s/\_PM$//;
        push @res, '    $main::fatpacked{"', $mod_pm, '"} = \'' . $line_prefix . q|#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'|, $label, "';\n";
        $module_srcs{$mod_pm} =~ s/^/$line_prefix/gm;
        push @res, $module_srcs{$mod_pm};
        push @res, "\n" unless $module_srcs{$mod_pm} =~ /\R\z/;
        push @res, "$label\n\n";
    }
    if ($pm) {
        push @res, '    $main::fatpacked{$_} =~ s/^'.quotemeta($line_prefix).'//mg for ('.join(", ", map {"'$_'"} sort keys %fatpack_keys).');'."\n";
    } else {
        push @res, '    s/^'.quotemeta($line_prefix).'//mg for values %main::fatpacked;'."\n";
    }
    push @res, <<'_';
    my $class = 'FatPacked::'.(0+\%main::fatpacked);
_

    # unneeded?
#    push @res, <<'_';
#    *{"${class}::files"} = sub { keys %{$_[0]} };
#_

    my $hook_src = <<'_';
    unless (defined &{"${class}::INC"}) {
        if ($] < 5.008) {
            *{"${class}::INC"} = sub {
                if (my $fat = $_[0]{$_[1]}) {
                    return sub {
                        return 0 unless length $fat;
                        $fat =~ s/^([^\n]*\n?)//;
                        $_ = $1;
                        return 1;
                    };
                }
                return;
            };
        } else {
            *{"${class}::INC"} = sub {
                if (my $fat = $_[0]{$_[1]}) {
                    open my $fh, '<', \$fat
                        or die "FatPacker error loading $_[1] (could be a perl installation issue?)";
                    return $fh;
                }
                return;
            };
        }
    }
_
    if ($pm) { $hook_src =~ s/\R\s+/ /g }
    push @res, $hook_src;
    push @res, <<'_';
    my $hook = bless(\%main::fatpacked, $class);
_
    if ($put_hook_at_the_end) {
        push @res, <<'_';
    push @INC, $hook unless grep {ref($_) && "$_" eq "$hook"} @INC;
_
    } else {
        push @res, <<'_';
    unshift @INC, $hook unless grep {ref($_) && "$_" eq "$hook"} @INC;
_
    }
    push @res, "}\n";
    push @res, "# END OF FATPACK CODE\n\n";
    push @res, $args{postamble} if defined $args{postamble};

    if ($args{output}) {
        my $outfile = $args{output};
        if (-f $outfile) {
            return [409, "Won't overwrite existing file '$outfile'"]
                unless $args{overwrite};
        }
        open my($fh), ">", $outfile or die "Can't write to '$outfile': $!";
        print $fh join("", @res);
        return [200, "OK, written to '$outfile'"];
    } else {
        return [200, "OK", join("", @res)];
    }
}

require PERLANCAR::AppUtil::PerlStripper; PERLANCAR::AppUtil::PerlStripper::_add_stripper_args_to_meta($SPEC{fatpack_modules});

1;
# ABSTRACT: Generate source code that contains fatpacked modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::FatPack - Generate source code that contains fatpacked modules

=head1 VERSION

This document describes version 0.16 of Module::FatPack (from Perl distribution Module-FatPack), released on 2016-12-29.

=head1 FUNCTIONS


=head2 fatpack_modules(%args) -> [status, msg, result, meta]

Generate source code that contains fatpacked modules.

This routine provides the same core technique employed by C<App::Fatpack> (which
is putting modules' source code inside Perl variables and loading them on-demand
via require hook) without all the other stuffs. All you need is supply the names
of modules (or the modules' source code themselves) and you'll get the output in
a file or string.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_begin_block> => I<bool>

Surround the code inside BEGIN { }.

=item * B<assume_strict> => I<bool> (default: 1)

Assume code runs under stricture.

=item * B<line_prefix> => I<str>

=item * B<module_names> => I<array[str]>

Module names to search.

=item * B<module_srcs> => I<hash>

Module source codes (a hash, keys are module names).

=item * B<output> => I<str>

Output filename.

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite output if previously exists.

=item * B<pm> => I<bool>

Make code suitable to put inside .pm file instead of script.

This setting adjusts the code so it is suitable to put one or several instances
of the code inside one or more .pm files. Also sets default for --line-prefix
'#' --no-add-begin-block --put-hook-at-the-end.

=item * B<postamble> => I<str>

Perl source code to add after the fatpack code.

=item * B<preamble> => I<str>

Perl source code to add before the fatpack code.

=item * B<put_hook_at_the_end> => I<bool>

Put the require hook at the end of @INC using "push" instead of at the front using "unshift".

=item * B<stripper> => I<bool> (default: 0)

Whether to strip included modules using Perl::Stripper.

=item * B<stripper_comment> => I<bool> (default: 1)

Set strip_comment=1 (strip comments) in Perl::Stripper.

=item * B<stripper_log> => I<bool> (default: 0)

Set strip_log=1 (strip log statements) in Perl::Stripper.

=item * B<stripper_maintain_linum> => I<bool> (default: 0)

Set maintain_linum=1 in Perl::Stripper.

=item * B<stripper_pod> => I<bool> (default: 1)

Set strip_pod=1 (strip POD) in Perl::Stripper.

=item * B<stripper_ws> => I<bool> (default: 1)

Set strip_ws=1 (strip whitespace) in Perl::Stripper.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-FatPack>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-FatPack>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-FatPack>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::FatPack>, the original implementation.

L<App::depak> for more options e.g. use various tracing methods, etc.

L<fatpack-modules>, CLI for C<fatpack_modules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
