
package Tao::DBI::db;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.012';

use DBI;
use Tao::DBI::st;
use Tao::DBI::st_deep;

# the instance variables:
# DBH
# NAME

# usage:
# $dbh = new Tao::DBI::db($args);
sub new {
    my ( $proto, $args ) = @_;
    my $class = ref($proto) || $proto;
    my $obj = bless {}, $class;
    $obj->initialize($args);
    return $obj;
}

# usage:
#   $dbh->initialize($args);
# where $args is
# { name => , dsn|url => , user => , password =>, options passed to DBI->connect }
#
#
# protected
sub initialize {
    my ( $self, $args ) = @_;

    $self->{NAME} = $args->{name};
    $self->{URL}  = $args->{dsn} || $args->{url};
    $self->{USER} = $args->{user};
    $self->{PASS} = $args->{password};
    unless ( exists $args->{FetchHashKeyName} ) {
        $args->{FetchHashKeyName} = 'NAME_lc';
    }
    unless ( exists $args->{AutoCommit} ) {
        $args->{AutoCommit} = 0;
    }

    my $dbh = DBI->connect( $self->{URL}, $self->{USER}, $self->{PASS}, $args )
      ;   # remaining arguments can be passed to DBI->connect (needs improving!)
    if ($dbh) {
        $self->{DBH} = $dbh;
    }
    else {
        die "Can't establish connection '$self->{NAME}': $DBI::errstr\n";
    }
}

# $stmt = $dbh->prepare($sql, $args);
# $stmt = $dbh->prepare($args); # $args is hashref
sub prepare {
    my $self = shift;
    my $sql;
    $sql = shift unless ref $_[0];    # first non-ref arg
    my $args    = shift         || {};
    my $st_type = $args->{type} || 'plain';
    if ( $st_type eq 'plain' ) {
        return new Tao::DBI::st(
            {
                ( $sql ? ( sql => $sql ) : () ),
                dbh => $self->{DBH},
                %$args
            }
        );
    }
    elsif ( $st_type eq 'deep' ) {
        return new Tao::DBI::st_deep(
            {
                ( $sql ? ( sql => $sql ) : () ),
                dbh => $self->{DBH},
                %$args
            }
        );
    }
    else {
        die "unknown statement type: $st_type\n";
    }
}

use vars qw ($AUTOLOAD);

# If method wasn't found, delegates to DBH instance variable.
# This way, instances of this class behaves like DBI connections.
#
# this needs improvement: non existent methods will provoke weird
# messages from DBI objects, instead of Tao::DBI::db
sub AUTOLOAD {
    my $self = shift;
    my $meth = $AUTOLOAD;
    $meth =~ s/.*:://;
    return $self->{DBH}->$meth(@_);
}

sub DESTROY { }

1;

# May 29, 2003

__END__

=head1 NAME

Tao::DBI::db - DBI connection with portable support for named placeholders in statements

=head1 SYNOPSIS

  use Tao::DBI qw(dbi_connect dbi_prepare);
  
  $dbh = dbi_connect($args);
  $sql = q{UPDATE T set a = :a, b = :b where k = :k};
  $stmt = $dbh->prepare($sql);
  $rc = $stmt->execute({ k => $k, a => $a, b => $b });
  
  # dbi_prepare() can also be used to create Tao::DBI::st
  $stmt = dbi_prepare($sql, { dbh => $dbh });
  

=head1 DESCRIPTION



=over 4

=item B<new>

  $dbh = DBI::db::new($args)

Note. Unless C<$args> has an explicit pair at key C<"FetchHashKeyName">,
the connection uses C<"FetchHashKeyName" => 'NAME_lc'> which
forces the keys in C<fetchrow_arrayref> to come in lower case.

Note. Unless C<$args> has an explicit pair at key C<"AutoCommit">,
the connection uses C<"AutoCommit" => 0> which
means you have to commit or rollback explicitly.

=item B<execute>

  $sth->execute($hash);
  $sth->execute($param);
  $sth->execute;

Returns 

=back

=head2 EXPORT

Nothing to be exported. Every method is available as a method.

=begin comment

=head1 SEE ALSO

=end comment

=head1 BUGS

Please report bugs via CPAN RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tao-DBI>.

=head1 AUTHOR

Adriano R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
