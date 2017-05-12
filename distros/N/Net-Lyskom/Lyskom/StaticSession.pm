package Net::Lyskom::StaticSession;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};
use Net::Lyskom::Time;

=head1 NAME

Net::Lyskom::StaticSession - static session information object

=head1 SYNOPSIS

  print "This session came from the host ", $obj->hostname, ".\n";

=head1 DESCRIPTION

=over

=item ->username()

The name of the "real" user.

=item ->hostname()

The hostname the connection came from.

=item ->ident_user()

The username as given by the client host ident daemon.

=item ->connection_time()

The time when the connection was initiated. Returns a
C<Net::Lyskom::Time> object.

=back

=cut

sub username {my $s = shift; return $s->{username}}
sub hostname {my $s = shift; return $s->{hostname}}
sub ident_user {my $s = shift; return $s->{ident_user}}
sub connection_time {my $s = shift; return $s->{connection_time}}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{username} = shift @{$ref};
    $s->{hostname} = shift @{$ref};
    $s->{ident_user} = shift @{$ref};
    $s->{connection_time} = Net::Lyskom::Time->new_from_stream($ref);

    return $s;
}

1;
