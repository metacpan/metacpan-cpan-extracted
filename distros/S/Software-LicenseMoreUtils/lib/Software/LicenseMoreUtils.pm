#
# This file is part of Software-LicenseMoreUtils
#
# This software is copyright (c) 2018, 2022 by Dominique Dumont.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Software::LicenseMoreUtils;
$Software::LicenseMoreUtils::VERSION = '1.009';
use strict;
use warnings;
use 5.10.1;

use Try::Tiny;
use Carp;
use Software::LicenseMoreUtils::LicenseWithSummary;
use Software::License 0.103014;

# ABSTRACT: More utilities and a summary for Software::License

use base qw/Software::LicenseUtils/;

# a short name with '+' at the end of the short name implies an
# "or later" clause.  i.e. GPL-1+ is "GPL-1 or any later version"
my %more_short_names = (
    'Apache-2'     => 'Software::License::Apache_2_0',
    'Artistic'     => 'Software::License::Artistic_1_0',
    'Artistic-1'   => 'Software::License::Artistic_1_0',
    'Artistic-2'   => 'Software::License::Artistic_2_0',
    'BSD-3-clause' => 'Software::License::BSD',
    'Expat'        => 'Software::License::MIT',
    'LGPL-2'       => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL_2'       => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL-3'       => 'Software::License::LGPL_3_0',
    'MPL-1.0'      => 'Software::License::Mozilla_1_0',
    'MPL-1.1'      => 'Software::License::Mozilla_1_1',
    'MPL-2.0'      => 'Software::License::Mozilla_2_0',

    # GPL SPDX identifiers have another convention for GPL version number
    'LGPL-2.0' => 'Software::LicenseMoreUtils::LGPL_2',

    'GPL-1.0'  => 'Software::License::GPL_1',
    'GPL-2.0'  => 'Software::License::GPL_2',
    'GPL-3.0'  => 'Software::License::GPL_3',
);

sub _create_license {
    my ( $class, $arg ) = @_;
    croak "no license short name specified"
          unless defined $arg->{short_name};

    my $lic_obj;
    try {
        $lic_obj = SUPER::new_from_short_name($arg);
    };

    return $lic_obj if $lic_obj;

    try {
        $lic_obj = SUPER::new_from_spdx_expression($arg);
    };

    return $lic_obj if $lic_obj;

    my $short = $arg->{short_name};
    $short =~ s/-(only|or-later)$//;
    $short =~ s/\+$//;

    my $subclass = $short;
    $subclass =~ s/[\-.]/_/g;

    my $info = $more_short_names{$short} || "Software::License::$subclass";
    my $lic_file = my $lic_class = $info;
    $lic_file =~ s!::!/!g;
    try {
        ## no critic (Modules::RequireBarewordIncludes)
        require "$lic_file.pm";
    } catch {
        Carp::croak "Unknow license with short name $short ($_)";
    } ;
    delete $arg->{short_name};
    # the holder default value fits well with BSD license text
    $lic_obj = $lic_class->new( { holder => 'the copyright holder', %$arg } );

    return $lic_obj;
}

sub new_license_with_summary {
    carp "new_license_with_summary is deprecated. Please use new_from_short_name";
    goto & new_from_short_name;
}

sub new_from_short_name {
    my ( $class, $arg ) = @_;
    croak "no license short name specified"
        unless defined $arg->{short_name};

    my $short = $arg->{short_name};

    my $info = $more_short_names{$short} || '';
    my $or_later = $short =~ /(\+|-or-later)$/ ? 1 : 0;
    my $lic = $class->_create_license($arg);

    my $xlic = Software::LicenseMoreUtils::LicenseWithSummary->new({
        license => $lic,
        or_later => $or_later,
        holder => $arg->{holder},
    });
    return $xlic;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::LicenseMoreUtils - More utilities and a summary for Software::License

=head1 VERSION

version 1.009

=head1 SYNOPSIS

 use Software::LicenseMoreUtils;

 my $lic = Software::LicenseMoreUtils->new_from_short_name({
    short_name => 'Apache-2.0', # or GPL-2+, Artistic-2 ...
    holder => 'X. Ample' # unlike Software::License, holder is optional
 });

 # On Debian, return a license summary, returns license text elsewhere
 # with ot without copyright notice, depending if holder is set.
 my $text = $lic->summary_or_text;

 # returns license full text
 my $text = $lic->text;

=head1 DESCRIPTION

This module provides more utilities for L<Software::License>:

=over

=item *

Method L</new_from_short_name> returns a
L<Software::LicenseMoreUtils::LicenseWithSummary> object that provides all
functionalities of C<Software::License::*> objects and a summary on
some Linux distribution (see below).

=item *

L</new_from_short_name> accepts more short names than
L<Software::LicenseUtils>

=item *

L</new_from_short_name> accepts "or any later version" variant of GPL
licenses. When a short name like C<GPL-3+> is used, the license
summary contains "or (at your option) any later version" statement.

=item *

L<Software::License::LGPL-2> license is also provided. Even though
license C<LGPL-2.1> is preferred over C<LGPL-2>, some software in
Debian use C<LGPL-2>.

=back

=head1 License summary

In some distribution like Debian, all packages should come with the
full text of the licenses of the package software.

To avoid many duplication of long license text, the text of the most
common licenses are provided in C</usr/share/common-licenses>
directory. Then the license text of a package need only to provide a
summary of the license that refer to the location of the common
license.

All summaries are provided for Debian (so, for Ubuntu). Other
distributions are welcome to send pull request for their license
summaries.

=head1 Methods

=head2 new_from_short_name

 my $license_object = Software::LicenseMoreUtils->new_from_short_name({
      short_name => 'GPL-1', # mandatory
      holder => 'X. Ample' # optional
 }) ;

Unlike L<Software::License>, the C<Holder> parameter is optional. When
set, L<Software::LicenseMoreUtils::LicenseWithSummary/summary_or_text>
returns a copyright notice with the text of the summary of the
license.

Returns a new L<Software::LicenseMoreUtils::LicenseWithSummary> object
which is a L<Software::License> wrapped with a summary. This is a
drop-in replacement for the L<Software::License> object as all methods
are delegated to the underlying L<Software::License> object.

Known short license names are C<GPL-*>, C<LGPL-*> , and their "or
later version" variant C<GPL-*+>, C<LGPL-*+> C<Artistic> and
C<Artistic-*>. Unlike vanilla L<Software::License>, this module
accepts license name with "-" (e.g. C<GPL-2>) along with "_"
(e.g. "C<GPL_2>").

SPDX v3 identifiers can also be used as short names. I.e. short names
like C<GPL-2.0-only> or C<LGPL-2.1-or-later> are supported.

If the short name is not known, this method tries to create a license
object with C<Software::License> and the specified short name
(e.g. C<Software::License::MIT> with C<< short_name => 'MIT' >> or
C<Software::License::Apache_2_0> with C<< short_name => 'Apache-2.0' >>).

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2022 by Dominique Dumont.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
