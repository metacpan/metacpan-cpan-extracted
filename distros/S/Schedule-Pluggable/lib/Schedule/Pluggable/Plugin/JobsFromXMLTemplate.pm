package Schedule::Pluggable::Plugin::JobsFromXMLTemplate;
use Moose::Role;
use XML::Simple;
use Template;
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
        croak("Mandator Parameter Xml input file Jobs missing for JobsFromXML");
    }
    return $jobs->{Job};
}
1;
__END__

=head1 NAME

Schedule::Pluggable::Plugin::JobsFromXMLTemplate - Plugin Role for Schedule::Pluggable to obtain Job configuration from a Template toolkit XML file

=head1 METHODS

=over

=item get_job_config

=back

=cut
