package Parse::Snort::Strict;
use base qw(Parse::Snort);

use strict;
use warnings;
use Carp qw(croak);
use List::Util qw(any);
use Sub::Util qw(set_subname);

our $VERSION = "0.8";

# valid values for rule parts
my $rule_parts_validation = {
  action => [qw( alert pass drop sdrop log activate dynamic reject )],
  proto => [qw( tcp udp ip icmp )],
  direction => [qw( -> <> <- )],
};

# method generator for simple rule parts, copypasta reduction
{
  my $generator = sub {
    # closures are teh awesome.
    my ($part,$value_ref) = @_;
    my $method = "SUPER::$part";

    return sub {
      my ($self,$value) = @_;

      # do validation
      croak "Invalid rule $part: '$value'" unless (any { $value eq $_ } @{ $value_ref });

      # call parent's method for value setting
      $self->$method($value);
    };
  };

  no strict qw(refs);
  while (my ($part,$value_ref) = each %$rule_parts_validation) {
    *{$part} = set_subname($part,$generator->($part,$value_ref));
  }
  use strict qw(refs);
}

# TODO: validate formatting of src/dst address and port, make sure they look like $VARIABLEs or [a:range]

1;

__END__;

=head1 NAME

Parse::Snort::Strict - Parse Snort rules with validation of the rules

=head1 DESCRIPTION

Parse Snort rules with validation regarding rule action, protocol and direction.  Look at L<Parse::Snort> for more usage detail, as this is a subclass of it.

=head1 SYNOPSIS

    use Parse::Snort::Strict;
    use Try::Tiny;

    my $rule = Parse::Snort::Strict->new();
    try {
        $rule->parse($text);
    }
    catch {
        warn "Unable to parse rule: $_";
    };

=head1 METHODS

=head2 action

You can only have the following actions

=over

=item alert

generate an alert using the selected alert method, and then

=item log

log the packet

=item pass

ignore the packet

=item activate

alert and then turn on another dynamic rule

=item dynamic

remain idle until activated by an activate rule , then act as a log rule

=item drop

block and log the packet

=item reject

block the packet, log it, and then send a TCP reset if the protocol is
TCP or an ICMP port unreachable message if the protocol is UDP.

=item sdrop

block the packet but do not log it.

=back

=head2 proto

You can only have the following protocols:

=over

=item tcp

=item udp

=item ip

=item icmp

=back

=head2 direction

You can Only have the following directions

=over

=item ->

=item <>

=item <-

=back

=cut
