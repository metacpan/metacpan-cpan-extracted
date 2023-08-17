package Rose::HTML::Objects;

use strict;

use Carp;
use File::Spec();
use File::Path();
use File::Basename();

our $VERSION = '0.626';

our $Debug = 0;

sub make_private_library
{
  my($class) = shift;

  my %args = @_;

  my($packages, $perl) = 
    Rose::HTML::Objects->private_library_perl(@_);

  my $debug = exists $args{'debug'} ? $args{'debug'} : $Debug;

  if($args{'in_memory'})
  {
    foreach my $pkg (@$packages)
    {
      my $code = $perl->{$pkg};
      $debug > 2 && warn $code, "\n";

      my $error;

      TRY:
      {
        local $@;
        eval $code;
        $error = $@;
      }

      die "Could not eval $pkg - $error"  if($error);
    }
  }
  else
  {
    my $dir = $args{'modules_dir'} or croak "Missing modules_dir parameter";    
    mkdir($dir)  unless(-d $dir);
    croak "Could not create modules_dir '$dir' - $!"  unless(-d $dir);

    foreach my $pkg (@$packages)
    {
      my @file_parts = split('::', $pkg);
      $file_parts[-1] .= '.pm';
      my $file = File::Spec->catfile($dir, @file_parts);

      my $file_dir = File::Basename::dirname($file);

      File::Path::mkpath($file_dir); # spews errors to STDERR
      croak "Could not make directory '$file_dir'"  unless(-d $file_dir);

      if(-e $file && !$args{'overwrite'})
      {
        $debug && warn "Refusing to overwrite '$file'";
        next;
      }

      open(my $fh, '>', $file) or croak "Could not create '$file' - $!";
      print $fh $perl->{$pkg};
      close($fh) or croak "Could not write '$file' - $!";

      $debug > 2 && warn $perl->{$pkg}, "\n";
    }
  }

  return wantarray ? @$packages : $packages;
}

sub private_library_perl
{
  my($class, %args) = @_;

  my $rename = $args{'rename'};
  my $prefix = $args{'prefix'};
  my $trim_prefix = $args{'trim_prefix'} || 'Rose::';
  my $in_memory = $args{'in_memory'} || 0;

  my $prefix_regex = qr(^$trim_prefix);

  $rename ||= sub 
  {
    my($name) = shift;
    $name =~ s/$prefix_regex/$prefix/;
    return $name;
  };

  my $save_rename = $rename;

  $rename = sub
  {
    my $name = shift;
    local $_ = $name;
    my $new_name = $save_rename->($name);

    if($_ ne $name && (!$new_name || $new_name == 1))
    {
      return $_;
    }

    return $new_name;
  };

  my $class_filter = $args{'class_filter'};

  my(%perl, %isa, @packages);

  require Rose::HTML::Object;

  my $base_object_type = Rose::HTML::Object->object_type_classes;
  my %base_type_object = reverse %$base_object_type;

  my %object_type;

  my $max_type_len = 0;

  while(my($type, $base_class) = each(%$base_object_type))
  {
    $object_type{$type} = $rename->($base_class);
    $max_type_len = length($type)  if(length($type) > $max_type_len);
  }

  my $object_map_perl =<<"EOF";
__PACKAGE__->object_type_classes
(
EOF

  foreach my $type (sort keys %object_type)
  {
    my $class = $object_type{$type};
    $object_map_perl .= sprintf("  %-*s => '$class',\n", $max_type_len + 2, qq('$type'));
  }

  $object_map_perl .=<<"EOF";
);
EOF

  my $object_package    = $rename->('Rose::HTML::Object');
  my $message_package   = $rename->('Rose::HTML::Object::Message::Localized');
  my $messages_package  = $rename->('Rose::HTML::Object::Messages');
  my $error_package     = $rename->('Rose::HTML::Object::Error');
  my $errors_package    = $rename->('Rose::HTML::Object::Errors');
  my $localizer_package = $rename->('Rose::HTML::Object::Message::Localizer');
  my $custom_package    = $rename->('Rose::HTML::Object::Custom');

  my $load_message_and_errors_perl = '';

  unless($in_memory)
  {
    $load_message_and_errors_perl=<<"EOF";
use $error_package;
use $errors_package();
use $message_package;
use $messages_package();
EOF
  }

  my $std_messages=<<"EOF";
# Import the standard set of message ids
use Rose::HTML::Object::Messages qw(:all);
EOF

  my $std_errors=<<"EOF";
# Import the standard set of error ids
use Rose::HTML::Object::Errors qw(:all);
EOF

  my %code =
  (
    $message_package =><<"EOF",
sub generic_object_class { '$object_package' }
EOF

    $messages_package =>
    {
      filter => sub
      {
        s/^(use base.+)/$std_messages$1/m;
      },

      code =><<"EOF",
##
## Define your new message ids below
##

# Message ids from 0 to 29,999 are reserved for built-in messages.  Negative
# message ids are reserved for internal use.  Please use message ids 30,000
# or higher for your messages.  Suggested message id ranges and naming
# conventions for various message types are shown below.

# Field labels

#use constant FIELD_LABEL_LOGIN_NAME         => 100_000;
#use constant FIELD_LABEL_PASSWORD           => 100_001;
#...

# Field error messages

#use constant FIELD_ERROR_PASSWORD_TOO_SHORT => 101_000;
#use constant FIELD_ERROR_USERNAME_INVALID   => 101_001;
#...

# Generic messages

#use constant LOGIN_NO_SUCH_USER             => 200_000;
#use constant LOGIN_USER_EXISTS_ERROR        => 200_001;
#...

### %CODE% ###

# This line must be below all the "use constant ..." declarations
BEGIN { __PACKAGE__->add_messages }
EOF
    },

    $error_package =><<"EOF",
sub generic_object_class { '$object_package' }
EOF

    $errors_package =>
    {
      filter => sub
      {
        s/^(use base.+)/$std_errors$1/m;
      },

      code =><<"EOF",
##
## Define your new error ids below
##

# Error ids from 0 to 29,999 are reserved for built-in errors.  Negative
# error ids are reserved for internal use.  Please use error ids 30,000
# or higher for your errors.  Suggested error id ranges and naming
# conventions for various error types are shown below.

# Field errors

#use constant FIELD_ERROR_PASSWORD_TOO_SHORT => 101_000;
#use constant FIELD_ERROR_USERNAME_INVALID   => 101_001;
#...

# Generic errors

#use constant LOGIN_NO_SUCH_USER             => 200_000;
#use constant LOGIN_USER_EXISTS_ERROR        => 200_001;
#...

### %CODE% ###

# This line must be below all the "use constant ..." declarations
BEGIN { __PACKAGE__->add_errors }
EOF
    },

    $localizer_package =><<"EOF",
$load_message_and_errors_perl
sub init_message_class  { '$message_package' }
sub init_messages_class { '$messages_package' }
sub init_error_class    { '$error_package' }
sub init_errors_class   { '$errors_package' }
EOF

    $custom_package =><<"EOF",
@{[ $in_memory ? "Rose::HTML::Object->import(':customize');" : "use Rose::HTML::Object qw(:customize);" ]}
@{[ $in_memory ? '' : "\nuse $localizer_package;\n" ]}
__PACKAGE__->default_localizer($localizer_package->new);

$object_map_perl
EOF

    $object_package =><<"EOF",
sub generic_object_class { '$object_package' }
EOF
  );

  #
  # Rose::HTML::Object
  #

  require Rose::HTML::Object;

  foreach my $base_class (qw(Rose::HTML::Object))
  {
    my $package = $rename->($base_class);

    push(@packages, $package);

    if($args{'in_memory'})
    {
      # Prevent "Base class package "..." is empty" errors from base.pm
      no strict 'refs';
      ${"${custom_package}::VERSION"} = $Rose::HTML::Object::VERSION;

      # XXX" Don't need to do this
      #(my $path = $custom_package) =~ s{::}{/}g;
      #$INC{"$path.pm"} = 123;
    }

    $isa{$package} = [ $custom_package, $base_class ];

    $perl{$package} = $class->subclass_perl(package      => $package, 
                                            isa          => $isa{$package},
                                            in_memory    => 0,
                                            default_code => \%code,
                                            code         => $args{'code'},
                                            code_filter  => $args{'code_filter'});
  }

  #
  # Rose::HTML::Object::Errors
  # Rose::HTML::Object::Messages
  # Rose::HTML::Object::Message::Localizer
  #

  require Rose::HTML::Object::Errors;
  require Rose::HTML::Object::Messages;
  require Rose::HTML::Object::Message::Localizer;

  foreach my $base_class (qw(Rose::HTML::Object::Error
                             Rose::HTML::Object::Errors
                             Rose::HTML::Object::Messages
                             Rose::HTML::Object::Message::Localized
                             Rose::HTML::Object::Message::Localizer))
  {
    my $package = $rename->($base_class);

    push(@packages, $package);

    $isa{$package} = $base_class;

    $perl{$package} = $class->subclass_perl(package      => $package, 
                                            isa          => $isa{$package},
                                            in_memory    => 0,
                                            default_code => \%code,
                                            code         => $args{'code'},
                                            code_filter  => $args{'code_filter'});
  }

  #
  # Rose::HTML::Object::Customized
  #

  $perl{$custom_package} =
    $class->subclass_perl(package      => $custom_package, 
                          in_memory    => $in_memory,
                          default_code => \%code,
                          code         => $args{'code'},
                          code_filter  => $args{'code_filter'});

  push(@packages, $custom_package);

  #
  # All other classes
  #

  foreach my $base_class (sort values %$base_object_type, 'Rose::HTML::Form::Field')
  {
    if($class_filter)
    {
      local $_ = $base_class;
      next  unless($class_filter->($base_class));
    }

    if($in_memory)
    {
      my $error;

      TRY:
      {
        local $@;
        eval "require $base_class";
        $error = $@;
      }

      croak "Could not load '$base_class' - $error"  if($error);
    }

    my $package = $rename->($base_class);

    push(@packages, $package);

    unless($isa{$package})
    {
      $isa{$package} = 
      [
        $custom_package,
        $base_type_object{$package} ? $rename->($base_class) : $base_class,
      ];
    }

    $perl{$package} = $class->subclass_perl(package     => $package, 
                                            isa         => $isa{$package},
                                            in_memory   => $in_memory,
                                            code        => $args{'code'},
                                            code_filter => $args{'code_filter'});
  }

  return wantarray ? (\@packages, \%perl) : \%perl;
}

sub isa_perl
{
  my($class, %args) = @_;

  my $isa  = $args{'isa'} or Carp::confess "Missing 'isa' parameter";
  $isa = [ $isa ]  unless(ref $isa eq 'ARRAY');

  if($args{'in_memory'})
  {
    return 'our @ISA = qw(' . join(' ', @$isa) . ");";
  }
  else
  {
    return 'use base qw(' . join(' ', @$isa) . ");";
  }
}

our $Perl;

sub subclass_perl
{
  my($class, %args) = @_;

  my $package = $args{'package'} or Carp::confess "Missing 'package' parameter";
  my $isa     = $args{'isa'};
  $isa = [ $isa ]  unless(ref $isa eq 'ARRAY');

  my $filter = $args{'code_filter'};

  my($code, @code, @default_code);

  foreach my $param (qw(default_code code))
  {
    my $arg = $args{$param} || '';

    if(ref $arg eq 'HASH')
    {
      $arg = $arg->{$package};
    }

    no warnings 'uninitialized';
    if(ref $arg eq 'HASH')
    {
      if(my $existing_filter = $filter)
      {
        my $new_filter = $arg->{'filter'};
        $filter = sub 
        {
          $existing_filter->(@_); 
          $new_filter->(@_);
        };
      }
      else
      {
        $filter = $arg->{'filter'};
      }

      $arg = $arg->{'code'};
    }

    if(ref $arg eq 'CODE')
    {
      $code = $arg->($package, $isa);
    }
    else
    {
      $code = $arg;
    }

    if($code)
    {
      for($code)
      {
        s/^\n*/\n/;
        s/\n*\z/\n/;
      }
    }
    else
    {
      $code = '';
    }

    if($code)
    {
      if($param eq 'code')
      {
        push(@code, $code);      
      }
      else
      {
        push(@default_code, $code);
      }
    }
  }

  foreach my $default_code (@default_code)
  {
    if($default_code =~ /\n### %CODE% ###\n/)
    {
      $default_code =~ s/\n### %CODE% ###\n/join('', @code)/me;
      undef @code; # Attempt to reclaim memory
      undef $code; # Attempt to reclaim memory
    }
  }

  local $Perl;

  $Perl=<<"EOF";
package $package;

use strict;
@{[ $args{'isa'} ? "\n" . $class->isa_perl(%args) . "\n" : '' ]}@{[ join('', @default_code, @code) ]}
1;
EOF

  if($filter)
  {
    local *_ = *Perl;
    $filter->(\$Perl);
  }

  return $Perl;
}

1;

__END__

=head1 NAME

Rose::HTML::Objects - Object-oriented interfaces for HTML.

=head1 SYNOPSIS

    #
    # HTML form/field abstraction
    #

    use Rose::HTML::Form;

    $form = Rose::HTML::Form->new(action => '/foo',
                                  method => 'post');

    $form->add_fields
    (
      name   => { type => 'text', size => 20, required => 1 },
      height => { type => 'text', size => 5, maxlength => 5 },
      bday   => { type => 'datetime' },
    );

    $form->params(name => 'John', height => '6ft', bday => '01/24/1984');

    $form->init_fields();

    $bday = $form->field('bday')->internal_value; # DateTime object

    print $bday->strftime('%A'); # Tuesday

    print $form->field('bday')->html;

    #
    # Generic HTML objects
    #

    $obj = Rose::HTML::Object->new('p');

    $obj->push_child('hello'); # text node
    $obj->add_child(' ');      # text node

    # Add two children: HTML object with text node child
    $obj->add_children(
      Rose::HTML::Object->new(element  => 'b',
                              children => [ 'world' ]));

    # Serialize to HTML
    print $obj->html; # prints: <p>hello <b>world</b></p>

=head1 DESCRIPTION

L<Rose::HTML::Objects> is a framework for creating a reusable set of HTML widgets as mutable Perl objects that can be serialized to HTML or XHTML for display purposes.  

The L<Rose::HTML::Object> class may be used directly to represent a generic tag with an explicitly set L<element|Rose::HTML::Object/element> name and arbitrary L<attributes|Rose::HTML::Object/html_attr>.  There are also methods for L<parentE<sol>child manipulation|Rose::HTML::Object/HIERARCHY>.

Though such generic usage is possible, this family of modules is primarily intended as a framework for creating a resuable set of L<form|Rose::HTML::Form> and L<field|Rose::HTML::Form::Field> widgets.  On the Perl side, these objects are treated as abstract entities that can be fed input and will produce output in the form that is most convenient for the programmer (e.g., pass a L<DateTime> object to a date picker field to initialize it, and get a L<DateTime> object back from the field when asking for its value).

Fields may be simple (one standard HTML form field per Perl field object) or L<compound|Rose::HTML::Form::Field::Compound> (a field object that serializes to an arbitrary number of HTML tags, but can be addressed as a single logical field internally).  Likewise, forms themselves can be L<nested|Rose::HTML::Form/"NESTED FORMS">.

Each L<field|Rose::HTML::Form::Field> has its own customizable validation, input filter, output filter, internal value (a plain value or a Perl object, whichever is most convenient), output value (the value shown when the field is redisplayed), label, associated error, and any other metadata deemed necessary.  Each field can also be serialized to the L<equivalent|Rose::HTML::Form::Field/html_hidden_fields> set of (X)HTML "hidden" fields.

L<Forms|Rose::HTML::Form> are expected to be initialized with and return an object or list of objects that the form represents.  For example, a registration form could be initialized with and return a C<UserAccount> object.

All labels, errors, and messages used in the bundled form and field widgets are localized in several languages, and you may add your own localized messages and errors using the provided L<localization framework|/LOCALIZATION>.

Users are encouraged to L<create their own libraries|/"PRIVATE LIBRARIES"> of reusable form and field widgets for use on their site.  The expectation is that the same kind of field appears in multiple places in any large web application (e.g., username fields, password fields, address forms, etc.)  Each field encapsulates a set of values (e.g., options in a pop-up menu), labels, validation constraints, filters, and error messages.  Similarly, each form encapsulates a set of fields along with any inter-field validation, error messages, and init-with/object-from methods.  Nesting forms and fields preserves this delegation of responsibility, with each higher level having access to its children to perform inter-form/field tasks.

=head1 PRIVATE LIBRARIES

The classes that make up the L<Rose::HTML::Objects> distribution can be used as-is to build forms, fields, and other HTML objects.  The provided classes may also be subclassed to change their behavior.  When subclassing, however, the interconnected nature of these classes may present some surprises.  For example, consider the case of subclassing the L<Rose::HTML::Form::Field::Option> class that represents a single option in a L<select box|Rose::HTML::Form::Field::SelectBox> or L<pop-up menu|Rose::HTML::Form::Field::PopUpMenu>.

    package My::HTML::Form::Field::Option;

    use base 'Rose::HTML::Form::Field::Option';

    sub bark
    {
      print "woof!\n";
    }

Now all your options can bark like a dog.

    $option = My::HTML::Form::Field::Option->new;
    $option->bark; # woof!

This seems great until you make your first select box or pop-up menu, pull out an option object, and ask it to bark.

    $color = 
      Rose::HTML::Form::Field::PopUpMenu->new(
        name    => 'color',
        options => [ 'red', 'green', 'blue' ]);

    $option = $color->option('red');

    $option->bark; # BOOM: fatal error, no such method!

What you'll get is an error message like this: "Can't locate object method 'bark' via package 'Rose::HTML::Form::Field::Option' - ..."  That's because C<$option> is a plain old L<Rose::HTML::Form::Field::Option> object and not one of your new C<My::HTML::Form::Field::Option> objects that can C<bark()>.

This is an example of the aforementioned interconnected nature of HTML objects: L<pop-up menus|Rose::HTML::Form::Field::PopUpMenu> and L<select boxes|Rose::HTML::Form::Field::SelectBox> contain L<options|Rose::HTML::Form::Field::Option>; L<radio button groups|Rose::HTML::Form::Field::RadioButtonGroup> contain L<radio buttons|Rose::HTML::Form::Field::RadioButton>; L<checkbox groups|Rose::HTML::Form::Field::CheckboxGroup> contain L<checkboxes|Rose::HTML::Form::Field::Checkbox>; L<forms|Rose::HTML::Form> contain all of the above; and so on.  What to do?

Well, one solution is to convince all the C<Rose::HTML::*> classes that might contain option objects to use your new C<My::HTML::Form::Field::Option> subclass instead of the standard L<Rose::HTML::Form::Field::Option> class.  But globally altering the behavior of the standard C<Rose::HTML::*> classes is an extremely bad idea.  To understand why, imagine that you did so and then tried to incorporate some other code that also uses C<Rose::HTML::*> classes.  That other code certainly doesn't expect the changes you've made.  It expects the documented behavior for all the classes it's using, and rightfully so.

That's the problem with making class-wide alterations: every piece of code using those classes will see your changes.  It's "anti-social behavior" in the context of code sharing and reuse.

The solution is to subclass not just the single class whose behavior is to be altered, but rather to create an entirely separate namespace for a full hierarchy of classes within which you can make your changes in isolation.  This is called a "private library," and the L<Rose::HTML::Objects> class contains methods for creating one, either dynamically in memory, or on disk in the form of actial C<*.pm> Perl module files.

Let's try the example above again, but this time using a private library.  We will use the the L<make_private_library|/make_private_library> class method to do this.  The reference documentation for this method appears below, but you should get a good idea of its functionality by reading the usage examples here.

First, let's create an in-memory private library to contain our changes.  The L<make_private_library|/make_private_library> method accepts a hash of class name/code pairs containing customizations to be incorporated into one or more of the classes in the newly created private library.  Let's use the C<My::> prefix for our private library.  Here's a hash containing just our custom code:

  %code = 
  (
    'My::HTML::Form::Field::Option' => <<'EOF',
  sub bark
  {
    print "woof!\n";
  }
  EOF
  );

Note that the code is provided as a string, not a code reference.  Be sure to use the appropriate quoting mechanism (a single-quoted "here document" in this case) to protect your code from unintended variable interpolation.

Next, we'll create the private library in memory:

  Rose::HTML::Objects->make_private_library(in_memory => 1, 
                                            prefix    => 'My::',
                                            code      => \%code);

Now we have a full hierarchy of C<My::>-prefixed classes, one for each public C<Rose::> class in the L<Rose::HTML::Objects> distribution.  Let's try the problematic code from earlier, this time using one of our new classes.

    $color = 
      My::HTML::Form::Field::PopUpMenu->new(
        name    => 'color',
        options => [ 'red', 'green', 'blue' ]);

    $option = $color->option('red');

    $option->bark; # woof!

Success!  Of course, this dynamic in-memory class creation is relatively heavyweight.  It necessarily has to have all the classes in memory.  Creating a private library on disk allows you to load only the classes you need.  It also provides an easier means of making your customizations persistent.  Editing the actual C<*.pm> files on disk means that your changes can be tracked on a per-file basis by your version control system, and so on.  We can still use the C<%code> hash from the in-memory example to "seed" the classes; the L<make_private_library|/make_private_library> method will insert our custom code into the initial C<*.pm> files it generates.

To create a private library on disk, we need to provide a path to the directory where the generated files will be placed.  The appropriate directory hierarchy will be created below it (e.g., the path to the C<My::HTML::Form> Perl module file will be C<My/HTML/Form.pm>, starting beneath the specified C<modules_dir>).  Let's do it:

  Rose::HTML::Objects->make_private_library(
    modules_dir => '/home/john/lib',
    prefix      => 'My::',
    code        => \%code);

To actually use the generated modules, we must, well, C<use> (or C<require>) them.  We must also make sure the specified C<modules_dir> is in our L<@INC|perlvar/@INC> path.  Example:

    use lib '/home/john/lib';

    use My::HTML::Form::Field::PopUpMenu;

    $color = 
      My::HTML::Form::Field::PopUpMenu->new(
        name    => 'color',
        options => [ 'red', 'green', 'blue' ]);

    $option = $color->option('red');

    $option->bark; # woof!

And it works.  Note that if the call to L<make_private_library|/make_private_library> that creates the Perl module files on disk was in the same file as the code above, the C<My::HTML::Form::Field::PopUpMenu> class would have to be C<require>d rather than C<use>d.  (All C<use> statements are evaluated at compile time, but the C<My::HTML::Form::Field::PopUpMenu> class is not created until the L<make_private_library|/make_private_library> call is executed, which happens at runtime in this example.)

One final example.  Suppose you want to add or override a method in I<all> HTML object classes within your private library.  To facilitate this, the L<make_private_library|/make_private_library> method will create a mix-in class which will be placed at the front of the inheritence chain (i.e., the first item in the C<@ISA> array) of all generated subclasses.  Given a prefix of C<My::> as in the example above, this custom class will be called C<My::HTML::Object::Custom>.  It comes pre-populated with an initial set of private-library-wide information such as the L<object_type_class mapping|Rose::HTML::Object/object_type_classes> and the L<default_localizer|Rose::HTML::Object/default_localizer> (all of which will be populated with your C<My::*> subclasses, naturally).  Simply add your own methods to this module:

    package My::HTML::Object::Custom;
    ...
    sub chirp
    {
      print "tweet!\n";
    }

Now the C<chirp()> method will appear in all other HTML object classes in your private library.

    # It's everwhere!
    My::HTML::Link->can('chirp'); # true
    My::HTML::Form::Field::Date->can('chirp'); # true
    My::HTML::Form::Field::CheckboxGroup->can('chirp'); # true
    ...

I hope this demonstrates the motivation for and utility of private libraries.  Please see the L<make_private_library|/make_private_library> documentation for a more information on this method.

=head1 LOCALIZATION

There are several components of L<Rose::HTML::Object>'s localization system: the L<message|Rose::HTML::Object::Message::Localized> and L<error|Rose::HTML::Object::Error> objects, the classes that L<manage|Rose::HTML::Object::Messages> L<them|Rose::HTML::Object::Errors>, and of course the L<localizer|Rose::HTML::Object::Message::Localizer> itself.  Using a L<private library|/"PRIVATE LIBRARIES">, you get your own private subclasses of all of these.  This is extremely important for several reasons, and you should definitely read the L<PRIVATE LIBRARIES|/"PRIVATE LIBRARIES"> section above before continuing.

The most important actor in the localization process is, predictably, the L<localizer|Rose::HTML::Object::Message::Localizer>, and the most important aspect of the localizer is the way in which it's accessed.

The general approach is that each object that is or contains something that needs to be localized has a C<localizer()> method through which it accesses its L<localizer|Rose::HTML::Object::Message::Localizer> object.  These methods check for a local localizer object attribute, and if one is not found, the method looks "up the chain" until it finds one.  The chain may include parent objects or class hierarchies.  Eventually, the assumption is that a localizer will be found and returned.

In the most granular case, this allows each localized object to have its own individual localizer.  In the more common (and default) case, there is a single localizer object camped out at some higher point in the chain of lookups, and this localizer serves all objects.

The default localizer class, L<Rose::HTML::Object::Message::Localizer>, reads localized message text from the C<__DATA__> sections of the Perl module files that make up the L<Rose::HTML::Objects> distribution.  This is done mostly because it's the most convenient way to include the "built-in" localized message text in this CPAN module distribution.  (See the L<Rose::HTML::Object::Message::Localizer> documentation for more information.)  Localized message text is stored in memory within the localizer object itself.

You can change both the source and storage of localized message text by creating your own localizer subclass.  The key, of course, is to ensure that your localizer subclass is used instead the default localizer class by all objects.  Thankfully, the creation of a L<private library|/"PRIVATE LIBRARIES"> takes care of that, both creating a localizer subclass and ensuring that it is accessible everywhere.

Here's a simple example of a customized localizer that overrides just one method, L<get_localized_message_text|Rose::HTML::Object::Message::Localizer/get_localized_message_text>, to add three stars C<***> around the built-in message text.

    sub get_localized_message_text
    {
      my($self) = shift;

      # Get message text using the default mechanism
      my $text = $self->SUPER::get_localized_message_text(@_);

      # Bail out early if no text is defined
      return $text  unless(defined $text);

      # Surround the text with stars and return it
      return "*** $text ***";
    }

This is a silly example, obviously, but it does demonstrate how easy it is to alter the default behavior.  A more useful example might be to look elsewhere for a message first, then fall back to the default mechanism.  This requires actually unpacking the method arguments (as opposed to simply passing them on to the superclass call in the example above), but is otherwise not much more complex:

    sub get_localized_message_text
    {
      my($self) = shift;

      my %args = @_;

      my $id      = $args{'id'};
      my $name    = $args{'name'};
      my $locale  = $args{'locale'};
      my $variant = $args{'variant'};

      # Look elsewhere for this localized text: in a database, pull
      # from a server, an XML file, whatever.
      $text = ...

      return $text  if($defined $text); #

      # Fall back to the default mechanism
      return $self->SUPER::get_localized_message_text(@_);
    }

By overriding this and othr methods in the L<Rose::HTML::Object::Message::Localizer> class, your localizer subclass could choose to entirely ignore the default mechanism for localized text storage and retrieval.

Here's an example of a new L<field|Rose::HTML::Form::Field> subclass that uses localized messages and errors.  It will use the default localized text mechanism to the sake of simplicity (i.e., text stored in C<__DATA__> sections of Perl modules).  It's a "nickname" field intended to be used as part of a localized form that asks for user information.  For the sake of demonstrating validation, let's say we've decided that nicknames may not contain space characters.

The first step is to define our L<message|Rose::HTML::Object::Messages> and L<error|Rose::HTML::Object::Errors> ids.  These should be added to the generated C<My::HTML::Object::Messages> and C<My::HTML::Object::Errors> classes, respectively.  You can do this during private library generation by adding to the C<code> hash passed to the L<make_private_library|/make_private_library> call, or by editing the generated files on disk.  (The relevant sections are indicated with comments that  L<make_private_library|/make_private_library> will place in the generated C<*.pm> files.)  First, the message ids:

    package My::HTML::Object::Messages;
    ...
    # Field labels
    use constant FIELD_LABEL_NICKNAME => 100_000;
    ...

    # Field errors
    use constant FIELD_ERROR_BAD_NICKNAME => 101_000;
    ...

Now the error ids.  Note that the error and message id numbers for each error message (just C<FIELD_ERROR_BAD_NICKNAME> in this case) should be the same in order to take advantage of the default behavior of the L<message_for_error_id|Rose::HTML::Object/message_for_error_id> method.

    package My::HTML::Object::Errors;
    ...
    # Field errors
    use constant FIELD_ERROR_BAD_NICKNAME => 101_000;
    ...

Finally, the nickname field class itself.  Note that it inherits from and uses  classes from our private library, not from C<Rose::>.

    package My::HTML::Form::Field::Nickname;

    # Import message and error ids.  Note that just the error id for
    # FIELD_LABEL_NICKNAME is imported, not the message id. That's
    # because we're using it as an error id below, passing it as an
    # argument to the error_id() method.
    use My::HTML::Object::Messages qw(FIELD_LABEL_NICKNAME);
    use My::HTML::Object::Errors qw(FIELD_ERROR_BAD_NICKNAME);

    # Inherit from our private library version of a text field
    use base qw(My::HTML::Form::Field::Text);

    sub init
    {
      my($self) = shift;

      # Set the default label before calling through to the superclass
      $self->label_id(FIELD_LABEL_NICKNAME);

      $self->SUPER::init(@_);
    }

    sub validate
    {
      my($self) = shift;

      # Do the default validation first
      my $ret = $self->SUPER::validate(@_);
      return $ret  unless($ret);

      #
      # Do our custom validation
      #

      my $nick = $self->internal_value;

      # Nicknames may not contain space characters
      if($nick =~ /\s/)
      {
        # Remember, the error_label falls back to the label if no
        # explicit error_label is set.  (And we set a default 
        # label_id in init() above.)
        my $label = $self->error_label;

        # Pass the (also localized!) label as a parameter to this error.
        # See the actual localized text in the __DATA__ section below.
        $self->error_id(FIELD_ERROR_BAD_NICKNAME, { label => $label });
        return 0;
      }

      return 1;
    }

    # Standard technique for conditionally loading all localized message
    # text from the __DATA__ section below using the default localizer.
    # (Alternately, you could remove the conditional and always load all 
    # the localized message text when this module is loaded.)
    if(__PACKAGE__->localizer->auto_load_messages)
    {
      __PACKAGE__->localizer->load_all_messages;
    }

    1;

    __DATA__

    [% LOCALE en %]

    FIELD_LABEL_NICKNAME     = "Nickname"    
    FIELD_ERROR_BAD_NICKNAME = "[label] may not contain space characters."

    [% LOCALE fr %]

    FIELD_LABEL_NICKNAME     = "Surnom"    
    FIELD_ERROR_BAD_NICKNAME = "[label] mai de ne pas contenir des espaces."

(Sorry for the bad French translations.  Corrections welcome!)

Finally, let's map the new nickname field class to its own field type name:

    package My::HTML::Form;
    ...
    # Add new field type class mappings
    __PACKAGE__->add_field_type_classes
    (
      nickname => 'My::HTML::Form::Field::Nickname',
      ...
    );

Here it is in action:

    $field = My::HTML::Form::Field::Nickname->new(name => 'nick');
    $field->input_value('bad nickname');
    $field->validate;

    print $field->error; # "Nickname may not contain space characters."

    $field->locale('fr');

    print $field->error; # "Surnom mai de ne pas contenir des espaces."

Of course, you'll rarely instantiate a field in isolation.  It will usually be part of a L<form|Rose::HTML::Form>.  Similarly, you will rarely set the L<locale|Rose::HTML::Object/locale> of a field directly.  Instead, you will set the locale of the entire form and let the fields use that locale, accessed through the delegation chain searched when the L<locale|Rose::HTML::Object/locale> method is called on a field object.  Example:

    $form = My::HTML::Form->new;
    $form->add_fields(nick => { type => 'nickname' });

    $form->params(nick => 'bad nickname');
    $form->validate;

    # "Nickname may not contain space characters."
    print $form->field('nick')->error; 

    $form->locale('fr');

    # "Surnom mai de ne pas contenir des espaces."
    print $form->field('nick')->error; 

Or you could set the locale on the localizer itself for a similar effect.

Also note the use of the label within the "bad nickname" error message.  In general, incorporating (independently set, remember) labels into messages like this tends to lead to translation issues.  (Is the label masculine?  Feminine? Singular?  Dual?  Plural?  Etc.)  I've done so here to demonstrate that one localized message can be incorporated into another localized message, with both dynamically matching their locales based on the locale set higher up in the object hierarchy.

=head1 CLASS METHODS

=over 4

=item B<make_private_library PARAMS>

Create a comprehensive collection of C<Rose::HTML::*> subclasses, either in memory or as C<*.pm> files on disk, in order to provide a convenient and isolated location for your customizations.  Please read the L<private libraries|/"PRIVATE LIBRARIES"> section above for more information.

Valid PARAMS name/value pairs are:

=over 4

=item B<class_filter CODEREF>

A reference to a subroutine that takes a C<Rose::HTML::*> class name as its argument and returns true if a subclass should be created for this class, false otherwise.  The class name will also be available in C<$_>.  If this parameter is omitted, all classes are subclassed.

=item B<code HASHREF>

A reference to a hash containing code to be added to subclasses.  The keys of the hash are the subclass class names (i.e., the names I<after> the application of the C<rename> code or the C<trim_prefix>/C<prefix> processing).

The value for each key may be either a string containing Perl code or a reference to a hash containing a C<code> key whose value is a string containing Perl code and a C<filter> key whose value is a reference to a subroutine used to filter the code.

The C<filter> subroutine will be passed a reference to a scalar containing the full Perl code for a subclass and is expected to modify it directly.  The Perl code will also be available in C<$_>.  Example:

    code => 
    {
      'My::HTML::Object' => <<'EOF', # code string argument
  sub my_method
  {
    # ...
  }
  EOF
      'My::HTML::Form' =>
      {
        filter => sub { s/__FOO__//g },
        code   => <<'EOF',
  sub my_other_method__FOO__
  {
    # ...
  }
  EOF
      },
    },

This will create C<my_method()> in the C<My::HTML::Object> class and, with the C<__FOO__> removed, C<my_other_method()> will be created in the C<My::HTML::Form> class.

Note that the use of this parameter is optional.  You can always add your code to the Perl module files after they've been generated, or add your code directly into memory after the classes have been created C<in_memory>.

=item B<code_filter CODEREF>

A reference to a subroutine used to filter the Perl code for all generated subclasses.  This filter will run before any subclass-specific C<filter> (see the C<code> parameter above for an explanation).  This subroutine will be passed a reference to a scalar containing the Perl code and is expected to modify it directly.  The Perl code will also be available in C<$_>.

=item B<debug INT>

Print debugging output to STDERR if INT is creater than 0.  Higher numbers produce more output.  The maximum useful value is 3.

=item B<in_memory BOOL>

If true, the classes that make up the private library will be compiled in memory.  If false (the default), then a C<modules_dir> must be provided.

=item B<modules_dir PATH>

The path to the directory under which all C<*.pm> Perl module files will be created.  The modules will be created in the expected tree structure.  For example, the C<My::HTML::Object> class will be in the file C<My/HTML/Object.pm> beneath the C<modules_dir> PATH.  This parameter is ignored if the C<in_memory> parameter is passed.

=item B<overwrite BOOL>

If true, overwrite any existing files that are located at the same paths as files created by this method call.  This option is not applicable if the C<in_memory> parameter is passed.

=item B<prefix STRING>

The class name prefix with which to replace the C<trim_prefix> in all subclass class names.  For example, a C<prefix> value of C<My::> combined with the (default) C<trim_prefix> of C<Rose::> would take a class named C<Rose::HTML::Whatever> and produce a subclass named C<My::HTML::Whatever>.  You must pass this parameter or the C<rename> parameter.

=item B<rename CODEREF>

A reference to a subroutine that takes a C<Rose::HTML::*> class name as its argument and returns an appropriate subclass name.  The name argument is also available in the C<$_> variable, enabling code like this:

    rename => sub { s/^Rose::/Foo::/ },

You must pass this parameter or the C<prefix> parameter.

=item B<trim_prefix STRING>

The prefix string to be removed from each C<Rose::HTML::*> class name.  This parameter is only relevant when the C<prefix> parameter is passed (and the C<rename> parameter is not).  Defaults to C<Rose::> if this parameter is not passed.

=back

=back

=head1 DEVELOPMENT POLICY

The L<Rose development policy|Rose/"DEVELOPMENT POLICY"> applies to this, and all C<Rose::*> modules.  Please install L<Rose> from CPAN and then run C<perldoc Rose> for more information.

=head1 SUPPORT

Any L<Rose::HTML::Objects> questions or problems can be posted to the L<Rose::HTML::Objects> mailing list.  To subscribe to the list or search the archives, go here:

L<http://groups.google.com/group/rose-html-objects>

Although the mailing list is the preferred support mechanism, you can also email the author (see below) or file bugs using the CPAN bug tracking system:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTML-Objects>

There's also a wiki and other resources linked from the Rose project home page:

L<http://rosecode.org>

=head1 CONTRIBUTORS

Tom Heady, Cees Hek, Kevin McGrath, Denis Moskowitz, RJBS, Jacques Supcik, Uwe Voelker

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
