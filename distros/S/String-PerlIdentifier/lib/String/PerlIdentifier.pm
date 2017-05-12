package String::PerlIdentifier;
use 5.006001;
use strict;
use base qw(Exporter);
our @EXPORT = qw{ make_varname };
our $VERSION = "0.06";
use Carp;

our @lower =  qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
our @upper = map { uc($_) } @lower;
our @alphas = (@upper, @lower);

our %forbidden = ();
our $MIN = 3;
our $MAX = 20;
our $DEFAULT = 10;

sub make_varname {
    my $length;
    my (@eligibles, @chars);
    my $scoresflag = 1;
    if (defined $_[0] and ref($_[0]) eq 'HASH') {
        my $argsref = shift;
        if ( (defined $argsref->{underscores}) &&
             ($argsref->{underscores} == 0) ) {
                 $scoresflag = 0;
        }
        if (defined $argsref->{min}) {
            croak "Minimum must be all numerals: $!"
                unless $argsref->{min} =~ /^\d+$/;
            croak "Cannot set minimum length less than 2: $!"
                unless $argsref->{min} >= 2;
            $MIN = $argsref->{min};
        }
        if (defined $argsref->{max}) {
            croak "Maximum must be all numerals: $!"
                unless $argsref->{max} =~ /^\d+$/;
            croak "Cannot set maximum length less than 3: $!"
                unless $argsref->{max} >= 3;
            $MAX = $argsref->{max};
        }
        if (defined $argsref->{default}) {
            croak "Default must be all numerals: $!"
                unless $argsref->{default} =~ /^\d+$/;
            $DEFAULT = $argsref->{default};
        }
        if ( (defined $argsref->{min}) &&
             (defined $argsref->{max}) ) {
            croak "Minimum must be <= Maximum: $!"
                if $argsref->{min} >= $argsref->{max};
        }
    } else {
        $length = shift;
    }
    $length = $DEFAULT if ! defined $length;
    $length = $MIN if $length < $MIN;
    $length = $MAX if $length > $MAX;
    @eligibles = $scoresflag ? (@alphas, q{_}) : (@alphas) ;
    @chars     = (@eligibles, 0..9);
        
    my $varname;
    MKVAR: {
        $varname = $eligibles[int(rand(@eligibles))];
        $varname .= $chars[int(rand(@chars))] for (1 .. ($length - 1));
        next MKVAR if $forbidden{$varname};
    }
    return $varname;
}

#################### DOCUMENTATION ###################

=head1 NAME

String::PerlIdentifier - Generate a random name for a Perl variable

=head1 VERSION

This document refers to version 0.06, released November 14 2016.

=head1 SYNOPSIS

    use String::PerlIdentifier;

    $varname = make_varname();      # defaults to 10 characters

or

    $varname = make_varname(12);    # min: 3    max: 20

or

    $varname = make_varname( {      # set your own attributes
        min     => $minimum,
        max     => $maximum,
        default => $default,
    } );

or

    $varname = make_varname( {      # no underscores in strings;
        underscores => 0,           # alphanumerics only
    } );

=head1 DESCRIPTION

This module automatically exports a single subroutine, C<make_varname()>, 
which returns a string composed of random characters that qualifies as 
the name for a Perl variable.  The characters are limited to upper- and
lower-case letters in the English alphabet, the numerals from 0 through 9
and the underscore character.  The first character may not be a numeral.

By default, C<make_varname()> returns a string of 10 characters, but if a
numerical argument between 3 and 20 is passed to it, a string of that length
will be returned.  Arguments smaller than 3 are rounded up to 3; arguments
greater than 20 are rounded down to 20.

C<make_varname()> can also take as an argument a reference to a hash
containing one or more of the following keys:

    min
    max
    default
    underscores

So if you wanted your string to contain a minimum of 15 characters and a
maximum of 30, you would call:

    $varname = make_varname( { min => 15, max => 30 } );

If you try to set C<min> greater than C<max>, you will get an error message
and C<croak>.  But if you set C<default> less than C<min> or greater than
C<max>, the default value will be raised to the minimum or lowered to the
maximum as is appropriate.

=head2 No underscores option

The only meaningful value for key C<underscores> is C<0>.
String::PerlIdentifier, like Perl itself, assumes that underscores are valid
parts of identifiers, so underscores are ''on'' by default.  So the only time
you need to worry about the C<underscores> element in the hash passed by
reference to C<make_varname()> is when you want to I<prevent> underscores from
being part of the string being generated -- in which case you set:

    underscores => 0

=head2 Non-Perl-identifier usages

Although the strings returned by C<make_varname()> qualify as Perl
identifiers, they also are a subset of the set of valid directory and file
names on operating systems such as Unix and Windows.  This is how, for
instance, this module's author uses C<make_varname()>.

B<Note:>  String::PerlIdentifier originally appeared on CPAN as
String::MkVarName.  When I went to register it on F<modules@perl.org>, 
C<brian d foy> persuaded me to change the name.

=head1 TO DO

Ideally, you should be able to pass the function a list of strings 
forbidden to be returned by C<make_varname>, I<e.g.,> a list of all 
Perl variables currently in scope.  String::PerlIdentifier doesn't do that yet.

=head1 SEE ALSO

=over 4

=item String::MkPasswd

This CPAN module by Chris Grau was the inspiration for String::PerlIdentifier.
String::PerlIdentifier evolved as a simplification of String::MkPasswd for 
use in the test suite for my other CPAN module File::Save::Home.

=item String::Random

This CPAN module by Steven Pritchard is a more general solution to the problem
of generating strings composed of random characters.  To generate a
10-character string that would qualify as a Perl identifier using
String::Random, you would proceed as follows:

    use String::Random;
    $rr = String::Random->new();
    $rr->{'E'} = [ 'A'..'Z', 'a'..'z', '_' ];
    $rr->{'F'} = [ 'A'..'Z', 'a'..'z', '_', 0..9 ];

then

    $rr->randpattern("EFFFFFFFFF");

String::Random's greater generality comes at the cost of more typing.

=item File::Save::Home

CPAN module by the same author as String::PerlIdentifier which uses
C<make_varname()> in its test suite as of its version 0.05.  
File::Save::Home is used internally within recent versions of 
ExtUtils::ModuleMaker and its test suite.

=back

=head1 AUTHOR

	James E Keenan
	CPAN ID: JKEENAN
	jkeenan@cpan.org
	http://search.cpan.org/~jkeenan

=head1 SUPPORT

Send email to jkeenan [at] cpan [dot] org.  Please include any of the
following in the subject line:

    String::PerlIdentifier
    String-PerlIdentifier
    make_varname

in the subject line.  Please report any bugs or feature requests to
C<bug-String-PerlIdentifier@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;


