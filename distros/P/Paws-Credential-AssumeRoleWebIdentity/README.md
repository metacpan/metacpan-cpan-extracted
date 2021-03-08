# NAME

Paws::Credential::AssumeRoleWebIdentity

# SYNOPSIS

    use Paws::Credential::AssumeRoleWebIdentity;

    my $paws = Paws->new(config => {
        credentials => Paws::Credential::AssumeRoleWebIdentity->new(
            DurationSeconds      => 900,
            RoleArn              => 'arn:....',
            WebIdentityTokenFile => '/var/run/secrets/eks.amazonaws.com/serviceaccount/token'
        )
    });

# DESCRIPTION

The AssumeRoleWebIdentity provider is used to obtain temporary credentials with an OIDC web identity token file. 

You can use this credential provider to obtain credentials when using AWS EKS and eks.amazonaws.com/role-arn annotation.

Credentials are refreshed with a re-call to STS when they before gets expired

## DurationSeconds: Int (optional)

The number of seconds for which the credentials will be valid

## WebIdentityTokenFile: Str (optional)

Path to web identity token file. Default: $ENV{'AWS\_WEB\_IDENTITY\_TOKEN\_FILE'}

## RoleArn: Str

The arn of the role to be assumed. Default: $ENV{'AWS\_ROLE\_ARN'}

## RoleSessionName: Str (optional) 

The name of the session (will appear in CloudTrail logs, for example). Default: paws-session-time();

# LICENSE

Copyright (C) Prajith P.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Prajith P
