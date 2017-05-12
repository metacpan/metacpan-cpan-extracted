package Rose::DB::Object::MakeMethods::BigNum;

use strict;

use Carp();

our $VERSION = '0.788'; # move up in the file to make CPAN happy

require Math::BigInt;

BIGNUM_VERSION_CHECK:
{
  (my $bignum_version = $Math::BigInt::VERSION) =~ s/_//g;

  if($bignum_version >= 1.78)
  {
    Math::BigInt->import(try => 'GMP');
  }
}

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DB::Object::Constants 
  qw(STATE_LOADING MODIFIED_COLUMNS MODIFIED_NP_COLUMNS SET_COLUMNS STATE_IN_DB);

our $Debug = 0;

sub bigint
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $default   = $args->{'default'};
  my $check_in  = $args->{'check_in'};
  my $min       = $args->{'min'};
  my $max       = $args->{'min'};

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $init_method;

  if(exists $args->{'with_init'} || exists $args->{'init_method'})
  {
    $init_method = $args->{'init_method'} || "init_$name";
  }

  ##
  ## Build code snippets
  ##

  my $qkey = $key;
  $qkey =~ s/'/\\'/g;
  my $qname = $name;
  $qname =~ s/"/\\"/g;

  my $col_name_escaped = $column_name;
  $col_name_escaped =~ s/'/\\'/g;

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my $dont_use_default_code = !$undef_overrides_default ? qq(defined \$self->{'$qkey'}) :
    qq(defined \$self->{'$qkey'} || ) .
    qq((\$self->{STATE_IN_DB()} && !(\$self->{SET_COLUMNS()}{'$col_name_escaped'} || \$self->{'$mod_columns_key'}{'$col_name_escaped'})) || ) .
    qq(\$self->{SET_COLUMNS()}{'$col_name_escaped'} || ) .
    qq(\$self->{'$mod_columns_key'}{'$col_name_escaped'});

  #
  # check_in code
  #

  my $check_in_code = '';
  my %check;

  if($check_in)
  {
    $check_in = [ $check_in ] unless(ref $check_in);

    $check_in_code=<<"EOF";
if(defined \$value)
    {
      my \$found = 0;

      foreach my \$check (\@\$check_in)
      {
        if(\$value == \$check)
        {
          \$found = 1;
          last;
        }
      }

      Carp::croak "Invalid $name: '\$value'"  unless(\$found);
    }
EOF
  }

  #
  # min/max code
  #

  my $min_max_code = '';

  if($min)
  {
    unless($min =~ /^-?\d+$/)
    {
      Carp::croak "Invalid minimum value for bigint column $qname: '$min'";
    }

    $min_max_code =<<"EOF";
no warnings 'uninitialized';
    if(\$value < $min)
    {
      Carp::croak ref(\$self), ": Value \$value for $qname() is too small.  ",
                  "It must be greater than or equal to $min.";
    }
EOF
  }

  if($max)
  {
    unless($max =~ /^-?\d+$/)
    {
      Carp::croak "Invalid maximum value for bigint column $qname: '$max'";
    }

    $min_max_code =<<"EOF";
no warnings 'uninitialized';
    if(\$value < $min)
    {
      Carp::croak ref(\$self), ": Value \$value for $qname() is too large.  ",
                  "It must be less than or equal to $max.";
    }
EOF
  }

  #
  # set code
  #

  my $set_code = qq(\$self->{'$qkey'} = defined \$value ? Math::BigInt->new(\$value) : undef;);

  #
  # column modified code
  #

  my $column_modified_code = 
    qq(\$self->{'$mod_columns_key'}{'$col_name_escaped'} = 1);

  #
  # return code
  #

  my($return_code, $return_code_shift);

  if(defined $default)
  {
    $default = defined $default ? Math::BigInt->new($default) : undef;

      $return_code=<<"EOF";
return ($dont_use_default_code) ? \$self->{'$qkey'} : 
  (scalar($column_modified_code, 
          \$self->{'$qkey'} = \$default));
EOF

  }
  elsif(defined $init_method)
  {
    $return_code=<<"EOF";
return \$self->{'$qkey'}  if(defined \$self->{'$qkey'});
$column_modified_code;
my \$init_value = \$self->$init_method();
return \$self->{'$qkey'} = defined \$init_value ? Math::BigInt->new(\$init_value) : undef;
EOF
  }
  else
  {
    $return_code       = qq(return \$self->{'$qkey'};);
    $return_code_shift = qq(return shift->{'$qkey'};);
  }

  $return_code_shift ||= $return_code;

  my %methods;

  if($interface eq 'get_set')
  {
    my $code;

    # I can't help myself...
    if(defined $default || defined $init_method)
    {
      $code=<<"EOF";
sub
{
  my \$self = shift;

  if(\@_)
  {
    my \$value = shift;

    $check_in_code
    $min_max_code
    $set_code
    $column_modified_code  unless(\$self->{STATE_LOADING()});
    $return_code
  }

  $return_code
};
EOF
    }
    else
    {
      $code=<<"EOF";
sub
{
  if(\@_ > 1)
  {
    my \$self  = shift;
    my \$value = shift;

    $check_in_code
    $min_max_code
    $column_modified_code  unless(\$self->{STATE_LOADING()});
    return $set_code
  }

  $return_code_shift
};
EOF
    }

    my $error;

    TRY:
    {
      local $@;
      $Debug && warn "sub $name = ", $code;
      $methods{$name} = eval $code;
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Error in generated code for method $name - $error\n",
                  "Code was: $code";
    }
  }
  elsif($interface eq 'get')
  {
    my $code;

    # I can't help myself...
    if(defined $default || defined $init_method)
    {
      $code = qq(sub { my \$self = shift; $return_code };);
    }
    else
    {
      $code = qq(sub { shift->{'$qkey'} });
    }

    my $error;

    TRY:
    {
      local $@;
      $Debug && warn "sub $name = ", $code;
      $methods{$name} = eval $code;
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Error in generated code for method $name - $error\n",
                  "Code was: $code";
    }
  }
  elsif($interface eq 'set')
  {
    my $arg_check_code = 
      qq(Carp::croak ref(\$_[0]), ": Missing argument in call to $qname"  unless(\@_ > 1););

    my $code=<<"EOF";
sub
{
  $arg_check_code
  my \$self = shift;
  my \$value = shift;

  $check_in_code
  $min_max_code
  $set_code
  $column_modified_code  unless(\$self->{STATE_LOADING()});
  $return_code
};
EOF

    my $error;

    TRY:
    {
      local $@;
      $Debug && warn "sub $name = ", $code;
      $methods{$name} = eval $code;
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Error in generated code for method $name - $error\n",
                  "Code was: $code";
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::BigNum - Create object methods for arbitrary-precision numeric attributes for Rose::DB::Object-derived objects.

=head1 SYNOPSIS

  package MyDBObject;

  our @ISA = qw(Rose::DB::Object);

  use Rose::DB::Object::MakeMethods::BigNum
  (
    bigint => 
    [
      count => 
      {
        with_init => 1,
        min       => 0,
      },

      # Important: specify very large integer values as strings
      tally => { default => '9223372036854775800' },
    ],
  );

  sub init_count { 12345 }
  ...

  $obj = MyDBObject->new(...);

  print $obj->count; # 12345
  print $obj->tally; # 9223372036854775800

=head1 DESCRIPTION

L<Rose::DB::Object::MakeMethods::BigNum> is a method maker that inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  See the L<Rose::DB::Object> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<bigint>

Create get/set methods for big integer attributes.  Values are stored internally and returned as L<Math::BigInt> objects.  When specifying very large integer values, use strings to be safe.  (See an example in the L<synopsis|/SYNOPSIS> above.)

=over 4

=item Options

=over 4

=item B<check_in ARRAYREF>

A reference to an array of valid values.  When setting the attribute, if the new value is not equal to one of the valid values, a fatal error will occur.

=item B<default VALUE>

Determines the default value of the attribute.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item B<init_method NAME>

The name of the method to call when initializing the value of an undefined attribute.  Defaults to the method name with the prefix C<init_> added.  This option implies C<with_init>.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=item B<max INT>

Get or set the maximum value this attribute is allowed to have.

=item B<min INT>

Get or set the minimum value this attribute is allowed to have.

=item B<with_init BOOL>

Modifies the behavior of the C<get_set> and C<get> interfaces.  If the attribute is undefined, the method specified by the C<init_method> option is called and the attribute is set to the return value of that method.

=back

=item Interfaces

=over 4

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for a big integer object attribute.  When called with an argument, the value of the attribute is set.  The current value of the attribute is returned.

=item B<get>

Creates an accessor method for a big integer object attribute that returns the current value of the attribute.

=item B<set>

Creates a mutator method for a big integer object attribute.  When called with an argument, the value of the attribute is set.  If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::BigNum
    (
      bigint => 
      [
        count => 
        {
          with_init => 1,
          min       => 0,
        },

        # Important: specify very large integer values as strings
        tally => { default => '9223372036854775800' },
      ],
    );

    sub init_count { 12345 }
    ...

    $obj = MyDBObject->new(...);

    print $obj->count; # 12345
    print $obj->tally; # 9223372036854775800

    $obj->count(-1); # Fatal error: minimum value is 0

=back

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
