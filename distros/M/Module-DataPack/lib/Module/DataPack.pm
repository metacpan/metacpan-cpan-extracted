package Module::DataPack;

our $DATE = '2016-12-28'; # DATE
our $VERSION = '0.20'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Slurper qw(read_binary write_binary);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(datapack_modules);

our %SPEC;

my $mod_re    = qr/\A[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z0-9_]+)*\z/;
my $mod_pm_re = qr!\A[A-Za-z_][A-Za-z0-9_]*(/[A-Za-z0-9_]+)*\.pm\z!;

$SPEC{datapack_modules} = {
    v => 1.1,
    summary => 'Like Module::FatPack, but uses datapacking instead of fatpack',
    description => <<'_',

Both this module and `Module:FatPack` generate source code that embeds modules'
source codes and load them on-demand via require hook. The difference is that
the modules' source codes are put in `__DATA__` section instead of regular Perl
hashes (fatpack uses `%fatpacked`). This reduces compilation overhead, although
this is not noticeable unless when the number of embedded modules is quite
large. For example, in `App::pause`, the `pause` script embeds ~320 modules with
a total of ~54000 lines. The overhead of fatpack code is ~49ms on my PC, while
with datapack the overhead is about ~10ms.

There are two downsides of this technique. The major one is that you cannot load
modules during BEGIN phase (e.g. using `use`) because at that point, DATA
section is not yet available. You can only use run-time require()'s.

Another downside of this technique is that you cannot use `__DATA__` section for
other purposes (well, actually with some care, you still can).

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
            summary => 'Perl source code to add before the datapack code',
            schema => 'str*',
            tags => ['category:input'],
        },
        postamble => {
            summary => 'Perl source code to add after the datapack code'.
                ' (but before the __DATA__ section)',
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

    },
    examples => [
        {
            summary => 'Datapack two modules',
            src => 'datapack-modules Text::Table::Tiny Try::Tiny',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },

    ],
};
sub datapack_modules {
    my %args = @_;

    my %module_srcs; # key: mod_pm
    if ($args{module_srcs}) {
        for my $mod (keys %{ $args{module_srcs} }) {
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm" unless $mod_pm =~ /\.pm\z/;
            $module_srcs{$mod_pm} = $args{module_srcs}{$mod};
        }
    } else {
        require Module::Path::More;
        for my $mod (@{ $args{module_names} }) {
            my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm" unless $mod_pm =~ /\.pm\z/;
            next if $module_srcs{$mod_pm};
            my $path = Module::Path::More::module_path(
                module => $mod, find_pmc=>0);
            die "Can't find module '$mod_pm'" unless $path;
            $module_srcs{$mod_pm} = read_binary($path);
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

    # how to line number (# line): position of __DATA__ + 1 (DSS header) + number of header lines + 1 (blank line) + $order+1 (number of ### file ### header) + lineoffset
    push @res, <<'_';
# BEGIN DATAPACK CODE
{
    my $toc;
    my $data_linepos = 1;
    unshift @INC, sub {
        $toc ||= do {

            my $fh = \*DATA;

        my $header_line;
        my $header_found;
        while (1) {
            my $header_line = <$fh>;
            defined($header_line)
                or die "Unexpected end of data section while reading header line";
            chomp($header_line);
            if ($header_line eq 'Data::Section::Seekable v1') {
                $header_found++;
                last;
            }
        }
        die "Can't find header 'Data::Section::Seekable v1'"
            unless $header_found;

        my %toc;
        my $i = 0;
        while (1) {
            $i++;
            my $toc_line = <$fh>;
            defined($toc_line)
                or die "Unexpected end of data section while reading TOC line #$i";
            chomp($toc_line);
            $toc_line =~ /\S/ or last;
            $toc_line =~ /^([^,]+),(\d+),(\d+)(?:,(.*))?$/
                or die "Invalid TOC line #$i in data section: $toc_line";
            $toc{$1} = [$2, $3, $4];
        }
        my $pos = tell $fh;
        $toc{$_}[0] += $pos for keys %toc;


            # calculate the line number of data section
            my $data_pos = tell(DATA);
            seek DATA, 0, 0;
            my $pos = 0;
            while (1) {
                my $line = <DATA>;
                $pos += length($line);
                $data_linepos++;
                last if $pos >= $data_pos;
            }
            seek DATA, $data_pos, 0;

            \%toc;
        };
        if ($toc->{$_[1]}) {
            seek DATA, $toc->{$_[1]}[0], 0;
            read DATA, my($content), $toc->{$_[1]}[1];
            my ($order, $lineoffset) = split(';', $toc->{$_[1]}[2]);
            $content =~ s/^#//gm;
            $content = "# line ".($data_linepos + $order+1 + $lineoffset)." \"".__FILE__."\"\n" . $content;
            open my $fh, '<', \$content
                or die "DataPacker error loading $_[1]: $!";
            return $fh;
        }
        return;
    };
}
# END DATAPACK CODE
_

    push @res, $args{postamble} if defined $args{postamble};

    require Data::Section::Seekable::Writer;
    my $writer = Data::Section::Seekable::Writer->new;
    my $linepos = 0;
    my $i = -1;
    for my $mod_pm (sort keys %module_srcs) {
        $i++;
        my $content = join(
            "",
            $module_srcs{$mod_pm},
        );
        $content =~ s/^/#/gm;
        $writer->add_part($mod_pm => $content, "$i;$linepos");
        my $lines = 0; $lines++ while $content =~ /^/gm;
        $linepos += $lines;
    }
    push @res, "\n__DATA__\n", $writer;

    if ($args{output}) {
        my $outfile = $args{output};
        if (-f $outfile) {
            return [409, "Won't overwrite existing file '$outfile'"]
                unless $args{overwrite};
        }
        write_binary($outfile, join("", @res))
            or die "Can't write to '$outfile': $!";
        return [200, "OK, written to '$outfile'"];
    } else {
        return [200, "OK", join("", @res)];
    }
}

require PERLANCAR::AppUtil::PerlStripper; PERLANCAR::AppUtil::PerlStripper::_add_stripper_args_to_meta($SPEC{datapack_modules});

1;
# ABSTRACT: Like Module::FatPack, but uses datapacking instead of fatpack

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::DataPack - Like Module::FatPack, but uses datapacking instead of fatpack

=head1 VERSION

This document describes version 0.20 of Module::DataPack (from Perl distribution Module-DataPack), released on 2016-12-28.

=head1 FUNCTIONS


=head2 datapack_modules(%args) -> [status, msg, result, meta]

Like Module::FatPack, but uses datapacking instead of fatpack.

Both this module and C<Module:FatPack> generate source code that embeds modules'
source codes and load them on-demand via require hook. The difference is that
the modules' source codes are put in C<__DATA__> section instead of regular Perl
hashes (fatpack uses C<%fatpacked>). This reduces compilation overhead, although
this is not noticeable unless when the number of embedded modules is quite
large. For example, in C<App::pause>, the C<pause> script embeds ~320 modules with
a total of ~54000 lines. The overhead of fatpack code is ~49ms on my PC, while
with datapack the overhead is about ~10ms.

There are two downsides of this technique. The major one is that you cannot load
modules during BEGIN phase (e.g. using C<use>) because at that point, DATA
section is not yet available. You can only use run-time require()'s.

Another downside of this technique is that you cannot use C<__DATA__> section for
other purposes (well, actually with some care, you still can).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module_names> => I<array[str]>

Module names to search.

=item * B<module_srcs> => I<hash>

Module source codes (a hash, keys are module names).

=item * B<output> => I<str>

Output filename.

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite output if previously exists.

=item * B<postamble> => I<str>

Perl source code to add after the datapack code (but before the __DATA__ section).

=item * B<preamble> => I<str>

Perl source code to add before the datapack code.

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

Please visit the project's homepage at L<https://metacpan.org/release/Module-DataPack>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-DataPack>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-DataPack>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::FatPack> for a similar module which uses fatpacking technique instead
of datapacking.

L<App::depak> for more options e.g. use various tracing methods, etc.

L<Data::Section::Seekable>, the format used for the data section

L<datapack-modules>, CLI for C<datapack_modules>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
