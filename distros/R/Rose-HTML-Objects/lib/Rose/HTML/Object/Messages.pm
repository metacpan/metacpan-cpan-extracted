package Rose::HTML::Object::Messages;

use strict;

use Carp;

use base 'Rose::HTML::Object::Exporter';

our $VERSION = '0.618';

our $Debug = 0;

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    '_message_names',
    'message_id_to_name_map',
    'message_name_to_id_map',
  ],
);

BEGIN
{
  __PACKAGE__->_message_names([]);
  __PACKAGE__->message_id_to_name_map({});
  __PACKAGE__->message_name_to_id_map({});
}

sub init_export_tags
{
  my($class) = shift;

  my $list = $class->message_names;

  $class->export_tags
  (
    all    => $list,
    field  => [ grep { /^FIELD_/ } @$list ],
    form   => [ grep { /^FORM_/ } @$list ],
    date   => [ grep { /^DATE_|_(?:YEAR|MONTH|DAY)$/ } @$list ],
    time   => [ grep { /^TIME_|_(?:HOUR|MINUTE|SECOND)$/ } @$list ],
    email  => [ grep { /^EMAIL_/ } @$list ],
    phone  => [ grep { /^PHONE_/ } @$list ],
    number => [ grep { /^NUM_/ } @$list ],
    set    => [ grep { /^SET_/ } @$list ],
    string => [ grep { /^STRING_/ } @$list ],
  );
}

sub import
{
  my($class) = shift;

  $class->use_private_messages;
  $class->init_export_tags;

  if($Rose::HTML::Object::Exporter::Target_Class)
  {
    $class->SUPER::import(@_);
  }
  else
  {
    local $Rose::HTML::Object::Exporter::Target_Class = (caller)[0];
    $class->SUPER::import(@_);
  }
}

our %Private;

sub use_private_messages
{
  my($class) = shift;

  unless($Private{$class})
  {
    $Private{$class} = 1;

    # Make private copies of inherited data structures 
    # (shallow copy is sufficient)
    $class->message_names([ $class->message_names ]);
    $class->message_id_to_name_map({ %{$class->message_id_to_name_map} });
    $class->message_name_to_id_map({ %{$class->message_name_to_id_map} });
  }
}

sub message_id_exists   { defined $_[0]->message_id_to_name_map->{$_[1]} }
sub message_name_exists { defined $_[0]->message_name_to_id_map->{$_[1]} }

sub message_names
{
  my($class) = shift;

  $class->_message_names(@_)  if(@_);

  wantarray ? @{$class->_message_names} :
              $class->_message_names;
}

sub get_message_id
{
  my($class, $symbol) = @_;
  no strict 'refs';
  my $const = "${class}::$symbol";
  return &$const  if(defined &$const);
  return undef;
}

sub message_ids
{
  my($class) = shift;
  my $map = $class->message_id_to_name_map;

  return wantarray ? 
    (sort { $a <=> $b } keys %$map) : 
    [ sort { $a <=> $b } keys %$map ];
}

sub get_message_name 
{
  no warnings 'uninitialized';
  return $_[0]->message_id_to_name_map->{$_[1]};
}

sub add_message
{
  my($class, $name, $id) = @_;

  $class->use_private_messages;

  unless($class->imported($name))
  {
    if(exists $class->message_name_to_id_map->{$name} && 
       $class->message_name_to_id_map->{$name} != $id)
    {
      croak "Could not add message '$name' - a message with that name already exists ",
            '(', $class->message_name_to_id_map->{$name}, ')';
    }

    if(exists $class->message_id_to_name_map->{$id} &&
       $class->message_id_to_name_map->{$id} ne $name)
    {
      croak "Could not add message '$name' - a message with the id $id already exists ",
            '(', $class->message_id_to_name_map->{$id}, ')';
    }
  }

  MAKE_CONSTANT:
  {
    no strict 'refs';
    my $const = "${class}::$name";
    unless($class->can($name) || defined &$const)
    {
      *{"${class}::$name"} = sub() { $id };

      #my $error;
      #
      #TRY:
      #{
      #  local $@;
      #  eval "package $class; use constant $name => $id;";
      #  $error = $@;
      #}
      #
      #croak "Could not create constant '$name' in $class - $error"  if($error);
    }
  }

  unless(exists $class->message_name_to_id_map->{$name})
  {
    push(@{$class->_message_names}, $name);
  }

  $class->message_id_to_name_map->{$id}   = $name;
  $class->message_name_to_id_map->{$name} = $id;

  return;
}

sub add_messages
{
  my($class) = shift;

  $class->use_private_messages;

  no strict 'refs';

  if(@_)
  {
    foreach my $name (@_)
    {
      $class->add_message($name, "${class}::$name"->());
    }
  }
  else
  {
    foreach my $name (keys %{"${class}::"})
    {
      my $fq_name = "${class}::$name";

      next  unless(defined *{$fq_name}{'CODE'} && $name =~ /^[A-Z0-9_]+$/);

      my $code = $class->can($name);

      # Skip it if it's not a constant
      next  unless(defined prototype($code) && !length(prototype($code)));

      # Should not need this check?
      next  if($name =~ /^(BEGIN|DESTROY|AUTOLOAD|TIE.*)$/);

      $Debug && warn "$class ADD $name = ", $code->(), "\n";
      $class->add_message($name, $code->());
    }
  }
}

#
# Messages
#

use constant CUSTOM_MESSAGE => -1;

# Fields and labels
use constant FIELD_LABEL              => 1;
use constant FIELD_DESCRIPTION        => 2;
use constant FIELD_REQUIRED_GENERIC   => 4;
use constant FIELD_REQUIRED_LABELLED  => 5;
use constant FIELD_REQUIRED_SUBFIELD  => 6;
use constant FIELD_REQUIRED_SUBFIELDS => 7;
use constant FIELD_PARTIAL_VALUE      => 8;
use constant FIELD_INVALID_GENERIC    => 10;
use constant FIELD_INVALID_LABELLED   => 11;

use constant FIELD_LABEL_YEAR   => 10_000;
use constant FIELD_LABEL_MONTH  => 10_001;
use constant FIELD_LABEL_DAY    => 10_002;
use constant FIELD_LABEL_HOUR   => 10_003;
use constant FIELD_LABEL_MINUTE => 10_004;
use constant FIELD_LABEL_SECOND => 10_005;

use constant FIELD_ERROR_LABEL_YEAR   => 11_000;
use constant FIELD_ERROR_LABEL_MONTH  => 11_001;
use constant FIELD_ERROR_LABEL_DAY    => 11_002;
use constant FIELD_ERROR_LABEL_HOUR   => 11_003;
use constant FIELD_ERROR_LABEL_MINUTE => 11_004;
use constant FIELD_ERROR_LABEL_SECOND => 11_005;

use constant FIELD_ERROR_LABEL_MINIMUM_DATE => 11_006;
use constant FIELD_ERROR_LABEL_MAXIMUM_DATE => 11_007;

# Forms
use constant FORM_HAS_ERRORS => 100;

# Numerical messages
use constant NUM_INVALID_INTEGER          => 1300;
use constant NUM_INVALID_INTEGER_POSITIVE => 1301;
use constant NUM_NOT_POSITIVE_INTEGER     => 1302;
use constant NUM_BELOW_MIN                => 1303;
use constant NUM_ABOVE_MAX                => 1304;
use constant NUM_INVALID_NUMBER           => 1305;
use constant NUM_INVALID_NUMBER_POSITIVE  => 1306;
use constant NUM_NOT_POSITIVE_NUMBER      => 1307;

# String messages
use constant STRING_OVERFLOW => 1400;

# Date messages
use constant DATE_INVALID              => 1500;
use constant DATE_MIN_GREATER_THAN_MAX => 1501;

# Time messages
use constant TIME_INVALID         => 1550;
use constant TIME_INVALID_HOUR    => 1551;
use constant TIME_INVALID_MINUTE  => 1552;
use constant TIME_INVALID_SECONDS => 1553;
use constant TIME_INVALID_AMPM    => 1554;

# Email messages
use constant EMAIL_INVALID => 1600;

# Phone messages
use constant PHONE_INVALID => 1650;

# Set messages
use constant SET_INVALID_QUOTED_STRING => 1700;
use constant SET_PARSE_ERROR           => 1701;

BEGIN { __PACKAGE__->add_messages }

1;

__END__

=head1 NAME

Rose::HTML::Object::Messages - Message ids and named constants for use with HTML objects.

=head1 SYNOPSIS

  package My::HTML::Object::Messages;

  use strict;

  # Import the standard set of message ids
  use Rose::HTML::Object::Messages qw(:all);
  use base qw(Rose::HTML::Object::Messages);

  ##
  ## Define your new message ids below
  ##

  # Message ids from 0 to 29,999 are reserved for built-in messages.
  # Negative message ids are reserved for internal use.  Please use
  # message ids 30,000 or higher for your messages.  Suggested message
  # id ranges and naming conventions for various message types are
  # shown below.

  # Field labels

  use constant FIELD_LABEL_LOGIN_NAME         => 100_000;
  use constant FIELD_LABEL_PASSWORD           => 100_001;
  ...

  # Field error messages

  use constant FIELD_ERROR_PASSWORD_TOO_SHORT => 101_000;
  use constant FIELD_ERROR_USERNAME_INVALID   => 101_001;
  ...

  # Generic messages

  use constant LOGIN_NO_SUCH_USER             => 200_000;
  use constant LOGIN_USER_EXISTS_ERROR        => 200_001;
  ...

  # This line must be below all the "use constant ..." declarations
  BEGIN { __PACKAGE__->add_messages }

  1;

=head1 DESCRIPTION

L<Rose::HTML::Object::Messages> stores message ids and names.  The message ids are defined as Perl L<constants|constant> with integer values.  The constants themselves as well as the mapping between the symbolic constant names and their values are stored as class data.

If you merely want to import one of the standard message id constants, you may use this module as-is (see the L<EXPORTS|/EXPORTS> section for details).  If you want to define your own messages, you must subclass this module exactly as shown in the synopsis.  The order of the statements is important!

When adding your own messages, you are free to choose any integer message id values, subject to the following constraints:

=over 4

=item * Message ids from 0 to 29,999 are reserved for built-in messages.

=item * Negative message ids are reserved for internal use.

=back

Please use ids 30,000 or higher for your messages.  Constant names may contain only the characters C<[A-Z0-9_]> and must be unique among all message constant names.

=head1 EXPORTS

L<Rose::HTML::Object::Messages> does not export any symbols by default.

The 'all' tag:

    use Rose::HTML::Object::Messages qw(:all);

will cause all message name constant to be imported.

The following tags will cause all messages whose names match the regular expression to the right of the tag name to be imported.

    TAG       NAME REGEX
    -----     -----------------
    field     ^FIELD_
    form      ^FORM_
    date      ^DATE_|_(?:YEAR|MONTH|DAY)$
    time      ^TIME_|_(?:HOUR|MINUTE|SECOND)$
    email     ^EMAIL_
    phone     ^PHONE_
    number    ^NUM_
    set       ^SET_
    string    ^STRING_

For example, this will import all the message constants whose names begin with "FIELD_"

    use Rose::HTML::Object::Messages qw(:field);

Finally, you can import individual message constant names as well:

    use Rose::HTML::Object::Messages qw(FIELD_LABEL_YEAR TIME_INVALID);

A complete listing of the default set of message constant names appears in the next section.

=head1 BUILT-IN MESSAGES

The list of built-in messages constant names appears below.  You should not rely on the actual numeric values of these constants.  Import and refer to them only by their symbolic names.

    FIELD_LABEL
    FIELD_DESCRIPTION
    FIELD_REQUIRED_GENERIC
    FIELD_REQUIRED_LABELLED
    FIELD_REQUIRED_SUBFIELD
    FIELD_REQUIRED_SUBFIELDS
    FIELD_PARTIAL_VALUE
    FIELD_INVALID_GENERIC
    FIELD_INVALID_LABELLED

    FIELD_LABEL_YEAR
    FIELD_LABEL_MONTH
    FIELD_LABEL_DAY
    FIELD_LABEL_HOUR
    FIELD_LABEL_MINUTE
    FIELD_LABEL_SECOND

    FIELD_ERROR_LABEL_YEAR
    FIELD_ERROR_LABEL_MONTH
    FIELD_ERROR_LABEL_DAY
    FIELD_ERROR_LABEL_HOUR
    FIELD_ERROR_LABEL_MINUTE
    FIELD_ERROR_LABEL_SECOND

    FIELD_ERROR_LABEL_MINIMUM_DATE
    FIELD_ERROR_LABEL_MAXIMUM_DATE

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

=item B<add_message NAME, ID>

Add a new message constant with NAME and an integer ID value.  Message ids from 0 to 29,999 are reserved for built-in messages.  Negative message ids are reserved for internal use.  Please use message ids 30,000 or higher for your messages.  Constant names may contain only the characters C<[A-Z0-9_]> and must be unique among all message names.

=item B<add_messages [NAME1, NAME2, ...]>

If called with no arguments, this method L<adds|/add_message> all message L<constants|constant> defined in the calling class.  Example:

    __PACKAGE__->add_messages;

If called with a list of constant names, add each named constant to the list of messages.  These L<constants|constant> must already exist in the calling class.  Example:

    use constant MY_MESSAGE1 => 123456;
    use constant MY_MESSAGE2 => 123457;
    ...
    __PACKAGE__->add_messages('MY_MESSAGE1', 'MY_MESSAGE2');

=item B<get_message_id NAME>

Returns the integer message id corresponding to the symbolic constant NAME, or undef if no such name exists.

=item B<get_message_name ID>

Returns the symbolic message constant name corresponding to the integer message ID, or undef if no such message ID exists.

=item B<message_id_exists ID>

Return true if the integer message ID exists, false otherwise.

=item B<message_name_exists NAME>

Return true if the symbolic message constant NAME exists, false otherwise.

=item B<message_ids>

Returns a list (in list context) or reference to an array (in scalar context) of integer message ids.

=item B<message_names>

Returns a list (in list context) or reference to an array (in scalar context) of message names.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
