package QBit::Application::Model::DB::mysql::Query;
$QBit::Application::Model::DB::mysql::Query::VERSION = '0.012';
use qbit;

use base qw(QBit::Application::Model::DB::Query);

sub with_rollup {
    my ($self, $value) = @_;

    $self->{'__WITH_ROLLUP__'} = !!$value;
}

sub _after_select {
    my ($self) = @_;

    return $self->{'__CALC_ROWS__'} ? ' SQL_CALC_FOUND_ROWS' : '';
}

sub _after_group_by {
    my ($self) = @_;

    return $self->{'__WITH_ROLLUP__'} ? ' WITH ROLLUP' : '';
}

sub _found_rows {
    my ($self) = @_;

    return $self->db->_get_all('SELECT FOUND_ROWS() AS `rows`')->[0]{'rows'};
}

TRUE;

__END__

=encoding utf8

=head1 Name
 
QBit::Application::Model::DB::mysql::Query - Class for MySQL queries.
 
=head1 Description
 
Implements methods for MySQL queries.

=head1 Package methods
 
=head2 with_rollup

B<Arguments:>

=over

=item

B<$value> - boolean

=back

B<Example:>

  $query->with_rollup(TRUE);

=cut
