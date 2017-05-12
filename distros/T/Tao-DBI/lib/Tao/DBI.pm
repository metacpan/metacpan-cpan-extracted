
package Tao::DBI;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

#our @EXPORT = qw(dbi_connect dbi_prepare);
our @EXPORT = qw(dbi_prepare);

our $VERSION = '0.012';

use Tao::DBI::db;
use Tao::DBI::st;

sub dbi_connect {
    __PACKAGE__->connect(@_);
}

sub connect {
    shift;
    return new Tao::DBI::db(@_);
}

sub dbi_prepare {
    my $sql  = shift;
    my $args = shift;
    return new Tao::DBI::st( { sql => $sql, %$args } );
}

1;

__END__

=head1 NAME

Tao::DBI - Portable support for named placeholders in DBI statements

=head1 SYNOPSIS

  use Tao::DBI;
  
  $dbh = Tao::DBI->connect({ dsn => $dsn, user => $user, pass => $pass });
  $sql = q{UPDATE T set a = :a, b = :b where k = :k};
  $stmt = $dbh->prepare($sql);
  $rc = $stmt->execute({ k => $k, a => $a, b => $b });
  

=head1 DESCRIPTION

B<THIS IS PRE-ALPHA SOFTWARE! MANY BUGS LURKING AROUND!>

perldoc DBI - section "Placeholders and Bind Values"

"Some drivers also allow placeholders like :name and :n 
(e.g., :1, :2, and so on) in addition to ?, but their 
use is not portable."


=over 4

=item B<connect>

  my $dbh = Tao::DBI->connect($args);

Returns a new database connection built from the arguments
in hash ref C<$args>. 

I<Note.> The previous C<dbi_prepare> function which was
exported on demand was deprecated in favor of this class
method that looks more DBIsh.

=item B<dbi_prepare>

  my $sth = dbi_prepare($args);

Returns a new prepared statement. This statement supports
named placeholders (like :a) whether the driver supports
it or not. (However, the driver has to support ? placeholders.)

You don't have to import this function if you plan
to create DBI connections via C<Tao::DBI::dbi_connect>,
because these will automatically support SQL with
named placeholders in C<prepare>.

=back

=head2 EXPORT

C<dbi_connect> and C<dbi_prepare> can be exported on demand.
C<dbi_connect> was deprecated. I think C<dbi_prepare> will
have the same fate soon.

=head1 PRINCIPLES OF THIS TAO

Every constructor is designed to accept named 
parameters.

  my $o = new Tao::DBI::o($hashref);
  # or
  my $o = new Tao::DBI::o(k1 => $v1, k2 => $v2);

This is one Tao, not the only one. As long
as it aims to perfection, it is Tao. It does not
need to aim to uniqueness. (This is not Python.
TIMTOWTDI.)

=head1 TAO STATEMENTS

Tao statements are DBI statements.

For Tao statements, both sets of parameters/placeholders
and rows I<may> be represented as hash refs.
The main point of this usage is to represent
an ensemble of values as one.

  $stmt->execute($params);
  while ($row = $stmt->fetch_hashref()) {
    ...
  }

If parameters are added, removed or modified
(eg. by changing data types), the code often
stays the same.

The emphasis on naming parts (hash keys)
also has to with this approach. Not relying
on artificial indices is good. Self-documenting
with well-chosen names is good too.

One intentional benefit of the uniform treatment
of statement parameters and selected rows
is the possibility of extracting data
via SELECT statements and injecting it
(possibly after transformation) via INSERT
and UPDATE statements. One example is in order,
but I am just too lazy today.

=head1 SEE ALSO

L<DBI>

=head1 BUGS

Please report bugs via CPAN RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tao-DBI>.

=head1 AUTHOR

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
