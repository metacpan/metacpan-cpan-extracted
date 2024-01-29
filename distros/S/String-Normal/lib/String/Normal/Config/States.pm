package String::Normal::Config::States;
use strict;
use warnings;

use String::Normal::Config;

our $us_codes = {
    ak => 'alaska',
    al => 'alabama',
    ar => 'arkansas',
    as => 'american samoa',
    az => 'arizona',
    ca => 'california',
    co => 'colorado',
    ct => 'connecticut',
    dc => 'district of columbia',
    de => 'delaware',
    fl => 'florida',
    fm => 'federated states of micronesia',
    ga => 'georgia',
    gu => 'guam',
    hi => 'hawaii',
    ia => 'iowa',
    id => 'idaho',
    il => 'illinois',
    in => 'indiana',
    ks => 'kansas',
    ky => 'kentucky',
    la => 'louisiana',
    ma => 'massachusetts',
    md => 'maryland',
    me => 'maine',
    mh => 'marshall islands',
    mi => 'michigan',
    mn => 'minnesota',
    mo => 'missouri',
    mp => 'northern mariana islands',
    ms => 'mississippi',
    mt => 'montana',
    nc => 'north carolina',
    nd => 'north dakota',
    ne => 'nebraska',
    nh => 'new hampshire',
    nj => 'new jersey',
    nm => 'new mexico',
    nv => 'nevada',
    ny => 'new york',
    oh => 'ohio',
    ok => 'oklahoma',
    or => 'oregon',
    pa => 'pennsylvania',
    pr => 'puerto rico',
    pw => 'palau',
    ri => 'rhode island',
    sc => 'south carolina',
    sd => 'south dakota',
    tn => 'tennessee',
    tx => 'texas',
    ut => 'utah',
    va => 'virginia',
    vi => 'virgin islands',
    vt => 'vermont',
    wa => 'washington',
    wi => 'wisconsin',
    wv => 'west virginia',
    wy => 'wyoming',
};

our $ca_codes = {
    ab => 'alberta',
    bc => 'british columbia',
    mb => 'manitoba',
    nb => 'new brunswick',
    nl => 'newfoundland and labrador',
    ns => 'nova scotia',
    nt => 'northwest territories',
    nu => 'nunavut',
    on => 'ontario',
    pe => 'prince edward island',
    qc => 'quebec',
    sk => 'saskatchewan',
    yt => 'yukon territory',
};

our $by_short = { %$us_codes, %$ca_codes };
our $by_long  = { reverse %$by_short };

#our $to_country = {
#    %{{ map { $_ => 'US' } keys %$us_codes }},
#    %{{ map { $_ => 'CA' } keys %$ca_codes }},
#};

sub _data {
    return {
        us_codes => $us_codes,
        ca_codes => $ca_codes,
        by_short => $by_short,
        by_long  => $by_long,
    };
}

1;

=head1 NAME

String::Normal::Config::States;

=head1 DESCRIPTION

This package defines valid U.S. and Candadian state codes.

=head1 STRUCTURE

Unless the other Config classes, this one provides a hash reference
which contains:

=over 4

=item * C<us_codes>

All valid US codes.

=item * C<ca_codes>

All valid CA codes.

=item * C<by_short>

All codes with their short version as the key.

=item * C<by_long>

All codes with their long version as the key.

=back

This Config class cannot be overriden.

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

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

=cut
