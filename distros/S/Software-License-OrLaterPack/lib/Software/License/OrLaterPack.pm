#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Software/License/OrLaterPack.pm
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

#   This is dummy main module of `OrLaterPack`, because CPAN does not handle well distributions
#   without a main module. Also, it documents the distribution as a whole.

package Software::License::OrLaterPack;

use strict;     # Let Kwalitee be happy.
use warnings;   # Ditto.
use version 0.77;

# ABSTRACT: Use GNU license with "or later" clause
our $VERSION = 'v0.10.2'; # VERSION

1;

#pod =pod
#pod
#pod =encoding UTF-8
#pod
#pod =for :this This is C<OrLaterPack> user manual. Read this if you want to use GNU license with "or later" clause.
#pod
#pod =for :those If you are going to hack or extend C<OrLaterPack> read module documentation, e. g.
#pod L<Software::License::GPL_3::or_later>. General topics like getting source, building, installing,
#pod bug reporting and some others are covered in the F<README> file.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 SYNOPSIS
#pod
#pod =for test_synopsis BEGIN { die "SKIP: Not Perl code.\n" };
#pod     # Ok, the second part is Perl code, but `Test::Synopsis` doesn't allow to check only part of
#pod     # synopsis.
#pod
#pod In C<dist.ini>:
#pod
#pod     name             = Foo-Bar
#pod     version          = 0.001
#pod     author           = John Doe <john.doe@example.com>
#pod     license          = GPL_3::or_later
#pod         ; or another license, see the list of provided licenses
#pod     copyright_holder = John Doe
#pod     copyright_year   = 2015
#pod     …
#pod
#pod Direct usage:
#pod
#pod     use Software::License::GPL_3::or_later;
#pod         # or another license, see the list of provided licenses
#pod     my $lic = Software::License::GPL_3::or_later->new( {
#pod         holder  => 'John Doe',
#pod         year    => '2010',
#pod         program => 'Assa',
#pod     } );
#pod     $lic->abbr;     # returns 'GPLv3+'
#pod     $lic->notice;   # Copyright statement and 3-paragraph GNU license notice
#pod     …
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 DESCRIPTION
#pod
#pod All "or later" are just subclasses of corresponding base license classes. For example,
#pod C<Software::License::GPL_3::or_later> is a subclass of C<Software::License::GPL_3>, so any "or
#pod later" license can be used like any other license. For example, in your F<dist.ini> file:
#pod
#pod     license = GPL_3::or_later
#pod
#pod However, licenses in the pack introduce few features not found in base classes.
#pod
#pod =head2 Program Name
#pod
#pod C<Software::License> constructor accepts hashref as the only argument:
#pod
#pod     $lic = Software::License::GPL_3::or_later->new( {
#pod         holder  => 'John Doe',
#pod         year    => '2010',
#pod     } );
#pod
#pod C<Software::License> documents two keys C<holder> and C<year> shown in example. However,
#pod C<Software::License> constructor just (re)blesses passed hashref to the package, keeping all the
#pod hash keys and values intact, so you can pass more arguments to the constructor.
#pod
#pod C<OrLaterPack> licenses use two more keys C<program> and C<Program>:
#pod
#pod     $lic = Software::License::GPL_3::or_later->new( {
#pod         holder  => 'John Doe',
#pod         year    => '2010',
#pod         program => 'assa',
#pod         Program => 'Assa',
#pod     } );
#pod
#pod These values are used as program name instead of generic "this program" in license notice, for
#pod example:
#pod
#pod     Assa is free software: you can redistribute it and/or modify it…
#pod
#pod C<program> key is used in the middle of sentence, C<Program> is used if program name starts a
#pod sentence. You may specify either one or both keys. If only one key specified, it is used in all the
#pod occurrences regardless of its position within a sentence.
#pod
#pod Note: At time of writing, these keys are used only by licenses from C<OrLaterPack>. You can safely
#pod pass them to constructor of any license, it does not hurt but keys will not be used.
#pod
#pod When using C<Dist::Zilla> you just specify few options, and C<Dist::Zilla> does all the work on
#pod behalf of you:
#pod
#pod     name                = Assa
#pod     license             = GPL_3::or_later
#pod     copyright_holder    = John Doe
#pod     copyright_year      = 2010
#pod
#pod Program name is specified, but C<Dist::Zilla> does not pass it to license object constructor. Patch
#pod for C<Dist::Zilla> submitted but not yet applied. Meanwhile, you can hack it with little help from
#pod C<Hook> plugin:
#pod
#pod     name                = Assa
#pod     license             = GPL_3::or_later
#pod     copyright_holder    = John Doe
#pod     copyright_year      = 2010
#pod     [Hook::Init]
#pod         . = $dist->license->{ program } = $dist->name;
#pod             ; Voilà: license has `program` key now.
#pod     ...
#pod
#pod For accessing these keys, C<OrLaterPack> introduced two methods: C<program> and C<Program>. They
#pod are convenient because you should not worry if the key was specified or not: a method returns best
#pod available variant of program name. For example, if C<program> key was not passed to the
#pod constructor, C<< $self->{ program } >> will return C<undef>, while C<< $self->program >> will
#pod return value of C<Program> key, if it was specified, or "this program" as the last resort. However,
#pod these methods are not defined in base class and can be invoked only on a license from
#pod C<OrLaterPack>.
#pod
#pod =head2 Short License Notice
#pod
#pod Standard GNU license notice consists of 3 paragraphs (more than 100 words and 600 characters). It
#pod is ok for the program documentation, but it far too long to be printed in the beginning of
#pod interactive session. For latter purpose FSF recommends to use short notice like this one:
#pod
#pod     Copyright (C) 2010 John Doe
#pod     License GPLv3+: GNU General Public License version 3 or later.
#pod     This is free software: you are free to change and redistribute it.
#pod     There is NO WARRANTY, to the extent permitted by law.
#pod
#pod To get short license notice, pass C<'short'> argument to the C<notice> method:
#pod
#pod     $lic->notice( 'short' );
#pod
#pod At time of writing, C<'short'> argument is respected only by licenses in C<orLaterPack>. Other
#pod licenses ignore the arguments and return ordinary license note.
#pod
#pod Note: This feature is considered experimental now.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 LIST OF PROVIDED LICENSES
#pod
#pod =for :list
#pod = L<Software::License::AGPL_3::or_later>
#pod = L<Software::License::GPL_1::or_later>
#pod = L<Software::License::GPL_2::or_later>
#pod = L<Software::License::GPL_3::or_later>
#pod = L<Software::License::LGPL_2_1::or_later>
#pod = L<Software::License::LGPL_3_0::or_later>
#pod
#pod
#pod =head1 CAVEATS
#pod
#pod L<CPAN::Meta::Spec> hardcodes the list of "valid" licenses. In version 2.150001 of the module there
#pod are no "upgradable" GNU licenses, so in CPAN the GPLv3+ will look as ordinal GPLv3 (C<gpl_3>), and
#pod so on.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod =   L<Dist::Zilla>
#pod =   L<Dist::Zilla::Plugin::Hook>
#pod =   L<Software::License>
#pod =   L<Why should programs say “Version 3 of the GPL or any later version”?|https://www.gnu.org/licenses/gpl-faq.html#VersionThreeOrLater>
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
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
# doc/why.pod #

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod C<Dist-Zilla> is a popular tool for building CPAN distributions. Build process is controlled by
#pod F<dist.ini>, C<Dist-Zilla> configuration file. A distribution author can specify license covering
#pod his work by using C<license> option in F<dist.ini> file:
#pod
#pod     license = NAME
#pod
#pod where I<NAME> is a name of module from L<Software::License> hierarchy.
#pod
#pod C<Software-License> is shipped with a set of popular licenses, from C<Apache_1_1> to C<Zlib>,
#pod including GNU licenses (GPL), including their "Affero" and "Lesser" variants.
#pod
#pod So, if a developer wants to release his work under the terms of the GPL version 3, he should write
#pod in his F<dist.ini>:
#pod
#pod     license = GPL_3
#pod
#pod However, L<Free Software Foundation recommends using clause "license version I<N> or (at your
#pod option) any later version"|https://www.gnu.org/licenses/gpl-faq.html#VersionThreeOrLater>. Unfortunately, C<Software-License> distribution
#pod does not supply (out of the box) a way to express such clause.
#pod
#pod C<OrLaterPack> fulfills the lack. If C<OrLaterPack> is installed, a developer can specify in his
#pod F<dist.ini>:
#pod
#pod     license = GPL_3::or_later
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::License::OrLaterPack - Use GNU license with "or later" clause

=head1 VERSION

Version v0.10.2, released on 2016-10-10 22:17 UTC.

=head1 WHAT?

C<Software-License-OrLaterPack> (or just C<OrLaterPack> for brevity) is an add-on for C<Software-License>, a set
of licenses with "or later" clause (like C<GPL_3::or_later>). It allows Perl developers (who use
C<Dist-Zilla>) to release their work under the terms of a I<License> version I<N> or (at user
option) any later version.

This is C<OrLaterPack> user manual. Read this if you want to use GNU license with "or later" clause.

If you are going to hack or extend C<OrLaterPack> read module documentation, e. g.
L<Software::License::GPL_3::or_later>. General topics like getting source, building, installing,
bug reporting and some others are covered in the F<README> file.

=head1 SYNOPSIS

=head1 DESCRIPTION

All "or later" are just subclasses of corresponding base license classes. For example,
C<Software::License::GPL_3::or_later> is a subclass of C<Software::License::GPL_3>, so any "or
later" license can be used like any other license. For example, in your F<dist.ini> file:

    license = GPL_3::or_later

However, licenses in the pack introduce few features not found in base classes.

=head2 Program Name

C<Software::License> constructor accepts hashref as the only argument:

    $lic = Software::License::GPL_3::or_later->new( {
        holder  => 'John Doe',
        year    => '2010',
    } );

C<Software::License> documents two keys C<holder> and C<year> shown in example. However,
C<Software::License> constructor just (re)blesses passed hashref to the package, keeping all the
hash keys and values intact, so you can pass more arguments to the constructor.

C<OrLaterPack> licenses use two more keys C<program> and C<Program>:

    $lic = Software::License::GPL_3::or_later->new( {
        holder  => 'John Doe',
        year    => '2010',
        program => 'assa',
        Program => 'Assa',
    } );

These values are used as program name instead of generic "this program" in license notice, for
example:

    Assa is free software: you can redistribute it and/or modify it…

C<program> key is used in the middle of sentence, C<Program> is used if program name starts a
sentence. You may specify either one or both keys. If only one key specified, it is used in all the
occurrences regardless of its position within a sentence.

Note: At time of writing, these keys are used only by licenses from C<OrLaterPack>. You can safely
pass them to constructor of any license, it does not hurt but keys will not be used.

When using C<Dist::Zilla> you just specify few options, and C<Dist::Zilla> does all the work on
behalf of you:

    name                = Assa
    license             = GPL_3::or_later
    copyright_holder    = John Doe
    copyright_year      = 2010

Program name is specified, but C<Dist::Zilla> does not pass it to license object constructor. Patch
for C<Dist::Zilla> submitted but not yet applied. Meanwhile, you can hack it with little help from
C<Hook> plugin:

    name                = Assa
    license             = GPL_3::or_later
    copyright_holder    = John Doe
    copyright_year      = 2010
    [Hook::Init]
        . = $dist->license->{ program } = $dist->name;
            ; Voilà: license has `program` key now.
    ...

For accessing these keys, C<OrLaterPack> introduced two methods: C<program> and C<Program>. They
are convenient because you should not worry if the key was specified or not: a method returns best
available variant of program name. For example, if C<program> key was not passed to the
constructor, C<< $self->{ program } >> will return C<undef>, while C<< $self->program >> will
return value of C<Program> key, if it was specified, or "this program" as the last resort. However,
these methods are not defined in base class and can be invoked only on a license from
C<OrLaterPack>.

=head2 Short License Notice

Standard GNU license notice consists of 3 paragraphs (more than 100 words and 600 characters). It
is ok for the program documentation, but it far too long to be printed in the beginning of
interactive session. For latter purpose FSF recommends to use short notice like this one:

    Copyright (C) 2010 John Doe
    License GPLv3+: GNU General Public License version 3 or later.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

To get short license notice, pass C<'short'> argument to the C<notice> method:

    $lic->notice( 'short' );

At time of writing, C<'short'> argument is respected only by licenses in C<orLaterPack>. Other
licenses ignore the arguments and return ordinary license note.

Note: This feature is considered experimental now.

=head1 WHY?

C<Dist-Zilla> is a popular tool for building CPAN distributions. Build process is controlled by
F<dist.ini>, C<Dist-Zilla> configuration file. A distribution author can specify license covering
his work by using C<license> option in F<dist.ini> file:

    license = NAME

where I<NAME> is a name of module from L<Software::License> hierarchy.

C<Software-License> is shipped with a set of popular licenses, from C<Apache_1_1> to C<Zlib>,
including GNU licenses (GPL), including their "Affero" and "Lesser" variants.

So, if a developer wants to release his work under the terms of the GPL version 3, he should write
in his F<dist.ini>:

    license = GPL_3

However, L<Free Software Foundation recommends using clause "license version I<N> or (at your
option) any later version"|https://www.gnu.org/licenses/gpl-faq.html#VersionThreeOrLater>. Unfortunately, C<Software-License> distribution
does not supply (out of the box) a way to express such clause.

C<OrLaterPack> fulfills the lack. If C<OrLaterPack> is installed, a developer can specify in his
F<dist.ini>:

    license = GPL_3::or_later

=for comment ---------------------------------------------------------------------------------------

=for test_synopsis BEGIN { die "SKIP: Not Perl code.\n" };
    # Ok, the second part is Perl code, but `Test::Synopsis` doesn't allow to check only part of
    # synopsis.

In C<dist.ini>:

    name             = Foo-Bar
    version          = 0.001
    author           = John Doe <john.doe@example.com>
    license          = GPL_3::or_later
        ; or another license, see the list of provided licenses
    copyright_holder = John Doe
    copyright_year   = 2015
    …

Direct usage:

    use Software::License::GPL_3::or_later;
        # or another license, see the list of provided licenses
    my $lic = Software::License::GPL_3::or_later->new( {
        holder  => 'John Doe',
        year    => '2010',
        program => 'Assa',
    } );
    $lic->abbr;     # returns 'GPLv3+'
    $lic->notice;   # Copyright statement and 3-paragraph GNU license notice
    …

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=head1 LIST OF PROVIDED LICENSES

=over 4

=item L<Software::License::AGPL_3::or_later>

=item L<Software::License::GPL_1::or_later>

=item L<Software::License::GPL_2::or_later>

=item L<Software::License::GPL_3::or_later>

=item L<Software::License::LGPL_2_1::or_later>

=item L<Software::License::LGPL_3_0::or_later>

=back

=head1 CAVEATS

L<CPAN::Meta::Spec> hardcodes the list of "valid" licenses. In version 2.150001 of the module there
are no "upgradable" GNU licenses, so in CPAN the GPLv3+ will look as ordinal GPLv3 (C<gpl_3>), and
so on.

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Plugin::Hook>

=item L<Software::License>

=item L<Why should programs say “Version 3 of the GPL or any later version”?|https://www.gnu.org/licenses/gpl-faq.html#VersionThreeOrLater>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
