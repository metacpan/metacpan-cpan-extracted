#
# SuperPython.pm
#
# 20010401 M J Dominus (mjd@plover.com)
#

=head1 NAME

SuperPython - Perl filter module to implement the SuperPython language

=head1 SYNOPSIS

  perl -MSuperPython hello.spy

  use SuperPython;
  # (SuperPython code follows here)
  no SuperPython;
  # regular Perl code resumes
  # (not recommended; regular Perl is too hard to understand and maintain)

=head1 DESCRIPTION

This module implements a Perl source filter for the SuperPython
language, allowing SuperPython code to be embedded into Perl programs.

SuperPython brings to Perl all the benefits of Python's vaunted
whitespace-sensitivity, including readability, maintainability, less
punctuation, and all that other great crap.  In fact, it goes several
steps further than Python in this direction.  However, SuperPython
retains Perl's powerful and flexible underlying semantics.

Example SuperPython programs (C<*.spy>) are included with this module.
The syntax should be clear even to a casual observer; however, watch
out for the upcoming 'SuperPython in a Nutshell' book from O'Reilly
and Associates.

=head1 FUTURE WORK

There is no reason why Python itself could not take advantage of the
benefits of SuperPython's improved syntax.  I look forward to working
with the Python community to port this module to work with Python.

=head1 AUTHOR

Mark Jason Dominus (mjd@plover.com)

=head1 SEE ALSO

python(1).

=cut

package SuperPython;

$VERSION = 0.91;

use Filter::Simple sub 
{
    s/( *)	/chr(length($1))/ge;
};

1;


