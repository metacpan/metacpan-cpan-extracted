package TableData::Software::License::FromSL;

use strict;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-27'; # DATE
our $DIST = 'TableDataBundle-Software-License'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: List of software license from Software::License::* modules

=pod

=encoding UTF-8

=head1 NAME

TableData::Software::License::FromSL - List of software license from Software::License::* modules

=head1 VERSION

This document describes version 0.002 of TableData::Software::License::FromSL (from Perl distribution TableDataBundle-Software-License), released on 2022-07-27.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Software-License>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Software-License>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Software-License>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
name,summary
AGPL_3,"GNU Affero General Public License, Version 3"
Apache_1_1,"The Apache Software License, Version 1.1"
Apache_2_0,"The Apache License, Version 2.0"
Apathyware,"Apathyware License"
Artistic_1_0,"The Artistic License"
Artistic_2_0,"The Artistic License 2.0"
BSD,"The (three-clause) BSD License"
BSD_1_Clause,"The 1-Clause BSD License"
Beerware,"""THE BEER-WARE LICENSE"" (Revision 42)"
Boost_1_0,"Boost Software License, Version 1.0, August 17th, 2003"
CC0_1_0,"the ""public domain""-like CC0 license, version 1.0"
CC_BY_1_0,"Creative Commons Attribution 1.0 License (CC BY 1.0)"
CC_BY_2_0,"Creative Commons Attribution 2.0 License (CC BY 2.0)"
CC_BY_3_0,"Creative Commons Attribution 3.0 Unported License (CC BY 3.0)"
CC_BY_4_0,"Creative Commons Attribution 4.0 International License (CC BY 4.0)"
CC_BY_NC_1_0,"Creative Commons Attribution-NonCommercial 1.0 License (CC BY-NC 1.0)"
CC_BY_NC_2_0,"Creative Commons Attribution-NonCommercial 2.0 License (CC BY-NC 2.0)"
CC_BY_NC_3_0,"Creative Commons Attribution-NonCommercial 3.0 Unported License (CC BY-NC 3.0)"
CC_BY_NC_4_0,"Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)"
CC_BY_NC_ND_2_0,"Creative Commons Attribution-NonCommercial-NoDerivs 2.0 License (CC BY-NC-ND 2.0)"
CC_BY_NC_ND_3_0,"Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License (CC BY-NC-ND 3.0)"
CC_BY_NC_ND_4_0,"Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License (CC BY-NC-ND 4.0)"
CC_BY_NC_SA_1_0,"Creative Commons Attribution-NonCommercial-ShareAlike 1.0 License (CC BY-NC-SA 1.0)"
CC_BY_NC_SA_2_0,"Creative Commons Attribution-NonCommercial-ShareAlike 2.0 License (CC BY-NC-SA 2.0)"
CC_BY_NC_SA_3_0,"Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License (CC BY-NC-SA 3.0)"
CC_BY_NC_SA_4_0,"Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)"
CC_BY_ND_1_0,"Creative Commons Attribution-NoDerivs 1.0 License (CC BY-ND 1.0)"
CC_BY_ND_2_0,"Creative Commons Attribution-NoDerivs 2.0 License (CC BY-ND 2.0)"
CC_BY_ND_3_0,"Creative Commons Attribution-NoDerivs 3.0 Unported License (CC BY-ND 3.0)"
CC_BY_ND_4_0,"Creative Commons Attribution-NoDerivatives 4.0 International License (CC BY-ND 4.0)"
CC_BY_ND_NC_1_0,"Creative Commons Attribution-NoDerivs-NonCommercial 1.0 License (CC BY-ND-NC 1.0)"
CC_BY_SA_1_0,"Creative Commons Attribution-ShareAlike 1.0 License (CC BY-SA 1.0)"
CC_BY_SA_2_0,"Creative Commons Attribution-ShareAlike 2.0 License (CC BY-SA 2.0)"
CC_BY_SA_3_0,"Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)"
CC_BY_SA_4_0,"Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)"
CC_PDM_1_0,"Creative Commons Public Domain Mark 1.0"
DWTFYWWI,"The ""Do Whatever The Fuck You Want With It"" license"
EUPL_1_1,"The European Union Public License (EUPL) v1.1"
EUPL_1_2,"The European Union Public License (EUPL) v1.2"
FreeBSD,"The FreeBSD License (aka two-clause BSD)"
GFDL_1_2,"The GNU Free Documentation License v1.2"
GFDL_1_3,"The GNU Free Documentation License v1.3"
GPL3andArtistic2,"GPL 3 and Artistic 2.0 Dual License"
GPL_1,"GNU General Public License, Version 1"
GPL_2,"GNU General Public License, Version 2"
GPL_3,"GNU General Public License, Version 3"
ISC,"The ISC License"
LGPL_2_1,"GNU Lesser General Public License, Version 2.1"
LGPL_3_0,"GNU Lesser General Public License, Version 3"
MIT,"The MIT (aka X11) License"
Mozilla_1_0,"Mozilla Public License 1.0"
Mozilla_1_1,"The Mozilla Public License 1.1"
Mozilla_2_0,"Mozilla Public License Version 2.0"
NYSL,"The ""public-domain""-like NYSL license, version 0.9982"
NetHack,"The NetHack General Public License"
OpenSSL,"The OpenSSL License"
OrLaterPack,"Use GNU license with ""or later"" clause"
Perl_5,"The Perl 5 License (Artistic 1 & GPL 1)"
PostgreSQL,"The PostgreSQL License"
PublicDomain,"A Public Domain ""License"""
QPL_1_0,"The Q Public License, Version 1.0"
SSLeay,"The Original SSLeay License"
Sun,"Sun Internet Standards Source License (SISSL)"
WTFPL_2,"The Do What The Fuck You Want To Public License, Version 2"
Zlib,"The zlib License"
