package Net::Amazon::EC2::StateReason;
$Net::Amazon::EC2::StateReason::VERSION = '0.36';
use Moose;

=head1 NAME

Net::Amazon::EC2::StateReason

=head1 DESCRIPTION

A class representing additional information on the reason for the current state of the instance.

=head1 ATTRIBUTES

=over

=item code (required)

A code for the state change reason.

=item message (required)

A message providing additional information about the state.

=back

=cut

has 'code'		=> ( is => 'ro', isa => 'Maybe[Int|Str]' );
has 'message' 	=> ( is => 'ro', isa => 'Maybe[Str]' );

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Jeff Kim <cpan@chosec.com>

=head1 COPYRIGHT

Copyright (c) 2006-2010 Jeff Kim. This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;
