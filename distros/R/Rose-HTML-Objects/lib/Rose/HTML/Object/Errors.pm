package Rose::HTML::Object::Errors;

use strict;

use Carp;

use base 'Rose::HTML::Object::Messages';

our $VERSION = '0.600';

BEGIN
{
  __PACKAGE__->message_names([]);
  __PACKAGE__->message_id_to_name_map({});
  __PACKAGE__->message_name_to_id_map({});
}

BEGIN
{
  *error_ids = \&Rose::HTML::Object::Messages::message_ids;
  *error_id_exists   = \&Rose::HTML::Object::Messages::message_id_exists;
  *error_name_exists = \&Rose::HTML::Object::Messages::message_name_exists;

  *get_error_id   = \&Rose::HTML::Object::Messages::get_message_id;
  *get_error_name = \&Rose::HTML::Object::Messages::get_message_name;

  *add_error    = \&Rose::HTML::Object::Messages::add_message;
  *add_errors   = \&Rose::HTML::Object::Messages::add_messages;
  *get_error_id = \&Rose::HTML::Object::Messages::get_message_id;

  *add_error  = \&Rose::HTML::Object::Messages::add_message;
  *add_errors = \&Rose::HTML::Object::Messages::add_messages;

  *error_names = \&Rose::HTML::Object::Messages::message_names;
}

sub init_export_tags
{
  my($class) = shift;

  my $list = $class->error_names;

  $class->export_tags
  (
    all    => $list,
    field  => [ grep { /^FIELD_/ } @$list ],
    form   => [ grep { /^FORM_/ } @$list ],
    date   => [ grep { /^DATE_/ } @$list ],
    time   => [ grep { /^TIME_/ } @$list ],
    email  => [ grep { /^EMAIL_/ } @$list ],
    phone  => [ grep { /^PHONE_/ } @$list ],
    number => [ grep { /^NUM_/ } @$list ],
    set    => [ grep { /^SET_/ } @$list ],
    string => [ grep { /^STRING_/ } @$list ],
  );
}

#
# Errors
#

use constant CUSTOM_ERROR => -1;

# Field errors
use constant FIELD_REQUIRED      => 3;
use constant FIELD_PARTIAL_VALUE => 8;
use constant FIELD_INVALID       => 9;

# Form errors
use constant FORM_HAS_ERRORS => 100;

# Numerical errors
use constant NUM_INVALID_INTEGER          => 1300;
use constant NUM_INVALID_INTEGER_POSITIVE => 1301;
use constant NUM_NOT_POSITIVE_INTEGER     => 1302;
use constant NUM_BELOW_MIN                => 1303;
use constant NUM_ABOVE_MAX                => 1304;
use constant NUM_INVALID_NUMBER           => 1305;
use constant NUM_INVALID_NUMBER_POSITIVE  => 1306;
use constant NUM_NOT_POSITIVE_NUMBER      => 1307;


# String errors
use constant STRING_OVERFLOW => 1400;

# Date errors
use constant DATE_INVALID              => 1500;
use constant DATE_MIN_GREATER_THAN_MAX => 1501;

# Time errors
use constant TIME_INVALID         => 1550;
use constant TIME_INVALID_HOUR    => 1551;
use constant TIME_INVALID_MINUTE  => 1552;
use constant TIME_INVALID_SECONDS => 1553;
use constant TIME_INVALID_AMPM    => 1554;

# Email errors
use constant EMAIL_INVALID => 1600;

# Phone errors
use constant PHONE_INVALID => 1650;

# Set errors
use constant SET_INVALID_QUOTED_STRING => 1700;
use constant SET_PARSE_ERROR           => 1701;

BEGIN { __PACKAGE__->add_errors }

1;

__END__

=head1 NAME

Rose::HTML::Object::Errors - Error ids and named constants for use with HTML objects.

=head1 SYNOPSIS

  package My::HTML::Object::Errors;

  use strict;

  # Import the standard set of error ids
  use Rose::HTML::Object::Errors qw(:all);
  use base qw(Rose::HTML::Object::Errors);

  ##
  ## Define your new error ids below
  ##

  # Error ids from 0 to 29,999 are reserved for built-in errors. 
  # Negative error ids are reserved for internal use.  Please use error
  # ids 30,000 or higher for your errors.  Suggested error id ranges
  # and naming conventions for various error types are shown below.

  # Field errors

  use constant FIELD_ERROR_PASSWORD_TOO_SHORT => 101_000;
  use constant FIELD_ERROR_USERNAME_INVALID   => 101_001;
  ...

  # Generic errors

  use constant LOGIN_NO_SUCH_USER             => 200_000;
  use constant LOGIN_USER_EXISTS_ERROR        => 200_001;
  ...

  # This line must be below all the "use constant ..." declarations
  BEGIN { __PACKAGE__->add_errors }

  1;

=head1 DESCRIPTION

L<Rose::HTML::Object::Errors> stores error ids and names.  The error ids are defined as Perl L<constants|constant> with integer values.  The constants themselves as well as the mapping between the symbolic constant names and their values are stored as class data.

If you merely want to import one of the standard error id constants, you may use this module as-is (see the L<EXPORTS|/EXPORTS> section for details).  If you want to define your own errors, you must subclass this module exactly as shown in the synopsis.  The order of the statements is important!

When adding your own errors, you are free to choose any integer error id values, subject to the following constraints.

=over 4

=item * Error ids from 0 to 29,999 are reserved for built-in errors.

=item * Negative error ids are reserved for internal use.

=back

Please use ids 30,000 or higher for your errors.  Constant names may contain only the characters C<[A-Z0-9_]> and must be unique among all error constant names.

=head1 EXPORTS

L<Rose::HTML::Object::Errors> does not export any symbols by default.

The 'all' tag:

    use Rose::HTML::Object::Errors qw(:all);

will cause all error name constant to be imported.

The following tags will cause all errors whose names match the regular expression to the right of the tag name to be imported.

    TAG       NAME REGEX
    -----     ----------
    field     ^FIELD_
    form      ^FORM_
    date      ^DATE_
    time      ^TIME_
    email     ^EMAIL_
    phone     ^PHONE_
    number    ^NUM_
    set       ^SET_
    string    ^STRING_

For example, this will import all the error constants whose names begin with "FIELD_"

    use Rose::HTML::Object::Errors qw(:field);

Finally, you can import individual error constant names as well:

    use Rose::HTML::Object::Errors qw(FIELD_REQUIRED NUM_INVALID_INTEGER);

A complete listing of the default set of error constant names appears in the next section.

=head1 BUILT-IN ERRORS

The list of built-in errors appears below.  You should not rely on the actual numeric values of these constants.  Import and refer to them only by their symbolic names.

    FIELD_REQUIRED
    FIELD_PARTIAL_VALUE
    FIELD_INVALID

    FORM_HAS_ERRORS

    NUM_INVALID_INTEGER
    NUM_INVALID_INTEGER_POSITIVE
    NUM_NOT_POSITIVE_INTEGER
    NUM_BELOW_MIN
    NUM_ABOVE_MAX
    NUM_INVALID_NUMBER
    NUM_INVALID_NUMBER_POSITIVE
    NUM_NOT_POSITIVE_NUMBER

    STRING_OVERFLOW

    DATE_INVALID
    DATE_MIN_GREATER_THAN_MAX

    TIME_INVALID
    TIME_INVALID_HOUR
    TIME_INVALID_MINUTE
    TIME_INVALID_SECONDS
    TIME_INVALID_AMPM

    EMAIL_INVALID

    PHONE_INVALID

    SET_INVALID_QUOTED_STRING
    SET_PARSE_ERROR

=head1 CLASS METHODS

=over 4

=item B<add_error NAME, ID>

Add a new error constant with NAME and an integer ID value.  Error ids from 0 to 29,999 are reserved for built-in errors.  Negative error ids are reserved for internal use.  Please use error ids 30,000 or higher for your errors.  Constant names may contain only the characters C<[A-Z0-9_]> and must be unique among all error names.

=item B<add_errors [NAME1, NAME2, ...]>

If called with no arguments, this method L<adds|/add_error> all error L<constants|constant> defined in the calling class.  Example:

    __PACKAGE__->add_errors;

If called with a list of constant names, add each named constant to the list of errors.  These L<constants|constant> must already exist in the calling class.  Example:

    use constant MY_ERROR1 => 123456;
    use constant MY_ERROR2 => 123457;
    ...
    __PACKAGE__->add_errors('MY_ERROR1', 'MY_ERROR2');

=item B<get_error_id NAME>

Returns the integer error id corresponding to the symbolic constant NAME, or undef if no such name exists.

=item B<get_error_name ID>

Returns the symbolic error constant name corresponding to the integer error ID, or undef if no such error ID exists.

=item B<error_id_exists ID>

Return true of the integer error ID exists, false otherwise.

=item B<error_name_exists NAME>

Return true of the symbolic error constant NAME exists, false otherwise.

=item B<error_ids>

Returns a list (in list context) or reference to an array (in scalar context) of integer error ids.

=item B<error_names>

Returns a list (in list context) or reference to an array (in scalar context) of error names.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
