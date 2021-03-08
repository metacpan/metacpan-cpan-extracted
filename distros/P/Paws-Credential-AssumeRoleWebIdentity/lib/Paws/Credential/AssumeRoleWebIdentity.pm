package Paws::Credential::AssumeRoleWebIdentity;

use Moose;
use DateTime::Format::ISO8601;
use Paws::Credential::None;

with 'Paws::Credential';

our $VERSION = "0.0.3";

has expiration => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 0 }
);

has RoleArn => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $ENV{'AWS_ROLE_ARN'} }
);

has WebIdentityTokenFile  => (
    is        => 'rw',
    isa       => 'Str',
    lazy      => 1,
    default   => sub { $ENV{'AWS_WEB_IDENTITY_TOKEN_FILE'} }
);

has sts_region => (
    is      => 'ro', 
    isa     => 'Str|Undef', 
    default => sub { undef }
);

has sts => (
    is      => 'ro', 
    isa     => 'Paws::STS', 
    lazy    => 1, 
    default => sub {
        my $self = shift;
        Paws->service('STS', 
            region      => $self->sts_region
        );
    }
);

has RoleSessionName => (
    is       => 'rw', 
    isa      => 'Str', 
    default  => sub {
        return sprintf('paws-session-%s', time())
    }
);

has DurationSeconds => (
    is  => 'rw', 
    isa => 'Maybe[Int]'
);

has actual_creds => (
    is  => 'rw',
    isa => 'Object'
);

sub _web_identity_token {
    my $self = shift;

    return unless -e $self->WebIdentityTokenFile;

    open my $fh, '<', $self->WebIdentityTokenFile or 
         die "Not able to open WebIdentityTokenFile: $!";
    my $token = do { local $/; <$fh> };
    close $fh; 

    return $token;
}

sub access_key {
    my $self = shift;
    $self->_refresh;

    return $self->actual_creds->AccessKeyId;
}

sub secret_key {
    my $self = shift;
    $self->_refresh;
    
    return $self->actual_creds->SecretAccessKey;
}

sub session_token {
    my $self = shift;
    $self->_refresh;

    return $self->actual_creds->SessionToken;
}

sub _refresh {
    my $self = shift;
    return if $self->expiration - 240 >= time;

    my $token  = $self->_web_identity_token();
    my $result = $self->sts->AssumeRoleWithWebIdentity(
        RoleSessionName  => $self->RoleSessionName,
        RoleArn          => $self->RoleArn,
        WebIdentityToken => $token,
        (defined $self->DurationSeconds) ? (DurationSeconds => $self->DurationSeconds) : (),
    );
    my $creds = $self->actual_creds($result->Credentials);

    my $expiration = $result->Credentials->Expiration;
    $self->expiration(
         DateTime::Format::ISO8601->parse_datetime($expiration)->epoch
    );
}

no Moose;
1;

__END__

# ABSTRACT:  The AssumeRoleWebIdentity provider is used to obtain temporary credentials with an OIDC web identity token file. 

=encoding UTF-8

=head1 NAME

Paws::Credential::AssumeRoleWebIdentity

=head1 SYNOPSIS

  use Paws::Credential::AssumeRoleWebIdentity;

  my $paws = Paws->new(config => {
      credentials => Paws::Credential::AssumeRoleWebIdentity->new(
          DurationSeconds      => 900,
          RoleArn              => 'arn:....',
          WebIdentityTokenFile => '/var/run/secrets/eks.amazonaws.com/serviceaccount/token'
      )
  });

=head1 DESCRIPTION

The AssumeRoleWebIdentity provider is used to obtain temporary credentials with an OIDC web identity token file. 

You can use this credential provider to obtain credentials when using AWS EKS and eks.amazonaws.com/role-arn annotation.

Credentials are refreshed with a re-call to STS when they before gets expired

=head2 DurationSeconds: Int (optional)

The number of seconds for which the credentials will be valid

=head2 WebIdentityTokenFile: Str (optional)

Path to web identity token file. Default: $ENV{'AWS_WEB_IDENTITY_TOKEN_FILE'}

=head2 RoleArn: Str

The arn of the role to be assumed. Default: $ENV{'AWS_ROLE_ARN'}

=head2 RoleSessionName: Str (optional) 

The name of the session (will appear in CloudTrail logs, for example). Default: paws-session-time();

=head1 LICENSE

Copyright (C) Prajith P.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Prajith P

=cut

