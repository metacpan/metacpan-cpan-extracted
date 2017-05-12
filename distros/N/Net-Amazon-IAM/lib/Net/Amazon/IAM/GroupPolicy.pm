package Net::Amazon::IAM::GroupPolicy;
use Moose;

=head1 NAME

Net::Amazon::IAM::GroupPolicy

=head1 DESCRIPTION

A class representing a IAM GroupPolicy list.

=head1 ATTRIBUTES

=over

=item PolicyName

The name of the policy.

=item PolicyDocument

The policy document.

=item GroupName

The group the policy is associated with.
   
=back

=cut

has 'PolicyName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'PolicyDocument' => (
   is       => 'ro',
   isa      => 'Maybe[HashRef]',
   required => 0,
);

has 'GroupName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Igor Tsigankov <tsiganenok@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2015 Igor Tsigankov . This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;
