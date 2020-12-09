package Tapper::CLI::Precondition;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Precondition::VERSION = '5.0.7';

use 5.010;
use warnings;
use strict;
use feature qw/ say /;
use English qw/ -no_match_vars /;

# list limit default value
my $i_limit_default = 50;


sub b_print_single_precondition {

    my ( $or_precondition, $hr_options ) = @_;

    my %h_print_elements = (
        'Id'            => [ 1, $or_precondition->id,               ],
        'Shortname'     => [ 2, $or_precondition->shortname,        ],
        'Precondition'  => [ 3, $or_precondition->precondition,     ],
        'Timeout'       => [ 4, $or_precondition->timeout || q##,   ],
    );

    if ( $hr_options->{nonewlines} ) {
        $h_print_elements{Precondition}[1] =~ s/\n/\\n/mg;
    }
    if ( $hr_options->{quotevalues} ) {
        require Data::Dumper;
        for my $s_key ( keys %h_print_elements ) {
            $h_print_elements{$s_key}[1] =
                Data::Dumper
                    ->new([$h_print_elements{$s_key}[1]])
                    ->Terse(1)
                    ->Indent(0)
                    ->Dump
            ;
        }
    }

    print  "\n";
    my $i_key_length = 0;
    for my $s_key ( keys %h_print_elements ) {
        if ( length $s_key > $i_key_length ) {
            $i_key_length = length $s_key;
        }
    }
    for my $s_key (
        sort {
            $h_print_elements{$a}[0] <=> $h_print_elements{$b}[0]
        } keys %h_print_elements
    ) {
        printf ' %' . $i_key_length . "s: %s\n", $s_key, $h_print_elements{$s_key}[1];
    }

    return 1;

}


sub b_print_preconditions {

    my ( $or_preconditions, $hr_options ) = @_;

    if ( $or_preconditions->isa('DBIx::Class::ResultSet') ) {
        for my $or_precondition ( $or_preconditions->all ) {
            b_print_single_precondition(
                $or_precondition,
                $hr_options,
            );
        }
    }
    else {
        b_print_single_precondition(
            $or_preconditions,
            $hr_options,
        );
    }
    print "\n";

    return 1;

}


sub ar_get_list_parameters {
    return [
        [ 'id|i=i@'       , 'list particular preconditions by id', 'Can be given multiple times.',                                      ],
        [ 'testrun|t=i@'  , 'list particular preconditions by testrun id', 'Can be given multiple times.',                              ],
        [ 'limit|l=i'     , "limit the number of testruns (default = $i_limit_default). A value smaller than 1 deactivates the limit.", ],
        [ 'verbose|v'     , 'print all output, without only print ids',                                                                 ],
        [ 'nonewlines|n'  , 'no newslines in precondition ( available in verbose mode )',                                               ],
        [ 'quotevalues|q' , 'quote every value ( available in verbose mode )',                                                          ],
        [ 'help|?'        , 'Print this help message and exit.',                                                                        ],
    ];
}


sub b_list {

    my ( $or_app_rad ) = @_;

    my $or_querylog;

    require Tapper::Model;
    my $or_schema = Tapper::Model::model('TestrunDB');

    if ( $ENV{DEBUG} ) {
        require DBIx::Class::QueryLog;
        $or_querylog = DBIx::Class::QueryLog->new();
        $or_schema->storage->debugobj( $or_querylog );
        $or_schema->storage->debug( 1 );
    }

    my $ar_parameters = ar_get_list_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my %h_options = %{$or_app_rad->options};

    if ( $h_options{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME precondition-list [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    my $hr_search;
    my $hr_search_options = {
        order_by => { -desc => 'me.id' },
    };

    if ( exists $h_options{limit} ) {
        if ( $h_options{limit} > 0 ) {
            $hr_search_options->{rows} = $h_options{limit};
        }
    }
    else {
        $hr_search_options->{rows} = $i_limit_default;
    }

    if ( my $ar_precondition_ids = $h_options{id} ) {

        if ( $h_options{testrun} ) {
            die "error: filter 'testrun' doesn't make sense with filter 'id'\n";
        }

        # filter 'id' doesn't make sense without verbose
        $h_options{verbose} = 1;

        $hr_search = { 'me.id' => $ar_precondition_ids }
    }
    elsif ( my $ar_testrun_ids = $h_options{testrun} ) {

        $hr_search = { 'testrun_precondition.testrun_id' => $ar_testrun_ids };
        $hr_search_options->{'join'} = 'testrun_precondition';

    }

    my $or_precondition_rs =
        $or_schema
            ->resultset('Precondition')
            ->search( $hr_search, $hr_search_options )
    ;

    if ( $h_options{verbose} ) {
        b_print_preconditions( $or_precondition_rs, \%h_options, );
    }
    else {
        for my $i_precondition_id ( $or_precondition_rs->get_column('id')->all ) {
            say $i_precondition_id;
        }
    }

    if ( $ENV{DEBUG} ) {

        require DBIx::Class::QueryLog::Analyzer;
        my $or_analyzer = DBIx::Class::QueryLog::Analyzer->new({
            querylog => $or_querylog,
        });

        require Data::Dumper;
        say {*STDERR} "Query count: " . scalar( @{$or_analyzer->get_sorted_queries} );
        say {*STDERR} Data::Dumper::Dumper([
            $or_analyzer->get_sorted_queries
        ]);

    }

    return;

}


sub ar_get_delete_parameters {
    return [
        [ 'id|i=i@'   , 'delete particular preconditions', 'Can be given multiple times.',  ],
        [ 'force|f'   , 'really execute the command',                                       ],
        [ 'verbose|v' , 'print all output, without only print ids',                         ],
        [ 'help|?'    , 'Print this help message and exit.',                                ],
    ];
}


sub b_delete {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_delete_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME precondition-delete [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if (! $hr_options->{id} ) {
        die "error: required parameter 'id' is missing\n";
    }

    if (! $hr_options->{force} ) {
        say {*STDERR} "info: Skip deleting preconditions unless --force is used.";
        return;
    }

    require Tapper::Cmd::Precondition;
    my $or_cmd = Tapper::Cmd::Precondition->new();
    foreach my $i_precondition_id ( @{$hr_options->{id}} ){
        if ( my $s_error = $or_cmd->del( $i_precondition_id ) ) {
            die "$s_error\n";
        }
        elsif ( $hr_options->{verbose} ) {
            say "info: precondition deleted $i_precondition_id";
        }
    }

    return;

}


sub s_read_condition_file {

    my ( $s_condition_file ) = @_;

    my $s_condition;
    if ( $s_condition_file ) {
        require File::Slurp;
        $s_condition = File::Slurp::read_file(
            # read from file or STDIN if filename == '-'
            $s_condition_file eq q#-# ? \*STDIN : $s_condition_file
        );
    }
    else {
        die "error: missing parameter 'condition file'\n";
    }

    return $s_condition;

}


sub ar_get_precondition_parameters {
    my ( $s_command ) = @_;
    return [
        (
            $s_command eq 'precondition-update'
                ? ( [ 'id|i=s', 'the precondition id to change', ] )
                : ()
        ),
        [ 'shortname|s=s'       , 'shortname',                                                      ],
        [ 'timeout|t=s'         , 'stop trying to fullfill this precondition after timeout second', ],
        [ 'condition|c=s'       , 'condition description in YAML format (see Spec)',                ],
        [ 'condition_file|f=s'  , 'filename from where to read condition, use - to read from STDIN' ],
        [ 'verbose|v'           , 'some more informational output',                                 ],
        [ 'help|?'              , 'print this help message and exit.',                              ],
    ];
}


sub hr_init_precondition_commands {

    my ( $or_app_rad, $s_command ) = @_;

    my $ar_parameters = ar_get_precondition_parameters( $s_command );
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME $s_command [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( !$hr_options->{condition} && !$hr_options->{condition_file} ) {
        die "error: missing parameter --condition or --condition_file\n";
    }
    elsif ( $hr_options->{condition} && $hr_options->{condition_file} ) {
        die "error: only one of --condition or --condition_file allowed\n";
    }

    my $s_condition      = $hr_options->{condition};
    my $s_condition_file = $hr_options->{condition_file};

    if (! $s_condition ) {
        $s_condition     = s_read_condition_file( $s_condition_file );
    }

    if ( $s_condition !~ /\n$/ ) {
        $s_condition .= "\n";
    }

    if ( my @a_elements = grep { $hr_options->{$_} } qw/ shortname timeout / ) {

        require YAML::Syck;
        my @a_yaml = YAML::Syck::Load( $s_condition );
        for my $hr_yaml ( @a_yaml ) {
            @{$hr_yaml}{@a_elements} = @{$hr_options}{@a_elements};
        }
        $s_condition = YAML::Syck::Dump( @a_yaml );

    }

    return {
        condition => $s_condition,
        options   => $hr_options,
    };

}


sub b_new {

    my ( $or_app_rad ) = @_;

    my $hr_precond_data = hr_init_precondition_commands(
        $or_app_rad, 'precondition-new',
    );

    require Tapper::Model;
    require Tapper::Cmd::Precondition;
    if ( my @a_precondition_ids = Tapper::Cmd::Precondition->new->add( $hr_precond_data->{condition} ) ) {
        if ( $hr_precond_data->{options}{verbose} ) {
            foreach my $i_precondition_id ( @a_precondition_ids ) {
                b_print_single_precondition(
                    Tapper::Model::model('TestrunDB')
                        ->resultset('Precondition')
                        ->search({ id => $i_precondition_id }, { rows => 1 })
                        ->first
                );
            }
        }
        else {
            print map { $_, "\n" } @a_precondition_ids;
        }
    }

    return;

}


sub b_update {

    my ( $or_app_rad ) = @_;

    my $hr_precond_data = hr_init_precondition_commands(
        $or_app_rad, 'precondition-update',
    );

    if (! $hr_precond_data->{options}{id} ) {
        die "error: Missing required parameter 'id'\n";
    }

    require Tapper::Model;
    require Tapper::Cmd::Precondition;
    my $or_cmd = Tapper::Cmd::Precondition->new();

    if (
        $or_cmd->update(
            $hr_precond_data->{options}{id},
            $hr_precond_data->{condition},
        )
    ) {
        if ( $hr_precond_data->{options}{verbose} ) {
            b_print_single_precondition(
                Tapper::Model::model('TestrunDB')
                    ->resultset('Precondition')
                    ->find( $hr_precond_data->{options}{id} )
            );
        }
        else {
            say $hr_precond_data->{options}{id};
        }
    }
    else {
        die "error: cannot update precondition\n";
    }

    return;

}


sub setup {

    my ( $or_apprad ) = @_;

    $or_apprad->register( 'precondition-list'  , \&b_list  , 'List preconditions'  , );
    $or_apprad->register( 'precondition-new'   , \&b_new   , 'Create preconditions', );
    $or_apprad->register( 'precondition-update', \&b_update, 'Update preconditions', );
    $or_apprad->register( 'precondition-delete', \&b_delete, 'Delete preconditions', );

    if ( $or_apprad->can('group_commands') ) {
        $or_apprad->group_commands(
            'Testrun commands',
                'precondition-list',
                'precondition-new',
                'precondition-update',
                'precondition-delete',
        );
    }

    return;

}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Precondition

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg} unless otherwise stated.

    use App::Rad;
    use Tapper::CLI::Test;
    Tapper::CLI::Test::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Test - Tapper - precondition related commands for the tapper CLI

=head1 FUNCTIONS

=head2 b_print_single_precondition

print a single precondition ( verbose )

=head2 b_print_preconditions

print preconditions

=head2 b_list

get "list precondition" parameters

=head2 b_list

list preconditions from database

=head2 ar_get_delete_parameters

get "delete precondition" parameters

=head2 b_delete

delete a precondition from database

=head2 s_read_condition_file

read a condition file and return it as strings

=head2 ar_get_precondition_parameters

get parameters and descriptions for command "precondition-new" and "precondition-update"

=head2 b_new

run some initial checks and commands for "new" and "update" command

=head2 b_new

create new preconditions

=head2 b_update

update a existing precondition

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
