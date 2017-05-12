package Pg::Priv;

use 5.8.0;
use strict;
use warnings;

our $VERSION = '0.12';

my %label_for = (
    r => 'SELECT',
    w => 'UPDATE',
    a => 'INSERT',
    d => 'DELETE',
    D => 'TRUNCATE',
    x => 'REFERENCE',
    t => 'TRIGGER',
    X => 'EXECUTE',
    U => 'USAGE',
    C => 'CREATE',
    c => 'CONNECT',
    T => 'TEMPORARY',
);

my %priv_for = map { $label_for{$_} => $_ } keys %label_for;

# Some aliases.
$priv_for{TEMP} = 'T';

sub parse_acl {
    my ($class, $acl, $quote) = @_;
    return unless $acl;

    my @privs;
    my $prev;
    for my $perms (@{ $acl }) {
        # http://www.postgresql.org/docs/current/static/sql-grant.html#SQL-GRANT-NOTES
        my ($role, $privs, $by) = $perms =~ m{^"?(?:(?:group\s+)?([^=]+))?=([^/]+)/(.*)};
        $prev = $privs eq '*' ? $prev : $privs;
        $role ||= 'public';
        push @privs, $class->new(
            to    => $quote ? _quote_ident($role) : $role,
            by    => $quote ? _quote_ident($by)   : $by,
            privs => $prev,
        )
    }
    return wantarray ? @privs : \@privs;
}

sub new {
    my $class = shift;
    my $self = bless { @_ } => $class;
    $self->{parsed} = { map { $_ => 1 } split //, $self->{privs} || '' };
    return $self;
}

sub to    { shift->{to}  }
sub by    { shift->{by}    }
sub privs { shift->{privs} }
sub labels {
    wantarray ? map { $label_for{$_} } keys %{ shift->{parsed} }
              : [ map { $label_for{$_} } keys %{ shift->{parsed} } ];
}
sub can   {
    my $can = shift->{parsed} or return;
    for my $what (@_) {
        return unless $can->{ length $what == 1 ? $what : $priv_for{uc $what} };
    }
    return 1;
}

sub can_select    { shift->can('r') }
sub can_read      { shift->can('r') }
sub can_update    { shift->can('w') }
sub can_write     { shift->can('w') }
sub can_insert    { shift->can('a') }
sub can_append    { shift->can('a') }
sub can_delete    { shift->can('d') }
sub can_reference { shift->can('x') }
sub can_trigger   { shift->can('t') }
sub can_execute   { shift->can('X') }
sub can_usage     { shift->can('U') }
sub can_create    { shift->can('C') }
sub can_connect   { shift->can('c') }
sub can_temporary { shift->can('T') }
sub can_temp      { shift->can('T') }

# ack ' RESERVED_KEYWORD' src/include/parser/kwlist.h | awk -F '"' '{ print "    " $2 }'
my %reserved = ( map { $_ => undef } qw(
    all
    analyse
    analyze
    and
    any
    array
    as
    asc
    asymmetric
    both
    case
    cast
    check
    collate
    column
    constraint
    create
    current_catalog
    current_date
    current_role
    current_time
    current_timestamp
    current_user
    default
    deferrable
    desc
    distinct
    do
    else
    end
    except
    false
    fetch
    for
    foreign
    from
    grant
    group
    having
    in
    initially
    intersect
    into
    leading
    limit
    localtime
    localtimestamp
    new
    not
    null
    off
    offset
    old
    on
    only
    or
    order
    placing
    primary
    references
    returning
    select
    session_user
    some
    symmetric
    table
    then
    to
    trailing
    true
    union
    unique
    user
    using
    variadic
    when
    where
    window
    with
));

sub _is_reserved($) {
    exists $reserved{+shift};
}

sub _quote_ident($) {
    my $role = shift;
    # Can avoid quoting if ident starts with a lowercase letter or underscore
    # and contains only lowercase letters, digits, and underscores, *and* is
    # not any SQL keyword. Otherwise, supply quotes.
    return $role if $role =~ /^[_a-z](?:[_a-z0-9]+)?$/ && !_is_reserved $role;
    $role =~ s/"/""/g;
    return qq{"$role"};
}

1;
__END__

##############################################################################

=head1 Name

Pg::Priv - PostgreSQL ACL parser and iterator

=head1 Synopsis

  use DBI;
  use Pg::Priv;

  my $dbh = DBI->connect('dbi:Pg:dbname=template1', 'postgres', '');
  my $sth = $dbh->prepare(
      q{SELECT relname, relacl FROM pg_class WHERE relkind = 'r'}
  );

  $sth->execute;
  while (my $row = $sth->fetchrow_hashref) {
      print "Table $row->{relname}:\n";
      for my $priv ( Pg::Priv->parse_acl( $row->{relacl} ) ) {
          print '    ', $priv->by, ' granted to ', $priv->to, ': ',
              join( ', ', $priv->labels ), $/;
      }
  }

=head1 Description

This module parses PostgreSQL ACL arrays and represents the underlying
privileges as objects. Use accessors on the objects to see what privileges are
granted by whom and to whom.

PostgreSQL ACLs are arrays of strings. Each string represents a single set of
privileges granted by one role to another role. ACLs look something like this:

  my $acl = [
     'miriam=arwdDxt/miriam',
     '=r/miriam',
     'admin=arw/miriam',
  ];

The format of the privileges are interpreted thus (borrowed from the
L<PostgreSQL
Documentation|http://www.postgresql.org/docs/current/static/sql-grant.html#SQL-GRANT-NOTES>):

       rolename=xxxx -- privileges granted to a role
               =xxxx -- privileges granted to PUBLIC

                   r -- SELECT ("read")
                   w -- UPDATE ("write")
                   a -- INSERT ("append")
                   d -- DELETE
                   D -- TRUNCATE
                   x -- REFERENCES
                   t -- TRIGGER
                   X -- EXECUTE
                   U -- USAGE
                   C -- CREATE
                   c -- CONNECT
                   T -- TEMPORARY
             arwdDxt -- ALL PRIVILEGES (for tables, varies for other objects)
                   * -- grant option for preceding privilege

               /yyyy -- role that granted this privilege

Pg::Priv uses these rules (plus a few other gotchas here and there) to parse
these privileges into objects. The above three privileges in the ACL array
would thus be returned by C<parse_acl()> as three Pg::Priv objects that you
could then interrogate.

=head1 Interface

=head2 Class Methods

=head3 parse_acl

  for my $priv ( Pg::Priv->parse_acl($acl) ) {
      print '    ', $priv->by, ' granted to ', $priv->to, ': ',
          join( ', ', $priv->labels ), $/;
  }

Takes a PostgreSQL ACL array, parses it, and returns a list or array reference
of Pg::Priv objects. Pass an optional second argument to specify that role
names should be quoted as identifiers (like the PostgreSQL C<quote_ident()>
function does).

=head2 Constructor

=head3 new

  my $priv = Pg::Priv->new(
      to    => $to,
      by    => $by,
      privs => $priv,
  );

Constructs and returns a Pg::Priv object for the given grantor, grantee, and
privileges. The C<privs> parameter is a string representing the privileges,
such as C<arwdxt>. If you're fetching ACLs from PostgreSQL, you're more likely
to want C<parse_acl()>, which will figure this stuff out for you.

=head2 Instance Methods

=head3 C<to>

Returns the name of the role to which the privileges were granted (the grantee).

=head3 C<by>

Returns the name of the role that granted the privileges (the grantor).

=head3 C<privs>

A string representing the privileges granted, such as C<arwdxt>.

=head3 C<labels>

A list or array reference of the labels for the granted privileges. These
correspond to the uppercase labels shown in the L<description|/"Description">.

=head3 C<can>

  print "We can read!\n" if $priv->can('r');
  print "We can read and write!\n" if $priv->can(qw(r w));

Pass in one or more privilege characters or labels and this method will return
true if that all the privileges have been granted. If at least one of the
specified privileges has not been granted, C<can> returns false.

=head3 C<can_*>

Convenience methods for verifying individual privileges:

=over

=item C<can_select>

Returns true if the SELECT privilege has been granted.

=item C<can_read>

Returns true if the SELECT privilege has been granted.

=item C<can_update>

Returns true if the UPDATE privilege has been granted.

=item C<can_write>

Returns true if the UPDATE privilege has been granted.

=item C<can_insert>

Returns true if the INSERT privilege has been granted.

=item C<can_append>

Returns true if the INSERT privilege has been granted.

=item C<can_delete>

Returns true if the DELETE privilege has been granted.

=item C<can_reference>

Returns true if the REFERENCE privilege has been granted.

=item C<can_trigger>

Returns true if the TRIGGER privilege has been granted.

=item C<can_execute>

Returns true if the EXECUTE privilege has been granted.

=item C<can_usage>

Returns true if the USAGE privilege has been granted.

=item C<can_create>

Returns true if the CREATE privilege has been granted.

=item C<can_connect>

Returns true if the CONNECT privilege has been granted.

=item C<can_temporary>

Returns true if the TEMPORARY privilege has been granted.

=item C<can_temp>

Returns true if the TEMPORARY privilege has been granted.

=back

=head1 See Also

=over

=item *

L<PostgreSQL Documentation: GRANT|http://www.postgresql.org/docs/current/static/sql-grant.html#SQL-GRANT-NOTES>.

=back

=head1 Acknowledgments

This module was originally developed under contract to L<Etsy,
Inc.|http://www.etsy.com/>. Many thanks to them for agreeing to release it as
open-source code!

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2009-2010 Etsy, Inc. and David. E. Wheeler. Some Rights
Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
