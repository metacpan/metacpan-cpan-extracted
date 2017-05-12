use strict;
use warnings;

package Pad::Tie::Plugin;

use Data::OptList;
use Carp ();

sub provides {
  Carp::confess "subclass $_[0] did not override virtual method 'provides'";
}

# input: ( [ foo => { -as => 'bar' } ], ... )
# return: { foo => 'bar', ... }
sub canon_args {
  my ($plugin, $args) = @_;

  my %n;
  my @args = @{ Data::OptList::mkopt($args) };
  for (@args) {
    my ($method, $xtra) = @$_;
    my $name = $xtra->{-as} || $method;
    #$name = "$xtra->{-prefix}$name" if $xtra->{-prefix};
    $n{$method} = $name;
  }
  return \%n;
}

1;  

__END__
=head1 NAME

Pad::Tie::Plugin - base class for method personalities

=head1 SYNOPSIS

  package Pad::Tie::Plugin::Mine;

  sub provides { 'mine' }

  sub mine {
    my ($plugin, $ctx, $self, $args) = @_;
    # put some stuff into $ctx
  }

=head1 DESCRIPTION

Pad::Tie::Plugin is a convenient place to put common method personality
functionality.

There's no practical reason that your plugin needs to inherit from
Pad::Tie::Plugin, but it should anyway, for the sake of future-proofing.

Your plugin should have two or more methods:

=over

=item * provides

This method should return a list of method personality names handled by this
plugin.

=item * (your method personality names)

Each of these methods will be called whenever a new Pad::Tie object is created.
It will be called with the plugin (since it is a method) and 3 additional
arguments: the context, the invocant, and whatever the argument was in the
original method configuration.  See
L<Lexical::Persistence|Lexical::Persistence> for details about the context,
L<Pad::Tie|Pad::Tie> for the others, and L</SYNOPSIS> for an example.

=head1 METHODS

=head2 canon_args

  my $args = $plugin->canon_args($args);

Given an arrayref of arrayrefs, each of which represents a method name and
possible arguments, return a hashref of method name to lexical variable.

A few special arguments are accepted:

=over

=item * -as

Instead of using the given method name, use this value

=back

(more options will be added as I think of them)

For example, this transformation would be done:

  [
    [ 'foo' ],
    [ 'bar' => { -as => 'baz' } ],
  ],

to

  {
    foo => 'foo',
    bar => 'baz',
  }

If your plugin doesn't want to take arguments, or doesn't want to handle them
as method names, you don't need to use this method, but it is handy to have.

=head1 TODO

plugin subclass for variables tied to methods

=head1 SEE ALSO

L<Pad::Tie>

=cut
