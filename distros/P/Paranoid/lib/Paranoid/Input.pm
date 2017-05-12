# Paranoid::Input -- Paranoid input functions
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Input.pm, 2.05 2017/02/06 01:48:57 acorliss Exp $
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

package Paranoid::Input;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Carp;

($VERSION) = ( q$Revision: 2.05 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(detaint stringMatch pchomp);
@EXPORT_OK   = ( @EXPORT, qw(NEWLINE_REGEX) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant NEWLINE_REGEX => qr#(?:\15\12|\15|\12)#so;

#####################################################################
#
# Module code follows
#
#####################################################################

sub pchomp (;\[$@%]) {

    # Purpose:  Platform neutral chomping
    # Returns:  same as chomp
    # Usage:    $n = pchomp($string);

    my ($ref) = @_;
    my $rv    = 0;
    my $nl    = NEWLINE_REGEX;
    my $e;

    # If no args were passed work on $_
    $ref = \$_ unless @_;

    # slurp-mode bypass
    return $rv unless defined $/;

    if ( ref $ref eq 'SCALAR' and defined $$ref ) {
        if ( $/ =~ /^$nl$/so ) {
            $e = length $$ref;
            $$ref =~ s/$nl$//so;
            $rv = $e - length $$ref;
        } else {
            $rv = chomp $$ref;
        }
    } elsif ( ref $ref eq 'ARRAY' ) {
        if ( $/ =~ /^$nl$/so ) {
            foreach (@$ref) {
                next unless defined;
                $e = length $_;
                $_ =~ s/$nl$//so;
                $rv += $e - length $_;
            }
        } else {
            $rv = chomp @$ref;
        }
    } elsif ( ref $ref eq 'HASH' ) {
        if ( $/ =~ /^$nl$/so ) {
            foreach ( keys %$ref ) {
                next unless defined $$ref{$_};
                $e = length $$ref{$_};
                $$ref{$_} =~ s/$nl$//so;
                $rv += $e - length $$ref{$_};
            }
        } else {
            $rv = chomp %$ref;
        }
    }

    return $rv;
}

our %regexes = (
    alphabetic   => qr/[a-z]+/si,
    alphanumeric => qr/[a-z0-9]+/si,
    alphawhite   => qr/[a-z\s]+/si,
    alnumwhite   => qr/[a-z0-9\s]+/si,
    email        => qr/[a-z][\w\.\-]*\@(?:[a-z0-9][a-z0-9\-]*\.)*[a-z0-9]+/si,
    filename     => qr#[/ \w\-\.:,@\+]+\[?#s,
    fileglob     => qr#[/ \w\-\.:,@\+\*\?\{\}\[\]]+\[?#s,
    hostname     => qr#(?:[a-z0-9][a-z0-9\-]*)(?:\.[a-z0-9][a-z0-9\-]*)*\.?#s,
    ipv4addr =>
        qr/(?:(?:\d\d?|1\d\d|2[0-4][0-9]|25[0-5])\.){3}(?:\d\d?|1\d\d|2[0-4][0-9]|25[0-5])/s,
    ipv4netaddr =>
        qr#(?:(?:\d\d?|1\d\d|2[0-4][0-9]|25[0-5])\.){3}(?:\d\d?|1\d\d|2[0-4][0-9]|25[0-5])/(?:(?:\d|[12]\d|3[0-2])|(?:(?:\d\d?|1\d\d|2[0-4][0-9]|25[0-5])\.){3}(?:\d\d?|1\d\d|2[0-4][0-9]|25[0-5]))#s,
    ipv6addr => qr/
        :(?::[abcdef\d]{1,4}){1,7}                 | 
        [abcdef\d]{1,4}(?:::?[abcdef\d]{1,4}){1,7} | 
        (?:[abcdef\d]{1,4}:){1,7}: 
        /six,
    ipv6netaddr => qr#(?::(?::[abcdef\d]{1,4}){1,7}| 
        [abcdef\d]{1,4}(?:::?[abcdef\d]{1,4}){1,7} | 
        (?:[abcdef\d]{1,4}:){1,7}:)/(?:\d\d?|1(?:[01]\d|2[0-8]))#six,
    login  => qr/[a-z][\w\.\-]*/si,
    nometa => qr/[^\%\`\$\!\@]+/s,
    number => qr/[+\-]?[0-9]+(?:\.[0-9]+)?/s,
    'int'  => qr/[-+]?\d+/s,
    uint   => qr/\d+/s,
    float  => qr/[-+]?\d+(?:\.\d+)/s,
    ufloat => qr/\d+(?:\.\d+)/s,
    bin    => qr/[01]+/s,
    octal  => qr/[0-7]+/s,
    'hex'  => qr/[a-z0-9]+/si,
    );

sub detaint (\[$@%]$;\[$@%]) {

    # Purpose:  Detaints and validates input in one call
    # Returns:  True (1) if detainting was successful,
    #           False (0) if there are any errors
    # Usage:    $rv = detaint($input, $dataType, $detainted);
    # Usage:    $rv = detaint(@input, $dataType, @detainted);
    # Usage:    $rv = detaint(%input, $dataType, %detainted);

    my $iref = shift;
    my $type = shift;
    my $oref = shift;
    my $po   = defined $oref;
    my $rv   = 0;
    my ( $regex, $tmp );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $iref, $type, $oref );
    pIn();

    # Make sure input and output data types match
    croak "$iref and $oref aren't compatible data types"
        unless !defined $oref
            or ref $iref eq ref $oref;

    # Warn on unknown regexes
    if ( ref $type eq 'Regexp' ) {
        $regex = $type;
        $type  = 'custom';
    } else {
        if ( defined $type and exists $regexes{$type} ) {
            $regex = $regexes{$type};
        } else {
            pdebug( 'unknown regex type requested: %s', PDLEVEL1, $type );
        }
    }

    # Create a reference structure under $oref if none was passed
    unless ( defined $oref ) {
        $oref =
              ref $iref eq 'ARRAY' ? []
            : ref $iref eq 'HASH'  ? {}
            :                        \$tmp;
    }

    # Make sure $oref is empty
    if ( ref $oref eq 'SCALAR' ) {
        $$oref = undef;
    } elsif ( ref $oref eq 'ARRAY' ) {
        @$oref = ();
    } else {
        %$oref = ();
    }

    # Start working
    if ( defined $regex ) {
        if ( ref $iref eq 'SCALAR' ) {
            pdebug( 'evaluating (%s)', PDLEVEL2, $$iref );
            ($$oref) = ( $$iref =~ /^($regex)$/s )
                if defined $$iref;
            $rv = defined $$oref;
        } elsif ( ref $iref eq 'ARRAY' ) {
            if ( scalar @$iref ) {
                $rv = 1;
                foreach (@$iref) {
                    pdebug( 'evaluating (%s)', PDLEVEL2, $_ );
                    ( $$oref[ $#{$oref} + 1 ] ) =
                        defined $_ ? m/^($regex)$/s : (undef);
                    $rv = 0 unless defined $$oref[-1];
                    pdebug( 'got (%s)', PDLEVEL2, $$oref[-1] );
                }
            }
            $rv = !scalar grep { !defined } @$oref;
        } else {
            if ( scalar keys %$iref ) {
                $rv = 1;
                foreach ( keys %$iref ) {
                    pdebug( 'evaluating (%s)', PDLEVEL2, $$iref{$_} );
                    ( $$oref{$_} ) =
                        defined $$iref{$_}
                        ? ( $$iref{$_} =~ m/^($regex)$/s )
                        : undef;
                    $rv = 0 unless defined $$oref{$_};
                }
            }
        }
    }

    # Copy everything back to $iref if needed
    unless ($po) {
        if ( ref $iref eq 'SCALAR' ) {
            $$iref = $$oref;
        } elsif ( ref $iref eq 'ARRAY' ) {
            @$iref = @$oref;
        } else {
            %$iref = %$oref;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub stringMatch ($@) {

    # Purpose:  Looks for occurrences of strings and/or regexes in the passed
    #           input
    # Returns:  True (1) any of the strings/regexes match,
    #           False (0), otherwise
    # Usage:    $rv = stringMatch($input, @words);

    my $input = shift;
    my @match = splice @_;
    my $rv    = 0;
    my @regex;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $input, @match );
    pIn();

    if ( defined $input and @match ) {

        # Populate @regex w/regexes
        @regex = grep { defined $_ && ref $_ eq 'Regexp' } @match;

        # Convert remaining strings to regexes
        foreach ( grep { defined $_ && ref $_ ne 'Regexp' } @match ) {
            push @regex, m#^/(.+)/$#s ? qr#$1#si : qr#\Q$_\E#si;
        }

        # Start comparisons
        study $input;
        foreach my $r (@regex) {
            if ( $input =~ /$r/si ) {
                $rv = 1;
                last;
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Input - Paranoid input functions

=head1 VERSION

$Id: lib/Paranoid/Input.pm, 2.05 2017/02/06 01:48:57 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Input;

  $rv = detaint($userInput, "login", $detainted);
  $rv = detaint(@userInput, "login", @detainted);
  $rv = detaint(%userInput, "login", %detainted);

  $rv = detaint($input, qr#\w+\s+\d+#s);
  $rv = detaint(@input, qr#\w+\s+\d+#s);
  $rv = detaint(%input, qr#\w+\s+\d+#s);

  $rv = stringMatch($input, @strings);

  $Paranoid::Input::regexes{'new_type"} = qr/\w\s+\d+/s;

  $rv = pchomp($lines);
  $rv = pchomp(@lines);
  $rv = pchomp(%dict);

  # Chomp $_
  $rv = pchomp();

=head1 DESCRIPTION

This provides some generic functions for working with text-based input.  The
main benefirst of this module is a relatively simple way of validating and
detainting formatted text and performing platform-agnostic chomps.

=head1 SUBROUTINES/METHODS

=head2 detaint

  $rv = detaint($userInput, "login", $val);

This function populates the passed data object with the detainted input from the
first argument.  The second argument specifies the type of data in the first
argument, and is used to validate the input before detainting.  If you don't
want to use one of the built-in regular expressions you can, instead, pass
your own custom regular expression.

The third argument is optional, but if used, must match the first argument's
data type.  If it is omitted all detainted values are used to overwrite the
contents of the first argument.  If detaint fails for any reason B<undef> is
used instead.

If the first argument fails to match against these regular expressions the
function will return 0.  If the string passed is either undefined or a
zero-length string it will also return 0.  And finally, if you attempt to use
an unknown (or unregistered) data type it will also return 0, and log an error
message in B<Paranoid::ERROR>.

The following regular expressions are known by name:

    Name            Description
    =========================================================
    alphabetic      Alphabetic characters
    alphanumeric    Alphabetic/numeric characters
    alphawhite      Alphabetic/whitespace characters
    alnumwhite      Alphabetic/numeric/whitespace characters
    email           RFC 822 Email address format
    filename        Essentially no-metacharacters
    fileglob        Same as filename, but with glob meta-
                    character support
    hostname        Alphanumeric/hyphenated host names
    ipv4addr        IPv4 address
    ipv4netaddr     IPv4 network address (CIDR/dotted quad)
    ipv6addr        IPv6 address
    ipv6netaddr     IPv6 network address (CIDR)
    login           UNIX login format
    nometa          Everything but meta-characters
    number          Integer/float/signed/unsigned
    int             Integer/signed/unsigned
    uint            Integer/unsigned
    float           Float/signed/unsigned
    ufloat          Float/unsigned
    bin             binary
    octal           octal
    hex             hexadecimal

=head2 stringMatch

  $rv = stringMatch($input, @strings);

This function does a multiline case insensitive regex match against the 
input for every string passed for matching.  This does safe quoted matches 
(\Q$string\E) for all the strings, unless the string is a perl Regexp 
(defined with qr//) or begins and ends with /.

B<NOTE>: this performs a study in hopes that for a large number of regexes
will be performed faster.  This may not always be the case.

=head2 pchomp

    $rv = pchomp(@lines);

B<pchomp> is meant to be a drop-in replacement for chomp, primarily where you
want it to work as a platform-agnostic line chomper.  If I<$/> is altered in
any manner (slurp mode, fixed record length, etc.) it will assume that's not
important and automatically call B<chomp> instead.  It should, then, be safe 
to be called in all instances in which you'd call B<chomp> itself.

In a nutshell, this function attempts to avoid the assumption that B<chomp>
makes in that the latter assumes that all input it works upon was authored on
the same system, using the same input record separators.  Using B<pchomp> in
lieu of B<chomp> will allow you to treat DOS, UNIX, and Mac-authored files
identically with no additional coding.

Because it is assumed that B<pchomp> will be used in potentially high
frequency scenarios no B<pdebug> calls are made within it to avoid exercising
the stack any more than necessary.  It is hoped that the relative simplicity
of the subroutine should make debug use unnecessary.

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

