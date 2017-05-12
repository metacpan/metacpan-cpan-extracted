package Sub::Clean;

# attribute handing requires 5.008
use 5.008;

use strict;
use warnings;

our $VERSION = 1.00;

# load all the magic
use Sub::Identify qw(sub_name);
require Attribute::Lexical;
use B::Hooks::EndOfScope;
use namespace::clean;

sub _cleaner  {
  my ($uboat, undef, undef, $state) = @_;
  on_scope_end {
    namespace::clean->clean_subroutines($state->[0],sub_name($uboat));
  }
};

sub import {
  Attribute::Lexical->import("CODE:Cleaned" => \&_cleaner);
  return;
}

1;

__END__

=head1 NAME

Sub::Clean - Clean subroutines with an attribute

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Sub::Clean;
  
  sub whatever :Cleaned {
    return "This cannot be called as a method";
  }

=head1 DESCRIPTION

This module 'cleans' subroutines you mark with the C<Cleaned> attribute,
preventing them being called from places they haven't been already been
bound by the perl compiler.

The main advantage in this is that you can declare subroutines and use them
in your code as functions, but prevent them from being called as a method.
This is particularly useful if your superclass (maybe unbeknownst to you)
has a method of the same name as the function which would normally be
'shadowed' by your method.

For example, this:

  package Banner;
  
  sub text { "example text\n" }
  sub bar  { "-"x20 . "\n" }
  
  sub message {
    my $class = shift;
    return $class->bar . $class->text . $class->bar
  }
  
  package PubBanner;
  use base qw(Banner);
  use Sub::Clean;
  
  sub text { bar() . "\n" }
  
  sub bar :Cleaned { 
    return (("Cheers","Quark's","Moe's")[rand(3)])
  }
  
  package main;
  print PubBanner->message();

Print out the right thing:

  --------------------
  Moe's
  --------------------

Rather than just printing three horizontal lines.

=head2 Lexical Scope

Please note that this module enables the C<Cleaned> attribute only in lexical
scope of the C<use Sub::Clean> statement.  This prevents namespace pollution.

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2010.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests through the web
interface at http://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Clean

=head1 AVAILABILITY

The latest version of this module is available from the
Comprehensive Perl Archive Network (CPAN). 
isit http://www.perl.com/CPAN/ to find a CPAN site near you,
or see http://search.cpan.org/dist/Sub-Clean/

The development version lives at http://github.com/2shortplanks/Sub-Clean/.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 SEE ALSO

L<namespace::clean> allows you to clean your namespace by dividing your
code up into sections that should be cleaned or not cleaned.

L<namespace::autoclean> automatically can clean imported subroutines
from other namespaces.

L<Lexical::Sub> allows you to declare subroutines that only exist in
lexical scope.

L<Attribute::Lexical> was used to create lexical attributes.

=cut