package Tapper::CLI::HostFeature;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::HostFeature::VERSION = '5.0.7';
use 5.010;

use warnings;
use strict;
use English qw/ -no_match_vars /;


sub ar_get_host_feature_parameters {
    my ( $s_cmd ) = @_;
    return [
        [ 'id|i=i'      , 'get host by id',                     ],
        [ 'name|n=s'    , 'get host by name',                   ],
        [ 'entry|e=s'   , 'host feature entry',                 ],
        (
            $s_cmd ne 'host-feature-delete'
                ? ( [ 'value|v=s'   , 'host feature value',         ] )
                : ( [ 'force|f'     , 'really delete host feature', ] )
        ),
        [ 'verbose|v'   , 'some more informational output',     ],
        [ 'help|?'      , 'Print this help message and exit.',  ],
    ];
}


sub b_init_host_feature_command {

    my ( $or_app_rad, $s_cmd ) = @_;

    my $ar_parameters = ar_get_host_feature_parameters( $s_cmd );
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME $s_cmd [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if (! ($hr_options->{name} || $hr_options->{id}) ) {
        die "error: one of parameter 'name' or 'id' is required\n";
    }
    if (! $hr_options->{entry} ) {
        die "error: missing parameter 'entry'\n";
    }
    if ( $s_cmd ne 'host-feature-delete' && !$hr_options->{value} ) {
        die "error: missing parameter 'value'\n";
    }

    return $hr_options;

}


sub b_host_feature_new {

    my ( $or_app_rad ) = @_;

    my $hr_options = b_init_host_feature_command(
        $or_app_rad, 'host-feature-new',
    );

    # help command is called
    if (! $hr_options ) {
        return;
    }

    require Tapper::Model;
    if (
        my $or_host =
            Tapper::Model::model('TestrunDB')
                ->resultset('Host')
                ->search(
                    $hr_options->{id} ? { id => $hr_options->{id} } : { name => $hr_options->{name} },
                    { rows => 1 },
                )
                ->first
    ) {
        if (
            my $or_host_feature =
                Tapper::Model::model('TestrunDB')
                    ->resultset('HostFeature')
                    ->search({
                        host_id => $or_host->id,
                        entry   => $hr_options->{entry},
                    },{
                        rows    => 1,
                    })
                    ->first
        ) {
            die "error: feature already exists\n";
        }
        else {
            require DateTime;
            my $or_host_feature_new =
                Tapper::Model::model('TestrunDB')
                    ->resultset('HostFeature')
                    ->new({
                        host_id     => $or_host->id,
                        entry       => $hr_options->{entry},
                        value       => $hr_options->{value},
                        created_at  => DateTime->now->strftime('%F %T'),
                    })
            ;
            if ( $or_host_feature_new->insert ) {
                say 'info: successfully inserted host feature ' . $or_host_feature_new->id;
            }
            else {
                die "error: cannot insert host feature\n";
            }
        }
    }
    else {
        die "error: host not found\n";
    }

    return;

}


sub b_host_feature_delete {

    my ( $or_app_rad ) = @_;

    my $hr_options = b_init_host_feature_command(
        $or_app_rad, 'host-feature-delete',
    );

    # help command is called
    if (! $hr_options ) {
        return;
    }

    if (! $hr_options->{force} ) {
        say {*STDERR} "info: Skip actual host-feature-delete unless --force is used.";
        return;
    }

    require Tapper::Model;
    if (
        my $or_host =
            Tapper::Model::model('TestrunDB')
                ->resultset('Host')
                ->search(
                    $hr_options->{id} ? { id => $hr_options->{id} } : { name => $hr_options->{name} },
                    { rows => 1 },
                )
                ->first
    ) {
        if (
            my $or_host_feature =
                Tapper::Model::model('TestrunDB')
                    ->resultset('HostFeature')
                    ->search({
                        host_id => $or_host->id,
                        entry   => $hr_options->{entry},
                    },{
                        rows    => 1,
                    })
                    ->first
        ) {
            if (! $or_host_feature->delete ) {
                die "error: cannot delete host feature\n";
            }
            elsif ( $hr_options->{verbose} ) {
                say 'info: successfully delete host feature ' . $or_host_feature->id;
            }
        }
        else {
            die "error: feature not exists\n";
        }
    }
    else {
        die "error: host not found\n";
    }

    return;

}


sub b_host_feature_update {

    my ( $or_app_rad ) = @_;

    my $hr_options = b_init_host_feature_command(
        $or_app_rad, 'host-feature-update',
    );

    # help command is called
    if (! $hr_options ) {
        return;
    }

    require Tapper::Model;
    if (
        my $or_host =
            Tapper::Model::model('TestrunDB')
                ->resultset('Host')
                ->search(
                    $hr_options->{id} ? { id => $hr_options->{id} } : { name => $hr_options->{name} },
                    { rows => 1 },
                )
                ->first
    ) {
        if (
            my $or_host_feature =
                Tapper::Model::model('TestrunDB')
                    ->resultset('HostFeature')
                    ->search({
                        host_id => $or_host->id,
                        entry   => $hr_options->{entry}
                    }, {
                        rows => 1
                    })
                    ->first
        ) {

            require DateTime;
            $or_host_feature->value( $hr_options->{value} );
            $or_host_feature->updated_at( DateTime->now->strftime('%F %T') );

            if ( $or_host_feature->update ) {
                if ( $hr_options->{verbose} ) {
                    say sprintf "Updated feature for host '%s': %s = %s",
                        $or_host->name,
                        $or_host_feature->entry,
                        $or_host_feature->value
                    ;
                }
            }
            else {
                die "error: cannot update feature\n";
            }
        }
    }
    else {
        die "error: host not found\n";
    }

    return;

}


sub setup {
        my ($c) = @_;

        $c->register('host-feature-new'   , \&b_host_feature_new   , 'Create a new host feature');
        $c->register('host-feature-update', \&b_host_feature_update, 'Update host feature');
        $c->register('host-feature-delete', \&b_host_feature_delete, 'Delete host feature');

        if ($c->can('group_commands')) {
                $c->group_commands(
                    'Host commands',
                        'host-feature-new',
                        'host-feature-update',
                        'host-feature-delete',
                );
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::HostFeature

=head2 setup

get command line parameters and help for host feature commands

=head2 setup

do some initial things for host feature commands

=head2 setup

add a new host feature

=head2 setup

delete a host feature

=head2 setup

update a host feature

=head2 setup

Initialize the host feature functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
