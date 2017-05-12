package Panotools::Makefile::Utils;

=head1 NAME

Panotools::Makefile::Utils - Makefile syntax

=head1 SYNOPSIS

Simple interface for generating Makefile syntax

=head1 DESCRIPTION

Writing Makefiles directly from perl scripts with print and "\t" etc... is
prone to error, this library provides a simple perl interface for assembling
Makefile rules.

See L<Panotools::Makefile::Rule> and L<Panotools::Makefile::Variable> for
object classes that you can use to contruct makefiles.

=cut

use strict;
use warnings;

use Exporter;
use vars qw /@ISA @EXPORT_OK/;
@ISA = qw /Exporter/;
@EXPORT_OK = qw /platform quotetarget quoteprerequisite quoteshell/;

our $PLATFORM;

=head1 USAGE

Access the current platform name (MSWin32, linux, etc...):

  print platform;

Define a different platform and access the new name:

  platform ('MSWin32');
  print platform;

Reset platform to default:

  platform (undef);

=cut

sub platform
{
    $PLATFORM = shift if @_;
    return $PLATFORM if defined $PLATFORM;
    return $^O;
}

=pod

Take a text string (typically a single filename or path) and quote/escape
spaces and special characters to make it suitable for use as a Makefile
'target' or 'prerequisite':

  $escaped_target = quotetarget ('My Filename.txt');
  $escaped_prerequisite = quoteprerequisite ('My Filename.txt');

Note that the =;:% characters are not usable as filenames, they may be used as
control characters in a target or prerequisite.  An exception is the : in
Windows paths such as C:\WINDOWS which is understood by gnu make.

* and ? are wildcards and will be expanded.  You may find that it is
possible to use these as actual characters in filenames, but this assumption
will lead to subtle errors.

$ can be used in a filename, but when used with brackets, ${FOO} or $(BAR),
will be substituted as a make variable.

Targets starting with . are special make targets and not usable as filenames,
the workaround is to supply a full path instead of a relative path.  i.e:
/foo/bar/.hugin rather than .hugin

Additionally the ?<>*|"^\ characters are not portable across filesystems (e.g.
USB sticks, CDs, Windows) and should be avoided in filenames.

=cut

sub quotetarget
{
    my $string = shift;
    # Transform all C:\foo\bar paths to C:/foo/bar
    $string =~ s/\\/\//g if (platform =~ /^(MSWin|dos)/);
    $string =~ s/([ #|\\])/\\$1/g;
    # escape $ as $$ unless part of a $(VARIABLE)
    $string =~ s/\$([^({]|$)/\$\$$1/g;
    return $string;
}

sub quoteprerequisite
{
    my $string = shift;
    # Transform all C:\foo\bar paths to C:/foo/bar
    $string =~ s/\\/\//g if (platform =~ /^(MSWin|dos)/);
    $string =~ s/([ #|\\])/\\$1/g;
    # escape $ as $$ unless part of a $(VARIABLE)
    $string =~ s/\$([^({]|$)/\$\$$1/g;
    return $string;
}

=pod

Take a text string, typically a command-line token, and quote/escape spaces and
special characters to make it suitable for use in a Makefile command:

  $escaped_token = quoteshell ('Hello World');

=cut

sub quoteshell
{
    my $string = shift;
    if (platform =~ /^(MSWin|dos)/)
    {
        # Transform all C:\foo\bar paths to C:/foo/bar
        # Not all tokens are file paths, so \:-) will become /:-)
        $string =~ s/\\/\//g;
        # hash is parsed by make as a comment, backslash escape
        $string =~ s/#/\\#/g;
        # caret escape " since we are using it for quoting
        $string =~ s/"/^"/g;
        # escape $ as $$ unless part of a $(VARIABLE)
        $string =~ s/\$([^({]|$)/\$\$$1/g;
        # ?<>:*|"^ are unusable in Windows filenames,
        # other unix shell characters are unspecial in Windows
        # so the only thing we can quote is a space, ampersand, caret and single quote
        $string = '"'.$string.'"' if $string =~ /[ &^']/;
    }
    else
    {
        # some shell char sequences are useful shell commands
        # others are automatic variables $(<D) $(<F) $<
        unless ($string =~ /^([&<>|]|>>|2>>|2>|\|\||&&|2>&1|`[^`]+`)$/
             or $string =~ /^(\$\(<D\)|\$\(<F\)|\$<|\$@|\$%|\$\?|\$\^|\$\+|\$\||\$\*)$/)
        {
            # backslash escape shell characters
            $string =~ s/([!#'"() `&<>|\\])/\\$1/g;
            # unquote $(FOO) variables escaped above
            $string =~ s/\$\\\(([^)]+)\\\)/\$($1)/g;
            # double escape $ as \$$ unless part of a $(VARIABLE)
            $string =~ s/\$([^({]|$)/\\\$\$$1/g;
        }
    }
    return $string;
}

1;
