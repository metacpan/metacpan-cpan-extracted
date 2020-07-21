# ABSTRACT: show/edit config file
use strict;
use warnings;

package Smartcat::App::Command::config;
use Smartcat::App -command;

use File::Basename;

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    my $app = $self->app;

    $app->{config}->{username} = $opt->{token_id} if defined $opt->{token_id};
    $app->{config}->{password} = $opt->{token}    if defined $opt->{token};
    $app->{config}->{base_url} = $opt->{base_url} if defined $opt->{base_url};

    if ( defined $opt->{log} ) {
        $self->usage_error(
"directory of 'log', which is set to '$opt->{log}', does not point to a valid directory"
        ) unless -d dirname( $opt->{log} ) && -w _;
        $app->{config}->{log} = $opt->{log};
    }

    $app->{config}->save;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $app = $self->app->{config}->cat;
}

1;
