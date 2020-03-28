package Regexp::Pattern::Git;

our $DATE = '2020-03-26'; # DATE
our $VERSION = '0.002'; # VERSION

our %RE = (
    ref => {
        summary => 'Valid reference name',
        description => <<'_',

This single regex pattern enforces the rules defined by the git-check-ref-format
manpage, reproduced below:

1. They can include slash / for hierarchical (directory) grouping, but no
   slash-separated component can begin with a dot . or end with the sequence
   .lock.

2. They must contain at least one /. This enforces the presence of a category
   like heads/, tags/ etc. but the actual names are not restricted.

3. They cannot have two consecutive dots .. anywhere.

4. They cannot have ASCII control characters (i.e. bytes whose values are lower
   than \040, or \177 DEL), space, tilde ~, caret ^, or colon : anywhere.

5. They cannot have question-mark ?, asterisk *, or open bracket [ anywhere.

6. They cannot begin or end with a slash / or contain multiple consecutive
   slashes.

7. They cannot end with a dot ..

8. They cannot contain a sequence: @ followed by {.

9. They cannot be the single character @.

10. They cannot contain a \.

_
        pat => qr(
                     \A(?:

                         # 1. (a) no slash-separated component can begin with a dot
                         (?!\.)
                         (?![^/]+/\.)

                         # 1. (b) ... or end with ".lock"
                         (?![^.]*\.lock(?:\z|/))

                         # 2. must contain at least one /
                         (?=[^/]*/)

                         # 3. cannot contain two consecutive dots anywhere
                         (?![^.]*\.\.)

                         # 4. cannot contain control char (<\040), DEL (\0177), space, tilde, caret, or colon anywhere
                         (?![^\000-\037\177 ~^:]*[\000-\037\177 ~^:])

                         # 5. cannot have question-mark ?, asterisk *, or open bracket [ anywhere
                         (?![^?*\[]*[?*\[])

                         # 6. (a) cannot begin with a slash, or contain multiple slashes
                         (?!/)
                         (?![^/]*//)

                         # 8. cannot contain the sequence: @ followed by {
                         (?![^@]*@\{)

                         # 9. cannot be single character @, implied by rule #2

                         # 10. cannot contain backslash
                         (?![^\\]*\\)

                         .+

                         # 6. (b) cannot end with a slash
                         (?<!/)

                         # 7. cannot end with a dot
                         (?<!\.)
                     )\z
                 )x,
        tags => ['anchored'],
        examples => [
            {str=>'foo/bar', matches=>1},

            {str=>'.foo/bar', matches=>0, summary=>'A slash-separated component begins with dot (rule 1)'},
            {str=>'foo/.bar', matches=>0, summary=>'A slash-separated component begins with dot (rule 1)'},

            {str=>'foo.lock/bar', matches=>0, summary=>'A slash-separated component ends with ".lock" (rule 1)'},
            {str=>'foo.locker/bar', matches=>1},
            {str=>'foo/bar.lock', matches=>0, summary=>'A slash-separated component ends with ".lock" (rule 1)'},
            {str=>'foo/bar.lock/baz', matches=>0, summary=>'A slash-separated component ends with ".lock" (rule 1)'},
            {str=>'foo/bar.locker/baz', matches=>1},

            {str=>'foo', matches=>0, summary=>'Does not contain at least one / (rule 2)'},

            {str=>'foo../bar', matches=>0, summary=>'Contains two consecutive dots (rule 3)'},

            {str=>'foo:/bar', matches=>0, summary=>'Contains colon (rule 4)'},

            {str=>'foo?/bar', matches=>0, summary=>'Contains question mark (rule 5)'},
            {str=>'foo[2]/bar', matches=>0, summary=>'Contains open bracket (rule 5)'},

            {str=>'/foo/bar', matches=>0, summary=>'Begins with / (rule 6)'},
            {str=>'foo/bar/', matches=>0, summary=>'Ends with / (rule 6)'},
            {str=>'foo//bar', matches=>0, summary=>'Contains multiple consecutive slashes'},

            {str=>'foo/bar.', matches=>0, summary=>'Ends with . (rule 7)'},

            {str=>'foo@{/bar', matches=>0, summary=>'Contains sequence @{ (rule 8)'},
            {str=>'foo@{baz}/bar', matches=>0, summary=>'Contains sequence @{ (rule 8)'},

            {str=>'@', matches=>0, summary=>'Cannot be single character @ (rule 9)'},
        ],
    },

    release_tag => {
        summary => 'Common release tag pattern',
        pat => qr/(?:(?:version|ver|v|release|rel)[_-]?)?\d/,
        description => <<'_',

This is not defined by git, but just common convention.

_
        tags => ['convention'],
        examples => [
            {str=>'release', matches=>0, summary=>'Does not contain digit'},
            {str=>'1', matches=>1},
            {str=>'1.23-456-foobar', matches=>1},
            {str=>'release-1.23', matches=>1},
            {str=>'v1.23', matches=>1},
            {str=>'ver-1.23', matches=>1},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to git

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Git - Regexp patterns related to git

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::Git (from Perl distribution Regexp-Pattern-Git), released on 2020-03-26.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Git::ref");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * ref

Valid reference name.

This single regex pattern enforces the rules defined by the git-check-ref-format
manpage, reproduced below:

=over

=item 1. They can include slash / for hierarchical (directory) grouping, but no
slash-separated component can begin with a dot . or end with the sequence
.lock.

=item 2. They must contain at least one /. This enforces the presence of a category
like heads/, tags/ etc. but the actual names are not restricted.

=item 3. They cannot have two consecutive dots .. anywhere.

=item 4. They cannot have ASCII control characters (i.e. bytes whose values are lower
than \040, or \177 DEL), space, tilde ~, caret ^, or colon : anywhere.

=item 5. They cannot have question-mark ?, asterisk *, or open bracket [ anywhere.

=item 6. They cannot begin or end with a slash / or contain multiple consecutive
slashes.

=item 7. They cannot end with a dot ..

=item 8. They cannot contain a sequence: @ followed by {.

=item 9. They cannot be the single character @.

=item 10. They cannot contain a .

=back


Examples:

 "foo/bar" =~ re("Git::ref");  # matches

A slash-separated component begins with dot (rule 1).

 ".foo/bar" =~ re("Git::ref");  # doesn't match

A slash-separated component begins with dot (rule 1).

 "foo/.bar" =~ re("Git::ref");  # doesn't match

A slash-separated component ends with ".lock" (rule 1).

 "foo.lock/bar" =~ re("Git::ref");  # doesn't match

 "foo.locker/bar" =~ re("Git::ref");  # matches

A slash-separated component ends with ".lock" (rule 1).

 "foo/bar.lock" =~ re("Git::ref");  # doesn't match

A slash-separated component ends with ".lock" (rule 1).

 "foo/bar.lock/baz" =~ re("Git::ref");  # doesn't match

 "foo/bar.locker/baz" =~ re("Git::ref");  # matches

Does not contain at least one E<sol> (rule 2).

 "foo" =~ re("Git::ref");  # doesn't match

Contains two consecutive dots (rule 3).

 "foo../bar" =~ re("Git::ref");  # doesn't match

Contains colon (rule 4).

 "foo:/bar" =~ re("Git::ref");  # doesn't match

Contains question mark (rule 5).

 "foo?/bar" =~ re("Git::ref");  # doesn't match

Contains open bracket (rule 5).

 "foo[2]/bar" =~ re("Git::ref");  # doesn't match

Begins with E<sol> (rule 6).

 "/foo/bar" =~ re("Git::ref");  # doesn't match

Ends with E<sol> (rule 6).

 "foo/bar/" =~ re("Git::ref");  # doesn't match

Contains multiple consecutive slashes.

 "foo//bar" =~ re("Git::ref");  # doesn't match

Ends with . (rule 7).

 "foo/bar." =~ re("Git::ref");  # doesn't match

Contains sequence @{ (rule 8).

 "foo\@{/bar" =~ re("Git::ref");  # doesn't match

Contains sequence @{ (rule 8).

 "foo\@{baz}/bar" =~ re("Git::ref");  # doesn't match

Cannot be single character @ (rule 9).

 "\@" =~ re("Git::ref");  # doesn't match

=item * release_tag

Common release tag pattern.

This is not defined by git, but just common convention.


Examples:

Does not contain digit.

 "release" =~ re("Git::release_tag");  # doesn't match

 1 =~ re("Git::release_tag");  # matches

 "1.23-456-foobar" =~ re("Git::release_tag");  # matches

 "release-1.23" =~ re("Git::release_tag");  # matches

 "v1.23" =~ re("Git::release_tag");  # matches

 "ver-1.23" =~ re("Git::release_tag");  # matches

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Git>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Git>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Git>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
