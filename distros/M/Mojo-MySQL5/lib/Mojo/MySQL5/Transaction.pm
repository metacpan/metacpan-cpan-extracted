package Mojo::MySQL5::Transaction;
use Mojo::Base -base;

has 'db';

sub DESTROY {
  my $self = shift;
  return unless $self->{rollback} and $self->db;
  local($@);
  $self->db->query('ROLLBACK');
  $self->db->query('SET autocommit=1');
}

sub commit {
  my $self = shift;
  return unless delete $self->{rollback};
  $self->db->query('COMMIT');
  $self->db->query('SET autocommit=1');
}

sub new {
  shift->SUPER::new(@_, rollback => 1);
}

1;

=encoding utf8

=head1 NAME

Mojo::MySQL5::Transaction - Transaction

=head1 SYNOPSIS

  use Mojo::MySQL5::Transaction;

  my $tx = Mojo::MySQL5::Transaction->new(db => $db);
  $tx->commit;

=head1 DESCRIPTION

L<Mojo::MySQL5::Transaction> is a cope guard for transactions started by
$db->L<begin|Mojo::MySQL5::Database/"begin">.

=head1 ATTRIBUTES

L<Mojo::MySQL5::Transaction> implements the following attributes.

=head2 db

  my $db = $tx->db;
  $tx    = $tx->db(Mojo::MySQL5::Database->new);

L<Mojo::MySQL5::Database> object this transaction belongs to.

=head1 METHODS

L<Mojo::MySQL5::Transaction> inherits all methods from L<Mojo::Base> and
implements the following ones.

=head2 commit

  $tx = $tx->commit;

Commit transaction.

=head2 new

  my $tx = Mojo::MySQL5::Transaction->new;
  my $tx = Mojo::MySQL5::Transaction->new(db => Mojo::MySQL5::Database->new);

Construct a new L<Mojo::MySQL5::Transaction> object.

=head1 SEE ALSO

L<Mojo::MySQL5>.

=cut
