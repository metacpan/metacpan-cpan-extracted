package Tapper::CLI::Scenario;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Scenario::VERSION = '5.0.5';

use 5.010;
use warnings;
use strict;
use feature qw/ say /;
use English qw/ -no_match_vars /;
no if $] >= 5.018, warnings => "experimental";



sub ar_get_create_scenario_parameters {
    return [
        [ 'file|f=s'    , 'String; use macro scenario file',                        ],
        [ 'dryrun|n'    , 'Print evaluated scenario without submit to DB',          ],
        [ 'verbose|v'   , 'some more informational output',                         ],
        [ 'D'           , 'Define a key=value pair used in macro preconditions',    ],
        [ 'help|?'      , 'Print this help message and exit.',                      ],
    ];
}


sub b_create_scenario {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_create_scenario_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} or not %$hr_options) {
        say {*STDERR} "Usage: $PROGRAM_NAME scenario-new [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    my $s_error;
    if (! $hr_options->{file} ) {
        $s_error = 'Scenario file needed';
    }
    if (! -e $hr_options->{file} ) {
        $s_error = 'Scenario file ' . $hr_options->{file} . ' does not exist';
    }
    if (! -r $hr_options->{file} ) {
        $s_error = 'Scenario file ' . $hr_options->{file} . ' is not readable';
    }
    if ( $s_error ) {
        die "error: $s_error\n";
    }

    require Tapper::Cmd::Scenario;
    my $or_scenario   = Tapper::Cmd::Scenario->new();
    my $s_scenario_text = $or_scenario->apply_macro($hr_options->{file}, $hr_options->{d});

    require YAML::Syck;
    my @scenario_conf = YAML::Syck::Load( $s_scenario_text );
    if ($hr_options->{dryrun}) {
            say STDERR $s_scenario_text;
            return;
    }

    my @scenario_ids = $or_scenario->add(\@scenario_conf);

    if ( $hr_options->{verbose} ) {

        require Tapper::Model;
        require Tapper::Config;
        foreach my $i_scenario_id (@scenario_ids) {
                my @a_testrun_ids = Tapper::Model::model('TestrunDB')->resultset('ScenarioElement')->search({
                                                                                                             scenario_id => $i_scenario_id
                                                                                                            })->get_column('testrun_id')->all;
                say "scenario $i_scenario_id consists of testruns ", join ', ', @a_testrun_ids;
                say Tapper::Config->subconfig->{base_url} // 'http://localhost/tapper', "/testruns/idlist/", join( q#,#, @a_testrun_ids );
        }

    }
    else {
        say join ",", @scenario_ids;
    }

    return;

}


sub setup {

    my ( $or_apprad ) = @_;

    $or_apprad->register( 'scenario-new', \&b_create_scenario, 'Create a scenraio', );

    if ( $or_apprad->can('group_commands') ) {
        $or_apprad->group_commands(
            'Testrun commands',
                'scenario-new',
        );
    }

    return;

}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Scenario

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg} unless otherwise stated.

    use App::Rad;
    use Tapper::CLI::Test;
    Tapper::CLI::Test::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Scenario - Tapper - testrun related commands for the tapper CLI

=head1 FUNCTIONS

=head2 b_create_scenario

return create scenario parameters and descriptions

=head2 b_create_scenario

create scenario

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
