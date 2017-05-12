package SQL::SqlObject::ODBC;

use strict;
use warnings;
use SQL::SqlObject;
use base 'SQL::SqlObject';

# additional/redefined args
SQL::SqlObject::Config::set DSN         => 'dbi:ODBC';
#SQL::SqlObject::Config::set NAME_PREFIX => '';

# initilization ruitine
sub _init { shift->db_name_prefix = '' }

# overload the hash quoting mechinism.
#   -ODBC wants it's numeric values quoted. (ECE)
sub _sql_quote_hash
  {
    Carp::confess "sql_quote_hash: No hash ref specified" unless @_ > 1;
    my ($self, $href) = @_;
    while ( my ($k,$v) = each %$href) {
      $v =~ s|^'||;   # Remove initial and final quotes, just in case.
      $v =~ s|'$||;
      $v =~ s|'|''|g; # Double the single-quotes in the string
      $v =~ s|"|""|g; # Double the double-quotes in the string
      $v =  qq('$v') unless $v =~ /^null$/;
      $href->{$k}=$v;
    }
}

1;
__END__

=head1 NAME

SQL::SqlObject::ODBC;

=head1 SYNOPSYS

  use SQL::SqlObject::ODBC;
  my $dbh = new Sql::SqlObject::ODBC($db_name);

=head1 DESCRIPTION

A subclass of SQL::SqlObject to support ODBC under L<DBI>, implemeting
the L<DBD::ODBC driver|DBD::ODBC>.

=head1 SEE ALSO

=over 

=item *
SQL::SqlObject

L<SQL::SqlObject>

=item *
DBD::ODBC

L<DBD::ODBC>

=back

=head1 AUTHOR

The ODBC extention to the SqlObject interface was written by

Corwin Brust E<lt>corwin@mpls.cxE<gt> and
Rev. Erik C. Elmshauser, D.D. E<lt>erike@pbgnw.comE<gt>

=head1 NOTE

This module may be redistributed under the same terms as perl.

=cut
