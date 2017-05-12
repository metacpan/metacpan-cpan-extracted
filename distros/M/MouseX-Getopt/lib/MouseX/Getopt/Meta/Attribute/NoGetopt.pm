package MouseX::Getopt::Meta::Attribute::NoGetopt;
# ABSTRACT: Optional meta attribute for ignoring params

use Mouse;

extends 'Mouse::Meta::Attribute'; # << Mouse extending Mouse :)
   with 'MouseX::Getopt::Meta::Attribute::Trait::NoGetopt';

no Mouse;

# register this as a metaclass alias ...
package # stop confusing PAUSE
    Mouse::Meta::Attribute::Custom::NoGetopt;
sub register_implementation { 'MouseX::Getopt::Meta::Attribute::NoGetopt' }

1;

=for stopwords metaclass commandline

=head1 SYNOPSIS

  package App;
  use Mouse;

  with 'MouseX::Getopt';

  has 'data' => (
      metaclass => 'NoGetopt',  # do not attempt to capture this param
      is        => 'ro',
      isa       => 'Str',
      default   => 'file.dat',
  );

=head1 DESCRIPTION

This is a custom attribute metaclass which can be used to specify
that a specific attribute should B<not> be processed by
C<MouseX::Getopt>. All you need to do is specify the C<NoGetopt>
metaclass.

  has 'foo' => (metaclass => 'NoGetopt', ... );

=cut
