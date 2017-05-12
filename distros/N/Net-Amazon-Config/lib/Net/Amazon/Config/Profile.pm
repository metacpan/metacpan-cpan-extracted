use strict;
use warnings;

package Net::Amazon::Config::Profile;
# ABSTRACT: Amazon credentials for given profile
our $VERSION = '0.002'; # VERSION

use Params::Validate ();

my @attributes;

BEGIN {
    @attributes = qw(
      profile_name
      access_key_id
      secret_access_key
      certificate_file
      private_key_file
      ec2_keypair_name
      ec2_keypair_file
      cf_keypair_id
      cf_private_key_file
      aws_account_id
      canonical_user_id
    );
}

use Object::Tiny @attributes;

sub new {
    my ( $class, $first, @rest ) = @_;
    my @args = ref $first eq 'ARRAY' ? (@$first) : ( $first, @rest );
    my %args = Params::Validate::validate( @args, { map { $_ => 0 } @attributes } );
    return bless \%args, $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::Config::Profile - Amazon credentials for given profile

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This module defines a simple object representing a 'profile' of
Amazon Web Services credentials and associated information.

=head1 USAGE

A profile object is created by L<Net::Amazon::Config> based on information
in a configuration file.  The object has the following read-only accessors:

=over

=item *

profile_name -- as provided in the configuration file

=item *

access_key_id -- identifier for REST requests

=item *

secret_access_key -- used to sign REST requests

=item *

certificate_file -- path to a file containing identifier for SOAP requests

=item *

private_key_file -- path to a file containing the key used to sign SOAP requests

=item *

ec2_keypair_name -- the name used to identify a keypair when launching an EC2 instance

=item *

ec2_keypair_file -- the private key file used by ssh to connect to an EC2 instance

=item *

cf_keypair_id -- identifier for CloudFront requests

=item *

cf_private_key_file -- path to a file containing the key use to sign CloudFront requests

=item *

aws_account_id -- identifier to share resources (except S3) 

=item *

canonical_user_id -- identifier to share resources (S3 only)

=back

If an attribute is not set in the configuration file, the accessor will
return undef.

=head1 SEE ALSO

=over

=item *

L<Net::Amazon::Config>

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
