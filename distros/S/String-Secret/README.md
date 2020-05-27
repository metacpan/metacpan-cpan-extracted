# NAME

String::Secret - secret string wrapper to mask secret from logger

# SYNOPSIS

    use String::Secret;
    use String::Compare::ConstantTime;
    use JSON::PP ();

    my $secret = String::Secret->new('mysecret');

    # safe secret for logging
    MyLogger->warn("invalid secret: $secret"); # oops! but the secret is hidden: "invalid secret: ********"

    # and safe secret for serialization
    # MyLogger->warn("invalid secret: ".JSON::PP->new->allow_tags->encode({ secret => $secret })); # oops! but the secret is hidden: invalid secret: {"secret":"********"}

    unless (String::Compare::ConstantTime::equals($secret->unwrap, SECRET)) {
        die "secret mis-match";
    }

    # and can it convert to serializable
    MyDB->credentials->new(
        id     => 'some id',
        secret => $secret->to_serializable, # or $secret->unwrap
    )->save();

# DESCRIPTION

String::Secret is a secret string wrapper to mask secret from logger.

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
