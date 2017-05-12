package Pod::Parser::Groffmom::Color;

=head1 NAME

Pod::Parser::Groffmom - Color formatting for groff -mom.

=head1 VERSION

Version 0.042

=cut

our $VERSION = '0.042';
$VERSION = eval $VERSION;

use warnings;
use strict;

use base 'Exporter';
our @EXPORT = qw(color_definitions get_highlighter);
our %EXPORT_TAGS = ( all => \@EXPORT );

use Syntax::Highlight::Engine::Kate;

sub color_definitions {
    return <<'    END';
.NEWCOLOR Alert        RGB #0000ff
.NEWCOLOR BaseN        RGB #007f00
.NEWCOLOR BString      RGB #c9a7ff
.NEWCOLOR Char         RGB #ff00ff
.NEWCOLOR Comment      RGB #7f7f7f
.NEWCOLOR DataType     RGB #0000ff
.NEWCOLOR DecVal       RGB #00007f
.NEWCOLOR Error        RGB #ff0000
.NEWCOLOR Float        RGB #00007f
.NEWCOLOR Function     RGB #007f00
.NEWCOLOR IString      RGB #ff0000
.NEWCOLOR Operator     RGB #ffa500
.NEWCOLOR Others       RGB #b03060
.NEWCOLOR RegionMarker RGB #96b9ff
.NEWCOLOR Reserved     RGB #9b30ff
.NEWCOLOR String       RGB #ff0000
.NEWCOLOR Variable     RGB #0000ff
.NEWCOLOR Warning      RGB #0000ff
    END
}

sub get_highlighter {
    my ($language) = @_;
    return Syntax::Highlight::Engine::Kate->new(
        language      => $language,
        substitutions => { "\\" => "\\\\", },
        format_table  => {
            Alert        => [ "\\*[Alert]",              "\\*[black]" ],
            BaseN        => [ "\\*[BaseN]",              "\\*[black]" ],
            BString      => [ "\\*[BString]",            "\\*[black]" ],
            Char         => [ "\\*[Char]",               "\\*[black]" ],
            Comment      => [ "\\*[Comment]\\f[I]",      "\\f[P]\\*[black]" ],
            DataType     => [ "\\*[DataType]",           "\\*[black]" ],
            DecVal       => [ "\\*[DecVal]",             "\\*[black]" ],
            Error        => [ "\\*[Error]\\f[BI]",       "\\f[P]\\*[black]" ],
            Float        => [ "\\*[Float]",              "\\*[black]" ],
            Function     => [ "\\*[Function]",           "\\*[black]" ],
            IString      => [ "\\*[IString]",            "" ],
            Keyword      => [ "\\f[B]",                  "\\f[P]" ],
            Normal       => [ "",                        "" ],
            Operator     => [ "\\*[Operator]",           "\\*[black]" ],
            Others       => [ "\\*[Others]",             "\\*[black]" ],
            RegionMarker => [ "\\*[RegionMarker]\\f[I]", "\\[P]\\*[black]" ],
            Reserved     => [ "\\*[Reserved]\\f[B]",     "\\f[P]\\*[black]" ],
            String       => [ "\\*[String]",             "\\*[black]" ],
            Variable     => [ "\\*[Variable]\\f[B]",     "\\f[P]\\*[black]" ],
            Warning      => [ "\\*[Warning]\\f[BI]",     "\\f[P]\\*[black]" ],
        },
    );
}

1;

__END__

=head1 Supported Syntaxes

The following syntaxes are from L<Syntax::Highlight::Engine::Kate>.  See that
module for a (possibly) more up-to-date list.  Enter these names exactly as
seen:

 =begin highlight Common Lisp

 (eval-after-load "cperl-mode"
     '(add-hook 'cperl-mode-hook
         (lambda () (local-set-key "\C-ct" 'cperl-prove))))

 (defun cperl-prove ()
     "Run the current test."
     (interactive)
     (shell-command (concat "prove -lv --merge -It/tests "
         (shell-quote_argument (buffer-file-name)))))

 =end highlight

=over 4

=item * "4GL"

=item * "4GL-PER"

=item * "ABC"

=item * "AHDL"

=item * "ANSI C89"

=item * "ASP"

=item * "AVR Assembler"

=item * "AWK"

=item * "Ada"

=item * "Ansys"

=item * "Apache Configuration"

=item * "Asm6502"

=item * "Bash"

=item * "BibTeX"

=item * "C"

=item * "C#"

=item * "C++"

=item * "CGiS"

=item * "CMake"

=item * "CSS"

=item * "CUE Sheet"

=item * "Cg"

=item * "ChangeLog"

=item * "Cisco"

=item * "Clipper"

=item * "ColdFusion"

=item * "Common Lisp"

=item * "Component-Pascal"

=item * "D"

=item * "Debian Changelog"

=item * "Debian Control"

=item * "Diff"

=item * "Doxygen"

=item * "E Language"

=item * "Eiffel"

=item * "Email"

=item * "Euphoria"

=item * "Fortran"

=item * "FreeBASIC"

=item * "GDL"

=item * "GLSL"

=item * "GNU Assembler"

=item * "GNU Gettext"

=item * "HTML"

=item * "Haskell"

=item * "IDL"

=item * "ILERPG"

=item * "INI Files"

=item * "Inform"

=item * "Intel x86 (NASM)"

=item * "JSP"

=item * "Java"

=item * "JavaScript"

=item * "Javadoc"

=item * "KBasic"

=item * "Kate File Template"

=item * "LDIF"

=item * "LPC"

=item * "LaTeX"

=item * "Lex/Flex"

=item * "LilyPond"

=item * "Literate Haskell"

=item * "Lua"

=item * "M3U"

=item * "MAB-DB"

=item * "MIPS Assembler"

=item * "Makefile"

=item * "Mason"

=item * "Matlab"

=item * "Modula-2"

=item * "Music Publisher"

=item * "Octave"

=item * "PHP (HTML)"

=item * "POV-Ray"

=item * "Pascal"

=item * "Perl"

=item * "PicAsm"

=item * "Pike"

=item * "PostScript"

=item * "Prolog"

=item * "PureBasic"

=item * "Python"

=item * "Quake Script"

=item * "R Script"

=item * "REXX"

=item * "RPM Spec"

=item * "RSI IDL"

=item * "RenderMan RIB"

=item * "Ruby"

=item * "SGML"

=item * "SML"

=item * "SQL"

=item * "SQL (MySQL)"

=item * "SQL (PostgreSQL)"

=item * "Sather"

=item * "Scheme"

=item * "Sieve"

=item * "Spice"

=item * "Stata"

=item * "TI Basic"

=item * "TaskJuggler"

=item * "Tcl/Tk"

=item * "UnrealScript"

=item * "VHDL"

=item * "VRML"

=item * "Velocity"

=item * "Verilog"

=item * "WINE Config"

=item * "Wikimedia"

=item * "XML"

=item * "XML (Debug)"

=item * "Yacc/Bison"

=item * "de_DE"

=item * "en_EN"

=item * "ferite"

=item * "nl"

=item * "progress"

=item * "scilab"

=item * "txt2tags"

=item * "x.org Configuration"

=item * "xHarbour"

=item * "xslt"

=item * "yacas"

=back

