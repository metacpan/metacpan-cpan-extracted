package Tangerine::hook::inline;
$Tangerine::hook::inline::VERSION = '0.23';
use 5.010;
use strict;
use warnings;
use parent 'Tangerine::Hook';
use Tangerine::HookData;
use Tangerine::Occurence;
use Tangerine::Utils qw(any stripquotelike $vre);

my %langmap = (
    (map { $_ => 'ASM' } qw/nasm NASM gasp GASP as AS asm/),
    (map { $_ => 'Awk' } qw/AWK awk/),
    basic => 'Basic',
    (map { $_ => 'BC' } qw/bc Bc/),
    (map { $_ => 'Befunge' } qw/befunge BEFUNGE bef BEF/),
    c => 'C',
    (map { $_ => 'CPP' } qw/cpp C++ c++ Cplusplus cplusplus CXX cxx/),
    GUILE => 'Guile',
    (map { $_ => 'Java' } qw/JAVA java/),
    lua => 'Lua',
    MZSCHEME => 'MzScheme',
    nouse => 'Nouse',
    octave => 'Octave',
    (map { $_ => 'Pdlpp' } qw/pdlpp PDLPP/),
    perl => 'Perl',
    (map { $_ => 'Python' } qw/py python PYTHON/),
    (map { $_ => 'Ruby' } qw/rb ruby RUBY/),
    (map { $_ => 'SLang' } qw/sl slang/),
    (map { $_ => 'SMITH' } qw/Smith smith/),
    (map { $_ => 'Tcl' } qw/tcl tk/),
    (map { $_ => 'TT' } qw/tt template/),
    webchat => 'WebChat',
);

sub run {
    my ($self, $s) = @_;
    if ((any { $s->[0] eq $_ } qw(use no)) && scalar(@$s) > 2 &&
        $s->[1] eq 'Inline') {
        my ($version) = $s->[2] =~ $vre;
        $version //= '';
        my $voffset = $version ? 3 : 2;
        my @args;
        if (scalar(@$s) > $voffset) {
            return if $s->[$voffset] eq ';';
            @args = @$s;
            @args = @args[($voffset) .. $#args];
            @args = stripquotelike(@args);
        }
        my @modules;
        if ($args[0] =~ /config/io) {
            return
        } elsif ($args[0] =~ /with/io) {
            shift @args;
            push @modules, @args;
        } else {
            push @modules, 'Inline::'.($langmap{$args[0]} // $args[0])
        }
        if (any { $_ eq 'FILTERS' } @args) {
            push @modules, 'Inline::Filters'
        }
        return Tangerine::HookData->new(
            modules => {
                map {
                    ( $_ => Tangerine::Occurence->new() )
                    } @modules,
                },
            );
    }
    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tangerine::hook::inline - Process Inline module use statements

=head1 DESCRIPTION

This hook parses L<Inline> arguments and attempts to report required
C<Inline> language modules or non-C<Inline> modules used for
configuration, usually loaded via the C<with> syntax.  This hook
also reports L<Inline::Filters> if C<FILTERS> are invoked.

=head1 AUTHOR

Petr Šabata <contyk@redhat.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2016 Petr Šabata

See LICENSE for licensing details.

=cut
