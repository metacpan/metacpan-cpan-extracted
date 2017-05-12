package Solstice::ValidationParam;

# $Id: Controller.pm 3036 2006-01-28 06:18:47Z mcrawfor $

=head1 NAME

Solstice::ValidationParam - Interface for validating user input.

=head1 SYNOPSIS

  # This should be called in a controller object... 
  my $param = $self->createRequiredParam('input_name');
  my $param = $self->createOptionalParam('input_name');
  # An alias for createRequiredParam
  my $param = $self->createParam('input_name');

  # To add your own constraint:
  $param->addConstraint('error_string_key', \&callback);

  # There are some built in constraints:
  $param->addNumberConstraint('err_key');
  $param->addIntegerConstraint('err_key');
  $param->addPositiveNumberConstraint('err_key');
  $param->addPositiveIntegerConstraint('err_key');
  $param->addLengthConstraint('err_key', { max => $max_length, min => $min_length });
  $param->addTrimmedLengthConstraint('err_key', { max_length => $max_length, min_length => $min_length });
  $param->addBooleanConstraint('err_key');
  $param->addRegexConstraint('err_key', qr/.*/);

=head1 DESCRIPTION

This is an interface for validation.  Tied in pretty tightly with the controllers at this point. 
TODO - Make it easy to specify a javascript constraint?

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::List;
use Unicode::String;

use constant TRUE  => 1;
use constant FALSE => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::ValidationParam object.  

=cut

sub new {
    my $class = shift;
    my $field = shift;
    
    my $self = $class->SUPER::new(@_);

    $self->_setField($field);
    $self->{'_constraints'} = Solstice::List->new();

    return $self;
}

=item addConstraint('error_key', \&constraint_function_ref);

Adds a constraint to the field.

=cut

sub addConstraint {
    my $self = shift;
    my $err_key = shift;
    my $constraint_function = shift;
    
    my $list = $self->getConstraints();
    
    $list->add({ error_key => $err_key, constraint => $constraint_function });
    return TRUE;
}

=item addRegexConstraint('error_key', qr/regexp/)

Add a matching constraint to the field. The passed $regexp is a string containing
a regular expression.

=cut

sub addRegexConstraint {
    my $self = shift;
    my $err_key = shift;
    my $reg_exp = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainRegex($reg_exp));
}

=item addLengthConstraint('error_key', { max => $max_length, min => $min_length })

Adds a constraint based on the length of the input.  Min defaults to 0 if not specified.

=cut

sub addLengthConstraint {
    my $self = shift;
    my $err_key = shift;
    my $input = shift;
    
    my $max = $input->{'max'};
    my $min = $input->{'min'} || 0;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainLength($max, $min));
}

=item addTrimmedLengthConstraint('error_key', { max => $max_length, min => $min_length })

Adds a constraint based on the length of the input, after whitespace has been removed from the beginning and end of the string.  Min defaults to 0 if not specified.

=cut

sub addTrimmedLengthConstraint {
    my $self = shift;
    my $err_key = shift;
    my $input = shift;
    
    my $max = $input->{'max'};
    my $min = $input->{'min'} || 0;
    my $trim_ws = TRUE;
    
    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainLength($max, $min, $trim_ws));
}

=item addNumberConstraint('error_key')

Adds a constraint requiring that the input be a number.

=cut

sub addNumberConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainNumber());
}

=item addIntegerConstraint('error_key')

Adds a constraint requiring that the input be an integer.

=cut

sub addIntegerConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainInteger());
}

=item addPositiveNumberConstraint('error_key')

Adds a constraint requiring that the input be a positive number.

=cut

sub addPositiveNumberConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainPositiveNumber());
}

=item addPositiveIntegerConstraint('error_key')

Adds a constraint requiring that the input be a positive integer.

=cut

sub addPositiveIntegerConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainPositiveInteger());
}

=item addBooleanConstraint('error_key')

Adds a constraint requiring that the input be a boolean.

=cut

sub addBooleanConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainBoolean());
}

=item addURLConstraint('error_key')

Adds a constraint requiring that the input be a url.

=cut

sub addURLConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainURL());
}

=item addEmailConstraint('error_key')

Adds a constraint requiring that the input be an email address.

=cut

sub addEmailConstraint {
    my $self = shift;
    my $err_key = shift;

    return $self->addConstraint($err_key, Solstice::ValidationParam::Constraints::constrainEmail());
}
  
=item getConstraints()

Returns the L<Solstice::List> of constraints.

=cut

sub getConstraints {
    my $self = shift;
    return $self->{'_constraints'};
}

=item setRequired()

Marks this field as required.  Cancels any calls to setOptional.

=cut

sub setRequired {
    my $self = shift;
    $self->{'_is_required'} = TRUE;
}

=item setOptional()

Marks this field as optional.  Cancels any calls to setRequired.

=cut

sub setOptional {
    my $self = shift;
    $self->{'_is_required'} = FALSE;
}

=item isRequired()

Returns the requiredness of this param.

=cut

sub isRequired {
    my $self = shift;
    return $self->{'_is_required'};
}

=item _setField($fname)

Sets the field we're validating.

=cut

sub _setField {
    my $self = shift;
    $self->{'_field_name'} = shift;
}

=item getFieldName()

Returns the name of the field we're validating.

=cut

sub getFieldName {
    my $self = shift;
    return $self->{'_field_name'};
}

=back

=cut

package Solstice::ValidationParam::Constraints;

use base qw(Solstice);

use Solstice::StringLibrary qw(trimstr decode);

=head1 NAME

Solstice::ValidationParam::Constraints - A set of methods to return validation routines for Solstice::ValidationParam.

=over 4

=cut

=item constrainRegex($reg_exp)

=cut

sub constrainRegex {
    my $reg_exp = shift;

    return sub {
        my $param = shift;
        return (defined $param and $param =~ $reg_exp);    
    };
}

=item constrainLength($max, $min, $trim_whitespace)

This method returns a reference to a subroutine which checks
the length of the string $param. Multi-byte characters will be
counted as a single character.

=cut

sub constrainLength {
    my $max = shift;
    my $min = shift;
    my $trim_whitespace = shift || 0;
   
    return sub {
        my $param = shift;

        return 0 unless defined $param;
        
        $param = trimstr(decode($param)) if $trim_whitespace;

        # Remove \r so that newlines will be counted as a single char
        $param =~ s/\r//g;
        
        my $length = Unicode::String->new($param)->length();
        if (defined $max) {
            return 0 unless $length <= $max;
        }
        if (defined $min) {
            return 0 unless $length >= $min;
        }
        return 1;
    };
}

=item constrainBoolean()

This method returns a reference to a subroutine which verifies that 
the string $param is a boolean.

=cut

sub constrainBoolean {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidBoolean(undef, $param));
    };
}

=item constrainNumber()

This method returns a reference to a subroutine which verifies that 
the string $param is numeric.

=cut

sub constrainNumber {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidNumber(undef, $param));
    };
}

=item constrainInteger()

This method returns a reference to a subroutine which verifies that 
the string $param is an integer.

=cut

sub constrainInteger {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidInteger(undef, $param));
    };
}

=item constrainPositiveInteger()

This method returns a reference to a subroutine which verifies that 
the string $param is a positive, non-zero integer.

=cut

sub constrainPositiveInteger {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidPositiveInteger(undef, $param));
    }
}

=item constrainPositiveNumber()

This method returns a reference to a subroutine which verifies that 
the string $param is a positive, non-zero rational number.

=cut

sub constrainPositiveNumber {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidPositiveNumber(undef, $param));
    }
}

=item constrainNonnegativeInteger()

This method returns a reference to a subroutine which verifies that 
the string $param is a non-negative integer.

=cut

sub constrainNonnegativeInteger {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidNonNegativeInteger(undef, $param));
    }
}

=item constrainURL()

Returns a reference to a subroutine which verifies that the string 
$param is a valid url.

=cut

sub constrainURL {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidURL(undef, $param));
    }
}

=item constrainEmail()

Returns a reference to a subroutine which verifies that the string
$param is a well-formed email address.

=cut

sub constrainEmail {
    return sub {
        my $param = shift;
        return (defined $param and Solstice::isValidEmail(undef, $param));
    }
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::List|Solstice::List>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

Version $Revision: 3036 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
