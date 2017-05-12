#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Software/License/AGPL_3/or_later.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Software-License-OrLaterPack.
#
#   perl-Software-License-OrLaterPack is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Software-License-OrLaterPack is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Software-License-OrLaterPack. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt
#tt


#pod =for :this This is C<Software::License::AGPL_3::or_later> module documentation. Read this if you
#pod are going to hack or extend the module, or use the module directly.
#pod
#pod =for :those If you want to use GNU license with "or later" clause read the L<user
#pod manual|Software::License::OrLaterPack>. General topics like getting source, building, installing,
#pod bug reporting and some others are covered in the F<README> file.
#pod
#pod =head1 SYNOPSIS
#pod
#pod     my $lic = Software::License::AGPL_3::or_later->new( {
#pod         holder  => 'John Doe',
#pod         year    => '2010',
#pod         program => 'Assa'
#pod     } );
#pod
#pod     $lic->_abbr;    # 'AGPL'
#pod     $lic->abbr;     # 'AGPLv3+'
#pod     $lic->_name;    # 'GNU Affero General Public License'
#pod     $lic->name;     # 'The GNU Affero General Public License version 3 or later'
#pod
#pod     $lic->notice;
#pod         # Copyright statement and
#pod         # standard GNU 3-paragraph license notice.
#pod     $lic->notice( 'short' );
#pod         # Copyright statement, license name and
#pod         # two sentences about free software and warranties.
#pod
#pod     # …and other methods inherited from Software::License::AGPL_3
#pod     # and Software::License.
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Software::License::AGPL_3::or_later> is a subclass of C<Software::License::AGPL_3>.
#pod It overrides few parent methods and introduces few own methods.
#pod
#pod See documentation on L<Software::License> for a general description of the class interface.
#pod
#pod =cut

package Software::License::AGPL_3::or_later;

use strict;
use warnings;
use version 0.77;

# ABSTRACT: AGPLv3+ license for Software::License infrastructure
our $VERSION = 'v0.10.2'; # VERSION

use parent 'Software::License::AGPL_3';
use Text::Wrap;

#pod =attr _abbr
#pod
#pod Bare abbreviated license name, "AGPL".
#pod
#pod Note: this attribute is I<not> inherited from the base class.
#pod
#pod =cut

sub _abbr {
    return 'AGPL';
};

#pod =attr abbr
#pod
#pod Abbreviated license name: concatenated bare abbreviated license name, 'v' character, and license
#pod version (with trailing plus sign).
#pod
#pod Note: this attribute is I<not> inherited from the base class.
#pod
#pod =cut

sub abbr {
    my ( $self ) = @_;
    return $self->_abbr . 'v' . $self->version;
};

#pod =attr base
#pod
#pod A reference to base license object, i. e. license without "or later" clause.
#pod
#pod Note: this attribute is I<not> inherited from the base class.
#pod
#pod =cut

sub base {
    my ( $self ) = @_;
    if ( not $self->{ base } ) {
        my %base = %$self;  # Create a copy, because `new` (re)blesses passed `HashRef`.
        $self->{ base } = Software::License::AGPL_3->new( \%base );
    };
    return $self->{ base };
};

#pod =attr _name
#pod
#pod Bare name of the license, which is also bare name of the base license, because it does
#pod include neither definitive article ("The"), nor license version nor "or later" clause:
#pod "GNU Affero General Public License".
#pod
#pod Note: this attribute is I<not> inherited from the base class.
#pod
#pod =cut

sub _name {
    return 'GNU Affero General Public License';
};

#pod =attr name
#pod
#pod This attribute meets C<Software::License> specification: returned name starts with definitive
#pod capitalized article ("The"). Returned name also includes the base license version (like other
#pod C<Software::License> classes do) (without trailing plus sign) and "or later" clause.
#pod
#pod =cut

sub name {
    my ( $self ) = @_;
    return sprintf( "The %s version %s or later", $self->_name, $self->base->version );
};

#pod =attr program
#pod
#pod A program name as specified by the C<program> option in constructor, or the C<Program> option in
#pod constructor, or "this program". This form of program name is intended to be used in the middle of
#pod sentence.
#pod
#pod Note: this attribute is I<not> inherited from the base class.
#pod
#pod =cut

sub program {
    my ( $self ) = @_;
    return $self->{ program } || $self->{ Program } || 'this program';
};

#pod =attr Program
#pod
#pod A program name as specified by the C<Program> option in constructor, or the C<program> option in
#pod constructor, or "This program". This form of program name is intended to be used in the beginning
#pod of sentence.
#pod
#pod Note: this attribute is I<not> inherited from the base class.
#pod
#pod =cut

sub Program {
    my ( $self ) = @_;
    return $self->{ Program } || $self->{ program } || 'This program';
};

#pod =method notice
#pod
#pod This method overrides L<Software::License>'s C<notice>. Differences are:
#pod
#pod =for :list
#pod *   If the license object was created with C<program> or C<Program> or both options, notice will
#pod     include real program name instead of generic "this program".
#pod *   It returns copyright statement followed by standard GNU 3-paragraph license notice.
#pod *   Result is formatted with L<Text::Wrap::fill|Text::Wrap>.
#pod
#pod The method can be called with C<'short'> argument to get short version of notice. Short version
#pod includes: copyright statement, license name, and two sentences about free software and warranties.
#pod Note: This is experimental feature.
#pod
#pod =cut

sub notice {
    my ( $self, $arg ) = @_;
    my $notice = Text::Wrap::fill( '', '', $self->_fill_in( $arg || 'NOTICE' ) );
    #   Documentation on `fill` says it deletes all trailing whitespace, but it looks like it
    #   may leave one space. Let us make sure notice ends with one newline.
    $notice =~ s{\s*\z}{\n}x;
    return $notice;
};

#pod =attr version
#pod
#pod License version (base license version with appended plus sign to denote "or later" clause).
#pod
#pod =cut

sub version {
    my ( $self ) = @_;
    return $self->base->version . '+';
};

1;

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# doc/what.pod #

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Software-License-OrLaterPack> (or just C<OrLaterPack> for brevity) is an add-on for C<Software-License>, a set
#pod of licenses with "or later" clause (like C<GPL_3::or_later>). It allows Perl developers (who use
#pod C<Dist-Zilla>) to release their work under the terms of a I<License> version I<N> or (at user
#pod option) any later version.
#pod
#pod =cut

# end of file #

=pod

=encoding UTF-8

=head1 NAME

Software::License::AGPL_3::or_later - AGPLv3+ license for Software::License infrastructure

=head1 VERSION

Version v0.10.2, released on 2016-10-10 22:17 UTC.

=head1 WHAT?

C<Software-License-OrLaterPack> (or just C<OrLaterPack> for brevity) is an add-on for C<Software-License>, a set
of licenses with "or later" clause (like C<GPL_3::or_later>). It allows Perl developers (who use
C<Dist-Zilla>) to release their work under the terms of a I<License> version I<N> or (at user
option) any later version.

This is C<Software::License::AGPL_3::or_later> module documentation. Read this if you
are going to hack or extend the module, or use the module directly.

If you want to use GNU license with "or later" clause read the L<user
manual|Software::License::OrLaterPack>. General topics like getting source, building, installing,
bug reporting and some others are covered in the F<README> file.

=head1 SYNOPSIS

    my $lic = Software::License::AGPL_3::or_later->new( {
        holder  => 'John Doe',
        year    => '2010',
        program => 'Assa'
    } );

    $lic->_abbr;    # 'AGPL'
    $lic->abbr;     # 'AGPLv3+'
    $lic->_name;    # 'GNU Affero General Public License'
    $lic->name;     # 'The GNU Affero General Public License version 3 or later'

    $lic->notice;
        # Copyright statement and
        # standard GNU 3-paragraph license notice.
    $lic->notice( 'short' );
        # Copyright statement, license name and
        # two sentences about free software and warranties.

    # …and other methods inherited from Software::License::AGPL_3
    # and Software::License.

=head1 DESCRIPTION

C<Software::License::AGPL_3::or_later> is a subclass of C<Software::License::AGPL_3>.
It overrides few parent methods and introduces few own methods.

See documentation on L<Software::License> for a general description of the class interface.

=head1 OBJECT ATTRIBUTES

=head2 _abbr

Bare abbreviated license name, "AGPL".

Note: this attribute is I<not> inherited from the base class.

=head2 abbr

Abbreviated license name: concatenated bare abbreviated license name, 'v' character, and license
version (with trailing plus sign).

Note: this attribute is I<not> inherited from the base class.

=head2 base

A reference to base license object, i. e. license without "or later" clause.

Note: this attribute is I<not> inherited from the base class.

=head2 _name

Bare name of the license, which is also bare name of the base license, because it does
include neither definitive article ("The"), nor license version nor "or later" clause:
"GNU Affero General Public License".

Note: this attribute is I<not> inherited from the base class.

=head2 name

This attribute meets C<Software::License> specification: returned name starts with definitive
capitalized article ("The"). Returned name also includes the base license version (like other
C<Software::License> classes do) (without trailing plus sign) and "or later" clause.

=head2 program

A program name as specified by the C<program> option in constructor, or the C<Program> option in
constructor, or "this program". This form of program name is intended to be used in the middle of
sentence.

Note: this attribute is I<not> inherited from the base class.

=head2 Program

A program name as specified by the C<Program> option in constructor, or the C<program> option in
constructor, or "This program". This form of program name is intended to be used in the beginning
of sentence.

Note: this attribute is I<not> inherited from the base class.

=head2 version

License version (base license version with appended plus sign to denote "or later" clause).

=head1 OBJECT METHODS

=head2 notice

This method overrides L<Software::License>'s C<notice>. Differences are:

=over 4

=item *

If the license object was created with C<program> or C<Program> or both options, notice will include real program name instead of generic "this program".

=item *

It returns copyright statement followed by standard GNU 3-paragraph license notice.

=item *

Result is formatted with L<Text::Wrap::fill|Text::Wrap>.

=back

The method can be called with C<'short'> argument to get short version of notice. Short version
includes: copyright statement, license name, and two sentences about free software and warranties.
Note: This is experimental feature.

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut

__DATA__

__NOTICE__
Copyright (C) {{$self->year}} {{$self->holder}}

{{$self->Program}} is free software: you can redistribute it and/or modify it
under the terms of the {{$self->_name}} as published by the Free Software Foundation, either
version {{$self->base->version}} of the License, or (at your option) any later version.

{{$self->Program}} is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the {{$self->_name}} for more details.

You should have received a copy of the {{$self->_name}} along with
{{$self->program}}. If not, see <http://www.gnu.org/licenses/>.

__short__
Copyright (C) {{$self->year}} {{$self->holder}}

License {{$self->abbr}}: {{$self->name}}
<{{$self->url}}>.

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

__END__

# end of file #
