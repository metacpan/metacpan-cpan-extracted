######################################################################
#
# Copyright 1999 Web Juice, LLC. All Rights Reserved.
#
# String/Checker.pm
#
# An extensible string validation module (allowing commonly used
# checks on a string to be called more concisely and consistently).
#
# $Header: /usr/local/repository/advoco/String-Checker/Checker.pm,v 1.2 1999/08/26 04:38:41 dlowe Exp $
# $Log: Checker.pm,v $
# Revision 1.2  1999/08/26 04:38:41  dlowe
# Bugfix.
#
# Revision 1.1.1.1  1999/07/09 01:25:16  dlowe
# String::Checker
#
#
######################################################################
package String::Checker;

use strict;
use vars qw($VERSION %check_subs);
use Date::Manip;

$VERSION = '0.03';


##
## This is the default set of allowed expectations
##
%check_subs = ('allow_empty'    => \&check_allow_empty,
               'disallow_empty' => \&check_disallow_empty,
               'min'            => \&check_min,
               'max'            => \&check_max,
               'want_int'       => \&check_want_int,
               'want_float'     => \&check_want_float,
               'allow_chars'    => \&check_allow_chars,
               'disallow_chars' => \&check_disallow_chars,
               'upcase'         => \&check_upcase,
               'downcase'       => \&check_downcase,
               'stripxws'       => \&check_stripxws,
               'enum'           => \&check_enum,
               'match'          => \&check_match,
               'want_email'     => \&check_email,
               'want_date'      => \&check_date,
               'want_phone'     => \&check_phone, );



######################################################################
## NAME:          checkstring
##
## DESCRIPTION:   Verifies that a string meets some set of expectations.
##
## USAGE:         String::Checker::checkstring($string, [ $expectation1,
##                                                        $expectation2 ];
##
## RETURN VALUES: Returns a reference to an array, the values of which
##                are the names of failed expectations.
##
## BUGS:          Hopefully none.
######################################################################
sub checkstring (\$$)
{
    my($string_ref) = shift;
    my($checks)     = shift;
    my(@output);

    if ((ref($string_ref) ne 'SCALAR') || (ref($checks) ne 'ARRAY'))
    {
        return undef;
    }

    foreach my $c (@{$checks})
    {
        my($arg);

        if (ref($c))
        {
            ($c, $arg) = @{$c}[0, 1];
        }

        if (defined($check_subs{$c}))
        {
            my($ret);

            if (defined($arg))
            {
                $ret = $check_subs{$c}->($string_ref, $arg);
            } else
            {
                $ret = $check_subs{$c}->($string_ref);
            }

            if ((defined($ret)) && ($ret == 1))
            {
                push(@output, $c);
            }
        }
    }

    return(\@output);
}
### end checkstring ##################################################



######################################################################
## NAME:          register_check
##
## DESCRIPTION:   Register a new string checking routine.
##
## USAGE:         String::Checker::register_check($name, \&sub);
##
## RETURN VALUES: None.
##
## BUGS:          Hopefully none.
######################################################################
sub register_check ($$)
{
    my($check)   = shift;
    my($coderef) = shift;

    if (ref($coderef) eq 'CODE')
    {
        $check_subs{$check} = $coderef;
    }
}
### end register_check ###############################################



######################################################################
## NAME:          check_*
##
## DESCRIPTION:   A default set of string validators
##
## USAGE:         Don't.  Let checkstring do it for you.
##
## RETURN VALUES: undef if there's no problem, 1 otherwise.
##
## BUGS:          Hopefully none.
######################################################################
# convert undef to an empty string, if necessary
sub check_allow_empty ($)
{
    my($string_ref) = shift;

    if ((! defined($$string_ref)) || ($$string_ref eq ''))
    {
        $$string_ref = '';
    }
    return undef;
}

# blow up if the string is empty or undef
sub check_disallow_empty ($)
{
    my($string_ref) = shift;

    if ((! defined($$string_ref)) || ($$string_ref eq ''))
    {
        return 1;
    }
    return undef;
}

# ensure the string is no shorter than some minimum number of characters
sub check_min ($$)
{
    my($string_ref) = shift;
    my($min)        = shift || 0;

    if ((defined($$string_ref)) && (length($$string_ref) < $min))
    {
        return 1;
    }
    return undef;
}

# ensure the string is no longer than some maximum number of characters
sub check_max ($$)
{
    my($string_ref) = shift;
    my($max)        = shift || 0;

    if ((defined($$string_ref)) && (length($$string_ref) > $max))
    {
        return 1;
    }
    return undef;
}

# check if the string looks like a whole number
sub check_want_int ($)
{
    my($string_ref) = shift;

    if ((defined($$string_ref)) && ($$string_ref !~ /^\d*$/))
    {
        return 1;
    }
    return undef;
}

# check if the string looks like a real number
sub check_want_float ($)
{
    my($string_ref) = shift;

    if ((defined($$string_ref)) && ($$string_ref !~ /^\d*\.?\d*?$/))
    {
        return 1;
    }
    return undef;
}

# allow a particular character class
sub check_allow_chars ($$)
{
    my($string_ref) = shift;
    my($chars)      = shift || '';

    if ((defined($$string_ref)) && ($$string_ref !~ /^[$chars]*$/))
    {
        return 1;
    }
    return undef;
}

# disallow a particular character class
sub check_disallow_chars ($$)
{
    my($string_ref) = shift;
    my($chars)      = shift || '';

    if ((defined($$string_ref)) && ($$string_ref =~ /[$chars]/))
    {
        return 1;
    }
    return undef;
}

# smash the case of the string to uppercase
sub check_upcase ($)
{
    my($string_ref) = shift;

    if (! defined($$string_ref))
    {
        return undef;
    }
    $$string_ref = uc($$string_ref);
    return undef;
}

# smash the case of the string to lowercase
sub check_downcase ($)
{
    my($string_ref) = shift;

    if (! defined($$string_ref))
    {
        return undef;
    }
    $$string_ref = uc($$string_ref);
    return undef;
}

# strip leading and trailing whitespace
sub check_stripxws ($)
{
    my($string_ref) = shift;

    if (! defined($$string_ref))
    {
        return undef;
    }
    $$string_ref =~ s/^\s+//;
    $$string_ref =~ s/\s+$//;
    return undef;
}

# verify that the string matches a particular regexp
sub check_match ($$)
{
    my($string_ref) = shift;
    my($regexp)     = shift || '';

    if ((defined($$string_ref)) && ($$string_ref !~ /$regexp/))
    {
        return 1;
    }
    return undef;
}

# verify that the string is a member of a given list
sub check_enum ($$)
{
    my($string_ref) = shift;
    my($enum_list)  = shift;

    if (! defined($$string_ref))
    {
        return 1;
    }

    if (ref($enum_list) ne 'ARRAY')
    {
        return 1;
    }

    foreach my $item (@{$enum_list})
    {
        if ($$string_ref eq $item)
        {
            return undef;
        }
    }
    return 1;
}

# verify that we have what appears to be a valid e-mail address
sub check_email ($$)
{
    my($string_ref) = shift;

    if ((defined($$string_ref)) && ($$string_ref !~ /^\S+\@[\w-]+\.[\w\.-]+$/))
    {
        return 1;
    }
    return undef;
}

# verify that we have a valid date
sub check_date ($$)
{
    my($string_ref) = shift;
    my($format)     = shift;
    my($date);

    if ((defined($$string_ref)) && (defined($format)) && ($format ne ''))
    {
        $date = UnixDate($$string_ref, $format);
        if (! defined($date))
        {
            return 1;
        }
        $$string_ref = $date;
        return undef;
    }
    if (defined($$string_ref))
    {
        $date = ParseDate($$string_ref);
        if (! defined($date))
        {
            return 1;
        }
    }
    return undef;
}

# verify that we have what appears to be a valid phone number
sub check_phone ($$)
{
    my($string_ref) = shift;

    if ((defined($$string_ref)) && ($$string_ref !~ /^[0-9+.()-]*$/))
    {
        return 1;
    }
    return undef;
}

### end check_* ######################################################

1;
__END__

=head1 NAME

String::Checker - An extensible string validation module (allowing
commonly used checks on strings to be called more concisely and
consistently).

=head1 SYNOPSIS

 use String::Checker;

 String::Checker::register_check($checkname, \&sub);
 $return = String::Checker::checkstring($string, [ expectation, ... ]);

=head1 DESCRIPTION

This is a very simple library for checking a string against a given set of
expectations.  It contains a number of pre-defined expectations which can be
used, and can also be extended to perform any arbitrary match or modification
on a string.

Why is this useful?  If you're only checking one string, it probably isn't.
However, if you're checking a bunch of strings (say, for example, CGI input
parameters) against a set of expectations, this comes in pretty handy.  As
a matter of fact, the CGI::ArgChecker module is a simple, CGI.pm aware wrapper
for this library.

=head2 Checking a string

The checkstring function takes a string scalar and a reference to a list of
'expectations' as arguments, and outputs a reference to a list, containing
the names of the expectations which failed.

Each expectation, in turn, can either be a string scalar (the name of the
expectation) or a two-element array reference (the first element being the
name of the expectation, and second element being the argument to that
expectation.)  For example:

   $string = "foo";
   String::Checker::checkstring($string, [ 'allow_empty',
                                           [ 'max' => 20 ] ] );

Note that the expectations are run in order.  In the above case, for example,
the 'allow_empty' expectation would be checked first, followed by the 'max'
expectation with an argument of 20.

=head2 Defined checks

The module predefines a number of checks.  They are:

=over 3

=item B<allow_empty>

Never fails - will convert an undef scalar to an empty string, though.

=item B<disallow_empty>

Fails if the input string is either undef or empty.

=item B<min>

Fails if the length of the input string is less than the numeric value of
it's single argument.

=item B<max>

Fails if the length of the input string is more than the numeric value of
it's single argument.

=item B<want_int>

Fails if the input string does not solely consist of numeric characters.

=item B<want_float>

Fails if the argument does not solely consist of numeric characters, plus
an optional single '.'.

=item B<allow_chars>

Fails if the input string contains characters other than those in its
argument.

=item B<disallow_chars>

Fails if the input string contains any of the characters in its argument.

=item B<upcase>

Never fails - converts the string to upper case.

=item B<downcase>

Never fails - converts the string to lower case.

=item B<stripxws>

Never fails - strips leading and trailing whitespace from the string.

=item B<enum>

Fails if the input string does not precisely match at least one of the
elements of the array reference it takes as an argument.

=item B<match>

Fails if the input string does not match the regular expression it takes
as an argument.

=item B<want_email>

Fails if the input string does not match the regular expression: ^\S+\@@[\w-]+\.[\w\.-]+$

=item B<want_phone>

Fails if the input string does not match the regular expression ^[0-9+.()-]*$

=item B<want_date>

Interprets the input string as a date, if possible.  This will fail if it can't
figure out a date from the input.  In addition, it is possible to use this to
standardize date input.  Pass a formatting string (see the strftime(3) man page)
as an argument to this check, and the string will be formatted appropriately
if possible.  This is based on the Date::Manip(1) module, so that documentation
might prove valuable if you're using this check.

=back

=head2 Extension checks

Use register_check to register a new expectation checking routine.  This
function should be passed a new expectation name and a code reference.

This code reference will be called every time the expectation name is seen,
with either one or two arguments.  The first argument will always be
a reference to the input string (the function is free to modify the value
of the string).  The second argument, if any, is the second element of a
two-part expectation, whatever that might be.

The function should return undef unless there's a problem, in which case
it should return 1.  It's also best (if possible) to return undef if the
string is undef, so that the user can decide whether to allow_empty or
disallow_empty independent of your check.

For example, registering a check to verify that the input word is "poot"
would look like:

   String::Checker::register_check("ispoot", sub {
       my($s) = shift;
       if ((defined($$s)) && ($$s ne 'poot')) {
           return 1;
       }
       return undef;
   };

=head1 BUGS

Hopefully none.

=head1 AUTHOR

J. David Lowe, dlowe@webjuice.com

=head1 SEE ALSO

perl(1), CGI::ArgChecker(1)

=cut
