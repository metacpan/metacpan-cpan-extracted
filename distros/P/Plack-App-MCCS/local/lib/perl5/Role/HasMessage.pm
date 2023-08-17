package Role::HasMessage 0.007;
use Moose::Role;
# ABSTRACT: a thing with a message method

#pod =head1 DESCRIPTION
#pod
#pod This is another extremely simple role.  A class that includes
#pod Role::HasMessage is promising to provide a C<message> method that
#pod returns a string summarizing the message or event represented by the object.
#pod It does I<not> provide any actual behavior.
#pod
#pod =cut

requires 'message';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::HasMessage - a thing with a message method

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This is another extremely simple role.  A class that includes
Role::HasMessage is promising to provide a C<message> method that
returns a string summarizing the message or event represented by the object.
It does I<not> provide any actual behavior.

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
