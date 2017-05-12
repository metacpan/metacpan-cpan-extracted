[![Build Status](https://travis-ci.org/binary-com/perl-RateLimitations-Pluggable.svg?branch=master)](https://travis-ci.org/binary-com/perl-RateLimitations-Pluggable)
[![codecov](https://codecov.io/gh/binary-com/perl-RateLimitations-Pluggable/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-RateLimitations-Pluggable)

# NAME

RateLimitations::Pluggable - pluggabe manager of per-service rate limitations

# VERSION

0.01

# STATUS

# SYNOPSIS

    my $storage = {};

    my $rl = RateLimitations::Pluggable->new({
        limits => {
            sample_service => {
                60   => 2,  # per minute limits
                3600 => 5,  # per hour limits
            }
        },
        # define an subroutine where hits are stored: redis, db, file, in-memory, cookies
        getter => sub {
            my ($service, $consumer) = @_;
            return $storage->{$service}->{$consumer};
        },
        # optional, notify back when hits are updated
        setter => sub {
            my ($service, $consumer, $hits) = @_;
            $storage->{$service}->{$consumer} = $hits;
        },
    });

    $rl->within_rate_limits('sample_service', 'some_client_id');  # true!
    $rl->within_rate_limits('sample_service', 'some_client_id');  # true!
    $rl->within_rate_limits('sample_service', 'some_client_id'),  # false!

# DESCRIPTION

The module access to build-in `time` function every time you invoke
`within_rate_limits` method, and checks whether limits are hits or not.

Each time the method `within_rate_limits` is invoked it appends
to the array of hit current time. It check that array will not
grow endlessly, and holds in per $service (or per $service/$consumer)
upto max\_time integers.

The array can be stored anywhere (disk, redis, DB, in-memory), hence the module
name is.

# ATTRIBUTES

## limits

Defines per-service limits. Below

    {
        service_1 => {
            60   => 20,    # up to 20 service_1 invocations per 1 minute
            3600 => 50,    # OR up to 50 service_1 invocations per 1 hour
        },

        service_2 => {
            60   => 25,
            3600 => 60,
        }

    }

Mandatory.

## getter->($service, $consumer)

Mandatory coderef which returns an array of hits for the service and some
`consumer`.

## setter->($service, $consumer, $hits)

Optional callback for storing per service/consumer array of hits.

# METHODS

## within\_rate\_limits($service, $consumer)

Appends service/consumer hits array with additional hit.

Returns true if the service limits aren't exhausted.

The `$service` string must be defined in the `limits` attribute;
the `$consumer` string is arbitrary object defined by application
logic. Cannot be `undef`

# SOURCE CODE

[GitHub](https://github.com/binary-com/perl-RateLimitations-Pluggable)

# AUTHOR

binary.com, `<perl at binary.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/binary-com/perl-RateLimitations-Pluggable/issues](https://github.com/binary-com/perl-RateLimitations-Pluggable/issues).

# LICENSE AND COPYRIGHT

Copyright (C) 2016 binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
