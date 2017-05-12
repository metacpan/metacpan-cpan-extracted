package Schedule::Pluggable::Plugin::JobsFromXML;
use Moose::Role;
use Data::Dumper;
use XML::Simple;
use Carp qw/ croak /;


sub get_job_config {
    my $self = shift;
    my $params = shift;
    my $jobs = undef;
    if ($params->{Jobs}) {
        if (-f $params->{Jobs}) {
            $jobs = XMLin($params->{Jobs}, KeyAttr=>{ name => 'name1'});
        }
        else {
            croak("Xml input file $params->{Jobs} does not exist");
        }
    }
    else  {
        croak("Mandator Paramneter Jobs with name of  XMLFile missing for JobsFromXML");
    }
    return $jobs->{Job};
}
1;
__END__

=head1 NAME

Schedule::Pluggable::Plugin::JobsFromXML - Plugin Role for Schedule::Pluggable to obtain Job configuration from a file containing XML

=head1 METHODS

=over

=item get_job_config

=back

=cut
