package Net::Lyskom::DynamicSession;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};

=head1 NAME

Net::Lyskom::DynamicSession - dynamic session info object

=head1 SYNOPSIS

  print "This session has been idle for ",$obj->idle_time, " seconds.\n";

=head1 DESCRIPTION

=over

=item ->session()

Session number.

=item ->person()

Person number.

=item ->working_conference()

Number of working conference.

=item ->idle_time()

Number of seconds idle or number of seconds since session was created.

=item ->what_am_i_doing()

What the client says it is doing.

=item ->invisible()

This session has requested that it be invisible.

=item ->user_active_used()

True if the client has issued a C<user_active> call, which means that
the various idle-time counters count idle time rather than time since
creation.

=item ->user_absent()

This flag is not used.

=back

=cut

sub session {my $s = shift; return $s->{session}}
sub person {my $s = shift; return $s->{person}}
sub working_conference {my $s = shift; return $s->{working_conference}}
sub idle_time {my $s = shift; return $s->{idle_time}}
sub what_am_i_doing {my $s = shift; return $s->{what_am_i_doing}}

sub invisible {my $s = shift; return $s->{invisible}}
sub user_active_used {my $s = shift; return $s->{user_active_used}}
sub user_absent {my $s = shift; return $s->{user_absent}}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $res = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{session} = shift @{$res};
    $s->{person} = shift @{$res};
    $s->{working_conference} = shift @{$res};
    $s->{idle_time} = shift @{$res};
    my $flags = shift @{$res};
    $s->{what_am_i_doing} = shift @{$res};

    ($s->{invisible}, $s->{user_active_used}, $s->{user_absent})
      = $flags =~ /./g;

    return $s;
}

1;
