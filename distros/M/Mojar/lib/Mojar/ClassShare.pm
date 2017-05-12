package Mojar::ClassShare;
use strict;
use warnings;

our $VERSION = 0.011;
# Adapted from Mojo::Base::attr

use Carp 'croak';

sub import {
  my $class = shift;
  if (@_ and shift eq 'have') {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::have"} = sub { class_attr($caller, @_) };
  }
}

# Public method

sub class_attr {
  my ($class, $attrs, $default) = @_;
  return unless ($class = ref $class || $class) && $attrs;

  croak 'Default has to be a code reference or constant value'
    if ref $default && ref $default ne 'CODE';

  for my $attr (@{ref $attrs eq 'ARRAY' ? $attrs : [$attrs]}) {
    croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

    # Header (check arguments)
    my $code = "package $class;\nsub $attr {\n  no strict 'refs';\n";
    $code .= "  if (\@_ == 1) {\n";

    # No default value (return value)
    unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }

    # Default value
    else {

      # Return value
      $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

      # Return default value
      $code .= "    return \$_[0]{'$attr'} = ";
      $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
    }

    # Store value
    $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

    # Footer (return invocant)
    $code .= "  \$_[0];\n}";

    warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{MOJO_BASE_DEBUG};
    croak "Mojo::Base error: $@" unless eval "$code;1";
  }
}

1;
__END__

=head1 NAME

Mojar::ClassShare - Attributes for both class and objects

=head1 SYNOPSIS

  package Somewhere::MyClass;
  use Mojar::ClassShare 'have';
  use Mojar::Config;

  have config => sub { Mojar::Config->load('/etc/myapp.conf') };
  $target_ip = Somewhere::MyClass->config->{target_ip};

=head1 DESCRIPTION

Provides attributes that can be used as class attributes or object attributes.
When the invocant is the class name, the class's shared storage is used.  When
the invocant is an object, that object's individual storage is used.

The storage of each object and the class's share are separate from each other.

  have 'value';
  ...
  $value_to_use = $object->value // MyClass->value;  # using share as a default

(It is unusual for class defaults to be dynamic, so that example is just for
illustration.)

=head1 CAVEATS

Sometimes, perhaps during debugging, you want to know where your class
attributes are really stored.  The answer is under a hashref that has the same
name as the class, but actually resides in the namespace above.  In the synopsis
example, any class attributes are stored in a hashref called $MyClass in the
Somewhere namespace.  Personally I don't see this as a problem if I own that
namespace, but be aware that this isn't an approach everyone is going to like.

I hope it is already clear, but the shared attributes are only accessible via
the classname.  When accessed via an object, the object's individual storage is
used (so the behaviour is the same as Mojo::Base::attr).

The share is only shared within its perl interpreter.  In any environment where
there are multiple instances of perl (eg hypnotoad, apache, job queues) each
process maintains its own class shares.  If your class share is fairly static,
that usually just means you need to intialise it each time an interpreter starts
up.  But if your objects update the class share, in a multi-process setup those
updates won't be shared with objects in other processes.

=head1 SEE ALSO

This module is only useful if you want cheap class attributes.  If you only want
object attributes, please go to the upstream module L<Mojo::Base>, from which
this one is forked.  If on the other hand you think you want more sophisticated
class shares, CPAN has many modules with richer implementations.

=cut
