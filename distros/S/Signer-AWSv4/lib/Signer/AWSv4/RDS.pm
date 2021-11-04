package Signer::AWSv4::RDS;
  use Moo;
  extends 'Signer::AWSv4';
  use Types::Standard qw/Str Int/;

  has '+expires' => (default => 900);
  has '+service' => (default => 'rds-db');
  has '+method' => (default => 'GET');
  has '+uri' => (default => '/');

  has host => (is => 'ro', isa => Str, required => 1);
  has user => (is => 'ro', isa => Str, required => 1);
  has port => (is => 'ro', isa => Int, default => 3306);

  sub build_params {
    my $self = shift;
    {
      'Action' => 'connect',
      'DBUser' => $self->user,
      'X-Amz-Algorithm' => $self->aws_algorithm,
      'X-Amz-Credential' => $self->access_key . "/" . $self->credential_scope,
      'X-Amz-Date' => $self->date_timestamp,
      'X-Amz-Expires' => $self->expires,
      'X-Amz-SignedHeaders' => $self->signed_header_list,
    }
  }

  sub build_headers {
    my $self = shift;
    {
      Host => $self->host . ':' . $self->port,
    }
  }

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Signer::AWSv4::RDS - Generate tokens for signing into MySQL/Aurora RDS servers with IAM credentials

=head1 SYNOPSIS

  use Signer::AWSv4::RDS;
  $pass_gen = Signer::AWSv4::RDS->new(
    access_key => 'AKIAIOSFODNN7EXAMPLE',
    secret_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    host => 'MyRDSEndpoint',
    user => 'iam_user',
    region => 'us-east-1',
  );
  my $password = $pass_gen->signed_qstring;

=head1 DESCRIPTION

Generate tokens for signing into MySQL/Aurora RDS servers with IAM credentials.
You can find details of the process in L<https://www.capside.com/es/labs/rds-aurora-database-with-iam-authentication/>.

=head1 Request Attributes

This module adds two required attributes in the constructor for obtaining a token (to be used
as a MySQL password):

=head2 host String

The AWS RDS instance endpoint

=head2 user String

The user of the MySQL database

=head2 port Integer

The port the database is running on. Defaults to 3306.

=head1 Signature Attributes

=head2 signed_qstring

This has to be used as the password for the MySQL Server. Please note that all of this needs
extra setup: correctly configuring your AWS environment AND your MySQL Client.

=head1 SEE ALSO

L<https://github.com/pplu/perl-rds-iam-authentication>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/AWSv4Signer>

Please report bugs to: L<https://github.com/pplu/AWSv4Signer/issues>

=head1 AUTHOR

    Jose Luis Martinez
    pplusdomain@gmail.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by Jose Luis Martinez

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
