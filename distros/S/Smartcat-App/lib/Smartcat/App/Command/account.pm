# ABSTRACT: show account info
use strict;
use warnings;

package Smartcat::App::Command::account;
use Smartcat::App -command;

use Smartcat::Client::AccountApi;
use Smartcat::App::Utils;

use Carp;
$Carp::Internal{ ('Smartcat::Client::AccountApi') }++;
use Log::Any qw($log);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $api = Smartcat::Client::AccountApi->new( $self->app->{api} );
    my $account_info = eval { $api->account_get_account_info };
    die $log->error(
        sprintf( "Failed to get account info.\nError:\n%s",
            format_error_message($@) )
    ) unless $account_info;

    print "Account Info\n  Name: "
      . $account_info->name
      . "\n  Id: "
      . $account_info->id . "\n";
}

1;
