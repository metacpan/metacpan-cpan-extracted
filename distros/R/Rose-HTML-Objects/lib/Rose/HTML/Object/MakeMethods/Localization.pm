package Rose::HTML::Object::MakeMethods::Localization;

use strict;

use Carp();

use base 'Rose::Object::MakeMethods';

our $VERSION = '0.615';

sub localized_message
{
  my($class, $name, $args, $opts) = @_;

  my %methods;

  my $interface = $args->{'interface'} || 'get_set';
  my $key       = $args->{'hash_key'} || $name;
  my $id_method = $args->{'msg_id_method'} || $key . '_message_id';

  my $accept_msg_class = $args->{'accept_msg_class'} || 'Rose::HTML::Object::Message';

  require Rose::HTML::Object::Message::Localized;

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        if(@_ > 1)
        {
          my($id) = shift;

          my @args;

          if(@_ == 1 && ref($_[0]) =~ /^(?:HASH|ARRAY)$/)
          {
            @args = (args => $_[0]);
          }
          else
          {
            @args = (args => [ @_ ]);
          }

          unless($id =~ /^\d+$/)
          {
            $id = $self->localizer->get_message_id($id) || 
              Carp::croak "Unknown message id: '$id'";
          }

          return $self->$name($self->localizer->message_class->new(id => $id, parent => $self, @args));
        }

        my $msg = shift;

        if(UNIVERSAL::isa($msg, $accept_msg_class))
        {
          $msg->parent($self);
          return $self->{$key} = $msg;
        }
        else
        {
          return $self->{$key} = $self->localizer->message_class->new(text => $msg, parent => $self);
        }
      }

      return $self->{$key};
    };

    $methods{$id_method} = sub
    {
      my($self) = shift;

      if(@_)
      {
        my($id, @args) = @_;
        return $self->$name(undef)  unless(defined $id);
        return $self->$name($self->localizer->message_class->new(id => $id, args => \@args, parent => $self));
      }

      my $error = $self->$name();
      return $error->id  if(UNIVERSAL::can($error, 'id'));
      return undef;
    };  
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub localized_error
{
  my($class, $name, $args) = @_;

  my %methods;

  my $interface   = $args->{'interface'} || 'get_set';
  my $key         = $args->{'hash_key'} || $name;
  my $id_method   = $args->{'error_id_method'} || $key . '_id';

  my $accept_error_class = $args->{'accept_error_class'} || 'Rose::HTML::Object::Error';

  require Rose::HTML::Object::Error;

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        return $self->{$key} = undef  unless(defined $_[0]);

        my $localizer = $self->localizer;

        if(@_ > 1)
        {
          my($id) = shift;

          my @args;

          if(@_ == 1 && ref($_[0]) =~ /^(?:HASH|ARRAY)$/)
          {
            @args = (args => $_[0]);
          }
          else
          {
            @args = (args => [ @_ ]);
          }

          unless($id =~ /^\d+$/)
          {
            $id = $self->localizer->get_error_id($id) || 
              Carp::croak "Attempt to call $name() with more than one ",
                          "argument, and the first argument is not a numeric ",
                          "error id: '$id'";
          }

          unshift(@args, error_id => $id);

          my $message;

          if($self->can('message_for_error_id'))
          {
            $message = $self->message_for_error_id(@args);

            unless(defined $message)
            {
              $message = $localizer->message_for_error_id(@args);
            }
          }
          else
          {
            $message = $localizer->message_for_error_id(@args);
          }


          return $self->$name($localizer->error_class->new(id      => $id, 
                                                           parent  => $self,
                                                           message => $message));
        }

        my $error = shift;

        if(UNIVERSAL::isa($error, $accept_error_class))
        {
          $error->parent($self);
          return $self->{$key} = $error;
        }
        elsif(defined $error)
        {
          return $self->{$key} = 
            $localizer->error_class->new(message => $localizer->messsage_class->new($error), 
                                         parent  => $self);
        }
      }

      return $self->{$key};
    };

    $methods{$id_method} = sub
    {
      my($self) = shift;

      if(@_)
      {
        my($id) = shift;

        my $localizer = $self->localizer;

        my @args;

        if(@_ == 1 && ref($_[0]) =~ /^(?:HASH|ARRAY)$/)
        {
          @args = (args => $_[0]);
        }
        else
        {
          @args = (args => [ @_ ]);
        }

        unless($id =~ /^\d+$/)
        {
          $id = $localizer->get_error_id($id) || 
            Carp::croak "Unknown error id: '$id'";
        }

        unshift(@args, error_id => $id);

        my $message;

        if($self->can('message_for_error_id'))
        {
          $message = $self->message_for_error_id(@args);

          unless(defined $message)
          {
            $message = $localizer->message_for_error_id(@args);
          }
        }
        else
        {
          $message = $localizer->message_for_error_id(@args);
        }


        return $self->$name($localizer->error_class->new(id      => $id, 
                                                         parent  => $self,
                                                         message => $message));
      }

      my $error = $self->$name();
      return $error->id  if(UNIVERSAL::can($error, 'id'));
      return undef;
    };

  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub localized_errors
{
  my($class, $name, $args) = @_;

  my %methods;

  my $interface      = $args->{'interface'} || 'get_set';
  my $key            = $args->{'hash_key'} || $name;
  my $plural_name    = $args->{'plural_name'} || $name;
  my $singular_name  = $args->{'singular_name'} || plural_to_singular($plural_name);
  my $has_method     = $args->{'has_error_method'} || 'has_' . $plural_name;
  my $has_method2    = $args->{'has_errors_method'} || 'has_' . $singular_name;
  my $add_method     = $args->{'add_error_method'} || 'add_' . $singular_name;
  my $adds_method    = $args->{'add_errors_method'} || 'add_' . $plural_name;
  my $id_method      = $args->{'error_id_method'} || $singular_name . '_id';
  my $ids_method     = $args->{'error_ids_method'} || $singular_name . '_ids';
  my $add_id_method  = $args->{'add_error_id_method'} || 'add_' . $singular_name . '_id';
  my $add_ids_method = $args->{'add_error_ids_method'} || 'add_' . $singular_name . '_ids';

  my $accept_error_class = $args->{'accept_error_class'} || 'Rose::HTML::Object::Error';

  require Rose::HTML::Object::Error;

  if($interface eq 'get_set')
  {
    $methods{$plural_name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        if(!defined $_[0] || (ref $_[0] eq 'ARRAY' && !@{$_[0]}))
        {
          return $self->{$key} = undef;
        }

        $self->{$key} = undef;
        $self->$adds_method(@_);
      }

      return wantarray ? @{$self->{$key} || []} : $self->{$key};
    };

    $methods{$singular_name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        return $self->{$key} = undef  unless(defined $_[0]);

        my $localizer = $self->localizer;

        if(@_ > 1)
        {
          my($id) = shift;

          my @args;

          if(@_ == 1 && ref($_[0]) =~ /^(?:HASH|ARRAY)$/)
          {
            @args = (args => $_[0]);
          }
          else
          {
            @args = (args => [ @_ ]);
          }

          unless($id =~ /^\d+$/)
          {
            $id = $localizer->get_error_id($id) || 
              Carp::croak "Attempt to call $singular_name() with more than one ",
                          "argument, and the first argument is not a numeric ",
                          "error id: '$id'";
          }

          unshift(@args, error_id => $id);

          my $message;

          if($self->can('message_for_error_id'))
          {
            $message = $self->message_for_error_id(@args);

            unless(defined $message)
            {
              $message = $localizer->message_for_error_id(@args);
            }
          }
          else
          {
            $message = $localizer->message_for_error_id(@args);
          }

          $self->{$key} = 
            [ $localizer->error_class->new(id => $id, parent => $self, message => $message) ];

          return $self->{$key}[-1];
        }

        my $error = shift;

        if(UNIVERSAL::isa($error, $accept_error_class))
        {
          $error->parent($self);
          $self->{$key} = [ $error ];
        }
        elsif(defined $error)
        {
          $self->{$key} = 
            [ $localizer->error_class->new(message => $localizer->message_class->new($error), parent => $self) ];
        }
      }

      return $self->{$key}[-1];
    };

    $methods{$adds_method} = sub
    {
      my($self) = shift;

      return  unless(@_);

      my $localizer = $self->localizer;
      my $errors = __errors_from_args($self, \@_, $localizer->error_class, $localizer->message_class, $accept_error_class, 0, 0);

      push(@{$self->{$key}}, @$errors);  

      return wantarray ? @$errors : $errors;
    };

    $methods{$add_method} = sub
    {
      my($self) = shift;

      return  unless(@_);

      my $localizer = $self->localizer;
      my $errors = __errors_from_args($self, \@_, $localizer->error_class, $localizer->message_class, $accept_error_class, 0, 1);

      push(@{$self->{$key}}, @$errors);

      return wantarray ? @$errors : $errors;
    };

    $methods{$id_method} = sub
    {
      my($self) = shift;

      if(@_)
      {
        my $localizer = $self->localizer;
        my $errors = __errors_from_args($self, \@_, $localizer->error_class, $localizer->message_class, $accept_error_class, 1, 1);
        $self->{$key} = $errors;
        return $errors->[-1]->id;
      }

      return $self->{$key}[-1] ? $self->{$key}[-1]->id : undef;
    };

    $methods{$ids_method} = sub
    {
      my($self) = shift;

      if(@_)
      {
        my $localizer = $self->localizer;
        my $errors = __errors_from_args($self, \@_, $localizer->error_class, $localizer->message_class, $accept_error_class, 1, 0);
        $self->{$key} = $errors;
        return wantarray ? @$errors : $errors;
      }

      if(defined(my $want = wantarray))
      {
        my @ids = map { $_->id } @{$self->{$key} || []};
        return $want ? @ids : \@ids;
      }

      return;
    };

    $methods{$add_ids_method} = sub
    {
      my($self) = shift;

      return  unless(@_);

      my $localizer = $self->localizer;
      my $errors = __errors_from_args($self, \@_, $localizer->error_class, $localizer->message_class, $accept_error_class, 1, 1);

      push(@{$self->{$key}}, @$errors);  

      if(defined(my $want = wantarray))
      {
        my @ids = map { $_->id } @$errors;
        return $want ? @ids : \@ids;
      }

      return;
    };

    $methods{$add_id_method} = sub
    {
      my($self) = shift;

      return  unless(@_);

      my $localizer = $self->localizer;
      my $errors = __errors_from_args($self, \@_, $localizer->error_class, $localizer->message_class, $accept_error_class, 1, 0);

      push(@{$self->{$key}}, @$errors);  

      if(defined(my $want = wantarray))
      {
        my @ids = map { $_->id } @$errors;
        return $want ? @ids : \@ids;
      }

      return;
    };

    $methods{$has_method}  = sub { scalar @{shift->{$key} || []} };
    $methods{$has_method2} = $methods{$has_method};
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub plural_to_singular
{
  my($word) = shift;
  return $word  if($word =~ /[aeiouy]ss$/i);
  $word =~ s/s$//;
  return $word;
}

# Acceptable formats:
#
# <error object>, ...
# <numeric error id> (id method only)
# <list of numeric error ids> (non-singular id method only)
# <numeric error id> <list of args> (singular only)
# <numeric error id> <arrayref of args>, ...
# <numeric error id> <hashref of args>, ...
sub __errors_from_args
{
  my($self, $args, $error_class, $msg_class, $accept_error_class, $id_method, $singular) = @_;

  local $Carp::CarpLevel = 1;

  $args = $args->[0]  if(@$args == 1 && ref($args->[0]) eq 'ARRAY');

  my @errors;

  my $localizer = $self->localizer;

  for(my $i = 0; $i <= $#$args; $i++)
  {
    my $arg = $args->[$i];

    if(UNIVERSAL::isa($arg, $accept_error_class))
    {
      $arg->parent($self);
      push(@errors, $arg);
      next;
    }

    my $id = $arg;

    if($id_method && $id !~ /^\d+$/)
    {
      $id = $localizer->get_error_id($id) || 
        Carp::croak "Unknown error id: '$id'";
    }

    my @msg_args;

    if(ref($args->[$i + 1]) =~ /^(?:HASH|ARRAY)$/)
    {
      @msg_args = (args => $args->[++$i]);
    }
    elsif($singular && ($i + 1) < $#$args)
    {
      @msg_args = (args => [ @$args[$i + 1 .. $#$args] ]);
      $i = $#$args;
    }

    unshift(@msg_args, error_id => $id, msg_class => $msg_class);

    my $message;

    if($id =~ /^\d+$/)
    {
      if($self->can('message_for_error_id'))
      {
        $message = $self->message_for_error_id(@msg_args);

        unless(defined $message)
        {
          $message = $localizer->message_for_error_id(@msg_args);
        }
      }
      else
      {
        $message = $localizer->message_for_error_id(@msg_args);
      }

      push(@errors, $error_class->new(id       => $id,
                                      message  => $message, 
                                      parent   => $self));
    }
    else
    {
      push(@errors, $error_class->new(message => $msg_class->new($id), 
                                      parent  => $self));
    }
  }

  return \@errors;
}

1;
