package Net::Amazon::IAM::PolicyVersion;
use Moose;

=head1 NAME

Net::Amazon::IAM::PolicyVersion

=head1 DESCRIPTION

Contains information about a version of a managed policy.

=head1 ATTRIBUTES

=over

=item CreateDate (optional)

The date and time, in ISO 8601 date-time format, when the policy version was created.

=item Document (optional)

The policy document.

=item IsDefaultVersion (optional)

Specifies whether the policy version is set as the policy's default version.

=item VersionId (optional)

The identifier for the policy version.
   
=back

=cut

has 'CreateDate' => (
   is       => 'ro',
   isa      => 'Maybe[Str]',
   required => 0,
);

has 'Document' => (
   is       => 'ro',
   isa      => 'Maybe[HashRef]',
   required => 0,
);

has 'IsDefaultVersion' => (
   is       => 'ro',
   isa      => 'Maybe[Str]',
   required => 0,
);

has 'VersionId' => (
   is       => 'ro',
   isa      => 'Maybe[Str]',
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
