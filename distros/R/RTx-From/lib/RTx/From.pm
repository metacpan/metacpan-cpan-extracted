package RTx::From;
our $VERSION = 0.04;

1;

__END__

=pod

=head1 NAME

RTx::From - Make it easier to find users and their tickets

=head1 SYNOPSIS

It can be hard to remember the exact name and email address of a user.
While powerful, the Configuration/Users search form can be tedious, nor
is it an obvious location. Therefore this simple plugin:

=over

=item Adds a C<from:> operator to Simple Search.

Note that unlike most other operators, which modify ticket queries,
this operator acts on principals and therefore cannot be meaningfully
combined with other search terms. The results of doing so are undefined
and unsupported. However, you may supply multiple C<from:> terms, which
will be OR'd together.

There is also a work-around if you wish to perform a complex query for
tickets from a fuzzily-remembered requestor:

=over

=item * Search with C<from:>

=item * Select "Requested" for the desired user

=item * "Edit Search"

=back

=item Adds a brief description of the operator, and a link to the native
user search on F<Search/Simple.html>.

=item Adds a sub-tab on a user's profile to a query for his tickets.

=item Lastly, if RTx::BecomeUser is loaded and accessible by the current user,
the search results stemming from a C<from:> search will include links to
convenience links to become ach of the matching users.

=back

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

=head1 SEE ALSO

L<RTx::BecomeUser>

=head1 LICENSE

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

Except F<Admin/Users/from.html> which is derived from GPL work by
Best Practical. But really, you can consider the above to be
"the same terms as perl itself."

=back

=cut
