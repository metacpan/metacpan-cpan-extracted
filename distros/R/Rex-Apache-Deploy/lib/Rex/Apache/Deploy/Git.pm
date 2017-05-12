#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::Git - Deploy applications with Git

=head1 DESCRIPTION

This module gives you a simple interface to Git based deployments. It uses I<git push> to upload a given commit to the server.

=head1 SYNOPSIS

 use Rex::Apache::Deploy qw/Git/;

 task "deploy", "server1", "server2", sub {
   my $param = shift;

   deploy $param->{commit},
     path  => "/var/www",
     switch => TRUE;
 };

 #bash# rex deploy --commit=385816

 task "rollback", "server1", "server2", sub {
   my $param = shift;

   switch_to_version $param->{commit};
 };

 #bash# rex rollback --commit=138274


=cut

package Rex::Apache::Deploy::Git;

use strict;
use warnings;

use Rex -base;

use vars qw(@EXPORT);
@EXPORT = qw(deploy switch_to_version);

sub deploy {
  my ( $commit, %option ) = @_;

  if ( !$commit ) {
    my %task_args = Rex::Args->get;
    if ( exists $task_args{commit} ) {
      $commit = $task_args{commit};
    }
    else {
      print "Usage: rex \$task --commit=git-hash\n";
      die("You have to give the commit you wish to deploy.");
    }
  }

  if ( !%option ) {
    if ( Rex::Config->get("package_option") ) {
      %option = %{ Rex::Config->get("package_option") };
    }
  }

  my $commit_to_deploy = $commit;
  my $repo_path        = $option{path};
  my $force            = ( $option{force} ? "-f" : "" );
  my $switch           = $option{switch};

  run "git init $repo_path";
  run "GIT_DIR=$repo_path/.git git config receive.denyCurrentBranch ignore";

  my $server = connection->server;
  my $user = $option{user} || Rex::Config->get_user;

  LOCAL {
    run
      "git push git+ssh://$user\@$server$repo_path $commit_to_deploy:refs/heads/master $force";

    if ( $? != 0 ) {
      die("Error pushing refs.");
    }
  };

  if ($switch) {
    switch_to_version( $commit_to_deploy, %option );
  }
}

sub switch_to_version {
  my ( $version, %option ) = @_;

  my $repo_path = $option{path};

  run "cd $repo_path && git reset --hard $version";

  if ( $? != 0 ) {
    die("Error switching to $version");
  }
}

sub import {

  no strict 'refs';
  for my $func (@EXPORT) {
    Rex::Logger::debug("Registering main::$func");
    *{"$_[1]::$func"} = \&$func;
  }

}

1;
