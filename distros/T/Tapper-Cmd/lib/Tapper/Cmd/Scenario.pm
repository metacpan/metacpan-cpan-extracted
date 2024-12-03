package Tapper::Cmd::Scenario;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::Scenario::VERSION = '5.0.14';
use warnings;
use strict;
use 5.010;
use Moose;

use YAML::XS;
use Tapper::Model 'model';
use parent 'Tapper::Cmd';

use Try::Tiny;
use Tapper::Cmd::Testrun;



sub create {
        my ($self, $scenario, $instance) = @_;
        $scenario->{instance_id} ||= $instance;
        return $self->add([$scenario]);
}


sub parse_interdep
{
        my ($self, $conf) = @_;

        # TODO
        # 2.) check whether more than 2 testruns are local and prevent sync in this case

        my $i_scenario_id;
        my $or_schema = model('TestrunDB');
        try {
                $or_schema->txn_do(sub {

                        my $scenario = $or_schema->resultset('Scenario')->new({
                                type    => 'interdep',
                                options => $conf->{scenario_options} || $conf->{options},
                                name    => $conf->{scenario_name} || $conf->{name},
                        });
                        $scenario->insert;

                        $i_scenario_id  = $scenario->id;
                        my $tr          = Tapper::Cmd::Testrun->new({ schema => $or_schema });

                        foreach my $plan (@{$conf->{scenario_description} || $conf->{description}}) {

                                $plan->{scenario_id} ||= $i_scenario_id;
                                $plan->{status}        = 'schedule';

                                # backwards compatibility for old interdep descriptions
                                if ( $plan->{requested_hosts} ) {
                                        $plan->{requested_hosts_any} = delete $plan->{requested_hosts};
                                }

                                $tr->create($plan, $conf->{instance_id});

                        }

                });

        }
        catch {
                die $_;
        };

        return $i_scenario_id;
}



sub add {
        my ($self, $list_of_confs) = @_;

        my @ids;
        foreach my $conf (@{$list_of_confs || [] }) {
                if ( $conf->{scenario_type} eq 'interdep' ) {
                        push @ids, $self->parse_interdep($conf);
                }
                elsif ( $conf->{scenario_type} eq 'multitest' ) {

                        my $sc = $self->schema->resultset('Scenario')->new({
                                type    => 'multitest',
                                options => $conf->{scenario_options} || $conf->{options},
                                name    => $conf->{scenario_name} || $conf->{name},
                        });

                        $sc->insert;

                        my $description = $conf->{scenario_description} || $conf->{description};
                           $description->{scenario_id} = $sc->id;

                        my $tr = Tapper::Cmd::Testrun->new( schema => $self->schema );
                           $tr->create($description);

                        push @ids, $sc->id;

                }
                else {
                        die "Unknown scenario type '" . ( $conf->{scenario_type} || q## ) . "'";
                }
        }

        return @ids;

}




sub del {
        my ($self, $id) = @_;
        my $scenario = model('TestrunDB')->resultset('Scenario')->find($id);
        $scenario->delete();
        return 0;
}

1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::Scenario

=head1 SYNOPSIS

This project offers backend functions for all projects for manipulation the
database on a higher level than that offered by Tapper::Schema.

    use Tapper::Cmd::Scenario;

    my $bar = Tapper::Cmd::Scenario->new();
    $bar->add($scenario);
    ...

=head1 NAME

Tapper::Cmd::Scenario - Backend functions for manipulation of scenario in the database

=head1 FUNCTIONS

=head2 create

Create a new scenario from one element of a test plan (actually a test
plan instance). If the new scenario belong to a test plan instance the
function expects the id of this instance as second parameter.

@param hash ref - test plan element
@param instance - test plan instance id

@return success - array - scenario ids
@return error   - die

=head2 parse_interdep

Parse an interdep scenario and do everything needed to put it into the
database.

@param hash ref - config containing all relevant information
@param hash ref - options

@return success - int - scenario_id
@return error   - die with error text

=head2 add

Add a new scenario to database. Add with testplan instance id if given.

@param hash ref - options for new scenario
@param instance - test plan instance id

@return success - array - scenario id
@return error   - die

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
