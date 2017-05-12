use strict;
use warnings;
package Pod::Coverage::TrustPod;
{
  $Pod::Coverage::TrustPod::VERSION = '0.100003';
}
use base 'Pod::Coverage::CountParents';
# ABSTRACT: allow a module's pod to contain Pod::Coverage hints

use Pod::Find qw(pod_where);
use Pod::Eventual::Simple;


sub __get_pod_trust {
  my ($self, $package, $collect) = @_;

  my @parents;
  {
    no strict 'refs';
    @parents = @{"$package\::ISA"};
  }

  return $collect unless my $file = pod_where( { -inc => 1 }, $package );

  my $output = Pod::Eventual::Simple->read_file($file);

  my @hunks = grep {;
    no warnings 'uninitialized';
    ((($_->{command} eq 'begin' and $_->{content} =~ /^Pod::Coverage\b/)
    ...
    ($_->{command} eq 'end' and $_->{content} =~ /^Pod::Coverage\b/))
    and $_->{type} =~ m{\Averbatim|text\z})
    or
    $_->{command} eq 'for' and $_->{content} =~ s/^Pod::Coverage\b//
  } @$output;

  my @trusted =
    grep { s/^\s+//; s/\s+$//; /\S/ }
    map  { split /\s/m, $_->{content} } @hunks;

  $collect->{$_} = 1 for @trusted;

  $self->__get_pod_trust($_, $collect) for @parents;

  return $collect;
}

sub _trustme_check {
  my ($self, $sym) = @_;

  my $from_pod = $self->{_trust_from_pod} ||= $self->__get_pod_trust(
    $self->{package},
    {}
  );

  return 1 if $from_pod->{'*EVERYTHING*'};
  return 1 if $self->SUPER::_trustme_check($sym);
  return 1 if grep { $sym =~ /\A$_\z/ } keys %$from_pod;
  return;
}

1;

__END__

=pod

=head1 NAME

Pod::Coverage::TrustPod - allow a module's pod to contain Pod::Coverage hints

=head1 VERSION

version 0.100003

=head1 DESCRIPTION

This is a Pod::Coverage subclass (actually, a subclass of
Pod::Coverage::CountParents) that allows the POD itself to declare certain
symbol names trusted.

Here is a sample Perl module:

  package Foo::Bar;

  =head1 NAME

  Foo::Bar - a bar at which fooes like to drink

  =head1 METHODS

  =head2 fee

  returns the bar tab

  =cut

  sub fee { ... }

  =head2 fie

  scoffs at bar tab

  =cut

  sub fie { ... }

  sub foo { ... }

  =begin Pod::Coverage

    foo

  =end Pod::Coverage

  =cut

This file would report full coverage, because any non-empty lines inside a
block of POD targeted to Pod::Coverage are treated as C<trustme> patterns.
Leading and trailing whitespace is stripped and the remainder is treated as a
regular expression anchored at both ends.

Remember, anywhere you could use C<=begin> and C<=end> as above, you could
instead write:

  =for Pod::Coverage foo

In some cases, you may wish to make the entire file trusted.  The special
pattern C<*EVERYTHING*> may be provided to do just this.

Keep in mind that Pod::Coverage::TrustPod sets up exceptions using the "trust"
mechanism rather than the "privacy" mechanism in Pod::Coverage.  This is
unlikely ever to matter to you, but it's true.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
