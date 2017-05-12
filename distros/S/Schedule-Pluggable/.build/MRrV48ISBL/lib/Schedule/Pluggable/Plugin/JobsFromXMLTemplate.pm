package Schedule::Pluggable::Plugin::JobsFromXMLTemplate;
use Moose::Role;
use XML::Simple;
use Template;
use Carp qw/ croak /;

sub get_job_config {
    my $self = shift;
    my $params = shift;
    my $jobs = undef;
    eval {
        use XML::Simple;
        use Template;
    };
    if ($params->{Jobs}) {
        if (-f $params->{Jobs}) {
            my $tt = Template->new();
            my $processed;
            $tt->process($params->{Jobs}, $params, \$processed)
                or die $tt->error;
            $jobs = XMLin($processed, KeyAttr=>{ name => 'name1'});
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
