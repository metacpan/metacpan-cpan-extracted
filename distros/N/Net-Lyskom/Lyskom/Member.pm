package Net::Lyskom::Member;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Time;

=head1 NAME

Net::Lyskom::Member - object holding member information

=head1 SYNOPSIS

  print "User was added at ",$obj->added_at->as_string, ".\n";

=head1 DESCRIPTION

=over

=item ->member()

Person number of member.

=item ->added_by()

Person number of person who added the member.

=item ->added_at()

Timestamp when member was added.

=item ->invitation()

Member is invited.

=item ->passive()

Member is a passive member.

=item ->secret()

Member is a secret member.

=back

=cut

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s, $class;

    $s->{member} = shift @{$ref};
    $s->{added_by} = shift @{$ref};
    $s->{added_at} = Net::Lyskom::Time->new_from_stream($ref);
    my $type = shift @{$ref};

    ($s->{invitation}, $s->{passive}, $s->{secret}) =
      $type =~ /./g;

    return $s;
}

sub member {my $s = shift; return $s->{member}}
sub added_by {my $s = shift; return $s->{added_by}}
sub added_at {my $s = shift; return $s->{added_at}}

sub invitation {my $s = shift; return $s->{invitation}}
sub passive {my $s = shift; return $s->{passive}}
sub secret {my $s = shift; return $s->{secret}}

1;
