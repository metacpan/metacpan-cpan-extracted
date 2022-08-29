package ScalarTypes::NumericTypes;

# Load the Perl pragmas.
use 5.030000;
use strict;
use warnings;

# Set the package version. 
our $VERSION = '0.11';

# Load the Perl pragma Exporter.
use Exporter;

# Base class of this module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutines.
our @EXPORT = qw(
                 is_unsigned_sepdec
                 is_signed_sepdec
                 is_unsigned_float
                 is_signed_float
                 is_unsigned_int
                 is_signed_int
                 is_decimal
                 is_binary
                 is_octal
                 is_hex
                 is_upper_hex
                 is_lower_hex
                 is_roman
);

#------------------------------------------------------------------------------# 
# Subroutine is_unsigned_float                                                 #
#                                                                              #
# Description:                                                                 #
# A unsigned float in the context of this method consists of numbers from 0 to #
# 9 and a decimal dot as separator. Spaces before and after the number are not #
# allowed.                                                                     #
#------------------------------------------------------------------------------# 
sub is_unsigned_float {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Set regex pattern using digits match.
    my $re = qr/^(([0-9]{1}|[1-9]{1}[0-9]+)[.][0-9]+)$/;
    # Check the argument with the regex pattern.
    my $is_unsigned_float = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_unsigned_float; 
};

#------------------------------------------------------------------------------# 
# Subroutine is_signed_float                                                   #
#                                                                              #
# Description:                                                                 #
# A signed float in the context of this method consists of numbers from 0 to 9 #
# and a decimal dot as separator. Spaces before and after the number are not   #
# allowed.                                                                     #
#------------------------------------------------------------------------------# 
sub is_signed_float {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Set regex pattern using digits match.
    my $re = qr/^([+-]([0-9]{1}|[1-9]{1}[0-9]+)[.][0-9]+)$/;
    # Check the argument with the regex pattern.
    my $is_signed_float = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_signed_float; 
};

#------------------------------------------------------------------------------# 
# Subroutine is_unsigned_int                                                   #
#                                                                              #
# Description:                                                                 #
# A unsigned int consists of numbers from 0-9.                                 #
#------------------------------------------------------------------------------# 
sub is_unsigned_int {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Set the Perl conform regex pattern.
    my $re = qr/^(([1-9][0-9]*)|0)$/;
    # Check the argument with the regex pattern.
    my $is_unsigned_int = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_unsigned_int; 
};

#------------------------------------------------------------------------------# 
# Subroutine is_signed_int                                                     #
#                                                                              #
# Description:                                                                 #
# A signed int consists of numbers from 0-9 plus a sign.                       #
#------------------------------------------------------------------------------# 
sub is_signed_int {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Set the Perl conform regex pattern.
    my $re = qr/^([+-][1-9][0-9]*)$/;
    # Check the argument with the regex pattern.
    my $is_signed_int = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_signed_int; 
};

#------------------------------------------------------------------------------# 
# Subroutine is_hex                                                            #
#                                                                              #
# Description:                                                                 #
# The subroutine checks whether the specified argument is a valid hexadecimal  #
# number. A hexadecimal number in the context of this method is a number       #
# consisting of integers from 0-9, lower case characters from a-f or upper     #
# case characters from A-F. Spaces before and after the number itself are not  #
# allowed. The subroutine returns 1 (true) or 0 (false) based on the check.    #
#------------------------------------------------------------------------------# 
sub is_hex {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([0-9a-fA-F]+)$/;
    # Check the argument with the regex pattern.
    my $is_hex = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_hex;
};

#------------------------------------------------------------------------------# 
# Subroutine is_upper_hex                                                      #
#                                                                              #
# Description:                                                                 #
# The subroutine checks whether the specified argument is a valid hexadecimal  #
# number. A hexadecimal number in the context of this method is a number       #
# consisting of integers from 0-9 or upper case characters from A-F. Spaces    #
# before and after the number itself are not allowed. The subroutine returns   #
# 1 (true) or 0 (false) based on the check.                                    #
#------------------------------------------------------------------------------# 
sub is_upper_hex {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([0-9A-F]+)$/;
    # Check the argument with the regex pattern.
    my $is_uc_hex = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_uc_hex;
};

#------------------------------------------------------------------------------# 
# Subroutine is_lower_hex                                                      #
#                                                                              #
# Description:                                                                 #
# The subroutine checks whether the specified argument is a valid hexadecimal  #
# number. A hexadecimal number in the context of this method is a number       #
# consisting of integers from 0-9 or lower case characters from a-f. Spaces    #
# before and after the number itself are not allowed. The subroutine returns   #
# 1 (true) or 0 (false) based on the check.                                    #
#------------------------------------------------------------------------------# 
sub is_lower_hex {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([0-9a-f]+)$/;
    # Check the argument with the regex pattern.
    my $is_lc_hex = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_lc_hex;
};

#------------------------------------------------------------------------------# 
# Subroutine is_binary                                                         #
#                                                                              #
# Description:                                                                 #
# Binary numbers consist of the numbers 0 and 1.                               #
#------------------------------------------------------------------------------# 
sub is_binary {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([01]+)$/;
    # Check the argument with the regex pattern.
    my $is_binary = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_binary;
};

#------------------------------------------------------------------------------# 
# Subroutine is_decimal                                                        #
#                                                                              # 
# The decimal numeral system is the standard system for denoting e.g. integer  #
# numbers. In the context of this method numbers from 0 to 9 are allowed. A    #
# leading 0 is also allowed. In the base 10 system, which the decimal system   #
# is each digit is multiplied by a power of 10 according to its place and than #
# summed up.                                                                   #   
#------------------------------------------------------------------------------# 
sub is_decimal {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([0-9]+)$/;
    # Check the argument with the regex pattern.
    my $is_decimal = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_decimal;
};

#------------------------------------------------------------------------------# 
# Subroutine is_roman                                                          #
#                                                                              #
# Description:                                                                 #
# Roman numbers consist of the letters I, V, X, L, C, D, and M.                #
#------------------------------------------------------------------------------# 
sub is_roman {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([IVXLCDM]+)$/;
    # Check the argument with the regex pattern.
    my $is_binary = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_binary;
};

#------------------------------------------------------------------------------# 
# Subroutine is_octal                                                          #
#                                                                              #
# Description:                                                                 #
# Octal numbers consist of numbers from 0 to 7.                                #
#------------------------------------------------------------------------------# 
sub is_octal {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([0-7]+)$/;
    # Check the argument with the regex pattern.
    my $is_octal = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_octal;
};

#------------------------------------------------------------------------------# 
# Subroutine is_unsigned_sepdec                                                #
#                                                                              #
# Description:                                                                 #
# Comma or other separator instead of decimal point.                           #
#------------------------------------------------------------------------------# 
sub is_unsigned_sepdec {
    # Get the subroutine arguments.
    my ($str, $sep) = @_;
    # Assign the subroutine arguments to the local variablea.
    $str = (defined $str ? $str : '');
    $sep = (defined $sep ? $sep : '.');
    # Define the Perl conform regex pattern.
    my $re = qr/^(([0-9]{1}|[1-9]{1}[0-9]+)[,][0-9]+)$/;
    # Check the argument with the regex pattern.
    my $is_float = (($str =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_float;
};

#------------------------------------------------------------------------------# 
# Subroutine is_signed_sepdec                                                  #
#                                                                              #
# Description:                                                                 #
# Comma or other separator instead of decimal point.                           #
#------------------------------------------------------------------------------# 
sub is_signed_sepdec {
    # Get the subroutine arguments.
    my ($str, $sep) = @_;
    # Assign the subroutine arguments to the local variablea.
    $str = (defined $str ? $str : '');
    $sep = (defined $sep ? $sep : '.');
    # Define the Perl conform regex pattern.
    my $re = qr/^([+-]([0-9]{1}|[1-9]{1}[0-9]+)[$sep][0-9]+)$/;
    # Check the argument with the regex pattern.
    my $is_float = (($str =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_float;
};

1;

__END__
# Below is the package documentation.

=head1 NAME

ScalarTypes::NumericTypes - Perl extension for checking numeric types of Perl scalars

=head1 SYNOPSIS

  use ScalarTypes::NumericTypes;

  # Declare the teststring.
  my $teststring = undef;

  # Test unsigned integer.
  $teststring = "12345678"; # Valid unsigned integer.
  $testresult = is_unsigned_int($teststring); # Returns 1 (true)
  print $testresult . "\n";

  # Test signed integer.
  $teststring = "-12345678"; # Valid signed integer. 
  $testresult = is_signed_int($teststring); # Returns 1 (true)
  print $testresult . "\n";

  # Test unsigned float.
  $teststring = "1234.5678"; # Valid unsigned float. 
  $testresult = is_unsigned_float($teststring); # Returns 1 (true)
  print $testresult . "\n";

  # Test signed float.
  $teststring = "+1234.5678"; # Valid signed float.
  $testresult = is_signed_float($teststring); # Returns 1 (true)
  print $testresult . "\n";

  # Test unsigned float with separator.
  $string = "1234,5678"; # Valid unsigned float. 
  $sep = ","; # Decimal comma instead of decimal point.
  $testresult = is_unsigned_sepdec($string, $sep); # Returns 1 (true)
  print $testresult . "\n";

  # Test unsigned float with separator.
  $string = "+1234,5678"; # Valid signed float.
  $sep = ","; # Decimal comma instead of decimal point. 
  $testresult = is_signed_sepdec($string, $sep); # Returns 1 (true)
  print $testresult . "\n";

=head1 DESCRIPTION

=head2 Implemented Methods

=over 4 

=item * is_signed_sepdec()

=item * is_unsigned_sepdec()

=item * is_signed_float()

=item * is_unsigned_float()

=item * is_signed_integer()

=item * is_unsigned_integer()

=item * is_decimal()

=item * is_binary()

=item * is_octal()

=item * is_hex()

=item * is_upper_hex()

=item * is_lower_hex()

=item * is_roman()

=back

All of the implemented methods return 1 (true) or return 0 (false). A
subroutine argument is necessary. If no argument is given in the 
subroutine call the argument is set to an empty string.

=head2 Method is_unsigned_float()

=head3 Method call

    is_unsigned_float($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

A unsigned float in the context of the method consists of numbers from 0 to 9
and a decimal dot as separator. Before and after the separtor there must be a 
valid number. Spaces before and after the number are not allowed. A sign like
+ or - is not allowed in front of the number. The seperator must be a decimal 
point.                                                                     

=head3 Examples of return values

Following scalars return 1 (true):

    '0.0'      -> 1
    '0.9'      -> 1
    '1.645'    -> 1
    '124.567'  -> 1

Following scalars return 0 (false):

    '.0'       -> 0
    '0.'       -> 0
    ' 1.3'     -> 0
    '3.1 '     -> 0
    ' 0.0 '    -> 0
    '4,5'      -> 0
    '+9.2'     -> 0
    'abc'      -> 0

=head2 Method is_signed_float()

=head3 Method call

    is_signed_float($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

A signed float in the context of the method consists of numbers from 0 to 9
and a decimal dot as separator. Before and after the separtor there must be a 
valid number. Spaces before and after the number are not allowed. A sign like
+ or - is required in front of the number. The seperator must be a decimal 
point.

=head3 Examples of return values

Following scalars return 1 (true):

    '+0.9'     -> 1
    '-1.645'   -> 1
    '+24.567'  -> 1

Following scalars return 0 (false):

    '+.0'      -> 0
    '-0.'      -> 0
    '.0'       -> 0
    '0.'       -> 0
    ' 0.0 '    -> 0
    ' -6.37 '  -> 0
    ' +2.3'    -> 0
    '-3.4 '    -> 0
    ' 1.3'     -> 0
    '3.1 '     -> 0
    '4,5'      -> 0
    'abc'      -> 0

=head2 Method is_unsigned_int()

=head3 Method call

    is_unsigned_int($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

A unsigned integer consists of numbers from 0-9.

=head3 Examples of return values

Following scalars return 1 (true):

    '0'        -> 1
    '6430'     -> 1
    '12345678' -> 1

Following scalars return 0 (false):

    '01234567' -> 0
    ' 823467'  -> 0
    '521496 '  -> 0

A leading 0 and spaces before and after result in not valid result.

=head2 Method is_signed_int()

=head3 Method call

    is_signed_int($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

A signed integer consists of numbers from 0-9.

=head3 Examples of return values

Following scalars return 1 (true):

    '+1'       -> 1
    '-6430'    -> 1
    '+1245678' -> 1

Following scalars return 0 (false):

    '-0'       -> 0
    ' +26367'  -> 0
    '-52496 '  -> 0

=head2 Method is_hex()
 
=head3 Method call

    is_hex($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

The subroutine checks whether the specified argument is a valid hexadecimal 
number. A hexadecimal number in the context of this method is a number      
consisting of integers from 0-9, lower case characters from a-f or upper    
case characters from A-F. Spaces before and after the number itself are not 
allowed. The subroutine returns 1 (true) or 0 (false) based on the check.   

=head3 Examples of return values

Following scalars return 1 (true):

    '1f'       -> 1
    '0E'       -> 1
    '2Ad3 '    -> 1

=head2 Method is_upper_hex()

=head3 Method call

    is_upper_hex($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

Same as is_hex(). Only uper case hex characters are valid.

=head2 Method is_lower_hex()

=head3 Method call

    is_lower_hex($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

Same as is_hex(). Only lower case hex characters are valid.

=head2 Method is_binary()

=head3 Method call

    is_binary($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

The method returns true on a valid binary. A valid binary consist of 0 and 1.

=head3 Examples of return values

Following scalars return 1 (true):

    '0'        -> 1
    '1'        -> 1
    '0110011'  -> 1
    '1011000'  -> 1

All other scalars are not valid.

=head2 Method is_decimal()

=head3 Method call

    is_decimal($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

The decimal numeral system is the standard system for denoting e.g. integer 
numbers. In the context of this method numbers from 0 to 9 are allowed. A   
leading 0 is also allowed. In the base 10 system, which the decimal system  
is, each digit is multiplied by a power of 10 according to its place and than
summed up.                                                                     

=head3 Examples of return values

Following scalars return 1 (true):

    '01'       -> 1
    '20'       -> 1
    '2345'     -> 1
    '0967'     -> 1

=head2 Method is_octal()

=head3 Method call

    is_octal($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

Octal numbers consist of numbers from 0 to 7.

=head3 Examples of return values

Following scalars return 1 (true):

    '01'       -> 1
    '70'       -> 1
    '672'      -> 1
    '0254'     -> 1

=head2 Method is_signed_sepdec()

=head3 Method call

    is_signed_sepdec($str, $sep)

If C<$str> is undefined or missing in the subroutine call the methods sets the
argument C<$str> to ''. If C<$sep> is undefined or missing in the subroutine call
the methods sets the argument C<$sep> to ''.

=head3 Method description

E.g. comma instead decimal point in signed decimal comma numbers.

=head3 Examples of return values

Following scalars return 1 (true) if separator is a comma:

    '0,1'      -> 1
    '70,34'    -> 1

=head2 Method is_unsigned_sepdec()

=head3 Method call

    is_unsigned_sepdec($str, $sep)

If C<$str> is undefined or missing in the subroutine call the methods sets the
argument C<$str> to ''. If C<$sep> is undefined or missing in the subroutine call
the methods sets the argument C<$sep> to ''.

=head3 Method description

E.g. comma instead decimal point in unsigned decimal comma numbers.

=head3 Examples of return values

Following scalars return 1 (true) if separator is a comma:

    '+0,1'      -> 1
    '-70,34'    -> 1

=head2 Method is_roman()

=head3 Method call

    is_roman($string)

If C<$string> is undefined or missing in the subroutine call the methods sets the
argument C<$string> to ''.

=head3 Method description

The method returns true on a valid roman number. A valid roman number consist 
of uper case letters I, V, X, L, C, D and M.

    I  ->  1 
    V  ->  5
    X  ->  10
    L  ->  50
    C  ->  100
    D  ->  500
    M  ->  1000

The method does not check whether the Roman numeral is valid according to the
Roman calculation rules. It is only checked whether the permitted number symbols
are contained in the number.

=head3 Examples of return values

Following scalars return 1 (true):

    'I'        -> 1
    'LM'       -> 1
    'CDI'      -> 1
    'MMXXII'   -> 1

=head1 Background

Regular expressions or short written regex are used to check the scalars.
According to the Perl documentation, \d recognises not only the numbers 0 to 9,
but other number signs. Accordingly, the methods of this module use e.g. [0-9]
for the recognition of numbers.

=head1 SEE ALSO

Perl documentation
Tutorials about Regular Expressions

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
