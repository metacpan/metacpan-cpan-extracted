#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::JobControl::Mojolicious::Plugin::Audit;
$Rex::JobControl::Mojolicious::Plugin::Audit::VERSION = '0.18.0';
use strict;
use warnings;

use Mojolicious::Plugin;

use base 'Mojolicious::Plugin';
use Rex::JobControl::Helper::AuditLog;
use Data::Dumper;

sub register {
  my ( $plugin, $app ) = @_;

  my $log = Rex::JobControl::Helper::AuditLog->new(
    path  => $app->config->{log}->{audit_log},
    level => 'info'
  );

  my %audit_calls = %{ $app->config->{audit} };

  $app->hook(
    around_action => sub {
      my ( $next, $c, $action, $last ) = @_;

      my $ctrl_name   = $c->stash('controller');
      my $action_name = $c->stash('action');

      if ( exists $audit_calls{$ctrl_name}
        && exists $audit_calls{$ctrl_name}->{$action_name} )
      {
        my %params;
        @params{ @{ $audit_calls{$ctrl_name}->{$action_name}->{params} } } =
          $c->param( $audit_calls{$ctrl_name}->{$action_name}->{params} );

        $log->audit(
          {
            controller => $ctrl_name,
            action     => $action_name,
            data       => \%params,
          }
        );
      }

      return $next->();
    },
  );

}

1;
