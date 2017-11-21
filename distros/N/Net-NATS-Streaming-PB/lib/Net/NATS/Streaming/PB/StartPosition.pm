package Net::NATS::Streaming::PB::StartPosition;

use strict;
use warnings;

use constant NewOnly => 0;
use constant LastReceived => 1;
use constant TimeDeltaStart => 2;
use constant SequenceStart => 3;
use constant First => 4;

1;

__END__

=pod

=head1 NAME

Net::NATS::Streaming::PB::StartPosition - Perl interface to Net.NATS.Streaming.PB.StartPosition

=head1 SYNOPSIS

 use Net::NATS::Streaming::PB::StartPosition;

 my $NewOnly = Net::NATS::Streaming::PB::StartPosition::NewOnly;
 my $LastReceived = Net::NATS::Streaming::PB::StartPosition::LastReceived;
 my $TimeDeltaStart = Net::NATS::Streaming::PB::StartPosition::TimeDeltaStart;
 my $SequenceStart = Net::NATS::Streaming::PB::StartPosition::SequenceStart;
 my $First = Net::NATS::Streaming::PB::StartPosition::First;

=head1 DESCRIPTION

Net::NATS::Streaming::PB::StartPosition defines the following constants:

=over 4

=item B<NewOnly>

This constant has a value of 0.

=item B<LastReceived>

This constant has a value of 1.

=item B<TimeDeltaStart>

This constant has a value of 2.

=item B<SequenceStart>

This constant has a value of 3.

=item B<First>

This constant has a value of 4.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.StartPosition by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

