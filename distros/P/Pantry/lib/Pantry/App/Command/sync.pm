use v5.14;
use warnings;

package Pantry::App::Command::sync;
# ABSTRACT: Implements pantry sync subcommand
our $VERSION = '0.012'; # VERSION

use Pantry::App -command;
use autodie;
use JSON 2;
use Storable qw/dclone/;
use Net::OpenSSH;
use Path::Class;
use Pantry::Model::Util qw/merge_hash dot_to_hash/;
use File::Temp 0.22 qw/tempfile/;

Net::OpenSSH->VERSION("0.56_01");

use namespace::clean;

sub abstract {
  return 'Run chef-solo on remote node';
}

sub command_type {
  return 'TARGET';
}

sub options {
  my ($self) = @_;
  return ( $self->sync_options );
}

sub valid_types {
  return qw/node/
}

my $rsync_opts = {
  verbose => 0, # XXX should trigger off a global option
  compress => 1,
  recursive => 1,
  'delete' => 1,
  links => 1,
  times => 1,
};

sub _remote_pantry_dir {
  return "/var/pantry";
};

sub _sync_node {
  my ($self, $opt, $name) = @_;
  my $obj = $self->_check_name('node', $name);
  $name = $obj->name; # canonical name

  say "Synchronizing $name";

  # open SSH connection
  my $host = $obj->pantry_host // $name;
  my $port = $obj->pantry_port // 22;
  my $user = $obj->pantry_user // 'root';
  my ($sudo, $sudo_i) = do {
    $user eq 'root' ? ('','') : ('sudo -- ', 'sudo -i -- ');
  };
  my $ssh = Net::OpenSSH->new($host, port => $port, user => $user);
#  $Net::OpenSSH::debug = 255;
  die "Couldn't establish an SSH connection: " . $ssh->error . "\n"
    if $ssh->error;

  # ensure destination directory and ownership
  my $dest_dir = $self->_remote_pantry_dir;
  $ssh->system($sudo . "mkdir -p $dest_dir")
    or die "Could not create $dest_dir\n";
  if ( $sudo ) {
    $ssh->system($sudo . "chown $user $dest_dir")
      or die "Could not chown $dest_dir to $user\n";
  }

  # generate local solo.rb and rsync it to /etc/chef/solo.rb
  my ($fh, $solo_rb) = tempfile( "pantry-solo.rb-XXXXXX", TMPDIR => 1 );
  print {$fh} $self->_solo_rb_guts;
  close $fh;
  $ssh->rsync_put($rsync_opts, $solo_rb, "$dest_dir/solo.rb")
    or die "Could not rsync solo.rb\n";

  # prepare node JSON for upload
  # XXX should really check to be sure it exists
  my ($node_fh, $node_json) = tempfile( "node.json-XXXXXX", TMPDIR => 1 );

  $obj->save_as($node_json);

  # XXX Chef Solo doesn't yet support environment data files, so we merge them
  # in manually, though it doesn't quite match Chef's natural attribute
  # precedence table.
  # http://wiki.opscode.com/display/chef/Attributes#Attributes-Precedence
  #
  # When Chef Solo supports env files (in repo but not released) this won't be
  # necessary, but we'll need to upload environment files and configure them in
  # solo.rb

  my $env = $self->pantry->environment($obj->env);
  if ( -e $env->path ) { # if we have a data file, then merge it
    my $base = decode_json( file($node_json)->slurp );
    my $env_default = dclone $env->default_attributes;
    my $env_override = dclone $env->override_attributes;
    for my $hash ( $env_default, $env_override ) {
      for my $k ( keys %$hash ) {
        dot_to_hash($hash, $k, $hash->{$k});
        delete $hash->{$k};
      }
    }
    my $merged = merge_hash( merge_hash( $env_default, $base ), $env_override );
    file($node_json)->spew( to_json( $merged, { utf8 => 1, pretty => 1 } ) );
  }

  # rsync node JSON to remote /etc/chef/node.json
  $ssh->rsync_put($rsync_opts, $node_json, "$dest_dir/node.json")
    or die "Could not rsync node.json\n";

  # rsync cookbooks to remote /var/chef-solo/cookbooks
  $ssh->rsync_put($rsync_opts, "cookbooks", $dest_dir)
    or die "Could not rsync cookbooks\n";

  # rsync roles to remote /var/chef-solo/roles
  $ssh->rsync_put($rsync_opts, "roles", $dest_dir)
    or die "Could not rsync roles\n";

  # rsync databags to remote /var/chef-solo/data_bags
  $ssh->rsync_put($rsync_opts, "data_bags", $dest_dir)
    or die "Could not rsync data_bags\n";

  # ssh execute chef-solo
  my $command = $sudo_i . "chef-solo -c $dest_dir/solo.rb";
  $command .= " -l debug" if $ENV{PANTRY_CHEF_DEBUG};
  $ssh->system({tty => $sudo ? 1 : 0}, $command) # XXX eventually capture output
    or die "Error running chef-solo\n";
  # cleanup report permissions if running under sudo so we can find/download it
  $ssh->system($sudo . "chown -R $user $dest_dir/reports") if $sudo;
  # scp get run report
  my $report = $ssh->capture("ls -t $dest_dir/reports | head -1");
  chomp $report;
  # XXX should check that the report timestamp makes sense -- xdg, 2012-05-03

  dir("reports")->mkpath;
  $ssh->rsync_get($rsync_opts, "$dest_dir/reports/$report", "reports/$name");

  if ( $opt->{reboot} ) {
    $ssh->system($sudo . "shutdown -r now");
  }

}

sub _solo_rb_guts {
  my ($self) = @_;
  my $dest_dir = $self->_remote_pantry_dir;
  return << "HERE";
file_cache_path "$dest_dir"
cookbook_path "$dest_dir/cookbooks"
role_path "$dest_dir/roles"
data_bag_path "$dest_dir/data_bags"
json_attribs "$dest_dir/node.json"
require 'chef/handler/json_file'
report_handlers << Chef::Handler::JsonFile.new(:path => "$dest_dir/reports")
exception_handlers << Chef::Handler::JsonFile.new(:path => "$dest_dir/reports")
HERE
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::App::Command::sync - Implements pantry sync subcommand

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  $ pantry sync node foo.example.com

=head1 DESCRIPTION

This class implements the C<pantry sync> command, which is used to rsync recipes
and node data to a server and then run C<chef-solo> on the server to finish configuration.

=for Pod::Coverage options validate

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
