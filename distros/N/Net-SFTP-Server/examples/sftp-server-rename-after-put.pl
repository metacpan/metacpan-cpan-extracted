#!/usr/bin/perl

use strict;
use warnings;
use File::Basename ();

my $server = Server->new(timeout => 15);
$server->run;
exit(0);

package Server;

use Net::SFTP::Server::Constants qw(SSH_FXF_WRITE);

use parent 'Net::SFTP::Server::FS';

sub handle_command_open_v3 {
    my ($self, $id, $path, $flags, $attrs) = @_;
    my $writable = $flags & SSH_FXF_WRITE;
    my $pflags = $self->sftp_open_flags_to_sysopen($flags);
    my $perms = $attrs->{mode};
    my $old_umask;
    if (defined $perms) {
	$old_umask = umask $perms;
    }
    else {
	$perms = 0666;
    }
    my $fh;
    unless (sysopen $fh, $path, $pflags, $perms) {
	$self->push_status_errno_response($id);
	umask $old_umask if defined $old_umask;
	return;
    }
    umask $old_umask if defined $old_umask;
    if ($writable) {
	Net::SFTP::Server::FS::_set_attrs($path, $attrs)
	    or $self->send_status_errno_response($id);
    }
    my $hid = $self->save_file_handler($fh, $flags, $perms, $path);
    $self->push_handle_response($id, $hid);
}

sub handle_command_close_v3 {
    my $self = shift;
    my ($id, $hid) = @_;
    my ($type, $fh, $flags, $perms, $path) = $self->get_handler($hid);

    $self->SUPER::handle_command_close_v3(@_);

    if ($type eq 'file' and $flags & SSH_FXF_WRITE) {
        my $name = File::Basename::basename($path);
        rename $path, "/tmp/$name";
    }
}
