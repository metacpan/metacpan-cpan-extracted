use strict;
use warnings;
package Pod::Coverage::TrustPod;
$Pod::Coverage::TrustPod::VERSION = '0.100005';
use base 'Pod::Coverage::CountParents';
# ABSTRACT: allow a module's pod to contain Pod::Coverage hints

use Pod::Find qw(pod_where);
use Pod::Eventual::Simple;

#pod =head1 DESCRIPTION
#pod
#pod This is a Pod::Coverage subclass (actually, a subclass of
#pod Pod::Coverage::CountParents) that allows the POD itself to declare certain
#pod symbol names trusted.
#pod
#pod Here is a sample Perl module:
#pod
#pod   package Foo::Bar;
#pod
#pod   =head1 NAME
#pod
#pod   Foo::Bar - a bar at which fooes like to drink
#pod
#pod   =head1 METHODS
#pod
#pod   =head2 fee
#pod
#pod   returns the bar tab
#pod
#pod   =cut
#pod
#pod   sub fee { ... }
#pod
#pod   =head2 fie
#pod
#pod   scoffs at bar tab
#pod
#pod   =cut
#pod
#pod   sub fie { ... }
#pod
#pod   sub foo { ... }
#pod
#pod   =begin Pod::Coverage
#pod
#pod     foo
#pod
#pod   =end Pod::Coverage
#pod
#pod   =cut
#pod
#pod This file would report full coverage, because any non-empty lines inside a
#pod block of POD targeted to Pod::Coverage are treated as C<trustme> patterns.
#pod Leading and trailing whitespace is stripped and the remainder is treated as a
#pod regular expression anchored at both ends.
#pod
#pod Remember, anywhere you could use C<=begin> and C<=end> as above, you could
#pod instead write:
#pod
#pod   =for Pod::Coverage foo
#pod
#pod In some cases, you may wish to make the entire file trusted.  The special
#pod pattern C<*EVERYTHING*> may be provided to do just this.
#pod
#pod Keep in mind that Pod::Coverage::TrustPod sets up exceptions using the "trust"
#pod mechanism rather than the "privacy" mechanism in Pod::Coverage.  This is
#pod unlikely ever to matter to you, but it's true.
#pod
#pod =cut

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

  my @trusted;
  for my $hunk (@hunks) {
    my $line = defined $hunk->{start_line} ? $hunk->{start_link} : '?';

    my @patterns = grep { s/^\s+//; s/\s+$//; /\S/ }
                   split /\s/m, $hunk->{content};

    PATTERN: for my $pattern (@patterns) {
      my $qr;

      if ($pattern eq q{*EVERYTHING*}) {
        $collect->{$pattern} = qr{.?};
        next PATTERN;
      }

      my $ok = eval { $qr = qr{\A$pattern\z}; 1 };
      Carp::croak("can't compile Pod::Coverage::TrustPod regex /$pattern/ at $file, line $line")
        unless $ok;

      $collect->{$pattern} = $qr;
    }
  }

  $self->__get_pod_trust($_, $collect) for @parents;

  return $collect;
}

sub _trustme_check {
  my ($self, $sym) = @_;

  my $from_pod = $self->{_trust_from_pod} ||= $self->__get_pod_trust(
    $self->{package},
    {}
  );

  return 1 if $self->SUPER::_trustme_check($sym);
  return 1 if grep { $sym =~ $_ } values %$from_pod;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::TrustPod - allow a module's pod to contain Pod::Coverage hints

=head1 VERSION

version 0.100005

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

=head1 CONTRIBUTOR

=for stopwords Andreas Marienborg

Andreas Marienborg <andreas.marienborg@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
