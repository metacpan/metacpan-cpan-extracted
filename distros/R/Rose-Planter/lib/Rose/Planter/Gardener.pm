=head1 NAME

Rose::Planter::Gardener -- base class for manager classes

=over

=cut

package Rose::Planter::Gardener;
use Log::Log4perl qw/get_logger/;
use base 'Rose::DB::Object::Manager';

=item get_objects_from_sql

Log queries to the category db.query
before calling the parent method.

=cut

sub get_objects_from_sql {

    my $self = shift;
    my %args = @_;

    my $sql = $args{sql};
    my @bind = @{ $args{args} };
    for my $b (@bind) {
        if (!defined($b)) {
            $sql =~ s/\?/NULL/;
        } else {
            $sql =~ s/\?/'$b'/;
        }
    }
    # TODO improve the above to really quote things

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    get_logger('db.query')->debug('get_objects_from_sql '.(ref $self || $self));
    get_logger('db.query')->debug($sql);

    $self->SUPER::get_objects_from_sql(%args);

}

=back

=cut

1;

