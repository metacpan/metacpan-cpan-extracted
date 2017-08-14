package Module::CPANfile::FromDistINI;

our $DATE = '2017-08-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Config::IOD;

our %SPEC;

$SPEC{distini_cpanfile} = {
    v => 1.1,
    summary => 'Generate cpanfile from prereqs information in dist.ini',
    args => {
    },
};
sub distini_cpanfile {
    my %args = @_;

    (-f "dist.ini")
        or return [412, "No dist.ini found. ".
                       "Are you in the right dir (dist top-level)? "];

    my $ct = do {
        open my($fh), "<", "dist.ini" or die "Can't open dist.ini: $!";
        local $/;
        binmode $fh, ":encoding(utf8)";
        ~~<$fh>;
    };

    my $ciod = Config::IOD->new(
        ignore_unknown_directive => 1,
    );

    my $cfg = $ciod->read_string($ct);

    my %mods_from_ini;
    for my $section ($cfg->list_sections) {
        $section =~ m!^(
                          osprereqs \s*/\s* .+ |
                          osprereqs(::\w+)+ |
                          prereqs (?: \s*/\s* (?<prereqs_phase_rel>\w+))? |
                          extras \s*/\s* lint[_-]prereqs \s*/\s* (assume-(?:provided|used))
                      )$!ix or next;
        my ($phase, $rel);
        if (my $pr = $+{prereqs_phase_rel}) {
            if ($pr =~ /^(develop|configure|build|test|runtime|x_\w+)(requires|recommends|suggests|x_\w+)$/i) {
                $phase = ucfirst(lc($1));
                $rel = ucfirst(lc($2));
            } else {
                return [400, "Invalid section '$section' (invalid phase/rel $pr)"];
            }
        } else {
            $phase = "Runtime";
            $rel = "Requires";
        }

        my %params;
        for my $param ($cfg->list_keys($section)) {
            my $v = $cfg->get_value($section, $param);
            if ($param =~ /^-phase$/) {
                $phase = ucfirst(lc($v));
                next;
            } elsif ($param =~ /^-(relationship|type)$/) {
                $rel = ucfirst(lc($v));
                next;
            }
            $params{$param} = $v;
        }
        #$log->tracef("phase=%s, rel=%s", $phase, $rel);

        for my $param (sort keys %params) {
            my $v = $params{$param};
            if (ref($v) eq 'ARRAY') {
                return [412, "Multiple '$param' prereq lines specified in dist.ini"];
            }
            my $dir = $cfg->get_directive_before_key($section, $param);
            my $dir_s = $dir ? join(" ", @$dir) : "";
            log_trace("section=%s, v=%s, param=%s, directive=%s", $section, $param, $v, $dir_s);

            my $mod = $param;
            $mods_from_ini{$phase}{$mod}   = $v unless $section =~ /assume-provided/;
        } # for param
    } # for section
    log_trace("mods_from_ini: %s", \%mods_from_ini);

    my $cpanfile = "";
    if ($mods_from_ini{Runtime}) {
        for my $k (sort keys %{ $mods_from_ini{Runtime} }) {
            my $v = $mods_from_ini{Runtime}{$k};
            $cpanfile .= "requires '$k'" . ($v ? ", '$v'" : "") . ";\n";
        }
        $cpanfile .= "\n";
    }
    for my $phase (sort keys %mods_from_ini) {
        next if $phase eq 'Runtime';
        $cpanfile .= "on ".lc($phase)." => sub {\n";
        for my $k (sort keys %{ $mods_from_ini{$phase} }) {
            my $v = $mods_from_ini{Runtime}{$k};
            $cpanfile .= "    requires '$k'" . ($v ? ", '$v'" : "") . ";\n";
        }
        $cpanfile .= "};\n\n";
    }

    [200, "OK", $cpanfile];
}

1;
# ABSTRACT: Generate cpanfile from prereqs information in dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CPANfile::FromDistINI - Generate cpanfile from prereqs information in dist.ini

=head1 VERSION

This document describes version 0.001 of Module::CPANfile::FromDistINI (from Perl distribution Module-CPANfile-FromDistINI), released on 2017-08-11.

=head1 SYNOPSIS

See the included script L<distini-cpanfile>.

=head1 FUNCTIONS


=head2 distini_cpanfile

Usage:

 distini_cpanfile() -> [status, msg, result, meta]

Generate cpanfile from prereqs information in dist.ini.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CPANfile-FromDistINI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CPANfile-FromDistINI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CPANfile-FromDistINI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
