#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::JobControl::Mojolicious::Plugin::MinionJobs;
$Rex::JobControl::Mojolicious::Plugin::MinionJobs::VERSION = '0.18.0';
use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::JobControl::Helper::Project;

use base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app ) = @_;

  $app->minion->add_task(
    execute_rexfile => sub {

      my ( $job, $project_dir, $job_dir, $current_user, $cmdb, @server ) = @_;

      $job->app->log->debug("Project: $project_dir");
      $job->app->log->debug("Job: $job_dir");
      $job->app->log->debug("User: $current_user");

      eval {
        my $pr  = $job->app->project($project_dir);
        my $job = $pr->get_job($job_dir);
        $job->execute( $current_user, $cmdb, @server );
        1;
      } or do {
        $job->app->log->debug("Error executing: $@");
      };

    }
  );

  $app->minion->add_task(
    checkout_rexfile => sub {

      my ( $job, $project_dir, $rexfile_name, $rexfile_url,
        $rexfile_description )
        = @_;

      $job->app->log->debug("checkout_rexfile: got params: " . join(", ", @_));

      eval {
        my $pr = $job->app->project($project_dir);
        $pr->create_rexfile(
          directory   => $rexfile_name,
          name        => $rexfile_name,
          url         => $rexfile_url,
          description => $rexfile_description,
        );
        1;
      } or do {
        $job->app->log->debug("Error checkout_rexfile: $@");
      };

    }
  );
}

1;
