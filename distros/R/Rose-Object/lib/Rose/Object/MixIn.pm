package Rose::Object::MixIn;

use strict;

use Carp;

our $Debug = 0;

our $VERSION = '0.856';

use Rose::Class::MakeMethods::Set
(
  inheritable_set => 
  [
    '_export_tag' =>
    {
      list_method    => '_export_tags',
      clear_method   => 'clear_export_tags',
      add_method     => '_add_export_tag',
      delete_method  => 'delete_export_tag',
      deletes_method => 'delete_export_tags',
    },

    '_pre_import_hook',
    {
      clear_method   => 'clear_pre_import_hooks',
      add_method     => 'add_pre_import_hook',
      adds_method    => 'add_pre_import_hooks',
      delete_method  => 'delete_pre_import_hook',
      deletes_method => 'delete_pre_import_hooks',    
    },
  ],
);

sub import
{
  my($class) = shift;

  my $target_class = (caller)[0];

  my($force, @methods, %import_as);

  foreach my $arg (@_)
  {
    if(!defined $target_class && $arg !~ /^-/)
    {
      $target_class = $arg;
      next;
    }

    if($arg =~ /^-?-force$/)
    {
      $force = 1;
    }
    elsif($arg =~ /^-?-target[-_]class$/)
    {
      $target_class = undef; # set on next iteration...lame
      next;
    }
    elsif($arg =~ /^:(.+)/)
    {
      my $methods = $class->export_tag($1) or
        croak "Unknown export tag - '$arg'";

      push(@methods, @$methods);
    }
    elsif(ref $arg eq 'HASH')
    {
      while(my($method, $name) = each(%$arg))
      {
        push(@methods, $method);
        $import_as{$method} = $name;
      }
    }
    else
    {
      push(@methods, $arg);
    }
  }

  foreach my $method (@methods)
  {
    my $code = $class->can($method) or 
      croak "Could not import method '$method' from $class - no such method";

    my $import_as = $import_as{$method} || $method;

    if($target_class->can($import_as) && !$force)
    {
      croak "Could not import method '$import_as' from $class into ",
            "$target_class - a method by that name already exists. ",
            "Pass a '-force' argument to import() to override ",
            "existing methods."
    }

    if(my $hooks = $class->pre_import_hooks($method))
    {
      foreach my $code (@$hooks)
      {
        my $error;

        TRY:
        {
          local $@;
          eval { $code->($class, $method, $target_class, $import_as) };
          $error = $@;
        }

        if($error)
        {
          croak "Could not import method '$import_as' from $class into ",
                "$target_class - $error";
        }
      }
    }

    no strict 'refs';      
    $Debug && warn "${target_class}::$import_as = ${class}->$method\n";
    *{$target_class . '::' . $import_as} = $code;
  }
}

sub export_tag
{
  my($class, $tag) = (shift, shift);

  if(index($tag, ':') == 0)
  {
    croak 'Tag name arguments to export_tag() should not begin with ":"';
  }

  if(@_ && !$class->_export_tag_value($tag))
  {
    $class->_add_export_tag($tag);
  }

  if(@_ && (@_ > 1 || (ref $_[0] || '') ne 'ARRAY'))
  {
    croak 'export_tag() expects either a single tag name argument, ',
          'or a tag name and a reference to an array of method names';
  }

  my $ret = $class->_export_tag_value($tag, @_);

  croak "No such tag: $tag"  unless($ret);

  return wantarray ? @$ret : $ret;
}

sub export_tags
{
  my($class) = shift;
  return $class->_export_tags  unless(@_);
  $class->clear_export_tags;
  $class->add_export_tags(@_);
}

sub add_export_tags
{
  my($class) = shift;

  while(@_)
  {
    my($tag, $arg) = (shift, shift);
    $class->export_tag($tag, $arg);
  }
}

sub pre_import_hook
{
  my($class, $method) = (shift, shift);

  if(@_ && !$class->_pre_import_hook_value($method))
  {
    $class->add_pre_import_hook($method);
  }

  if(@_ && (@_ > 1 || (ref $_[0] && (ref $_[0] || '') !~ /\A(?:ARRAY|CODE)\z/)))
  {
    croak 'pre_import_hook() expects either a single method name argument, ',
          'or a method name and a code reference or a reference to an array ',
          'of code references';
  }

  if(@_)
  {
    unless(ref $_[0] eq 'ARRAY')
    {
      $_[0] = [ $_[0] ];
    }
  }

  my $ret = $class->_pre_import_hook_value($method, @_) || [];

  return wantarray ? @$ret : $ret;
}

sub pre_import_hooks { shift->pre_import_hook(shift) }

1;

__END__

=head1 NAME

Rose::Object::MixIn - A base class for mix-ins.

=head1 SYNOPSIS

  package MyMixInClass;

  use Rose::Object::MixIn(); # Use empty parentheses here
  our @ISA = qw(Rose::Object::MixIn);

  __PACKAGE__->export_tag(all => [ qw(my_cool_method my_other_method) ]);

  sub my_cool_method  { ... }
  sub my_other_method { ... }
  ...

  package MyClass;
  # Import methods my_cool_method() and my_other_method()
  use MyMixInClass qw(:all);
  ...

  package MyOtherClass;  
  # Import just my_cool_method()
  use MyMixInClass qw(my_cool_method);
  ...

  package YetAnotherClass;
  # Import just my_cool_method() as cool()
  use MyMixInClass { my_cool_method => 'cool' }

=head1 DESCRIPTION

L<Rose::Object::MixIn> is a base class for mix-ins.  A mix-in is a class that exports methods into another class.  This export process is controlled with an L<Exporter>-like interface, but L<Rose::Object::MixIn> does not inherit from L<Exporter>.

When you L<use|perlfunc/use> a L<Rose::Object::MixIn>-derived class, its L<import|/import> method is called at compile time.  In other words, this:

    use Rose::Object::MixIn 'a', 'b', { c => 'd' };

is the same thing as this:

    BEGIN { Rose::Object::MixIn->import('a', 'b', { c => 'd' }) }

To prevent the L<import|/import> method from being run, put empty parentheses "()" after the package name instead of a list of arguments.

    use Rose::Object::MixIn();

See the L<synopsis|/SYNOPSIS> for an example of when this is handy: using L<Rose::Object::MixIn> from within a subclass.  Note that the empty parenthesis are important.  The following is I<not> equivalent:

    # This is not the same thing as the example above!
    use Rose::Object::MixIn;

See the documentation for the L<import|/import> method below to learn what arguments it accepts.

=head1 CLASS METHODS

=over 4

=item B<import ARGS>

Import the methods specified by ARGS into the package from which this method was called.  If the current class L<can|perlfunc/can> already perform one of these methods, a fatal error will occur.  To override an existing method, you must use the C<-force> argument (see below).

Valid formats for ARGS are as follows:

=over 4

=item * B<A method name>

Literal method names will be imported as-is.

=item * B<A tag name>

Tags names are indicated with a leading colon.  For example, ":all" specifies the "all" tag.  A tag is a stand-in for a list of methods.  See the L<export_tag|/export_tag> method to learn how to create tags.

=item * B<A reference to a hash>

Each key/value pair in this hash contains a method name and the name that it will be imported as.  Use this feature to import methods under different names in order to avoid conflicts with existing methods.

=item * C<-force>

The special literal argument C<-force> will cause the specified methods to be imported even if the calling class L<can|perlfunc/can> already perform one or more of those methods.

=item * C<-target_class CLASS>

The special literal argument C<-target-class> followed by a class name will cause the specified methods to be imported into CLASS rather than into the calling class.

=back

See the L<synopsis|/SYNOPSIS> for several examples of the L<import|/import> method in action.  (Remember, it's called implicitly when you L<use|perlfunc/use> a L<Rose::Object::MixIn>-derived class with anything other than an empty set of parenthesis "()" as an argument.)

=item B<clear_export_tags>

Delete the entire list of L<export tags|/export_tags>.

=item B<export_tag NAME [, ARRAYREF]>

Get or set the list of method names associated with a tag.  The tag name should I<not> begin with a colon.  If ARRAYREF is passed, then the list of methods associated with the specific tag is set.

Returns a list (in list context) or a reference to an array (in scalar context) of method names.  The array reference return value should be treated as read-only.  If no such tag exists, and if an ARRAYREF is not passed, then a fatal error will occur.

=item B<export_tags>

Returns a list (in list context) and a reference to an array (in scalar context) containing the complete list of export tags.  The array reference return value should be treated as read-only.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
