# Paranoid::Debug -- Debug support for paranoid programs
#
# $Id: lib/Paranoid/Debug.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
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
use Carp;

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT = qw(PDEBUG pdebug pIn pOut subPreamble subPostamble
    PDEBUG1 PDEBUG2 PDEBUG3 PDEBUG4 PDEBUG5 PDEBUG6 PDEBUG7 PDEBUG8);
@EXPORT_OK = (
    @EXPORT,
    qw(pderror PDPREFIX PDLEVEL1 PDLEVEL2 PDLEVEL3 PDLEVEL4 PDMAXINDENT),
    );
%EXPORT_TAGS = (
    all       => [@EXPORT_OK],
    constants => [
        qw(PDEBUG1 PDEBUG2 PDEBUG3 PDEBUG4 PDEBUG5 PDEBUG6
            PDEBUG7 PDEBUG8)
        ],
        );

use constant PDLEVEL1 => 9;
use constant PDLEVEL2 => 10;
use constant PDLEVEL3 => 11;
use constant PDLEVEL4 => 12;

use constant PDMAXIND    => 40;
use constant PDMAXSCALAR => 20;

use constant PDEBUG1 => 1;
use constant PDEBUG2 => 2;
use constant PDEBUG3 => 3;
use constant PDEBUG4 => 4;
use constant PDEBUG5 => 5;
use constant PDEBUG6 => 6;
use constant PDEBUG7 => 7;
use constant PDEBUG8 => 8;

use constant CSF_PKG => 0;
use constant CSF_FNM => 1;
use constant CSF_LN  => 2;
use constant CSF_SUB => 3;
use constant CSF_HAS => 4;
use constant CSF_WNT => 5;
use constant CSF_EVL => 6;
use constant CSF_REQ => 7;
use constant CSF_HNT => 8;
use constant CSF_BIT => 9;
use constant CSF_HSH => 10;

#####################################################################
#
# Module code follows
#
#####################################################################

{
    my $dlevel   = 0;           # Start with no indentation
    my $pdebug   = 0;           # Start with debug output disabled
    my $maxLevel = PDMAXIND;    # Start with normal max indentation

    my $odefprefix = sub {

        # Old default Prefix to use with debug messages looks like:
        #
        #   [PID - $dlevel] Subroutine:
        #
        my $caller      = shift;
        my $indentation = shift;
        my $oi          = $indentation;
        my $prefix;

        # Cap indentation
        $indentation = $maxLevel if $indentation > $maxLevel;

        # Construct the prefix
        $prefix = ' ' x $indentation . "[$$-$oi] $caller: ";

        return $prefix;
    };
    my $defprefix = sub {

        # Default Prefix to use with debug messages looks like:
        #
        #   [PID-level caller]
        #
        my $caller      = shift;
        my $indentation = shift;
        my $prefix      = '';
        my $oi          = $indentation;

        # Cap indentation
        $indentation = ( $maxLevel / 3 ) if ( $indentation * 3 ) > $maxLevel;

        # Compose the prefix
        if ( $indentation == 1 ) {
            $prefix = '+> ';
        } elsif ( $indentation > 1 ) {
            $prefix = '|  ' x ( $indentation - 1 ) . '+> ';
        }
        $prefix .= "[$$-$oi $caller] ";

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
              defined $crec[CSF_SUB] ? $crec[CSF_SUB]
            : defined $crec[CSF_FNM] ? "$crec[CSF_FNM]/$crec[CSF_LN]"
            :                          'undef';

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
                $msg = sprintf $msg, @pfargs;
            }
        }

        return $msg if $level > PDEBUG;

        # Execute the code block, if that's what it is
        $prefix = &$prefix( $caller, $dlevel ) if ref($prefix) eq 'CODE';

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

        $dlevel++;

        return 1;
    }

    sub pOut () {

        # Purpose:  Decreases indentation level
        # Returns:  Always True (1)
        # Usage:    pOut();

        $dlevel--;

        return 1;
    }

    my %subprotos;

    sub _protos ($$) {

        # Purpose:  Converts a string prototype declaration to an array
        # Returns:  Array
        # Usage:    @proto = _protos($caller, $proto);

        my $caller = shift;
        my $proto  = shift;
        my ( $t, $p, @rv );

        if ( defined $proto and length $proto ) {

            if ( exists $subprotos{$caller} ) {

                # Return cached values if we have them
                @rv = @{ $subprotos{$caller} };

            } else {

                # Parse and generate list of argument types
                $p = $proto;
                while ( length $p ) {
                    if ( $p =~ /^\\/s ) {

                        # argument is a reference to... something.
                        push @rv, 'ref';
                        $p =~ s/^\\(\[[^\]]+\]|.)//s;

                    } elsif ( $p =~ /^([\$@%&\*pb])/s ) {

                        $t = $1;
                        push @rv,
                              $t eq '$' ? 'scalar'
                            : $t eq 'p' ? 'private'
                            : $t eq 'b' ? 'bytes'
                            : $t eq '@' ? 'array'
                            : $t eq '%' ? 'hash'
                            : $t eq '&' ? 'code'
                            :             'glob';
                        $p =~ s/^.//s;

                    } elsif ( $p =~ /^;/ ) {

                        # Remove the optional delimiter
                        $p =~ s/^;//s;

                    } else {
                        croak
                            "unknown prototype: $proto (stopped on $p) in\n\t"
                            . join ',',
                            caller 2;
                    }
                }

                # Cache results
                $subprotos{$caller} = [@rv];
            }

        }

        return @rv;
    }

    sub _summarize (\@@) {

        # Purpose:  Summarizes potentially long types of scalars
        # Returns:  Array
        # Usage:    @args = _summarize(@argt, @args);

        my $tref = shift;
        my @args = @_;
        my ( @tmp, %tmp, $i, $l );

        no warnings;
        use bytes;

        # Iterate over args/argt and summarize where appropriate
        for ( $i = 0; $i < @args; $i++ ) {
            if ( $$tref[$i] eq 'scalar' and not ref $args[$i] ) {
                if ( defined $args[$i] ) {
                    $l = length $args[$i];
                    $args[$i] =
                        substr( $args[$i], 0, PDMAXSCALAR ) . "... ($l bytes)"
                        if $l > PDMAXSCALAR;
                    $args[$i] =~ s/\n/\\n/sg;
                    $args[$i] =~ s/[^[:print:]]/./sg;
                }
            } elsif ( $$tref[$i] eq 'array' ) {
                @tmp = splice @args, $i;
                $args[$i] = sprintf 'list of %d items', scalar @tmp;
            } elsif ( $$tref[$i] eq 'hash' ) {
                %tmp = splice @args, $i;
                $args[$i] = sprintf 'hash of %d k/v pairs', scalar keys %tmp;
            } elsif ( $$tref[$i] eq 'private' ) {
                if ( defined $args[$i] ) {
                    $l = length $args[$i];
                    $args[$i] = "REDACTED ($l bytes)";
                }
            } elsif ( $$tref[$i] eq 'bytes' ) {
                if ( defined $args[$i] ) {
                    $l = length $args[$i];
                    $args[$i] = "$l bytes";
                }
            }

            $args[$i] = 'undef' unless defined $args[$i];
        }

        return @args;
    }

    sub subPreamble ($;$@) {

        # Purpose:  Specialized wrapper meant specifically for use in
        #           functions and methods
        # Returns:  Output of pdebug()
        # Usage:    subPreamble(PDEBUG1, '$$@', @_);

        my $level  = shift;
        my $proto  = shift;
        my @args   = splice @_;
        my @caller = caller(1);
        my @argt   = _protos $caller[CSF_SUB] . "-pre", $proto;
        my ( $rv, $msg );

        no warnings;

        # Summarize the args
        @args = _summarize( @argt, @args );

        # Print message
        $msg = 'entering';
        if (@args) {
            $msg .= ' w/' . '(%s)' x ( scalar @args );
        }
        $rv = pdebug( $msg, ( $level * -1 ), @args );

        # Increase indentation level
        $dlevel++;

        return $rv;
    }

    sub subPostamble ($$@) {

        # Purpose:  Specialized wrapper meant specifically for use in
        #           functions and methods
        # Returns:  Output of pdebug()
        # Usage:    subPostamble(PDEBUG1, '$', $rv);

        my $level  = shift;
        my $proto  = shift;
        my @args   = splice @_;
        my @caller = caller(1);
        my @argt   = _protos $caller[CSF_SUB] . '-post', $proto;
        my ( $rv, $msg );

        # Decrease indentation level
        $dlevel--;

        # Summarize the args
        @args = _summarize( @argt, @args );

        # Print message
        $msg = 'leaving w/rv: ';
        if (@args) {
            $msg .= '(%s)' x ( scalar @args );
        }
        $rv = pdebug( $msg, ( $level * -1 ), @args );

        return $rv;
    }

}

1;

__END__

=head1 NAME

Paranoid::Debug - Trace message support for paranoid programs

=head1 VERSION

$Id: lib/Paranoid/Debug.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Debug;

  PDEBUG        = 1;
  PDMAXINDENT   = 40;
  PDPREFIX      = sub { scalar localtime };
  pdebug("starting program", PDEBUG1);
  foo();

  # New method
  sub foo {
    my $foo = shift;
    my @bar = shift;
    my $rv;

    subPreamble(PDEBUG1, '$@', $foo, @bar);

    # Miscellaneous code...
    pdebug("someting happened!", PDEBUG2);

    # More miscellaneous code...

    subPostamble(PDEBUG1, '$', $rv);

    return $rv;
  }

  # Old method
  sub foo {
    my $foo = shift;
    my @bar = shift;
    my $rv;

    pdebug('entering w/(%s)(%s)', PDEBUG1, $foo, @bar);
    pIn();

    # Miscellaneous code...
    pdebug("someting happened!", PDEBUG2);

    # More miscellaneous code...

    pOut();
    pdebug('leaving w/rv: %s', PDEBUG1, $rv);

    return $rv;
  }

  pderror("error msg");

=head1 DESCRIPTION

The purpose of this module is to provide a useful framework to produce
debugging output.  With this module you can assign a level of detail to pdebug
statements, and they'll only be displayed to STDERR when PDEBUG is set to 
that level or higher.  This allows you to have your program produce varying 
levels of debugging output.

Using the B<subPreamble> and B<subPostamble> functions at the beginning and 
end of each function will cause debugging output to be indented appropriately 
so you can visually see the level of recursion.

B<NOTE:> All modules within the Paranoid framework use this module.  Their
debug levels range from 9 and up.  You should use 1 - 8 for your own modules
or code.  PDEBUG1 - PDEBUG8 exists for those purposes.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    PDEBUG pdebug pIn pOut subPreamble subPostamble PDEBUG1 .. PDEBUG8

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    constants   PDEBUG1 PDEBUG2 PDEBUG3 PDEBUG4 PDEBUG5 
                PDEBUG6 PDEBUG7 PDEBUG8
    all         @defaults @constants 
                pderror PDPREFIX PDLEVEL1 PDLEVEL2 
                PDLEVEL3 PDLEVEL4 PDMAXINDENT

=head1 CONSTANTS

=head2 PDEBUG1 .. PDEBUG8

There are eight constants exported by default for use by developers that allow
for up to eight levels of diagnostic output.  None of these levels are used by
internal B<Paranoid> code, they are reserved for use by third parties.

=head2 PDLEVEL1 .. PDLEVEL4

These constants are not intended for use by other modules, rather the exist
for the internal debug levels used by all Paranoid::* modules.  These levels
are all higher than what PDEBUG* to allow the developer to have as much
control over their verbosity as possible, but without the Paranoid diagnostics
adding unwanted noise.

=head1 SUBROUTINES/METHODS

=head2 PDEBUG

B<PDEBUG> is an lvalue subroutine which is initially set to 0, but can be 
set to any positive integer.  The higher the number the more pdebug 
statements are printed.

=head2 PDPREFIX

    PDPREFIX = sub {
        
        # Old default Prefix to use with debug messages looks like:
        #
        #   [PID - $dlevel] Subroutine:
        #
        my $caller      = shift;
        my $indentation = shift;
        my $oi          = $indentation;
        my $maxLevel    = PDMAXINDENT;
        my $prefix;

        # Cap indentation
        $indentation = $maxLevel if $indentation > $maxLevel;

        # Construct the prefix
        $prefix = ' ' x $indentation . "[$$-$oi] $caller: ";

        return $prefix;
        };

B<PDPREFIX> is an lvalue subroutine that contains a code reference to a
subroutine that returns an appropriate prefix for debug messages.  The default
subroutine prints an indented string (indented according to depth on the call 
stack) that prints the process PID, debug level, and the current routine/or 
method that B<pdebug> was called in.

=head2 PDMAXINDENT

B<PDMAXINDENT> is an lvalue subroutine which is initially set to 40, but can 
be set to any integer.  This controls the max indentation of the debug 
messages.  Obviously, it wouldn't help to indent a debug message by a hundred 
columns on an eighty column terminal just because your stack depth gets that 
deep.

=head2 pderror

  pderror("error msg");

This function prints the passed message to STDERR.

=head2 pdebug

  pdebug("debug statement", PDEBUG3);
  pdebug("debug statement: %s %2d %.3f", PDEBUG3, @values);

This function is called with one mandatory argument (the string to be
printed), and an optional integer.  This integer is compared against B<PDEBUG>
and the debug statement is printed if PDEBUG is equal to it or higher.

The return value is always the debug statement itself.  This allows for a
single statement to produce debug output and set variables.  For instance:

    Paranoid::ERROR = pdebug("Something bad happened!", PDEBUG3);

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

=head2 subPreamble

    subPreamble(PDEBUG1, '$@', @_);

This function combines the functionality of L<pdebug> and L<pIn> to mark the
entry point into a given function.  It also provides a convenient
summarization function to prevent logging overly long arguments to diagnostic
output.

The second argument to this function would be essentially whatever a valid
subroutine prototype would be for your function (see I<Prototypes> in
L<perlsub(3)> for more examples).  In addition to the standard prototypes, we
also support B<p> as a prototype.  This is essentially the same as a scalar
prototype, but instead of printing a summarized excerpt of its contents, it
replaces all characters with I<*> characters.  Any argument containing
sensitive information, such as passwords, etc, should use B<p> instead of
B<$>.

Summarization is performed in the following manner:  any scalar value
(excluding references of any kind) that exceeds 20 characters gets truncated
to 20 characters, and appended with the full number of bytes.  Lists merely
report how many elements in the array, and hashes list the number if key/value
pairs in the hash.  All other types are passed as-is.

Indentation is adjusted after the initial summarized message.

=head2 subPostamble

    subPostamble(PDEBUG1, '$', $rv);

This function works the same as L<subPreamble>, but with indentation happening
in reverse order.  The prototype should reflect the prototype of the returned
value, not the function arguments.  Indentation is set back prior to the the
summarized message is printed.

=head1 DEPENDENCIES

=over

=item o

L<Paranoid>

=item o

L<Carp>

=back

=head1 BUGS AND LIMITATIONS

B<pderror> (and by extension, B<pdebug>) will generate errors if STDERR is
closed elsewhere in the program.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

