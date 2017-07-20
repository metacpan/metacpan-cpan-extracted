package Perinci::CmdLine::Classic::Role::Help;

our $DATE = '2017-07-14'; # DATE
our $VERSION = '1.76'; # VERSION

# split here just so it's more organized

use 5.010;
use Moo::Role;

use Locale::TextDomain::UTF8 'Perinci-CmdLine';
use Perinci::Object;

sub _help_draw_curtbl {
    my ($self, $r) = @_;

    if ($r->{_help_curtbl}) {
        $r->{_help_buf} .= $r->{_help_curtbl}->draw;
        undef $r->{_help_curtbl};
    }
}

# ansitables are used to draw formatted help. they are 100% wide, with no
# borders (except space), but you can customize the number of columns (which
# will be divided equally)
sub _help_add_table {
    require Text::ANSITable;

    my ($self, $r, %args) = @_;
    my $columns = $args{columns} // 1;

    $self->_help_draw_curtbl($r);
    my $t = Text::ANSITable->new;
    $t->border_style('Default::spacei_ascii');
    $t->cell_pad(0);
    if ($args{column_widths}) {
        for (0..$columns-1) {
            $t->set_column_style($_, width => $args{column_widths}[$_]);
        }
    } else {
        my $tw = $self->term_width;
        my $cw = int($tw/$columns)-1;
        $t->cell_width($cw);
    }
    $t->show_header(0);
    $t->column_wrap(0); # we'll do our own wrapping, before indent
    $t->columns([0..$columns-1]);

    $r->{_help_curtbl} = $t;
}

sub _help_add_row {
    my ($self, $r, $row, $args) = @_;
    $args //= {};
    my $wrap    = $args->{wrap}   // 0;
    my $indent  = $args->{indent} // 0;
    my $columns = @$row;

    # start a new table if necessary
    $self->_help_add_table(
        $r,
        columns=>$columns, column_widths=>$args->{column_widths})
        if !$r->{_help_curtbl} ||
            $columns != @{ $r->{_help_curtbl}{columns} };

    my $t = $r->{_help_curtbl};
    my $rownum = @{ $t->{rows} };

    $t->add_row($row);

    my $dux_available = eval { require Data::Unixish; 1 } && !$@;

    if ($dux_available) {
        for (0..@{$t->{columns}}-1) {
            my %styles = (formats=>[]);
            push @{ $styles{formats} },
                [wrap=>{ansi=>1, mb=>1, width=>$t->{cell_width}-$indent*2}]
                if $wrap;
            push @{ $styles{formats} }, [lins=>{text=>"  " x $indent}]
                if $indent && $_ == 0;
            $t->set_cell_style($rownum, $_, \%styles);
        }
    }
}

sub _help_add_heading {
    my ($self, $r, $heading) = @_;
    $self->_help_add_row($r, [$self->_color('heading', $heading)]);
}

sub _color {
    my ($self, $color_name, $text) = @_;
    my $color_code = $color_name ?
        $self->get_theme_color_as_ansi($color_name) : "";
    my $reset_code = $color_code ? "\e[0m" : "";
    "$color_code$text$reset_code";
}

sub help_section_summary {
    my ($self, $r) = @_;

    my $summary = rimeta($r->{_help_meta})->langprop("summary");
    return unless $summary;

    my $name = $self->get_program_and_subcommand_name($r);
    my $ct = join(
        "",
        $self->_color('program_name', $name),
        ($name && $summary ? ' - ' : ''),
        $summary // "",
    );
    $self->_help_add_row($r, [$ct], {wrap=>1});
}

sub help_section_usage {
    my ($self, $r) = @_;

    my $co = $self->common_opts;
    my @con = grep {
        my $cov = $co->{$_};
        my $show = $cov->{show_in_usage} // 1;
        for ($show) { if (ref($_) eq 'CODE') { $_ = $_->($self, $r) } }
        $show;
    } sort {
        ($co->{$a}{order}//1) <=> ($co->{$b}{order}//1) || $a cmp $b
    } keys %$co;

    my $pn = $self->_color(
        'program_name', $self->get_program_and_subcommand_name($r));
    my $ct = "";
    for my $con (@con) {
        my $cov = $co->{$con};
        next unless $cov->{usage};
        $ct .= ($ct ? "\n" : "") . $pn . " " . __($cov->{usage});
    }
    if ($self->subcommands && !$r->{subcommand_name}) {
        if (defined $self->default_subcommand) {
            $ct .= ($ct ? "\n" : "") . $pn .
                " " . __("--cmd=<other-subcommand> [options]");
        } else {
            $ct .= ($ct ? "\n" : "") . $pn .
                " " . __("<subcommand> [options]");
        }
    } else {
        my $usage = $r->{_help_clidocdata}{usage_line};
        $usage =~ s/\[\[prog\]\]/$pn/;
        $usage =~ s/\[options\]/__("[options]")/e;
        $ct .= ($ct ? "\n" : "") . $usage;
    }
    $self->_help_add_heading($r, __("Usage"));
    $self->_help_add_row($r, [$ct], {indent=>1});
}

sub help_section_options {
    my ($self, $r) = @_;

    my $opts = $r->{_help_clidocdata}{opts};
    return unless keys %$opts;

    my $verbose = $r->{_help_verbose};
    my $info = $r->{_help_info};
    my $meta = $r->{_help_meta};
    my $args_p = $meta->{args};
    my $sc = $self->subcommands;

    # group options by raw category, e.g. $cats{""} (for options
    # without category and common options) or $cat{"cat1"}.
    my %cats; # val = [ospec, ...]

    for (keys %$opts) {
        push @{ $cats{$opts->{$_}{raw_category} // ''} }, $_;
    }

    for my $cat (sort keys %cats) {
        # find the longest option
        my @opts = sort {length($b)<=>length($a)} @{ $cats{$cat} };
        my $len = length($opts[0]);
        # sort again by name
        @opts = sort {
            (my $a_without_dash = $a) =~ s/^-+//;
            (my $b_without_dash = $b) =~ s/^-+//;
            lc($a) cmp lc($b);
        } @opts;

        my $cat_title;
        if ($cat eq '') {
            $cat_title = __("Options");
        } else {
            $cat_title = __x("{category} options", category=>ucfirst($cat));
        }
        $self->_help_add_heading($r, $cat_title);

        if ($verbose) {
            for my $opt_name (@opts) {
                my $opt_spec = $opts->{$opt_name};
                my $arg_spec = $opt_spec->{arg_spec};
                my $ct = $self->_color('option_name', $opt_name);
                # BEGIN DUPE1
                if ($arg_spec && !$opt_spec->{main_opt} &&
                        defined($arg_spec->{pos})) {
                    if ($arg_spec->{greedy}) {
                        $ct .= " (=arg[$arg_spec->{pos}-])";
                    } else {
                        $ct .= " (=arg[$arg_spec->{pos}])";
                    }
                }
                if ($arg_spec && !$opt_spec->{main_opt} &&
                        defined($arg_spec->{cmdline_src})) {
                    $ct .= " (or from $arg_spec->{cmdline_src})";
                    $ct =~ s!_or_!/!;
                }
                # END DUPE1
                $self->_help_add_row($r, [$ct], {indent=>1});

                if ($opt_spec->{summary} || $opt_spec->{description}) {
                    my $ct = "";
                    $ct .= ($ct ? "\n\n":"")."$opt_spec->{summary}."
                        if $opt_spec->{summary};
                    $ct .= ($ct ? "\n\n":"").$opt_spec->{description}
                        if $opt_spec->{description};
                    $self->_help_add_row($r, [$ct], {indent=>2, wrap=>1});
                }
            }
        } else {
            # for compactness, display in columns
            my $tw = $self->term_width;
            my $columns = int($tw/40); $columns = 1 if $columns < 1;
            while (1) {
                my @row;
                for (1..$columns) {
                    last unless @opts;
                    my $opt_name = shift @opts;
                    my $opt_spec = $opts->{$opt_name};
                    my $arg_spec = $opt_spec->{arg_spec};
                    my $ct = $self->_color('option_name', $opt_name);
                    # BEGIN DUPE1
                    if ($arg_spec && !$opt_spec->{main_opt} &&
                            defined($arg_spec->{pos})) {
                        if ($arg_spec->{greedy}) {
                            $ct .= " (=arg[$arg_spec->{pos}-])";
                        } else {
                            $ct .= " (=arg[$arg_spec->{pos}])";
                        }
                    }
                    if ($arg_spec && !$opt_spec->{main_opt} &&
                            defined($arg_spec->{cmdline_src})) {
                        $ct .= " (or from $arg_spec->{cmdline_src})";
                        $ct =~ s!_or_!/!;
                    }
                    # END DUPE1
                    push @row, $ct;
                }
                last unless @row;
                for (@row+1 .. $columns) { push @row, "" }
                $self->_help_add_row($r, \@row, {indent=>1});
            }
        }
    }
}

sub help_section_subcommands {
    my ($self, $r) = @_;

    my $verbose = $r->{_help_verbose};
    return unless $self->subcommands && !$r->{subcommand_name};
    my $scs = $self->list_subcommands;

    my @scs = sort keys %$scs;
    my @shown_scs;
    for my $scn (@scs) {
        my $sc = $scs->{$scn};
        next unless $sc->{show_in_help} // 1;
        $sc->{name} = $scn;
        push @shown_scs, $sc;
    }

    # for help_section_hints
    my $some_not_shown = @scs > @shown_scs;
    $r->{_help_hide_some_subcommands} = 1 if $some_not_shown;

    $self->_help_add_heading(
        $r, $some_not_shown ? __("Popular subcommands") : __("Subcommands"));

    # in compact mode, we try to not exceed one screen, so show long mode only
    # if there are a few subcommands.
    my $long_mode = $verbose || @shown_scs < 12;
    if ($long_mode) {
        for (@shown_scs) {
            my $summary = rimeta($_)->langprop("summary");
            $self->_help_add_row(
                $r,
                [$self->_color('program_name', $_->{name}), $summary],
                {column_widths=>[-17, -40], indent=>1});
        }
    } else {
        # for compactness, display in columns
        my $tw = $self->term_width;
        my $columns = int($tw/25); $columns = 1 if $columns < 1;
            while (1) {
                my @row;
                for (1..$columns) {
                    last unless @shown_scs;
                    my $sc = shift @shown_scs;
                    push @row, $sc->{name};
                }
                last unless @row;
                for (@row+1 .. $columns) { push @row, "" }
                $self->_help_add_row($r, \@row, {indent=>1});
            }

    }
}

sub help_section_hints {
    my ($self, $r) = @_;

    my $verbose = $r->{_help_verbose};
    my @hints;
    unless ($verbose) {
        push @hints, N__("For more complete help, use '--help --verbose'");
    }
    if ($r->{_help_hide_some_subcommands}) {
        push @hints,
            N__("To see all available subcommands, use '--subcommands'");
    }
    return unless @hints;

    $self->_help_add_row(
        $r, [join(" ", map { __($_)."." } @hints)], {wrap=>1});
}

sub help_section_description {
    my ($self, $r) = @_;

    my $desc = rimeta($r->{_help_meta})->langprop("description") //
        $self->description;
    return unless $desc;

    $self->_help_add_heading($r, __("Description"));
    $self->_help_add_row($r, [$desc], {wrap=>1, indent=>1});
}

sub help_section_examples {
    my ($self, $r) = @_;

    my $verbose = $r->{_help_verbose};
    my $meta = $r->{_help_meta};
    my $egs = $r->{_help_clidocdata}{examples};
    return unless $egs && @$egs;

    $self->_help_add_heading($r, __("Examples"));
    my $pn = $self->_color(
        'program_name', $self->get_program_and_subcommand_name($r));
    for my $eg (@$egs) {
        my $cmdline = $eg->{cmdline};
        $cmdline =~ s/\[\[prog\]\]/$pn/;
        $self->_help_add_row($r, ["% $cmdline"], {indent=>1});
        if ($verbose) {
            my $ct = "";
            if ($eg->{summary}) { $ct .= "$eg->{summary}." }
            if ($eg->{description}) { $ct .= "\n\n$eg->{description}" }
            $self->_help_add_row($r, [$ct], {indent=>2}) if $ct;
        }
    }
}

sub help_section_result {
    my ($self, $r) = @_;

    my $meta   = $r->{_help_meta};
    my $rmeta  = $meta->{result};
    my $rmetao = rimeta($rmeta);
    my $text;

    my $summary = $rmetao->langprop('summary') // '';
    my $desc    = $rmetao->langprop('description') // '';
    $text = $summary . ($summary ? "\n\n" : "") . $desc;

    # collect handler
    my %handlers;
    for my $k0 (keys %$rmeta) {
        my $v = $rmeta->{$k0};

        my $k = $k0; $k =~ s/\..+//;
        next if $k =~ /\A_/;

        # check builtin result spec key
        next if $k =~ /\A(
                           summary|description|tags|default_lang|
                           schema|
                           x
                       )\z/x;

        # try a property module first
        require "Perinci/Sub/Property/result/$k.pm";
        my $meth = "help_hookmeta_result__$k";
        unless ($self->can($meth)) {
            die "No help handler for property result/$k0 ($meth)";
        }
        my $hmeta = $self->$meth;
        $handlers{$k} = {
            prio => $hmeta->{prio},
            meth => "help_hook_result__$k",
        };
    }

    # call all the handlers in order
    for my $k (sort {$handlers{$a}{prio} <=> $handlers{$b}{prio}}
                   keys %handlers) {
        my $h = $handlers{$k};
        my $meth = $h->{meth};
        my $t = $self->$meth($r);
        $text .= $t if $t;
    }

    return unless length $text;

    $self->_help_add_heading($r, __("Result"));
    $self->_help_add_row($r, [$text], {wrap=>1, indent=>1});
}

sub help_section_links {
    # not yet
}

sub action_help {
    my ($self, $r) = @_;

    $r->{_help_buf} = '';

    my $verbose = $ENV{VERBOSE} // 0;
    local $r->{_help_verbose} = $verbose;

    # get function metadata first
    unless ($r->{_help_meta}) {
        my $url = $r->{subcommand_data}{url} // $self->url;
        my $res = $self->riap_client->request(info => $url);
        die [500, "Can't info '$url': $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $r->{_help_info} = $res->[2];
        $res = $self->riap_client->request(meta => $url);
        die [500, "Can't meta '$url': $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $r->{_help_meta} = $res->[2]; # cache here
    }

    # get cli opt spec
    unless ($r->{_help_clidocdata}) {
        require Perinci::Sub::To::CLIDocData;
        my $res = Perinci::Sub::To::CLIDocData::gen_cli_doc_data_from_meta(
            meta => $r->{_help_meta}, meta_is_normalized => 1,
            common_opts  => $self->common_opts,
            per_arg_json => $self->per_arg_json,
            per_arg_yaml => $self->per_arg_yaml,
        );
        die [500, "Can't gen_cli_doc_data_from_meta: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $r->{_help_clidocdata} = $res->[2]; # cache here
    }

    # ux: since --verbose will potentially show lots of paragraph text, let's
    # default to 80 and not wider width, unless user specifically requests
    # column width via COLUMNS.
    if ($verbose && !defined($ENV{COLUMNS}) && $self->term_width > 80) {
        $self->term_width(80);
    }

    # determine which help sections should we generate
    my @hsects;
    if ($verbose) {
        @hsects = (
            'summary',
            'usage',
            'subcommands',
            'examples',
            'description',
            'options',
            'result',
            'links',
            'hints',
        );
    } else {
        @hsects = (
            'summary',
            'usage',
            'subcommands',
            'examples',
            'options',
            'hints',
        );
    }

    for my $s (@hsects) {
        my $meth = "help_section_$s";
        #say "D:$meth";
        #$log->tracef("=> $meth()");
        $self->$meth($r);
    }
    $self->_help_draw_curtbl($r);
    [200, "OK", $r->{_help_buf}, {"cmdline.skip_format"=>1}];
}

1;
# ABSTRACT: Help-related routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Classic::Role::Help - Help-related routines

=head1 VERSION

This document describes version 1.76 of Perinci::CmdLine::Classic::Role::Help (from Perl distribution Perinci-CmdLine-Classic), released on 2017-07-14.

=for Pod::Coverage ^(.+)$

=head1 REQUEST KEYS

=over

=item * _help_*

Temporary. Various data stored during help generation that is passed between the
various C<_help_*> methods.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Classic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Classic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Classic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
