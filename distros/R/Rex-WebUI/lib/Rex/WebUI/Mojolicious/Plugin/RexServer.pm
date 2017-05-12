   
package Rex::WebUI::Mojolicious::Plugin::RexServer;

use strict;
use warnings;

use Mojolicious::Plugin;
use base qw(Mojolicious::Plugin);

use Rex -base;

use Data::Dumper;

sub register {
   my ($plugin, $app) = @_;

   $app->helper(
#      rex => sub {
#         my $self = shift;
#         my $cl;
#
#         if($app->config->{ssl}) {
#            $cl = Rex::IO::Client->create(protocol => 1, ssl => $app->config->{ssl});
#         }
#         else {
#            $cl = Rex::IO::Client->create(protocol => 1);
#         }
#
#         $cl->endpoint = $app->config->{server};
#
#         return $cl;
#      },
      rex => $self,
      tasklist => sub {
      	 
      	 my $rexfile = "SampleRexfile";

         do($rexfile);

         my $tasklist = Rex::TaskList->create();
         
         return $tasklist;
      },
   );
}

sub get_tasklist {
	
#   if($opts{'T'}) {
      Rex::Logger::debug("Listing Tasks and Batches");
      _print_color("Tasks\n", "yellow");
      my @tasks = Rex::TaskList->create()->get_tasks;
      unless(@tasks) {
         print "   no tasks defined.\n";
         exit;
      }
      if(defined $ARGV[0]) {
        @tasks = map { Rex::TaskList->create()->is_task($_) ?  $_ : () } @ARGV;
      }
      for my $task (@tasks) {
         printf "  %-30s %s\n", $task, Rex::TaskList->create()->get_desc($task);
         if($opts{'v'}) {
             _print_color("      Servers: " . join(", ", @{ Rex::TaskList->create()->get_task($task)->{'server'} }) . "\n");
         }
      }
      _print_color("Batches\n", 'yellow') if(Rex::Batch->get_batchs);
      for my $batch (Rex::Batch->get_batchs) {
         printf "  %-30s %s\n", $batch, Rex::Batch->get_desc($batch);
         if($opts{'v'}) {
             _print_color("      " . join(" ", Rex::Batch->get_batch($batch)) . "\n");
         }
      }
      _print_color("Environments\n", "yellow") if(Rex::Commands->get_environments);
      print "  " . join("\n  ", Rex::Commands->get_environments()) . "\n";

      my %groups = Rex::Group->get_groups;
      _print_color("Server Groups\n", "yellow") if(keys %groups);
      for my $group (keys %groups) {
         printf "  %-30s %s\n", $group, join(", ", @{ $groups{$group} });
      }

      Rex::global_sudo(0);
      Rex::Logger::debug("Removing lockfile") if(! exists $opts{'F'});
      CORE::unlink("$::rexfile.lock")               if(! exists $opts{'F'});
      CORE::exit 0;	
}
1;
