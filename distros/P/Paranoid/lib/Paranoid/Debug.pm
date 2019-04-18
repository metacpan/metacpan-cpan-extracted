# Paranoid::Debug -- Debug support for paranoid programs
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Debug.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Debug;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;

($VERSION) = ( q$Revision: 2.07 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT = qw(PDEBUG pdebug pIn pOut
    PDEBUG1 PDEBUG2 PDEBUG3 PDEBUG4 PDEBUG5 PDEBUG6 PDEBUG7 PDEBUG8);
@EXPORT_OK = (
    @EXPORT,
    qw(pderror PDPREFIX PDLEVEL1 PDLEVEL2 PDLEVEL3 PDLEVEL4 PDMAXINDENT),
    );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant PDLEVEL1 => 9;
use constant PDLEVEL2 => 10;
use constant PDLEVEL3 => 11;
use constant PDLEVEL4 => 12;

use constant PDMAXIND => 60;

use constant PDEBUG1 => 1;
use constant PDEBUG2 => 2;
use constant PDEBUG3 => 3;
use constant PDEBUG4 => 4;
use constant PDEBUG5 => 5;
use constant PDEBUG6 => 6;
use constant PDEBUG7 => 7;
use constant PDEBUG8 => 8;

#####################################################################
#
# Module code follows
#
#####################################################################

{
    my $dlevel     = 0;           # Start with no debug level
    my $ilevel     = 0;           # Start with no identation
    my $pdebug     = 0;           # Start with debug output disabled
    my $maxLevel   = PDMAXIND;    # Start with normal max indentation
    my $indIgnored = 0;           # Start without ignoring indentation

    my $defprefix = sub {

        # Default Prefix to use with debug messages looks like:
        #
        #   [PID - $dlevel] Subroutine:
        #
        my $caller = shift;
        my $prefix = ' ' x $ilevel . "[$$-$dlevel] $caller: ";

        return $prefix;
    };
    my $pdprefix = $defprefix;

    sub PDEBUG : lvalue {
        $pdebug;
    }

    sub PDPREFIX : lvalue {
        $pdprefix;
    }

    sub PDMAXINDENT : lvalue {
        $maxLevel;
    }

    sub pderror ($) {

        # Purpose:  Print passed string to STDERR
        # Returns:  Return value from print function
        # Usage:    $rv = pderror("Foo!");

        my $msg = shift;

        $@ = $msg;

        return print STDERR "$msg\n";
    }

    sub pdebug ($;$@) {

        # Purpose:  Calls pderror() if the message level is less than or equal
        #           to the value of PDBEBUG, after prepending the string
        #           returned by the PDPREFIX routine, if defined
        # Returns:  Always returns the passed message, regardless of PDEBUG's
        #           value
        # Usage:    pdebug($message, $level);

        my $msg    = shift;
        my $level  = shift || 1;
        my @pfargs = @_;
        my $prefix = PDPREFIX;
        my ( $ci, @crec, $caller, $n, $np );

        $msg = '' unless defined $msg;

        # If called with a negative level it merely means we
        # need to go a little bit deeper in the call stack to find the
        # true initiator of the message.  This provides the mechanism for
        # Paranoid::Log::plog to pass indirect debug messages
        $ci = $level < 0 ? 2 : 1;
        $level *= -1 if $level < 0;

        # Get the call stack info
        @crec = caller $ci;
        $caller =
              defined $crec[3] ? $crec[3]
            : defined $crec[1] ? "$crec[1]/$crec[2]"
            :                    'undef';

        # Filter message through sprintf if args were passed
        $n = [ $msg =~ m#(%[\w.]+)#sg ];
        $np = $n = scalar @$n;
        if ($n) {

            # Adjust n upwards if we were given more list items than
            # we see placeholders for in the messsage string
            $n = scalar @pfargs if @pfargs > $n;

            # Make sure the requisite number of args are translated for undefs
            while ( $n > 0 ) {
                $n--;
                $pfargs[$n] = 'undef' unless defined $pfargs[$n];
            }

            # Consolidate extra args into the last placeholder's spot
            if ( scalar @pfargs > $np ) {
                $n = $np - 1;
                @pfargs =
                    ( @pfargs[ 0 .. ( $n - 1 ) ], "@pfargs[$n .. $#pfargs]" );
            }

            # Filter through sprintf
            {
                no warnings;
                $msg = sprintf( $msg, @pfargs );
            }
        }

        return $msg if $level > PDEBUG;

        # Execute the code block, if that's what it is
        $prefix = &$prefix($caller) if ref($prefix) eq 'CODE';

        {
            no warnings;
            pderror("$prefix$msg");
        }

        return $msg;
    }

    sub pIn () {

        # Purpose:  Increases indentation level
        # Returns:  Always True (1)
        # Usage:    pIn();

        if ( $ilevel < PDMAXINDENT ) {
            $ilevel++;
        } else {
            $indIgnored = 1;
        }
        $dlevel++;

        return 1;
    }

    sub pOut () {

        # Purpose:  Decreases indentation level
        # Returns:  Always True (1)
        # Usage:    pOut();

        if ($indIgnored) {
            $indIgnored = 0;
        } else {
            $ilevel-- if $ilevel > 0;
        }
        $dlevel--;

        return 1;
    }

}

1;

__END__

=head1 NAME

Paranoid::Debug - Trace message support for paranoid programs

=head1 VERSION

$Id: lib/Paranoid/Debug.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Debug;

  PDEBUG        = 1;
  PDMAXINDENT   = 40;
  PDPREFIX      = sub { scalar localtime };
  pdebug("starting program", 1);
  foo();

  sub foo {
    pdebug("entering foo()", 2);
    pIn();

    pdebug("someting happened!", 2);

    pOut();
    pdebug("leaving w/rv: $rv", 2):
  }

  pderror("error msg");

=head1 DESCRIPTION

The purpose of this module is to provide a useful framework to produce
debugging output.  With this module you can assign a level of detail to pdebug
statements, and they'll only be displayed to STDERR when PDEBUG is set to 
that level or higher.  This allows you to have your program produce varying 
levels of debugging output.

Using the B<pIn> and B<pOut> functions at the beginning and end of each
function will cause debugging output to be indented appropriately so you can
visually see the level of recursion.

B<NOTE:> All modules within the Paranoid framework use this module.  Their
debug levels range from 9 and up.  You should use 1 - 8 for your own modules
or code.

=head2 EXPORT TARGETS

Only I<PDEBUG>, I<pdebug>, I<pIn>, and I<pOut> are exported by default.  All
other functions and constants can be exported with the I<:all> tag set.

=head1 CONSTANTS

=head2 PDEBUG1 - PDEBUG8

There are eight constants exported by default for use by developers that allow
for up to eight levels of diagnostic output.  None of these levels are used by
internal B<Paranoid> code, they are reserved for use by third parties.

=head1 SUBROUTINES/METHODS

=head2 PDEBUG

B<PDEBUG> is an lvalue subroutine which is initially set to 0, but can be 
set to any positive integer.  The higher the number the more pdebug 
statements are printed.

=head2 PDMAXINDENT

B<PDMAXINDENT> is an lvalue subroutine which is initially set to 60, but can 
be set to any integer.  This controls the max indentation of the debug 
messages.  Obviously, it wouldn't help to indent a debug message by a hundred 
columns on an eighty column terminal just because your stack depth gets that 
deep.

=head2 PDPREFIX

B<PDPREFIX> is also an lvalue subroutine and is set by default to a 
code reference that returns as a string the standard prefix for debug 
messages:

  [PID - DLEVEL] Subroutine:

Assigning another reference to a subroutine or string can override this 
behavior.  The only argument that will be passed to any such routine will be
the name of the calling subroutine.

=head2 pderror

  pderror("error msg");

This function prints the passed message to STDERR.

=head2 pdebug

  pdebug("debug statement", 3);
  pdebug("debug statement: %s %2d %.3f", 3, @values);

This function is called with one mandatory argument (the string to be
printed), and an optional integer.  This integer is compared against B<PDEBUG>
and the debug statement is printed if PDEBUG is equal to it or higher.

The return value is always the debug statement itself.  This allows for a
single statement to produce debug output and set variables.  For instance:

  Paranoid::ERROR = pdebug("Something bad happened!", 3);

As an added benefit you can pass a L<printf> template along with their values
and they will be handled appropriately.  String values passed as B<undef> will
be replaced with the literal string "I<undef>".

One deviation from L<printf> allows you to specify a placeholder which can
gobble up any number of extra arguments while still performing the "I<undef>"
substitution:

    pdebug("I was passed these values: %s", 3, @values);

=head2 pIn

  pIn();

This function causes all subsequent pdebug messages to be indented by one
additional space.

=head2 pOut

  pOut();

This function causes all subsequent pdebug messages to be indented by one
less space.

=head1 DEPENDENCIES

L<Paranoid>

=head1 BUGS AND LIMITATIONS

B<pderror> (and by extension, B<pdebug>) will generate errors if STDERR is
closed elsewhere in the program.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

