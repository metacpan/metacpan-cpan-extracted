package Pony::Object {
  # "I am 100% sure that we're not completely sure"

  use feature ':5.10';
  use Storable qw/dclone/;
  use Module::Load;
  use Carp qw(confess);
  use Scalar::Util qw(refaddr);

  use constant DEBUG => 0;

  BEGIN {
    if (DEBUG) {
      say STDERR "\n[!] Pony::Object DEBUGing mode is turning on!\n";
      
      *{dumper} = sub {
        use Data::Dumper;
        $Data::Dumper::Indent = 1;
        say Dumper(@_);
        say '=' x 79;
      }
    }
  }

  our $VERSION = "1.02";

  # Var: $DEFAULT
  #   Use it to redefine default Pony's options.
  our $DEFAULT = {
    '' => {
      'withExceptions' => 0,
      'baseClass' => [],
    }
  };

  # Function: import
  #   This function will runs on each use of this module.
  #   It changes caller - adds new keywords,
  #   makes caller more strict and modern,
  #   create from simple package almost normal class.
  #   Also it provides some useful methods.
  #   
  #   Don't forget: it's still OOP with blessed refs,
  #   but now it looks better - more sugar for your code.
  sub import {
    my $this = shift;
    my $call = caller;
    
    # Modify caller just once.
    # We suppose, that only we can create function ALL.
    return if defined *{$call.'::ALL'};
    
    # Parse parameters.
    my $default = dclone $DEFAULT;
    my $profile;
    
    # Get predefined params.
    for my $prefix (sort {length $b <=> length $a} keys %$DEFAULT) {
      if ($call =~ /^$prefix/) {
        my @doesnt_exist = grep {
          not exists $profile->{$_}
        } keys %{ $default->{$prefix} };
        
        $profile->{$_} = $default->{$prefix}->{$_} for @doesnt_exist;
        next;
      }
      
      last if keys %{$default->{''}} == keys %{$default->{$call}};
    }
    
    $profile->{isAbstract} = 0; # don't do default object abstract.
    $profile->{isSingleton} = 0; # don't do default object singleton.
    $profile = parseParams($call, $profile, @_);
    
    # Keywords, base methods, attributes.
    predefine($call, $profile);
    
    # Pony objects must be strict and modern.
    strict  ->import;
    warnings->import;
    feature ->import(':5.10');
    feature ->import('signatures') if $] >= 5.020;
    
    unless ($profile->{noObject}) {
      # Base classes and params.
      prepareClass($call, "${call}::ISA", $profile);
      
      methodsInheritance($call);
      propertiesInheritance($call);
      
      *{$call.'::new'} = sub { importNew($call, @_) };
    }
  }

  # Function: importNew
  #  Constructor for Pony::Objects.
  #
  # Parameters:
  #   $call - Str - caller package.
  #
  # Returns:
  #   self
  sub importNew {
    my $call = shift;
    
    if ($call->META->{isAbstract}) {
      confess "Trying to use an abstract class $call";
    } else {
      $call->AFTER_LOAD_CHECK;
    }
    
    # For singletons.
    return ${$call.'::instance'} if defined ${$call.'::instance'};
    
    my $this = shift;
    my $obj = dclone { %{${this}.'::ALL'} };
    
    while (my ($k, $p) = each %{$this->META->{properties}}) {
      if (grep {$_ eq 'static'} @{$p->{access}}) {
        tie $obj->{$k}, 'Pony::Object::TieStatic',
          $call->META->{static}, $k, $call->META->{static}->{$k} || $obj->{$k};
      }
    }
    
    $this = bless $obj, $this;
    
    ${$call.'::instance'} = $this if $call->META->{isSingleton};
    
    # 'After hook' for user.
    $this->init(@_) if $call->can('init');
    return $this;
  }

  # Function: parseParams
  #   Load all base classes and read class params.
  #
  # Parameters:
  #   $call    - Str      - caller package.
  #   $profile - HashRef  - profile of this use.
  #   @params  - Array    - import params.
  #
  # Returns:
  #   HashRef - $profile
  sub parseParams {
    my ($call, $profile, @params) = @_;
    
    for my $param (@params) {
      
      # Define singleton class.
      if ($param =~ /^-?singleton$/) {
        $profile->{isSingleton} = 1;
        next;
      }
      
      # Define abstract class.
      elsif ($param =~ /^-?abstract$/) {
        $profile->{isAbstract} = 1;
        next;
      }
      
      # Features:
      
      # Use exceptions featureset.
      elsif ($param =~ /^:exceptions?$/ || $param =~ /^:try$/) {
        $profile->{withExceptions} = 1;
        next;
      }
      
      # Don't use exceptions featureset.
      elsif ($param =~ /^:noexceptions?$/ || $param =~ /^:notry$/) {
        $profile->{withExceptions} = 0;
        next;
      }
      
      # Don't create an object.
      # Just make package strict modern and add some staff.
      elsif ($param =~ /^:noobject$/) {
        $profile->{noObject} = 1;
        next;
      }
      
      # Base classes:
      
      # Save class' base classes.
      else {
        push @{$profile->{baseClass}}, $param;
      }
    }
    
    return $profile;
  }

  # Function: prepareClass
  #   Load all base classes and process class params.
  #
  # Parameters:
  #   $call     - Str       - caller package.
  #   $isaRef   - ArrayRef  - ref to @ISA.
  #   $profile  - HashRef   - parsed params profile.
  sub prepareClass {
    my ($call, $isaRef, $profile) = @_;

    $call->META->{isSingleton} = $profile->{isSingleton} // 0;
    $call->META->{isAbstract} = $profile->{isAbstract} // 0;

    for my $base (@{ $profile->{baseClass} }) {
      next if $call eq $base;
      load $base;
      $base->AFTER_LOAD_CHECK if $base->can('AFTER_LOAD_CHECK');
      push @$isaRef, $base;
    }
  }

  # Function: predefine
  #   Predefine keywords and base methods.
  #
  # Parameters:
  #   $call - Str - caller package.
  #   $profile - HashRef
  sub predefine {
    my ($call, $profile) = @_;
    
    # Only for objects.
    unless ($profile->{noObject}) {
      # Predefine ALL and META.
      %{$call.'::ALL' } = ();
      %{$call.'::META'} = ();
      ${$call.'::META'}{isSingleton}= 0;
      ${$call.'::META'}{isAbstract} = 0;
      ${$call.'::META'}{abstracts}  = [];
      ${$call.'::META'}{methods}    = {};
      ${$call.'::META'}{properties} = {};
      ${$call.'::META'}{symcache}   = {};
      ${$call.'::META'}{checked}    = 0;
      ${$call.'::META'}{static}     = {};
      
      # Access for properties.
      *{$call.'::has'}      = sub { addProperty ($call, @_) };
      *{$call.'::static'}   = sub { addStatic   ($call, @_) };
      *{$call.'::public'}   = sub { addPublic   ($call, @_) };
      *{$call.'::private'}  = sub { addPrivate  ($call, @_) };
      *{$call.'::protected'}= sub { addProtected($call, @_) };
      
      # Convert object's data into hash.
      # Uses ALL() to get properties' list.
      *{$call.'::toHash'} = *{$call.'::to_h'} = sub {
        my $this = shift;
        my %hash = map { $_, $this->{$_} } keys %{ $this->ALL() };
        return \%hash;
      };
      
      *{$call.'::AFTER_LOAD_CHECK'} = sub { checkImplementations($call) };
      
      # Save method's attributes.
      *{$call.'::MODIFY_CODE_ATTRIBUTES'} = sub {
        my ($pkg, $ref, @attrs) = @_;
        my $sym = findsym($pkg, $ref);
        
        $call->META->{methods}->{ *{$sym}{NAME} } = {
          attributes => \@attrs,
          package => $pkg
        };
        
        for my $attr (@attrs) {
          if    ($attr eq 'Public'   ) { makePublic   ($pkg, $sym, $ref) }
          elsif ($attr eq 'Protected') { makeProtected($pkg, $sym, $ref) }
          elsif ($attr eq 'Private'  ) { makePrivate  ($pkg, $sym, $ref) }
          elsif ($attr eq 'Abstract' ) { makeAbstract ($pkg, $sym, $ref) }
        }
        return;
      };
      
      # Getters for REFs to special variables %ALL and %META.
      *{$call.'::ALL'}  = sub { \%{ $call.'::ALL' } };
      *{$call.'::META'} = sub { \%{ $call.'::META'} };
    }
    
    # Try, Catch, Finally.
    # Define them if user wants.
    if ($profile->{withExceptions}) {
      *{$call.'::try'} = sub (&;@) {
        my($try, $catch, $finally) = @_;
        local $@;
        
        # If some one wanna to get some
        # values from try/catch/finally blocks.
        if (defined wantarray) {
          if (wantarray == 0) {
            my $ret = eval{ $try->() };
            $ret = $catch->($@) if $@ && defined $catch;
            $ret = $finally->() if defined $finally;
            return $ret;
          }
          elsif (wantarray == 1) {
            my @ret = eval{ $try->() };
            @ret = $catch->($@) if $@ && defined $catch;
            @ret = $finally->() if defined $finally;
            return @ret;
          }
        }
        else {
          eval{ $try->() };
          $catch->($@) if $@ && defined $catch;
          $finally->() if defined $finally;
        }
      };
      *{$call.'::catch'} = sub (&;@) { @_ };
      *{$call.'::finally'} = sub (&) { @_ };
    }
    
    # This method provides deep copy
    # for Pony::Objects
    *{$call.'::clone'}  = sub { dclone shift };
    
    # Simple Data::Dumper wrapper.
    *{$call.'::dump'} = sub {
      use Data::Dumper;
      $Data::Dumper::Indent = 1;
      Dumper(@_);
    };
  }

  # Function: methodsInheritance
  #   Inheritance of methods.
  #
  # Parameters:
  #   $this - Str - caller package.
  sub methodsInheritance {
    my $this = shift;
    
    for my $base ( @{$this.'::ISA'} ) {
      # All Pony-like classes.
      if ($base->can('META')) {
        my $methods = $base->META->{methods};
        
        while (my($k, $v) = each %$methods) {
          $this->META->{methods}->{$k} = $v
            unless exists $this->META->{methods}->{$k};
        }
        
        # Abstract classes.
        if ($base->META->{isAbstract}) {
          my $abstracts = $base->META->{abstracts};
          push @{ $this->META->{abstracts} }, @$abstracts;
        }
      }
    }
  }

  # Function: checkImplementations
  #   Check for implementing abstract methods
  #   in our class in non-abstract classes.
  #
  # Parameters:
  #   $this - Str - caller package.
  sub checkImplementations {
    my $this = shift;
    
    return if $this->META->{checked};
    $this->META->{checked} = 1;
    
    # Check: does all abstract methods implemented.
    for my $base (@{$this.'::ISA'}) {
      if ( $base->can('META') && $base->META->{isAbstract} ) {
        my $methods = $base->META->{abstracts};
        my @bad;
        
        # Find Abstract methods,
        # which was not implements.
        for my $method (@$methods) {
          # Get Abstract methods.
          push @bad, $method
            if grep { $_ eq 'Abstract' }
              @{ $base->META->{methods}->{$method}->{attributes} };
          
          # Get abstract methods,
          # which doesn't implement.
          @bad = grep { !exists $this->META->{methods}->{$_} } @bad;
        }
        
        if (@bad) {
          my @messages = map
            {"Didn't find method ${this}::$_() defined in $base."}
              @bad;
          push @messages, "You should implement abstract methods before.\n";
          confess join("\n", @messages);
        }
      }
    }
  }

  # Function: addProperty
  #   Guessing access type of property.
  #
  # Parameters:
  #   $this - Str - caller package.
  #   $attr - Str - name of property.
  #   $value - Mixed - default value of property.
  sub addProperty {
    my ($this, $attr, $value) = @_;
    
    # Properties
    if (ref $value ne 'CODE') {
      if ($attr =~ /^__/) {
        return addPrivate(@_);
      } elsif ($attr =~ /^_/) {
        return addProtected(@_);
      } else {
        return addPublic(@_);
      }
    }
    
    # Methods
    else {
      *{$this."::$attr"} = $value;
      my $sym = findsym($this, $value);
      my @attrs = qw/Public/;
      
      if ($attr =~ /^__/) {
        @attrs = qw/Private/;
        return makePrivate($this, $sym, $value);
      } elsif ($attr =~ /^_/) {
        @attrs = qw/Protected/;
        return makeProtected($this, $sym, $value);
      } else {
        return makePublic($this, $sym, $value);
      }
      
      $this->META->{methods}->{ *{$sym}{NAME} } = {
        attributes => \@attrs,
        package => $this
      };
    }
  }

  # Function: addStatic
  #   Add static property or make property static.
  #
  # Parameters:
  #   $call - Str - caller package.
  #   $name - Str - property's name.
  #   $value - Mixed - default value.
  #
  # Returns:
  #   $name - Str - property's name.
  #   $value - Mixed - default value.
  sub addStatic {
    my $call = shift;
    my ($name, $value) = @_;
    push @{ $call->META->{statics} }, $name;
    addPropertyToMeta('static', $call, @_);
    return @_;
  }

  # Function: addPropertyToMeta
  #   Save property's info into META
  #
  # Parameters:
  #   $access - Str - property's access type.
  #   $call - Str - caller package.
  #   $name - Str - property's name.
  #   $value - Mixed - property's default value.
  sub addPropertyToMeta {
    my $access = shift;
    my $call = shift;
    my ($name, $value) = @_;
    
    my $props = $call->META->{properties};
    
    # Delete inhieritated properties for polymorphism.
    delete $call->META->{properties}->{$name} if
      exists $call->META->{properties}->{$name} &&
      $call->META->{properties}->{$name}->{package} ne $call;
    
    # Create if doesn't exist
    %$props = (%$props, $name => {access => []}) if
      not exists $props->{$name} ||
      ( $props->{$name}->{package} && $props->{$name}->{package} ne $call );
    
    push @{$props->{$name}->{access}}, $access;
    $props->{$name}->{package} = $call;
  }

  # Function: addPublic
  #   Create public property with accessor.
  #   Save it in special variable ALL.
  #
  # Parameters:
  #   $call  - Str - caller package.
  #   $name  - Str - name of property.
  #   $value - Mixed - default value of property.
  sub addPublic {
    my $call = shift;
    my ($name, $value) = @_;
    addPropertyToMeta('public', $call, @_);
    
    # Save pair (property name => default value)
    %{ $call.'::ALL' } = ( %{ $call.'::ALL' }, $name => $value );
    *{$call."::$name"} = sub : lvalue { my $call = shift; $call->{$name} };
    return @_;
  }

  # Function: addProtected
  #   Create protected property with accessor.
  #   Save it in special variable ALL.
  #   Can die on wrong access attempt.
  #
  # Parameters:
  #   $pkg  - Str - caller package.
  #   $name - Str - name of property.
  #   $value - Mixed - default value of property.
  sub addProtected {
    my $pkg = shift;
    my ($name, $value) = @_;
    addPropertyToMeta('protected', $pkg, @_);
    
    # Save pair (property name => default value)
    %{$pkg.'::ALL'} = (%{$pkg.'::ALL'}, $name => $value);
    
    *{$pkg."::$name"} = sub : lvalue {
      my $this = shift;
      my $call = caller;
      confess "Protected ${pkg}::$name called"
        unless ($call->isa($pkg) || $pkg->isa($call)) and $this->isa($pkg);
      $this->{$name};
    };
    return @_;
  }

  # Function: addPrivate
  #   Create private property with accessor.
  #   Save it in special variable ALL.
  #   Can die on wrong access attempt.
  #
  # Parameters:
  #   $pkg  - Str - caller package.
  #   $name - Str - name of property.
  #   $value - Mixed - default value of property.
  sub addPrivate {
    my $pkg = shift;
    my ($name, $value) = @_;
    addPropertyToMeta('private', $pkg, @_);
    
    # Save pair (property name => default value)
    %{ $pkg.'::ALL' } = ( %{ $pkg.'::ALL' }, $name => $value );
    
    *{$pkg."::$name"} = sub : lvalue {
      my $this = shift;
      my $call = caller;
      confess "Private ${pkg}::$name called"
        unless $pkg->isa($call) && $this->isa($pkg);
      $this->{$name};
    };
    return @_;
  }

  # Function: makeProtected
  #   Function's attribute.
  #   Uses to define, that this code can be used
  #   only inside this class and his childs.
  #
  # Parameters:
  #   $pkg - Str - name of package, where this function defined.
  #   $symbol - Symbol - reference to perl symbol.
  #   $ref - CodeRef - reference to function's code.
  sub makeProtected {
    my ($pkg, $symbol, $ref) = @_;
    my $method = *{$symbol}{NAME};
    
    no warnings 'redefine';
    
    *{$symbol} = sub {
      my $this = $_[0];
      my $call = caller;
      confess "Protected ${pkg}::$method() called"
        unless ($call->isa($pkg) || $pkg->isa($call)) and $this->isa($pkg);
      goto &$ref;
    }
  }

  # Function: makePrivate
  #   Function's attribute.
  #   Uses to define, that this code can be used
  #   only inside this class. NOT for his childs.
  #
  # Parameters:
  #   $pkg - Str - name of package, where this function defined.
  #   $symbol - Symbol - reference to perl symbol.
  #   $ref - CodeRef - reference to function's code.
  sub makePrivate {
    my ($pkg, $symbol, $ref) = @_;
    my $method = *{$symbol}{NAME};
    
    no warnings 'redefine';
    
    *{$symbol} = sub {
      my $this = $_[0];
      my $call = caller;
      confess "Private ${pkg}::$method() called"
        unless $pkg->isa($call) && $this->isa($pkg);
      goto &$ref;
    }
  }

  # Function: makePublic
  #   Function's attribute.
  #   Uses to define, that this code can be used public.
  #
  # Parameters:
  #   $pkg - Str - name of package, where this function defined.
  #   $symbol - Symbol - reference to perl symbol.
  #   $ref - CodeRef - reference to function's code.
  sub makePublic {
    # do nothing
  }

  # Function: makeAbstract
  #   Function's attribute.
  #   Define abstract attribute.
  #   It means, that it doesn't conteins realisation,
  #   but none abstract class, which will extends it,
  #   MUST implement it.
  #
  # Parameters:
  #   $pkg - Str - name of package, where this function defined.
  #   $symbol - Symbol - reference to perl symbol.
  #   $ref - CodeRef - reference to function's code.
  sub makeAbstract {
    my ($pkg, $symbol, $ref) = @_;
    my $method = *{$symbol}{NAME};
    
    # Can't define abstract method
    # in none-abstract class.
    confess "Abstract ${pkg}::$method() defined in non-abstract class"
      unless $pkg->META->{isAbstract};
    
    # Push abstract method
    # into object meta.
    push @{ $pkg->META->{abstracts} }, $method;
    
    no warnings 'redefine';
    
    # Can't call abstract method.
    *{$symbol} = sub { confess "Abstract ${pkg}::$method() called" };
  }

  # Function: propertiesInheritance
  #   This function calls when we need to get
  #   properties (with thier default values)
  #   form classes which our class extends to our class.
  #
  # Parameters:
  #   $this - Str - caller package.
  sub propertiesInheritance {
    my $this = shift;
    my %classes;
    my @classes = @{ $this.'::ISA' };
    my @base;
    my %props;
    
    # Get all parent's properties
    while (@classes) {
      my $c = pop @classes;
      next if exists $classes{$c};
      %classes = (%classes, $c => 1);
      push @base, $c;
      push @classes, @{$c.'::ISA'};
    }
    
    for my $base (reverse @base) {
      if ($base->can('ALL')) {
        # Default values
        my $all = $base->ALL();
        for my $k (keys %$all) {
          unless (exists ${$this.'::ALL'}{$k}) {
            %{$this.'::ALL'} = (%{$this.'::ALL'}, $k => $all->{$k});
          }
        }
        # Statics
        $all = $base->META->{properties};
        for my $k (keys %$all) {
          unless (exists $this->META->{properties}->{$k}) {
            %{$this->META->{properties}} = (%{$this->META->{properties}},
              $k => $base->META->{properties}->{$k});
          }
        }
      }
    }
  }

  # Function: findsym
  #   Get perl symbol by ref.
  #
  # Parameters:
  #   $pkg - Str - package, where it defines.
  #   $ref - CodeRef - reference to method.
  #
  # Returns:
  #   Symbol
  sub findsym {
    my ($pkg, $ref) = @_;
    my $symcache = $pkg->META->{symcache};
    
    return $symcache->{$pkg, $ref} if $symcache->{$pkg, $ref};
    
    my $type = 'CODE';
    
    for my $sym (values %{$pkg."::"}) {
      next unless ref ( \$sym ) eq 'GLOB';
      
      return $symcache->{$pkg, $ref} = \$sym
        if *{$sym}{$type} && *{$sym}{$type} == $ref;
    }
  }
}


###############################################################################
# Class: Pony::Object::TieStatic
#   Tie class. Use for make properties are static.
package Pony::Object::TieStatic {
  # "When you see me again, it won't be me"

  # Method: TIESCALAR
  #   tie constructor
  #
  # Parameters:
  #   $storage - HashRef - data storage
  #   $name - Str - property's name
  #   $val - Mixed - Init value
  #
  # Returns:
  #   Pony::Object::TieStatic
  sub TIESCALAR {
    my $class = shift;
    my ($storage, $name, $val) = @_;
    $storage->{$name} = $val unless exists $storage->{$name};

    bless {name => $name, storage => $storage}, $class;
  }

  # Method: FETCH
  #   Defines fetch for scalar.
  #
  # Returns:
  #   Mixed - property's value
  sub FETCH {
    my $self = shift;
    return $self->{storage}->{ $self->{name} };
  }

  # Method: STORE
  #   Defines store for scalar.
  #
  # Parameters:
  #   $val - Mixed - property's value
  sub STORE {
    my $self = shift;
    my $val = shift;
    $self->{storage}->{ $self->{name} } = $val;
  }
}

1;

__END__

=head1 NAME

Pony::Object - An object system.

=head1 OVERVIEW

If you wanna protected methods, abstract classes and other OOP stuff, you
may use Pony::Object. Also Pony::Objects are strict and modern.

=head1 SYNOPSIS

  # Class: MyArticle (Example)
  #   Abstract class for articles.
  package MyArticle {
    use Pony::Object qw(-abstract :exceptions);
    use MyArticle::Exception::IO; # Based on Pony::Object::Throwable class.
    
    protected date => undef;
    protected authors => [];
    public title => '';
    public text => '';
    
    # Function: init
    #   Constructor.
    #
    # Parameters:
    #   date - Int
    #   authors - ArrayRef
    sub init : Public($this) {
      ($this->date, $this->authors) = @_;
    }
    
    # Function: getDate
    #   Get formatted date.
    #
    # Returns:
    #   Str
    sub getDate : Public($this) {
      return $this->dateFormat($this->date);
    }
    
    # Function: dateFormat
    #   Convert Unix time to good looking string. Not implemented.
    #
    # Parameters:
    #   date - Int
    #
    # Returns:
    #   String
    sub dateFormat : Abstract;
    
    # Function: from_pdf
    #   Trying to create article from pdf file.
    #
    # Parameters:
    #   file - Str - pdf file.
    sub from_pdf : Public($this, $file) {
      try {
        open F, $file or
          throw MyArticle::Exception::IO(action => "read", file => $file);
        
        # do smth
        
        close F;
      } catch {
        my $e = shift; # get exception object
        
        if ($e->isa('MyArticle::Exception::IO')) {
          # handler for MyArticle::Exception::IO exceptions
        }
      };
    }
  }
  
  1;

=head1 Methods and properties

=head2 has

Keyword C<has> declares new property. Also you can define methods via C<has>.

  package News;
  use Pony::Object;
    
    # Properties:
    has 'title';
    has text => '';
    has authors => [ qw/Alice Bob/ ];
    
    # Methods:
    has printTitle => sub {
      my $this = shift;
      say $this->title;
    };
    
    sub printAuthors {
      my $this = shift;
      print @{$this->authors};
    }
  1;



  package main;
  use News;
  my $news = new News;
  $news->printAuthors();
  $news->title = 'Sensation!'; # Yep, you can assign property's value via "=".
  $news->printTitle();

=head2 new

Pony::Objects hasn't method C<new>. In fact, of course they has. But C<new> is an
internal function, so you should not use C<new> as name of method.

Instead of this Pony::Objects has C<init> methods, where you can write the same,
what you wish write in C<new>. C<init> is after-hook for C<new>.

  package News;
  use Pony::Object;
    
    has title => undef;
    has lower => undef;
    
    sub init {
      my $this = shift;
      $this->title = shift;
      $this->lower = lc $this->title;
    }
    
  1;

  package main;
  use News;
  my $news = new News('Big Event!');
  print $news->lower;

=head2 public, protected, private properties

You can use C<has> keyword to define property. If your variable starts with "_", variable becomes 
protected. "__" for private.

  package News;
  use Pony::Object;
  
    has text => '';
    has __authors => [ qw/Alice Bob/ ];
    
    sub getAuthorString {
      my $this = shift;
      return join(' ', @{$this->__authors});
    }
    
  1;



  package main;
  use News;
  my $news = new News;
  say $news->getAuthorString();

The same but with keywords C<public>, C<protected> and C<private>.

  package News;
  use Pony::Object;
    
    public text => '';
    private authors => [ qw/Alice Bob/ ];
    
    sub getAuthorString {
      my $this = shift;
      return join(' ', @{$this->authors});
    }
    
  1;



  package main;
  use News;
  my $news = new News;
  say $news->getAuthorString();

=head2 Public, Protected, Private methods

Use attributes C<Public>, C<Private> and C<Protected> to define method's access type.

  package News;
  use Pony::Object;
    
    public text => '';
    private authors => [ qw/Alice Bob/ ];
    
    sub getAuthorString : Public
      {
        return shift->joinAuthors(', ');
      }
    
    sub joinAuthors : Private
      {
        my $this = shift;
        my $delim = shift;
        
        return join( $delim, @{$this->authors} );
      }
    
  1;



  package main;
  use News;
  my $news = new News;
  say $news->getAuthorString();

=head2 Static properties

Just say "C<static>" and property will the same in all objects of class.

  package News;
  use Pony::Object;
    
    public static 'default_publisher' => 'Georgy';
    public 'publisher';
    
    sub init : Public
      {
        my $this = shift;
        $this->publisher = $this->default_publisher;
      }
    
  1;



  package main;
  use News;
  
  my $n1 = new News;
  $n1->default_publisher = 'Bazhukov';
  my $n2 = new News;
  print $n1->publisher; # "Georgy"
  print $n2->publisher; # "Bazhukov"

=head1 Default methods

=head2 toHash or to_h

Get object's data structure and return this as a hash.

  package News;
  use Pony::Object;
    
    has title => 'World';
    has text => 'Hello';
    
  1;



  package main;
  use News;
  my $news = new News;
  print $news->toHash()->{text};
  print $news->to_h()->{title};

=head2 dump

Shows object's current struct.

  package News;
  use Pony::Object;
    
    has title => 'World';
    has text => 'Hello';
    
  1;



  package main;
  use News;
  my $news = new News;
  $news->text = 'Hi';
  print $news->dump();

Returns

  $VAR1 = bless( {
    'text' => 'Hi',
    'title' => 'World'
  }, 'News' );

=head2 Without Objects

If you like functions C<say>, C<dump>, C<try>/C<catch>, you can use them without creating object.
Use C<:noobject> option to enable them but do not create object/making class.

  use Pony::Object qw/:noobject :try/;
  
  my $a = {deep => [{deep => ['structure']}]};
  say dump $a;
  
  my $data = try {
    local $/;
    open my $fh, './some/file' or die;
    my $slurp = <$fh>;
    close $fh;
    return $slurp;
  } catch {
    return '';
  };
  
  say "\$data: $data";

=head1 Classes

=head2 Inheritance

You can define base classes via C<use> params.
For example, C<use Pony::Object 'Base::Class';>

  package BaseCar;
  use Pony::Object;
    
    public speed => 0;
    protected model => "Base Car";
    
    sub get_status_line : Public {
      my $this = shift;
      my $status = ($this->speed ? "Moving" : "Stopped");
      return $this->model . " " . $status;
    }
    
  1;



  package MyCar;
  # extends BaseCar
  use Pony::Object qw/BaseCar/;
    
    protected model => "My Car";
    protected color => undef;
    
    sub set_color : Public {
      my $this = shift;
      ($this->color) = @_;
    }
    
  1;



  package main;
  use MyCar;
  my $car = new MyCar;
  $car->speed = 20;
  $car->set_color("White");
  print $car->get_status_line();
  # "My Car Moving"

=head2 Singletons

Pony::Object has simple syntax for singletons . You can declare this via C<use> param;

  package Notes;
  use Pony::Object 'singleton';
    
    protected list => [];
    
    sub add : Public {
      my $this = shift;
      push @{ $this->list }, @_;
    }
    
    sub show : Public {
      my $this = shift;
      say for @{$this->list};
    }
    
    sub flush : Public {
      my $this = shift;
      $this->list = [];
    }
    
  1;



  package main;
  use Notes;
  
  my $n1 = new Notes;
  my $n2 = new Notes;
  
  $n1->add(qw/eat sleep/);
  $n1->add('Meet with Mary at 8 o`clock');
  
  $n2->flush;
  
  $n1->show();  # Print nothing.
                # Em... When I should meet Mary? 

=head2 Abstract methods and classes

You can use abstract methods and classes follows way:

  # Let's define simple interface for texts.
  package Text::Interface;
  use Pony::Object -abstract; # Use 'abstract' or '-abstract'
                              # params to define abstract class.
    
    sub getText : Abstract; # Use 'Abstract' attribute to
    sub setText : Abstract; # define abstract method.
    
  1;



  # Now we can define base class for texts.
  # It's abstract too but now it has some code.
  package Text::Base;
  use Pony::Object qw/abstract Text::Interface/;
    
    protected text => '';
    
    sub getText : Public {
      my $this = shift;
      return $this->text;
    }
    
  1;



  # In the end we can write Text class.
  package Text;
  use Pony::Object 'Text::Base';
    
    sub setText : Public {
      my $this = shift;
      $this->text = shift;
    }
  
  1;



  # Main file.
  package main;
  use Text;
  use Text::Base;
  
  my $textBase = new Text::Base;  # Raises an error!
  
  my $text = new Text;
  $text->setText('some text');
  print $text->getText();   # Returns 'some text';

Don't forget, that perl looking for functions from left to right in list of
inheritance. You should define abstract classes in the end of
Pony::Object param list.

=head2 Exceptions

See L<Pony::Object::Throwable>.

=head2 Inside

=head3 ALL

If you wanna get all default values of Pony::Object-based class,
you can call C<ALL> method. I don't know why you need them, but you can.

  package News;
  use Pony::Object;
    
    has 'title';
    has text => '';
    has authors => [ qw/Alice Bob/ ];
    
  1;



  package main;
  my $news = new News;
  print for keys %{ $news->ALL() };

=head3 META

One more internal method. It provides access to special hash C<%META>.
You can use this for Pony::Object introspection. It can be changed in next versions.

  my $news = new News;
  say dump $news->META;

=head3 $Pony::Object::DEFAULT

This is a global variable. It defines default Pony::Object's params. For example you can set
C<$Pony::Object::DEFAULT->{''}->{withExceptions} = 1> to enable exceptions
(try, catch, finally blocks) by default.
Use it carefully.

  # Startup script
  ...
  use Pony::Object;
  
  BEGIN {
    # Use exceptions by default.
    $Pony::Object::DEFAULT->{''}->{withExceptions} = 1;
    # All classes will extends Default::Base.
    $Pony::Object::DEFAULT->{''}->{baseClass} = [qw/Default::Base/];
    # All classes in namespace "Default::NoBase" will not.
    $Pony::Object::DEFAULT->{'Default::NoBase'}->{baseClass} = [];
  }
  ...

One more example:

  # Startup script
  ...
  use Pony::Object;
  
  BEGIN {
    $Pony::Object::DEFAULT->{'My::Awesome::Project'} = {
      withExceptions => 1,
      baseClass => [],
    };
    
    $Pony::Object::DEFAULT->{'My::Awesome::Project::Model'} = {
      withExceptions => 1,
      baseClass => [qw/My::Awesome::Project::Model::Abstract/],
    };
  }
  ...

=head1 SEE

=over

=item Git

L<https://github.com/bugov/pony-object>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2017, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
