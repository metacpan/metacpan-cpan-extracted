package Paws::LicenseManager::ConsumedLicenseSummary;
  use Moose;
  has ConsumedLicenses => (is => 'ro', isa => 'Int');
  has ResourceType => (is => 'ro', isa => 'Str');
1;

### main pod documentation begin ###

=head1 NAME

Paws::LicenseManager::ConsumedLicenseSummary

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::LicenseManager::ConsumedLicenseSummary object:

  $service_obj->Method(Att1 => { ConsumedLicenses => $value, ..., ResourceType => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::LicenseManager::ConsumedLicenseSummary object:

  $result = $service_obj->Method(...);
  $result->Att1->ConsumedLicenses

=head1 DESCRIPTION

Details about license consumption.

=head1 ATTRIBUTES


=head2 ConsumedLicenses => Int

  Number of licenses consumed by the resource.


=head2 ResourceType => Str

  Resource type of the resource consuming a license.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::LicenseManager>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

