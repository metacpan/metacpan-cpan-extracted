package SyntaxHighlight::Any;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(highlight_string detect_language list_languages);

our %LANGS = (
    yaml       => {pygments => 'yaml'},
    perl       => {pygments => 'perl', sh => 'perl'},
    json       => {pygments => 'json', sh => 'js'  },
    js         => {pygments => 'js'  , sh => 'js'  },
    php        => {pygments => 'php' , sh => 'php' },
    apacheconf => {pygments => 'apacheconf'},
    bash       => {pygments => 'bash', sh => 'bash'},
    sh         => {pygments => 'sh'  , sh => 'sh'  },
    c          => {pygments => 'c'   , sh => 'c'   },
    cpp        => {pygments => 'cpp' , sh => 'cc'  },
    css        => {pygments => 'css' , sh => 'css' },
    diff       => {pygments => 'diff', sh => 'diff'},
    html       => {pygments => 'html', sh => 'html'},
    ini        => {pygments => 'ini' , sh => 'ini' },
    makefile   => {pygments => 'makefile', sh => 'makefile'},
    python     => {pygments => 'python', sh => 'python'},
    ruby       => {pygments => 'ruby', sh => 'ruby'},
    sql        => {pygments => 'sql' , sh => 'sql' },
    xml        => {pygments => 'xml' , sh => 'xml' },
);

sub _try_source_highlight_binary {
    require File::Which;
    require IPC::Run;

    my ($strref, $opts) = @_;

    my $path = File::Which::which("source-highlight");
    return undef unless $path;

    my $out;
    IPC::Run::run(
        [$path,
         "-f", ($opts->{output} eq 'ansi' ? "esc" : "html"),
         "-s", $LANGS{ $opts->{lang} }{sh}],
        $strref,
        \$out,
    );
    return undef if $?;
    return $out;
}

sub _try_pygments_binary {
    require File::Which;
    require IPC::Run;

    my ($strref, $opts) = @_;

    my $path = File::Which::which("pygmentize");
    return undef unless $path;

    my $out;
    IPC::Run::run(
        [$path,
         "-f", ($opts->{output} eq 'ansi' ? "terminal" : "html"),
         "-l", $LANGS{ $opts->{lang} }{pygments}],
        $strref,
        \$out,
    );
    return undef if $?;
    return $out;
}

sub highlight_string {
    my ($str, $opts) = @_;

    $opts //= {};

    state $langs = [list_languages()];

    for ($opts->{output}) {
        if (!$_) {
            if ($ENV{TERM}) {
                $_ = 'ansi';
            } elsif ($ENV{GATEWAY_INTERFACE} || $ENV{MOD_PERL} || $ENV{PLACK_ENV}) {
                $_ = 'html';
            } else {
                $_ = 'ansi';
            }
        }
        die "Please specify 'ansi' or 'html'" unless /\A(ansi|html)\z/;
    }

    for ($opts->{lang}) {
        $_ //= detect_language($str);
        die "Unsupported lang '$_'" unless $LANGS{$_};
    }

    my $res;

    if ($LANGS{ $opts->{lang} }{sh}) {
        # XXX try_source_highlight_module(\$str, $opts);

        $res = _try_source_highlight_binary(\$str, $opts);
        if (defined $res) {
            log_trace("Used source-highlight binary to format code");
            return $res;
        }
    }

    if ($LANGS{ $opts->{lang} }{pygments}) {
        $res = _try_pygments_binary(\$str, $opts);
        if (defined $res) {
            log_trace("Used pygmentize binary to format code");
            return $res;
        }
    }

    log_warn("No syntax highlighting backend for (l=%s, o=%s) is available",
                $opts->{lang}, $opts->{output});
    return $str;
}

sub detect_language {
    my ($code, $opts) = @_;
    $opts //= {};

    die "Sorry, detect_language() not yet implemented, please specify language explicitly for now";
}

sub list_languages {
    sort keys %LANGS;
}

1;
# ABSTRACT: Common interface for syntax highlighting and detecting language in code

__END__

=pod

=encoding UTF-8

=head1 NAME

SyntaxHighlight::Any - Common interface for syntax highlighting and detecting language in code

=head1 VERSION

This document describes version 0.07 of SyntaxHighlight::Any (from Perl distribution SyntaxHighlight-Any), released on 2017-07-10.

=head1 SYNOPSIS

 use SyntaxHighlight::Any qw(highlight_string detect_language);

 my $str = <<'EOT';
 while (<>) {
     $lines++;
     $nonblanks++ if  /\S/;
     $blanks++ unless /\S/;
 }
 EOT
 say highlight_string($str, {lang=>"perl"});
 my @lang = detect_language($str); # => ("perl")

=head1 DESCRIPTION

B<CAVEAT: EARLY DEVELOPMENT MODULE. SOME FUNCTIONS NOT YET IMPLEMENTED. HELP ON
ADDING BACKENDS APPRECIATED.>

This module provides a common interface for syntax highlighting and detecting
programming language in code.

=head1 BACKENDS

Currently, the distribution does not pull the backends as dependencies. Please
make sure you install desired backends.

=head1 FUNCTIONS

=head2 detect_language($code, \%opts) => LIST

CURRENTLY NOT YET IMPLEMENTED.

Attempt to detect programming language of C<$code> and return zero or more
possible candidates. Return empty list if cannot detect. Die on error (e.g. no
backends available or unexpected output from backend).

C<%opts> is optional. Known options:

=over

=back

=head2 highlight_string($code, \%opts) => STR

Syntax-highlight C<$code> and return the highlighted string. Will choose an
appropriate and available backend which is capable of formatting code in the
specified/detected language and to the specified output. Die on error (e.g.
unexpected output from backend).

Will return C<$code> as-is if no backends are available (a warning is produced
via L<Log::Any> though).

By default try to detect whether to output HTML code or ANSI codes (see
C<output> option). By default try to detect language of C<$code>.

Backends: currently in general tries B<GNU Source-highlight> (via
L<Syntax::SourceHighlight>, or binary if module not available), then B<Pygments>
(binary). Patches for detecting/using other backends are welcome.

C<%opts> is optional. Known options:

=over

=item * lang => STR

Tell the function what programming language C<$code> should be regarded as. The
list of known languages can be retrieved using C<list_languages()>.

If unspecified, the function will perform the following. For backends which can
detect the language, this function will just give C<$code> to the backend for it
to figure out the language. For backends which cannot detect the language, this
function will first call C<detect_language()>.

B<NOTE: SINCE detect_language()> is not implemented yet, please specify this.>

=item * output => STR

Either C<ansi>, in which syntax-highlighting is done with ANSI escape color
codes, or C<html>. If not specified, will try to detect whether program is
running under terminal (in which case C<ansi> is chosen) or web environment e.g.
under CGI/FastCGI, mod_perl, or Plack (in which case C<html> is chosen). If
detection fails, C<ansi> is chosen.

=back

=head2 list_languages() => LIST

List known languages.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SyntaxHighlight-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SyntaxHighlight-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SyntaxHighlight-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

For syntax-highlighting (as well as encoding/formatting) to JSON, there's
L<JSON::Color> or L<Syntax::Highlight::JSON> (despite the module name, the
latter is an encoder, not strictly a string syntax highlighter). For YAML
there's L<YAML::Tiny::Color>.

An article in late 2012 describing the various CPAN modules for syntax
highlighting
L<http://blogs.perl.org/users/steven_haryanto/2012/11/the-sad-state-of-syntax-highlighting-libraries-on-cpan.html>
(with the actual reviews posted to L<http://cpanratings.perl.org>). Modules
mentioned including: L<Syntax::SourceHighlight>
(L<reviews|http://cpanratings.perl.org/dist/Syntax-SourceHighlight>),
L<Syntax::Highlight::Engine::Kate>
(L<reviews|http://cpanratings.perl.org/dist/Syntax-Highlight-Engine-Kate>),
L<Syntax::Highlight::JSON>
(L<reviews|http://cpanratings.perl.org/dist/Syntax-Highlight-JSON>),
L<Syntax::Highlight::Engine::Simple>
(L<reviews|http://cpanratings.perl.org/dist/Syntax-Highlight-Engine-Simple>),
L<Syntax::Highlight::Universal>
(L<reviews|http://cpanratings.perl.org/dist/Syntax-Highlight-Universal>), and
L<Text::Highlight> (L<reviews|http://cpanratings.perl.org/dist/text-highlight>).
Some non-Perl solutions are also mentioned.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
