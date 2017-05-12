package Net::Amazon::IAM::PolicyVersions;
use Moose;

=head1 NAME

Net::Amazon::IAM::PolicyVersions

=head1 DESCRIPTION

A class representing a IAM policy versions list.

=head1 ATTRIBUTES

=over

=item Policies (required)

List of L<Net::Amazon::IAM::PolicyVersion> objects.

=back

=cut

has 'Policies' => (
   is       => 'ro',
   isa      => 'ArrayRef[Net::Amazon::IAM::PolicyVersion]',
   required => 1,
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
