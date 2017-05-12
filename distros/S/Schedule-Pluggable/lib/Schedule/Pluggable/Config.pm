package Schedule::Pluggable::Config;

use Moose::Role;
use Carp;
use Try::Tiny;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

has JobsPlugin => ( is      => 'rw',
                    isa     => 'Str',
                    reader  => '_get_JobsPlugin',
                    default => 'JobsFromData',
                    );


after BUILD => sub {
    my $self = shift;
	$self->load_plugins( $self->_get_JobsPlugin );
};

# Gets the job config via the plugin method get_job_config, validates it, works out the dependencies
sub _validate_config {
	my ($self, $params) = @_;
    my $job_config = $self->get_job_config($params); # get_job_config from JobsPlugin
	my $status = $self->_get_status();
	my %prerequisites = ();
    my $jobs = [];
    if (ref ($job_config) eq "HASH") {   # if we get passed a hash - convert it into an array of hashes
        foreach my $job_name (sort keys %{ $job_config }) {
            my %j = %{ $job_config->{$job_name} };
            $j{name} ||= $job_name;
            push(@{ $jobs }, { %j });
        }
    }
    elsif (ref ($job_config) eq "ARRAY") {
        $jobs = $job_config;
    }
    else {
        croak "Invalid jobs specification supplied via ".$self->get_JobsPlugin." : must be a reference to an array or a hash not ".Data::Dumper->Dump([$job_config],[qw/$job_config/]);
    }

	# First, setup the groups
	foreach my $job (@{ $jobs }) {
		$status->{Groups}{ $job->{name} }{ $job->{name} } = 1;
        my @groups = $self->_get_values($job->{groups}, $job->{group});
		map { $status->{Groups}{ $_ }{ $job->{name} } = 1; } @groups if @groups;
	}
	foreach my $job (@{ $jobs }) {
		$status->{Groups}{ $job->{name} }{ $job->{name} } = 1;
		if ($job->{dependencies}) {
            my @dependencies = $self->_get_values( $job->{dependencies} );
			foreach my $dependency (@dependencies) {
				if ($status->{ Groups }{ $dependency }) {
					map { $prerequisites{ $_ }{ $job->{name} } = undef; } keys %{ $status->{Groups}{$dependency} };
				}
				else {
					$prerequisites{ $job->{name} } { $dependency } = undef;
				}
			}
		}
    }
	foreach my $job (@{ $jobs }) {
		my $job_name = $job->{name};
		$status->{Jobs}{ $job_name } = { %{ $job } };
        $status->{TotalJobs}++;
		if ($job->{prerequisites} or $prerequisites{ $job_name }) {
            my @prerequisites = $self->_get_values( $job->{prerequisites}, keys %{ $prerequisites{ $job_name } } );
			foreach my $prerequisite (@prerequisites) {
				if ($status->{Groups}{$prerequisite}) {
					map { $prerequisites{ $job->{name} }{ $_ } = undef; } keys %{ $status->{Groups}{$prerequisite} };
				}
				else {
					$prerequisites{ $job->{name} }{ $prerequisite } = undef;
				}
			}
		}
		else {
			$status->{Jobs}{ $job_name }->{ pending_prerequisites } = 0;
			$status->{Ready_to_Run}{$job_name} = { %{ $job } };
		}
        $status->{Jobs}{ $job_name }->{ prerequisites } = { %{ $prerequisites{ $job_name } } } if $prerequisites{ $job_name };
        $status->{Jobs}{ $job_name }->{ pending_prerequisites } = scalar( keys ( %{ $prerequisites{ $job_name } } ) ) if $prerequisites{ $job_name };
        delete $status->{Jobs}{ $job_name }->{ dependencies };

	}
	return $status;
}
sub _get_values {
    my $self = shift;
    my @values = ();
    foreach my $what (@_) {
        next unless $what;
        push (@values,  @{ $what }) if ref $what eq 'ARRAY';
        push (@values,  values %{ $what }) if ref $what eq 'HASH';
        push (@values,  $what) if ref $what eq '';
    }
    return @values;


}
no Moose;
1;
__END__

=head1 NAME

Schedule::Pluggable::Config - Moose Role to provide methods to validate the Schedule config

=head1 DESCRIPTION

Moose Role to add method to Schedule::Pluggable to provide methods to validate the Schedule config- not runnable on it's own

=head1 METHODS

No public methods

=cut

