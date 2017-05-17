package PAUSE::Permissions::Entry;
$PAUSE::Permissions::Entry::VERSION = '0.17';
use Moo;

has 'module'     => (is => 'ro');
has 'user'       => (is => 'ro');
has 'permission' => (is => 'ro');

1;

=head1 NAME

PAUSE::Permissions::Entry - represents one line from 06perms.txt

=head1 SYNOPSIS

 use PAUSE::Permissions::Entry;
 
 my $mp = PAUSE::Permissions::Entry->new(
                module => 'Module::Path',
                user   => 'NEILB',
                module => 'f',
                );
 
=head1 DESCRIPTION

PAUSE::Permissions::Entry is a data class that holds the information
from one line in 06perms.txt.
Generally you won't instantiate this class directly, but will get
back instances of it when you request an C<entry_iterator>
from L<PAUSE::Permissions>.

=head1 SEE ALSO

L<PAUSE::Permissions>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

