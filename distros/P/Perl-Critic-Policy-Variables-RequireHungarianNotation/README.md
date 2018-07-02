[![pipeline status](https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation/badges/master/pipeline.svg)](https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation/commits/master)

# NAME

Perl::Critic::Policy::Variables::RequireHungarianNotation - Critic policy for hungarian notation.

# VERSION

Version 0.0.4

# SYNOPSIS

# DESCRIPTION

Don't let anyone guess which type you expect in your code:

    my @array    = ();    # don't do this
    my %hash     = ();    # or this
    my $hashref  = {};    # or this
    my $arrayref = [];    # or this
    my $string   = '';    # or this

The policy is also running through sub declarations.    

    # won't work
    sub some_sub {
        my ($self, $arrayref, $string) = @_;
        ...
    }

Instead, do this:

    my @a_array     = (); # do this
    my %h_hash      = (); # and this
    my $hr_hashref  = {}; # and this
    my $ar_arrayref = []; # and this
    my $s_string    = ''; # and this

    # this will (hopefuly)
    sub some_sub {
        my ($self, $ar_arrayref, $s_string) = @_;
        ...
    }

$self as variable is excluded.

# SUBROUTINES/METHODS

### expl()

Returns a string containing an explanation of this policy.

### supported_parameters
 
Return an array with information about the parameters supported.
 
    my @supported_parameters = $policy->supported_parameters();

### default_severity

Returns a numeric constant defining the severity of violating this policy.

### default_themes

Returns a list of strings defining the themes for this policy.

### applies_to

Returns a string describing the elements to which this policy applies.

### violates

Check an element for violations against this policy.
 
    my $o_policy->violates( $o_element, $o_document );

### desc()

Returns a string containing a sort description of this policy.

# INTERFACE 

[Perl::Critic::Policy](https://metacpan.org/pod/Perl::Critic::Policy)

# DIAGNOSTICS

# CONFIGURATION AND ENVIRONMENT

Each prefix is full configurable for it's own

### array

Prefix for Array vars.

    [Variables::RequireHungarianNotation]
    array = a_

### hash

Prefix for Hash vars.

    [Variables::RequireHungarianNotation]
    hash = h_

### array_ref

Prefix for Arrayref vars.

    [Variables::RequireHungarianNotation]
    array_ref = ar_

### hash_ref

Prefix for Hashref vars.

    [Variables::RequireHungarianNotation]
    hash_ref = hr_

### code_ref

Prefix for Coderef vars.

    [Variables::RequireHungarianNotation]
    code_ref = cr_

### object

Prefix for Object vars.

    [Variables::RequireHungarianNotation]
    object = o_

### integer

Prefix for Integer vars.

    [Variables::RequireHungarianNotation]
    integer = i_

### float

Prefix for Float vars.

    [Variables::RequireHungarianNotation]
    float = f_

### string

Prefix for String vars.

    [Variables::RequireHungarianNotation]
    string = s_

### boolean

Prefix for Boolean vars.

    [Variables::RequireHungarianNotation]
    boolean = b_

### regex

Prefix for predefined regular expressions.

    [Variables::RequireHungarianNotation]
    regex = rx_

### self

Ingore self is the class variable for it's own.

    [Variables::RequireHungarianNotation]
    self = this

### custom

A space-separated list of possible types you can append by your own style.

    [Variables::RequireHungarianNotation]
    custom = inv obj any


# DEPENDENCIES

 * [Perl::Critic::Policy](https://metacpan.org/pod/Perl::Critic::Policy)
 * [Perl::Critic::Utils](https://metacpan.org/pod/Perl::Critic::Utils)

# INCOMPATIBILITIES

None reported.

# BUGS AND LIMITATIONS

Please report any bugs or feature requests to 
[issues](https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation/issues)

# AUTHOR

Mario Zieschang  C<< <mziescha -at - cpan -dot- org> >>

# LICENSE AND COPYRIGHT

Copyright (c) 2018, Mario Zieschang. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See 
[perlartistic](https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation/blob/master/LICENSE).


# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

