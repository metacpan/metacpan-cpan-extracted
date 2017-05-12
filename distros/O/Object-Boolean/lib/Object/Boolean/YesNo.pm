package Object::Boolean::YesNo;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'Object::Boolean';

__PACKAGE__->strTrue('Yes');
__PACKAGE__->strFalse('No');

=head1 NAME

Object::Boolean::YesNo - Boolean objects which stringify to "Yes" or "No"

=head1 SYNOPSIS

    use Object::Boolean::YesNo 
        True  => { -as => 'Yes'},  # optional
        False => { -as => 'No' };  # optional

    # The constructor will create a false object with a Perl 
    # false value or the word 'No'.
    my $a = Object::Boolean::YesNo->new(0);
    my $b = Object::Boolean::YesNo->new('No');

    # Anything else will be true :
    my $c = Object::Boolean::YesNo->new(1);
    my $d = Object::Boolean::YesNo->new('hippopotamus');

    # These objects stringify to 'Yes' and 'No'.
    print $a;  # No
    print !$a; # Yes (negating produces another object)
    print $c;  # Yes
    print $d;  # Yes

=head1 DESCRIPTION

Boolean objects that stringify to 'Yes' and 'No', but behave like booleans
in boolean context.  The constants (functions) True and False can be imported 
as Yes and No as shown above.

=head1 SEE ALSO

Object::Boolean

=head1 NOTES

If you are using Class::DBI, and you have columns which represent booleans
as enum('Yes','No'), then doing this :

    __PACKAGE__->has_a(column_name => 'Object::Boolean::YesNo')

will make column_name inflate and deflate into Object::Boolean::YesNo objects.

=cut

1;

