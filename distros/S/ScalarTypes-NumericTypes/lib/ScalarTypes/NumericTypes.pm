package ScalarTypes::NumericTypes;

# Load the Perl pragmas.
use 5.030000;
use strict;
use warnings;

# Set the package version. 
our $VERSION = '0.02';

# Load the Perl pragma Exporter.
use Exporter;

# Base class of this module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutines.
our @EXPORT = qw(
                 is_unsigned_float
                 is_signed_float
                 is_unsigned_int
                 is_signed_int
                 is_binary
                 is_hex
);

#------------------------------# 
# Subroutine is_unsigned_float #
#------------------------------# 
sub is_unsigned_float {
    # Assign subroutine argument to local variable.
    my $input = $_[0];
    # Set output variable.
    my $is_float = undef;
    # Set regex pattern using digits match.
    my $re = qr/^(([0-9]{1}|[1-9]{1}[0-9]+)[.][0-9]+)$/;
    # Check input with regex pattern.
    if ($input =~ $re) {
        $is_float = 1;
    } else {
        $is_float = 0;
    };
    # Return 0 (false) or 1 (true).
    return $is_float; 
};

#----------------------------# 
# Subroutine is_signed_float #
#----------------------------# 
sub is_signed_float {
    # Assign subroutine argument to local variable.
    my $input = $_[0];
    # Set output variable.
    my $is_float = undef;
    # Set regex pattern using digits match.
    my $re = qr/^([+-]([0-9]{1}|[1-9]{1}[0-9]+)[.][0-9]+)$/;
    # Check input with regex pattern.
    if ($input =~ $re) {
        $is_float = 1;
    } else {
        $is_float = 0;
    };
    # Return 0 (false) or 1 (true).
    return $is_float; 
};

#----------------------------# 
# Subroutine is_unsigned_int #
#----------------------------# 
sub is_unsigned_int {
    print "LOCAL\n";
    # Assign the subroutine argument to the local variable.
    my $input = $_[0];
    # Declare the return variable.
    my $is_int = undef;
    # Set the Perl conform regex pattern.
    my $re = qr/^(([1-9][0-9]*)|0)$/;
    # Check the input with the regex pattern.
    if ($input =~ $re) {
        # Set result to true.
        $is_int = 1;
    } else {
        # Set result to false.
        $is_int = 0;
    };
    # Return 0 (false) or 1 (true).
    return $is_int; 
};

#--------------------------# 
# Subroutine is_signed_int #
#--------------------------# 
sub is_signed_int {
    # Assign the subroutine argument to the local variable.
    my $input = $_[0];
    # Declare the return variable.
    my $is_int = undef;
    # Set the Perl conform regex pattern.
    my $re = qr/^([+-]([1-9][0-9]*|0))$/;
    # Check the input with the regex pattern.
    if ($input =~ $re) {
        # Set result to true.
        $is_int = 1;
    } else {
        # Set result to false.
        $is_int = 0;
    };
    # Return 0 (false) or 1 (true).
    return $is_int; 
};

#------------------------------------------------------------------------------# 
# Subroutine is_hex                                                            #
#                                                                              #
# Description:                                                                 #    
# The subroutine checks if the given argument is a valid hexadecimal number.   #
# A hexadecimal number is valid when it consists of integer numbers from 0-9   #
# and lower case characters a-f as well as the upper case characters A-F-      #
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

#----------------------# 
# Subroutine is_binary #
#----------------------# 
sub is_binary {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Define the Perl conform regex pattern.
    my $re = qr/^([0-1]+)$/;
    # Check the argument with the regex pattern.
    my $is_binary = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_binary;
};

1;

__END__
# Below is the package documentation.

=head1 NAME

ScalarTypes::NumericTypes - Perl extension for identifyling special types of numbers

=head1 SYNOPSIS

  use ScalarTypes::NumericTypes;

  # Declare the teststring.
  my $teststring = undef;

  # Test unsigned integer.
  $teststring = "12345678";
  $testresult = is_unsigned_int($teststring); # Returns 1 (true) otherwise 0 (false)
  print $testresult . "\n";

  # Test signed integer.
  $teststring = "-12345678";
  $testresult = is_signed_int($teststring); # Returns 1 (true) otherwise 0 (false)
  print $testresult . "\n";

  # Test unsigned float.
  $teststring = "1234.5678";
  $testresult = is_unsigned_float($teststring); # Returns 1 (true) otherwise 0 (false)
  print $testresult . "\n";

  # Test signed float.
  $teststring = "+1234.5678";
  $testresult = is_signed_float($teststring); # Returns 1 (true) otherwise 0 (false)
  print $testresult . "\n";

  etc.

=head1 DESCRIPTION

=head2 Implemented Methods

=over 

=item is_signed_integer()
=item is_unsigned_integer()
=item is_signed_float()
=item is_unsigned_float()
=item is_binary()
=item is_hex()

=back

All of the implemented methods return 1 (true) or return 0 (false). A
subroutine argument is necessary otherwise an exception is thrown. 

=head2 is_unsigned_int()

Allowed integer is '12345678' to get true returned. Not allowed as an integer is
e.g. '01234567' with a starting null.

=head2 is_signed_int()

Allowed integer is '+12345678' to get true returned. Not allowed integer is e.g.
'-01234567' with a starting null.

=head2 is_unsigned_float()

Allowed float is '1234.5678' to get true returned. Not allowed float are '0123.4567', '.1234' or '0.'.

=head2 is_signed_float()

Allowed float is '-1234.5678' to get true returned. Not allowed float are '+0123.4567', '-.1234' or '+0.'.

=head1 SEE ALSO

Regular Expressions

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
