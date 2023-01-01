package Role::Identifiable 0.009;
# ABSTRACT: a thing you can identify somehow

use strict;
use warnings;

#pod =head1 DESCRIPTION
#pod
#pod Role::Identifiable isn't really a module that does anything.  It's here to make
#pod things simpler for indexing on CPAN and looking up docs.
#pod
#pod You probably want to use either L<Role::Identifiable::HasIdent>, for
#pod identifying things by an identifier string, or L<Role::Identifiable::HasTags>
#pod for identifying things by a list of tags.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::Identifiable - a thing you can identify somehow

=head1 VERSION

version 0.009

=head1 DESCRIPTION

Role::Identifiable isn't really a module that does anything.  It's here to make
things simpler for indexing on CPAN and looking up docs.

You probably want to use either L<Role::Identifiable::HasIdent>, for
identifying things by an identifier string, or L<Role::Identifiable::HasTags>
for identifying things by a list of tags.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
