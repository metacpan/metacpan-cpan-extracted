package Schedule::Pluggable::Plugin::JobsFromData;
use Moose::Role;

# Nice and simple in this case - just return the jobs data passed
sub get_job_config {
    return $_[1]->{Jobs};
}
no Moose;
1;
__END__

=head1 NAME

Schedule::Pluggable::Plugin::JobsFromData - Plugin Role for Schedule::Pluggable to obtain Job configuration from a data structure

=head1 METHODS

=over

=item get_job_config

=back

=cut
