package Store::Opaque;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Store::Opaque', $VERSION);

1;
__END__

=head1 NAME

Store::Opaque - Opaque objects to prevent accidental Dumping or appearance in stack traces

=head1 SYNOPSIS

  package MyCreditCardInfo;
  use strict; use warnings;
  use Store::Opaque;
  our @ISA = qw(Store::Opaque);
  
  sub get_creditcard_number {
    $_[0]->_get("ccnumber")
  }
  
  sub set_creditcard_number {
    $_[0]->_set("ccnumber", $_[1])
  }
  
  1;
  # use this like any other object...

=head1 DESCRIPTION

Before you go any further, please do realize that this module is B<not
directly about security> in the sense of preventing malicious action!
It's about preventing mistakes that could turn out to be a security
or compliance issue.

Consider that you have code that handles sensitive data that should never
end up in your logs.

  use Carp;
  foo("This does not belong in logs");
  sub foo {
    my $super_sensitive = shift;
    this_can_die();
  }
  sub this_can_die {
    Carp::confess("Gotcha"); # stack trace
  }

If you're logging erros, you get this in your logs:

  Gotcha at /tmp/t.pl line 8
          main::this_can_die() called at /tmp/t.pl line 5
          main::foo('This does not belong in logs') called at /tmp/t.pl line 2

Great, not! Various techniques can be used to fix this. The easiest one is
simply using hash-based objects to store this info and pass it around.
In general, you'd pass it around as some sort of reference to prevent this.

Alas, that is easily defeated by accident if developers write stuff like this:

  sub foo {
    warn Data::Dumper->Dump(\@_); # FIXME just for debugging
    my $super_sensitive = shift;
    this_can_die();
  }

Again, there's a myriad of ways to explicitly defeat that, but I'd bring up
the more powerful Data::Dump::Streamer (in conjunction with PadWalker and
B::Deparse) next. Even inside out objects can accidentally be dumped if you're
using Data::Dump::Streamer to dump their methods.
It's becoming progressively less easy to make a mistake
like the above, but why bother?

This module implements an opaque object implementation that does not suffer from
these issues. Let me repeat. This isn't about hiding anything from an attacker.
It's about preventing mistakes from people who have legitimate access.

Oh, and don't use this for *all* of your objects as it comes with a small memory
and moderate performance overhead.

=head1 WARNING

If you do not fully understand the previous section, look elsewhere and do not
use this module.

=head1 METHODS AND USAGE

You use this module by subclassing. If that doesn't work for you, you can manually
import the methods in the class. If you don't know how that works, you shouldn't be
doing it.

Your subclass will inherit the following methods:

=head2 new

Simple constructor that takes no arguments. You can override is as follows:

  sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    # initialize here
    return $self;
  }

=head2 _set

Generic setter for the stored information:

  sub set_ccinfo {
    my $self = shift;
    my $value = shift;
    $self->_set("ccinfo", $value);
  }

where C<ccinfo> is the key to store the C<$value>
under. If this feel reminiscent of a hash, then that's not
coincidental as the object is a hash under the hood.

You can use any string has a key that would otherwise work
in a normal hash-based object.

=head2 _get

Generic accessor for the stored information. Works just liek C<_set>
without the C<$value>.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
