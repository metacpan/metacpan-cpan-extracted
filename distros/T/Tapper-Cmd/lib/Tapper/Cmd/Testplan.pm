package Tapper::Cmd::Testplan;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::Testplan::VERSION = '5.0.9';
use 5.010;
use Moose;

use Cwd;
use Try::Tiny;
use YAML::Syck;
use Tapper::Model 'model';
use Tapper::Reports::DPath::TT;
use File::Slurp 'slurp';
use Perl6::Junction 'any';

extends 'Tapper::Cmd';



sub get_module_for_type
{
        my ($self, $type) = @_;
        
        if ( lc($type) eq 'multitest' ) {
            return "Tapper::Cmd::Testrun";
        }
        elsif ( lc($type) eq 'scenario')  {
            return "Tapper::Cmd::Scenario"
        }
        else {
            $type = ucfirst($type); return "Tapper::Cmd::$type";
        }
}


sub add {
        my ($self, $plan_content, $path, $name) = @_;

        my @plans = YAML::Syck::Load($plan_content);
        # use Data::Dumper;
        # print STDERR "plans: ".Dumper($plan_content);
        # print STDERR "plans: ".Dumper(\@plans);

        my $instance = model('TestrunDB')->resultset('TestplanInstance')->new({
            evaluated_testplan => $plan_content,
            path               => $path,
            name               => $name,
        });
        $instance->insert;

        my @testrun_ids;
        foreach my $plan (@plans) {
                die "Missing plan type for the following testplan: \n".Dump($plan) unless $plan->{type};
                my $module = $self->get_module_for_type($plan->{type});

                try {
                        eval "use $module";
                } catch {
                        die "Can not load '$module' to handle testplan of type $plan->{type}: $!";
                };

                my $handler = "$module"->new();
                my $description = $plan->{testplan_description} || $plan->{description};
                my @new_ids = $handler->create($description, $instance->id);
                push @testrun_ids, @new_ids;

        }
        return $instance->id;
}


sub del {
        my ($self, $id) = @_;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        while(my $testrun = $testplan->testruns->next) {
                if ($testrun->testrun_scheduling->status eq 'running') {
                        my $message = model('TestrunDB')->resultset('Message')->new({testrun_id => $testrun->id,
                                                                                     type       => 'state',
                                                                                     message    => {
                                                                                                    state => 'quit',
                                                                                                    error => 'Testplan cancelled'
                                                                                                   }});
                        $message->insert();
                }
                $testrun->testrun_scheduling->testrun->testplan_id(undef);
                $testrun->testrun_scheduling->testrun->update;
                $testrun->testrun_scheduling->status('finished');
                $testrun->testrun_scheduling->update;
        }
        $testplan->delete();
        return 0;
}


sub cancel {
    my ($self, $id, $comment) = @_;

    $comment ||= 'Testplan cancelled';
    my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
    my $cmd = Tapper::Cmd::Testrun->new;
    my $testruns = $testplan->testruns;
    while(my $testrun = $testruns->next) {
        $cmd->cancel($testrun->id, $comment);
    }
    return 0;
}


sub rerun
{
        my ($self, $id) = @_;

        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        die "No testplan with ID $id\n" unless $testplan;

        return $self->add($testplan->evaluated_testplan, $testplan->path, $testplan->name);
}


sub parse_path
{
        my ($self, $filename) = @_;
        $filename = Cwd::abs_path($filename);
        my $basedir = Tapper::Config->subconfig->{paths}{testplan_path};
        # splitting filename at basedir returns an array with the empty
        # string before and the path after the basedir
        my $path = (split $basedir, $filename)[1];
        return $path;
}

sub get_shortname {

    my ( $or_self, $s_plan ) = @_;

    foreach my $s_line ( split /\n/, $s_plan ) {
        if ( $s_line =~ /^[#\s]*-?\s*(?:short)?name\s*:\s*(.+?)\s*$/i ) {
            my $shortname = $1;
            $shortname =~ s/['"]+//g;
            return $shortname;
        }
    }

    return;

}


sub guide
{
        my ($self, $file, $substitutes, $include) = @_;
        my $text;
        my $guide = $self->apply_macro($file,
                                       $substitutes,
                                       $include);

        my @guide = grep { m/^###/ } split (qr/\n/, $guide);
        $text = "Self-documentation:\n";
        $text = join "\n", map { my $l = $_; $l =~ s/^###/ /; "$l" } @guide;
        return $text;
}


sub testplannew {
        my ($self, $opt) = @_;

        my $plan = $self->apply_macro($opt->{file}, $opt->{substitutes}, $opt->{include});
        my $path = $opt->{path} || $self->parse_path($opt->{file});
        my $name = $self->get_shortname($plan);
        return $self->add($plan, $path, $name);
}


sub status
{
        my ($self, $id) = @_;
        my $results = model('TestrunDB')->fetch_raw_sql({
                                                        query_name  => 'testplans::testplan_status',
                                                        fetch_type  => '$%',
                                                        query_vals  => {testplan_id => $id},
                                                       });
        my $testruns_rs = model->resultset("Testrun")->search({testplan_id => $id});
        my %testrun_ids = map { $_->id => $_->topic_name} $testruns_rs->all;
        $results->{testruns} = \%testrun_ids;
        return $results;

# TODO check how we can get old infos back in
# * status - one of 'schedule', 'running', 'pass', 'fail'
# * complete_percentage - percentage of finished testruns
# * started_percentage  - percentage of running and finished testruns
# * success_percentage  - average of success rates of finished testruns
}


sub testplan_files
{
        my ($self, $testplan_id, $filter) = @_;
        my $results_rawsql = model('TestrunDB')->fetch_raw_sql({
                                                                query_name  => 'testplans::reportfile',
                                                                fetch_type  => '@@',
                                                                query_vals  => {testplan_id => $testplan_id, filter => $filter},
                                                               });
        my @results = map { $_->[0] } @$results_rawsql;
        return \@results;
}


1; # End of Tapper::Cmd::Testplan

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::Testplan

=head1 SYNOPSIS

This project offers functions to add, delete or update testplan
instances in the database.

    use Tapper::Cmd::Testplan;

    my $cmd = Tapper::Cmd::Testplan->new();
    my $plan_id = $cmd->add($plan);
    $cmd->update($plan_id, $new_plan);
    $cmd->del($plan_id);

    ...

=head1 NAME

Tapper::Cmd::Testplan - Backend functions for manipluation of testplan instances in the database

=head1 FUNCTIONS

=head2 get_module_for_type

Get the name of the Tapper::Cmd module that is reponsible for a given
type. The name of the module is optimized for the Tapper developer but
the type given in the testplan should be telling for the testplan user.

@param string - type

@return string - name of the responsible module

=head2 add

Add a new testplan instance to database and create the associated
testruns. The function expects a string containing the evaluated test
plan content and a path.

@param    string - plan content
@param    string - path
@optparam string - name

@return int - testplan instance id

@throws die()

=head2 del

Delete testrun with given id from database. Please not that this does
not remove the associated testruns.

@param int - testplan instance id

@return success - 0
@return error - exception

@throws die()

=head2 cancel

Cancel testplan by canceling all of its testruns.

@param int - testplan instance id

@return success - 0
@return error - exception

@throws die()

=head2 rerun

Reapply the evaluated testplan of the given testplan instance.

@param int - testplan instance id

@return success - new testplan id
@return error   - exception

@throws die()

=head2 parse_path

Get the test plan path from the filename. This is a little more tricky
since we do not simply want the dirname but kind of an "un-prefix".

@param string - file name

@return string - test plan path

=head2 guide

Get self documentation of a testplan file.

@param string - file name of testplan file

@return success - documentation text

@throws - die()

=head2 testplannew

Create a testplan instance from a file.

@param hash ref - options containing

required:
* file: string, path of the testplan file
* substitutes: hash ref, substitute variables for Template Toolkit

optional:
* include: array ref of strings containing include paths
* path: string, alternative path instead of real path
* name: string, overwrite shortname in plan

@return success - testplan id

@throws die

=head2 status

Get information of one testplan.

@param int - testplan id

@return - hash ref -
* count_fail      0,
* count_pass      2,
* count_pending   0,
* name            "HWXYZ",
* path            undef,
* testplan_date   "2014-03-24",
* testplan_id     1040,
* testplan_time   "14:17"

@throws - die

=head2 testplan_files

Get all files that belong to a testplan.

@param int    - testplan id
@param string - filter

@return array ref - list of report file ids

@throws - die

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
