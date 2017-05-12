# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Sub-Chain
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Sub::Chain::Named;
BEGIN {
  $Sub::Chain::Named::VERSION = '0.012';
}
BEGIN {
  $Sub::Chain::Named::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: subclass of Sub::Chain with named subs

use Carp qw(croak);
use Sub::Chain;
our @ISA = qw(Sub::Chain);


sub new {
  my $class = shift;
  my %opts = ref $_[0] ? %{$_[0]} : @_;
  my $subs = delete $opts{subs};

  my $self = $class->SUPER::new(%opts);
  $self->{named} = $subs || {};

  return $self;
}


sub append {
  my ($self, $name, @append) = @_;
  my $sub = $self->{named}{$name}
    or croak("No sub defined for name: $name");
  $self->SUPER::append($sub, @append);
}


sub name_subs {
  my ($self) = shift;
  my %subs = ref $_[0] ? %{$_[0]} : @_;

  # TODO: warn if already exists?
  @{ $self->{named} }{keys %subs} = values %subs;

  # chainable
  return $self;
}

1;


__END__
=pod

=for :stopwords Randy Stauner

=head1 NAME

Sub::Chain::Named - subclass of Sub::Chain with named subs

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  my $chain = Sub::Chain::Named->new(subs => {name1 => \&sub1});
  $chain->name_subs(name2 => \&sub2, name3 => \&sub3);

  # ...

  $chain->append($name, \@args, \%opts);

=head1 DESCRIPTION

This is a subclass of L<Sub::Chain>.
It stores a list of named subs
and then accepts the name as an argument to L</append>
(instead of the coderef).

This can simplify things if, for example,
you are taking the list of subs dynamically from file input.

=head1 METHODS

=head2 new

  my $chain = Sub::Chain::Named->new(
    subs => {
      action => sub {},
    }
  );

Instantiate a L<Sub::Chain> instance
with a collection of named subs.

A hashref of C<< name => \&sub >> pairs can be passed
as the C<subs> option.

See L<Sub::Chain/new> for more information.

=head2 append

  $named->append($sub_name);
  $named->append($sub_name, \@args, \%opts);

Just like L<Sub::Chain/append>
except that C<$sub_name> is a string
which is converted to the corresponding sub
and then passed to L<Sub::Chain/append>.

=head2 name_subs

  $named->name_subs(goober => \&peant_butter);

Add named subs to the collection.
Takes a hash (or hashref),
or just a single name and a value (a small hash).

=for test_synopsis my ($name, @args, %opts);

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

