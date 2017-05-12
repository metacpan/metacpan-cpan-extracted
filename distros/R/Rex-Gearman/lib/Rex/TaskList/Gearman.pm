#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::TaskList::Gearman;
   
use strict;
use warnings;

use Cwd qw(getcwd);
use File::Basename;
use Gearman::Client;

use Rex::TaskList::Base;
use Rex::Logger;
use JSON::XS;
use base qw(Rex::TaskList::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_); 

   bless($self, $proto);

   return $self;
}

sub run {
   my ($self, $task_name, %option) = @_;

   $option{params} ||= { Rex::Args->get };


   my $task = $self->get_task($task_name);
   my @all_server = @{ $task->server };

   my $client = Gearman::Client->new;
   my $conf = eval eval { local(@ARGV, $/) = ("client.conf"); <>; };

   if($@) {
      print "Error parsing configuration file.\n";
      print $@ . "\n";
      CORE::exit 1;
   }

   Rex::Logger::debug("Found worker servers: " . join(", ", @{ $conf->{job_servers} }));

   $client->job_servers(@{ $conf->{job_servers} });
   my $taskset = $client->new_task_set;
   my $func_name = basename(getcwd());
   Rex::Logger::debug("Using func_name: $func_name");

   for my $server (@all_server) {

      my $options = {
         task => $task_name,
         server => $server->to_s,
         argv => \@ARGV,
         options => \%option,
         in_transaction => $self->is_transaction,
         default_auth => $self->is_default_auth,
      };

      Rex::Logger::info("Adding new task to execute $task_name on $server->to_s");
      $taskset->add_task(
         $func_name => encode_json($options), {
            on_complete => sub {
               Rex::Logger::info("Successfully executed task on $server");
            }, #  nothing yet
            on_fail => sub {
               Rex::Logger::info("Error executing task on $server");
            }, 
         }
      );


   }

   Rex::Logger::debug("Waiting for children to finish");

   $taskset->wait;

}

1;
