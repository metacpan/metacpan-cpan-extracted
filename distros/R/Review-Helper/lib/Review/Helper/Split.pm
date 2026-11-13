package Review::Helper::Split;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;

my %KIND_BY_EXT = (
    (map { ($_ => 'perl') } qw/pm pl t psgi pod/),
    (map { ($_ => 'javascript') } qw/js mjs cjs jsx/),
    (map { ($_ => 'typescript') } qw/ts mts cts tsx/),
    (map { ($_ => 'html') } qw/html htm/),
    (map { ($_ => 'xml') } qw/xml xsd xsl xslt/),
    (map { ($_ => 'markdown') } qw/md markdown/),
    (map { ($_ => 'shell') } qw/sh bash zsh ksh bashrc zshrc bash_profile/),
    (map { ($_ => 'yaml') } qw/yml yaml/),
    (map { ($_ => 'ini') } qw/ini cfg/),
    (map { ($_ => 'python') } qw/py pyi/),
    (map { ($_ => 'ruby') } qw/rb rake gemspec/),
    (map { ($_ => 'c') } qw/c h/),
    (map { ($_ => 'cpp') } qw/cpp cc cxx hpp hh hxx/),
    (map { ($_ => 'diff') } qw/diff patch/),
    (map { ($_ => 'image') } qw/png jpg jpeg gif webp bmp ico/),
    (map { ($_ => $_) } qw/css sql json toml go java/),
    rs => 'rust',
    mk => 'makefile',
);

my %KIND_BY_NAME = (
    (map { ($_ => 'makefile') } qw/makefile gnumakefile/),
    dockerfile => 'dockerfile',
);

my %KIND_BY_INTERPRETER = (
    perl => 'perl',
    (map { ($_ => 'shell') } qw/sh bash zsh ksh dash ash/),
    (map { ($_ => 'javascript') } qw/node nodejs/),
    python => 'python',
    ruby   => 'ruby',
);

sub kind_for($class, $path, $first_line = undef) {
    croak "kind_for() needs a path" unless defined $path;

    my ($name) = $path =~ m{([^/]*)\z};
    my ($ext)  = $name =~ m{\.([^.]+)\z};
    my $kind   = defined($ext) ? $KIND_BY_EXT{lc $ext} : undef;
    $kind //= $KIND_BY_NAME{lc $name};
    return $kind if $kind;

    return $class->_kind_by_interpreter($first_line) // 'text';
}

# The kind a #! line names: its interpreter, or the command env runs, less
# any version number (python3, perl5.36).
sub _kind_by_interpreter($class, $first_line) {
    return undef unless defined($first_line) && $first_line =~ m/^#!\s*(\S+)(.*)/;
    my ($program, $rest) = ($1, $2);
    ($program) = grep { !m/^-/ && !m/=/ } split ' ', $rest if $program =~ m{(?:^|/)env\z};
    return undef unless defined $program;
    $program =~ s{.*/}{};
    $program =~ s/[\d.]+\z//;
    return $KIND_BY_INTERPRETER{$program};
}

sub lines($class, $text) {
    return [] unless length $text;

    my @lines = CORE::split(/\n/, $text, -1);
    pop @lines if $text =~ m/\n\z/;
    return \@lines;
}

# Lay out an agent's units as the file's sections. A run of lines in no unit
# must be all blank: it joins the section holding the line before it (the
# line after it at the top of the file), in code or documentation like that
# line. Units must not share lines. No units: the file is left whole.
sub assemble($class, $units, $lines) {
    my @sections = map { +{%$_} } @$units or return [];

    my (@owner, @code);
    for my $section (@sections) {
        $owner[$_] = $code[$_] = $section for map { $_->[0] .. $_->[1] } @{$section->{ranges}};
        $owner[$_] = $section             for map { $_->[0] .. $_->[1] } @{$section->{doc_ranges}};
    }

    for my $run (@{$class->to_ranges(grep { !$owner[$_] } 1 .. scalar @$lines)}) {
        my ($first, $final) = @$run;
        my ($text) = grep { $lines->[$_ - 1] =~ m/\S/ } $first .. $final;
        croak "Line $text is in no section" if defined $text;

        my $next = $first > 1 ? $first - 1 : $final + 1;
        my $host = $owner[$next] or next;
        my $part = $code[$next] ? 'ranges' : 'doc_ranges';
        $host->{$part} = $class->to_ranges((map { $_->[0] .. $_->[1] } @{$host->{$part}}), $first .. $final);
    }

    return [sort { $class->_first_line($a) <=> $class->_first_line($b) } @sections];
}

sub _first_line($class, $section) {
    my $first = $section->{ranges}->[0]->[0];
    my $doc   = $section->{doc_ranges}->[0];
    return $doc && $doc->[0] < $first ? $doc->[0] : $first;
}

sub to_ranges($class, @lines) {
    my @ranges;
    for my $line (sort { $a <=> $b } @lines) {
        if (@ranges && $ranges[-1]->[1] + 1 == $line) {
            $ranges[-1]->[1] = $line;
        }
        else {
            push @ranges => [$line, $line];
        }
    }
    return \@ranges;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Split - Pick a file's kind and lay out an agent's sections.

=head1 DESCRIPTION

The tool does not split code itself: the agent filling the review names a
file's sections through the fill sheet (see "Sections" in the format
specification, F<standards/FORMAT.md> in the share directory), covering every
line of the file or none. This module lays out those sections, and picks each
file's kind for highlighting and images.

A section is a hashref:

    {
        name       => 'sub foo',
        package    => 'Foo::Bar' | undef,
        ranges     => [[$start, $end], ...],    # code lines, 1-based, inclusive
        doc_ranges => [[$start, $end], ...],    # its documentation
    }

Sections must not share lines. A run of lines in no section must be all
blank; it joins the section holding the line before it, as code or
documentation like that line; at the top of the file it joins the section
holding the line after it.

Sections come back in file order of their first line, code or documentation.

=head1 SYNOPSIS

    use Review::Helper::Split;

    my $kind     = Review::Helper::Split->kind_for('lib/Foo.pm', $first_line);
    my $lines    = Review::Helper::Split->lines($text);
    my $sections = Review::Helper::Split->assemble(\@units, $lines);

=head1 PUBLIC METHODS

=over 4

=item $kind = Review::Helper::Split->kind_for($path)

=item $kind = Review::Helper::Split->kind_for($path, $first_line)

Returns the file's kind: C<perl>, C<javascript>, C<typescript>, C<css>,
C<html>, C<xml>, C<markdown>, C<shell>, C<sql>, C<json>, C<yaml>, C<ini>,
C<toml>, C<python>, C<ruby>, C<go>, C<rust>, C<c>, C<cpp>, C<java>,
C<makefile>, C<dockerfile>, C<diff>, C<image>, or C<text>, by file extension,
or by file name for C<Makefile> and C<Dockerfile>. SVG is C<text>: it is
diffed and takes line feedback like any text file. A file with no known
extension or name takes its kind from a C<#!> line in C<$first_line>: Perl,
a shell (C<sh>, C<bash>, C<zsh>, C<ksh>, C<dash>, C<ash>), Node, Python or
Ruby, run directly or through C<env>. Whether a file is binary is decided by
the caller.

=item $lines = Review::Helper::Split->lines($text)

Returns the lines of C<$text> without their newlines. A final newline does
not start another line.

=item $sections = Review::Helper::Split->assemble(\@units, \@lines)

Copies of the units (each with C<ranges> and C<doc_ranges>, sorted, sharing
no line) for a file of C<@lines> (as C<lines()> gives them), with the blank
runs described above joined to them. Croaks when a line in no unit is not
blank, unless there are no units: then the file is left whole, with no
sections.

=item $ranges = Review::Helper::Split->to_ranges(@lines)

The line numbers as a sorted range list, C<[[$start, $end], ...]>.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
