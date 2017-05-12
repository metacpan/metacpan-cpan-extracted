package Net::Lyskom::Membership;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Time;
use Net::Lyskom::Util qw{:all};

=head1 NAME

Net::Lyskom::Membership - conference membership information object

=head1 SYNOPSIS

  print "The last text this user read was ", $obj->last_text_read;

=head1 DESCRIPTION

All this object's methods are read-only and take no arguments. For
details on the meaning of the returned information, see the protocol spec.

=head2 Methods

=over

=item ->position()

=item ->last_time_read()

Returns a L<Net::Lyskom::Time> object.

=item ->conference()

=item ->priority()

=item ->last_text_read()

=item ->read_texts()

Returns a list.

=item ->added_by()

=item ->added_at()

Returns a L<Net::Lyskom::Time> object.

=item ->invitation()

=item ->passive()

=item ->secret()

=back

=cut

#' Stupid XEmacs...

sub position {my $s=shift; return $s->{position}}
sub last_time_read {my $s=shift; return $s->{last_time_read}}
sub conference {my $s=shift; return $s->{conference}}
sub priority {my $s=shift; return $s->{priority}}
sub last_text_read {my $s=shift; return $s->{last_text_read}}
sub read_texts {my $s=shift; return @{$s->{read_texts}}}
sub added_by {my $s=shift; return $s->{added_by}}
sub added_at {my $s=shift; return $s->{added_at}}

sub invitation {my $s=shift; return $s->{invitation}}
sub passive {my $s=shift; return $s->{passive}}
sub secret {my $s=shift; return $s->{secret}}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{position} = shift @{$ref};
    $s->{last_time_read} = Net::Lyskom::Time->new_from_stream($ref);
    $s->{conference} = shift @{$ref};
    $s->{priority} = shift @{$ref};
    $s->{last_text_read} = shift @{$ref};
    $s->{read_texts} = [parse_array_stream(sub{shift @{$_[0]}},$ref)];
    $s->{added_by} = shift @{$ref};
    $s->{added_at} = Net::Lyskom::Time->new_from_stream($ref);
    my $type = shift @{$ref};

    ($s->{invitation},$s->{passive},$s->{secret}) = $type =~ /./g;

    return $s;
}
1;
