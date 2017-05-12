package MouseX::Getopt::Meta::Attribute::Trait::NoGetopt;
# ABSTRACT: Optional meta attribute trait for ignoring params

use Mouse::Role;
no Mouse::Role;

# register this as a metaclass alias ...
package # stop confusing PAUSE
    Mouse::Meta::Attribute::Custom::Trait::NoGetopt;
sub register_implementation { 'MouseX::Getopt::Meta::Attribute::Trait::NoGetopt' }

1;

=for stopwords metaclass commandline

=head1 SYNOPSIS

  package App;
  use Mouse;

  with 'MouseX::Getopt';

  has 'data' => (
      traits  => [ 'NoGetopt' ],  # do not attempt to capture this param
      is      => 'ro',
      isa     => 'Str',
      default => 'file.dat',
  );

=head1 DESCRIPTION

This is a custom attribute metaclass trait which can be used to
specify that a specific attribute should B<not> be processed by
C<MouseX::Getopt>. All you need to do is specify the C<NoGetopt>
metaclass trait.

  has 'foo' => (traits => [ 'NoGetopt', ... ], ... );

=cut
