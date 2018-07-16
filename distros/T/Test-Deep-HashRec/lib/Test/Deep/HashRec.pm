use strict;
use warnings;

package Test::Deep::HashRec;
# ABSTRACT:  test hash entries for required and optional fields
$Test::Deep::HashRec::VERSION = '0.001';
#pod =func hashrec
#pod
#pod   cmp_deeply(
#pod     $got,
#pod     hashrec({
#pod       required => { count => any(1,2,3), b => ignore() },
#pod       optional => { name  => { first => ignore(), last => ignore() } },
#pod     }),
#pod     "we got a valid record",
#pod   );
#pod
#pod C<hashrec> returns a Test::Deep comparator that asserts that:
#pod
#pod =for :list
#pod * all required elements are present
#pod * nothing other than required and optional elements are present
#pod * all present elements match the comparator given for them
#pod
#pod If you pass a true C<allow_unknown> argument, then unknown elements will be
#pod permitted, and their values ignored.
#pod
#pod =cut

use Exporter 'import';

our @EXPORT = qw(hashrec);

sub hashrec { Test::Deep::HashRec::Object->new(@_) };

package
  Test::Deep::HashRec::Object {

use Test::Deep::Cmp;
use Test::Deep::HashElements;

sub init {
  my ($self, $val) = @_;

  Carp::confess("argument to hashrec must be a hash reference")
    unless ref $val eq 'HASH';

  my %copy = %$val;

  $self->{required}       = delete $copy{required} || {};
  $self->{optional}       = delete $copy{optional} || {};
  $self->{allow_unknown}  = delete $copy{allow_unknown};

  $self->{is_permitted} = {
    map {; $_ => 1 } (keys %{ $self->{required} }, keys %{ $self->{optional} })
  };

  $self->{diagnostics} = [];

  Carp::confess("unknown arguments to hashrec: " . join q{, }, keys %copy)
    if keys %copy;

  my @dupes = grep {; exists $self->{required}{$_} }
              keys %{ $self->{optional} };

  Carp::confess("Keys found in both optional and required: @dupes")
    if @dupes;

  return;
}

sub diagnostics {
  my ($self, $where, $last) = @_;

  my $error = $self->{diag} =~ s/^/  /rgm;
  my $diag  = <<EOM;
In hash record $where
$error
EOM

  return $diag;
}

sub descend {
  my ($self, $got) = @_;

  undef $self->{diag};

  unless (ref $got eq 'HASH') {
    $self->{diag} = "Didn't get a hash reference";
    return
  }

  my @keys = keys %$got;

  my @errors;

  unless ($self->{allow_unknown}) {
    my @unknown = grep {; ! exists $self->{is_permitted}{$_} } @keys;
    if (@unknown) {
      push @errors, "Unknown keys found: @unknown";
    }
  }

  if (my @missing = grep {; ! exists $got->{$_} } keys %{ $self->{required}}) {
    push @errors, "Missing required keys: @missing";
  }

  if (@errors) {
    $self->{diag} = join qq{\n}, @errors;
    return;
  }

  my %effective = (
    map   {; $_ => ($self->{required}{$_} // $self->{optional}{$_}) }
    grep  {; $self->{is_permitted}{$_} }
    keys %$got
  );

  return Test::Deep::descend(
    $got,
    Test::Deep::HashElements->new(\%effective),
  );
}

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::HashRec - test hash entries for required and optional fields

=head1 VERSION

version 0.001

=head1 FUNCTIONS

=head2 hashrec

  cmp_deeply(
    $got,
    hashrec({
      required => { count => any(1,2,3), b => ignore() },
      optional => { name  => { first => ignore(), last => ignore() } },
    }),
    "we got a valid record",
  );

C<hashrec> returns a Test::Deep comparator that asserts that:

=over 4

=item *

all required elements are present

=item *

nothing other than required and optional elements are present

=item *

all present elements match the comparator given for them

=back

If you pass a true C<allow_unknown> argument, then unknown elements will be
permitted, and their values ignored.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
