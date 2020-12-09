package Tapper::CLI::Testplan;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Handle testplans
$Tapper::CLI::Testplan::VERSION = '5.0.7';
use 5.010;
use warnings;
use strict;
use Perl6::Junction qw/all/;
use English '-no_match_vars';
no if $] >= 5.018, warnings => "experimental";

use JSON::XS;
use YAML::XS;



sub testplanlist
{

        my ($c) = @_;
        $c->getopt( 'name|n=s@', 'path|p=s@', 'testrun|t=s@', 'id|i=i@','active|a','verbose|v','result|r', 'format=s', 'help|?' );
        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-list [--path=path|-p=path]* [--name|-n=name]* [--testrun=id|-t=id]* [--id=number|-i=number] [--active|-a] [ --format=JSON|YAML ] [--verbose|-v]";
                say STDERR "";
                say STDERR "    --path|-p         Path name of testplans to list.";
                say STDERR "                      Only slashes(/) are allowed as separators.";
                say STDERR "                      Can be an SQL like condition (i.e. '\%name\%'). Make sure your shell does not break it.";
                say STDERR "                      Can be given multiple times";
                say STDERR "                      Will reduce number of testplans when given with --testrun or --name, can't go with --id";
                say STDERR "    --name|-n         name of testplans to list.";
                say STDERR "                      Can be an SQL like condition (i.e. '\%name\%'). Make sure your shell does not break it.";
                say STDERR "                      Can be given multiple times";
                say STDERR "                      Will reduce number of testplans when given with --testrun or --path, can't go with --id";
                say STDERR "    --testrun|-t      Show testplan containing this testrun id";
                say STDERR "                      Can be given multiple times";
                say STDERR "                      Will reduce number of testplans when given with --name or --path, can't go with --id";
                say STDERR "    --id|-i           Show testplan of given id";
                say STDERR "                      Can be given multiple times. Implies -v";
                say STDERR "                      Will override --testrun, --path and --name";
                say STDERR "    --active|-a       Only show testplan with testruns that are not finished yet.";
                say STDERR "                      Will reduce number of testplans when given with any other filter.";
                say STDERR "    --result|-r       Determine failure or success of testplan. Expensive operation.";
                say STDERR "    --format          Give output in this format. Valid values are YAML, JSON. Case insensitive. Always verbose.";
                say STDERR "    --verbose|-v      Show testplan with id, name and associated testruns. Without only testplan id is shown.";
                say STDERR "    --help            Print this help message and exit.";
                exit -1;
        }
        my @ids;
        my $filtered;
        my $format    = $c->options->{format};

        require Tapper::Model;
        if (@{$c->options->{id} || []}) {
                @ids = @{$c->options->{id}};
        } elsif (@{$c->options->{testrun} || []}) {
                my $testruns = Tapper::Model::model('TestrunDB')->resultset('Testrun')->search({id => $c->options->{testrun}});
                while (my $testrun = $testruns->next) {
                        push @ids, $testrun->testplan_id if $testrun->testplan_id;
                }
        } elsif ( @{$c->options->{name} || []}) {
                my $regex = join("|", map { "($_)" } @{$c->options->{name}});
                my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id if $instance->path and $instance->path =~ /$regex/;
                }
        } else {
                my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id;
                }
                $c->options->{verbose} = 1;
        }

        # a join would be faster and maybe cleaner
        if ($c->options->{active}) {
                my @local_ids = @ids;
                my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance')->search({id => \@local_ids});
                @ids = ();
                while (my $instance = $instances->next) {
                        if ($instance->testruns and grep {$_->testrun_scheduling->status ne 'finished'} $instance->testruns->all) {
                                push @ids, $instance->id;
                        }
                }
                $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance')->search({id => [ @ids ]});
        }

        if ($c->options->{quiet}) {
                return join ("\n",@ids);
        }

        my %inst_data;
        my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance')->search({id => \@ids});
        while (my $instance = $instances->next) {
                my $current_inst_data = $inst_data{$instance->id} =
                {
                 path     => $instance->path ? $instance->path : '',
                 name     => $instance->path ? $instance->path : '',
                 testruns => [ map { {id => $_->id, status => ''.$_->testrun_scheduling->status} } $instance->testruns ], # stringify enum object
                };

               if ($c->options->{result}) {
                        my %testrunrefs = map { $_->{id} => $_ } @{$current_inst_data->{testruns}};
                        my $iter = Tapper::Model::model('TestrunDB')->resultset('ReportgroupTestrunStats')->search({testrun_id => [ keys %testrunrefs ]});
                        while (my $stat = $iter->next) {
                                $testrunrefs{$stat->testrun_id}->{success} = !($stat->success_ratio < 100);
                        }
               }
        }
        if ($c->options->{format}) {
                use Data::Dumper;
                given(lc($c->options->{format})) {
                        when ('yaml') { return YAML::XS::Dump(\%inst_data)}
                        when ('json') { return encode_json(\%inst_data)}
                        default       { die "unknown format: ",$c->options->{format}}
                }
        } else {
                if ($c->options->{verbose}) {
                        my @testplan_info;
                        foreach my $id (keys %inst_data) {
                                my $line = join(" - ",
                                                $id,
                                                $inst_data{$id}->{path},
                                                "testruns: ".join(", ", map{$_->{id}} @{$inst_data{$id}->{testruns}})
                                               );
                                push @testplan_info, $line;
                        }
                        return join "\n", @testplan_info;
                } else {
                        return join "\n", map { $_->id} $instances->all;
                }
        }

}


sub testplannew
{
        my ($c) = @_;
        $c->getopt( 'include|I=s@', 'name=s', 'path=s', 'file=s', 'D=s%', 'dryrun|n', 'guide|g', 'quiet|q', 'subst_json=s','verbose|v', 'help|?' );

        my $opt = $c->options;

        if ( $opt->{help} or not $opt->{file}) {
                say STDERR "Usage: $0 testplan-new --file=s  [ -dry-run|n ] [ -v ] [ -Dkey=value ] [ --path=s ] [ --name=s ] [ --include=s ]*";
                say STDERR "";
                say STDERR "    -D           Define a key=value pair used for macro expansion";
                say STDERR "    --dryrun     Just print evaluated testplan without submit to DB";
                say STDERR "    --file       Use (macro) testplan file";
                say STDERR "    --guide      Just print self-documentation";
                say STDERR "    --include    Add include directory (multiple allowed)";
                say STDERR "    --name       Provide a name for this testplan instance";
                say STDERR "    --path       Put this path into db instead of file path";
                say STDERR "    --subst_json File name that contains macro expansion values in JSON formaxt";
                say STDERR "    --verbose    Show more progress output.";
                say STDERR "    --quiet      Only show testplan ids, suppress path, name and testrun ids.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        die "Testplan file needed\n" if not $opt->{file};
        die "Testplan file @{[ $opt->{file} ]} does not exist"  if not -e $opt->{file};
        die "Testplan file @{[ $opt->{file} ]} is not readable" if not -r $opt->{file};

        require Tapper::Cmd::Testplan;
        if ($opt->{subst_json}) {
                use File::Slurp;
                my $data = File::Slurp::read_file($opt->{subst_json});
                $opt->{substitutes} = JSON::XS::decode_json($data);
        } else {
                        $opt->{substitutes} = $opt->{D};
        }
        my $cmd = Tapper::Cmd::Testplan->new;
        if ($opt->{guide}) {
                return $cmd->guide($opt->{file}, $opt->{substitutes}, $opt->{include});
        }
        if ($opt->{dryrun}) {
                return  $cmd->apply_macro($opt->{file}, $opt->{substitutes}, $opt->{include});
        }

        my $answer = $cmd->testplannew($opt);
        # Format:
        #   TESTPLANID: TESTRUNID TESTRUNID TESTRUNID
        my $output =
          $answer->{testplan_id}
          . ': '
          . join(' ', @{$answer->{testrun_ids} || []});

        return $output;
}


sub testplancancel
{
        my ($c) = @_;

        $c->getopt( 'id|i=i@', 'comment=s', 'help|?' );
        my $opt = $c->options;

        if ( $opt->{help} or not $opt->{id}) {
                say STDERR "Usage: $0 testplan-cancel --id=number [ --comment=comment ]";
                say STDERR "";
                say STDERR "    --id=number        Cancel the testplan with this id. Can be specified multiple times. Required at least once.";
                say STDERR "    --comment=comment  Specify a comment to add to the cancelled testruns.";
                say STDERR "    --help             Print this help message and exit.";
                exit -1;
        }

        require Tapper::Cmd::Testplan;
        my $cmd = Tapper::Cmd::Testplan->new();

        my $comment = $opt->{comment} || "Cancelled from Tapper CLI";

        foreach my $testplan (@{$opt->{id}}) {
                print "Cancelling testplan $testplan\n";
                $cmd->cancel( $testplan, $comment );
        }
        return;

}


sub setup
{
        my ($c) = @_;
        $c->register('testplan-send', \&testplansend, 'Send choosen testplan reports');
        $c->register('testplan-list', \&testplanlist, 'List testplans matching a given pattern');
        $c->register('testplan-cancel', \&testplancancel, 'Cancel testplans with given IDs');
        $c->register('testplan-tj-send', \&testplan_tj_send, 'Send all testplan reports that are due according to taskjuggler plan');
        $c->register('testplan-tj-generate', \&testplan_tj_generate, 'Apply all testplans that are due according to taskjuggler plan');
        $c->register('testplan-new', \&testplannew, 'Create new testplan instance from file');
        if ($c->can('group_commands')) {
                $c->group_commands('Testplan commands', 'testplan-send', 'testplan-list', 'testplan-tj-send', 'testplan-tj-generate', 'testplan-new');
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Testplan - Handle testplans

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Testplan;
    Tapper::CLI::Testplan::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Testplan - Tapper - testplan related commands for the tapper CLI

=head1 FUNCTIONS

=head2 testplanlist

List testplans matching a given pattern.

=head2 testplannew

Create new testplan instance from file.

=head2 testplancancel

Cancel a testplan

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
