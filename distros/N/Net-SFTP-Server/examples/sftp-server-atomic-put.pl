#!/usr/bin/perl


use 5.010;
use strict;
use warnings;

use parent 'Net::SFTP::Server::FS';
use Net::SFTP::Server::Constants qw(:all);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{overlay} = {};
    $self;
}

sub handle_command_open_v3 {
    my ($self, $id, $path, $flags, $attrs) = @_;
    my $writable = $flags & SSH_FXF_WRITE;
    my $perms = $attrs->{mode};
    my ($old_umask, $fh, $target_path);
    if (exists $self->{overlay}{$path}) {
        $path = $self->{overlay}{$path}
    }
    elsif ($writable) {
        if ( (-f $path and $flags & SSH_FXF_TRUNC) or
             (!-e $path and $flags & SSH_FXF_CREAT) )  {
            $target_path = $path;
            $path .= '.part';
            if (-e $path) {
                $self->push_status_response($id, SSH_FX_FAILURE, "A temporal file blocks the transfer");
                return;
            }
            $flags |= SSH_FXF_CREAT|SSH_FXF_TRUNC;
        }
    }
    my $pflags = $self->sftp_open_flags_to_sysopen($flags);
    if (defined $perms) {
	$old_umask = umask $perms;
    }
    else {
	$perms = 0666;
    }
    unless (sysopen $fh, $path, $pflags, $perms) {
        die "error: $!";
        $self->push_status_errno_response($id);
        umask $old_umask if defined $old_umask;
        return;
    }
    umask $old_umask if defined $old_umask;
    if ($writable) {
	Net::SFTP::Server::FS::_set_attrs($path, $attrs)
	    or $self->send_status_errno_response($id);
    }
    my $hid = $self->save_file_handler($fh, $flags, $perms, $target_path // $path);
    $self->{overlay}{$target_path} = $path if defined $target_path;
    $self->push_handle_response($id, $hid);
}

sub handle_command_close_v3 {
    my ($self, $id, $hid) = @_;
    my ($type, $fh, undef, undef, $target_path) = $self->remove_handler($hid)
	or return $self->push_status_response($id, SSH_FX_FAILURE, "Bad file handler");
    if ($type eq 'dir') {
	closedir($fh) or return $self->push_status_errno_response($id);
    }
    elsif ($type eq 'file') {
        my $path = delete $self->{overlay}{$target_path};
	close($fh) or return $self->push_status_errno_response($id);
        if (defined $path) {
            rename $path, $target_path or return $self->push_status_errno_response($id);
        }
    }
    else {
	die "Internal error: unknown handler type $type";
    }
    $self->push_status_ok_response($id);
}

for my $action (qw(lstat stat setstat)) {
    my $method = "handle_command_${action}_v3";
    my $super = Net::SFTP::Server::FS->can($method);
    no strict 'refs';
    *$method = sub {
        my ($self, $id, $target_path) = @_;
        my $path = $self->{overlay}{$target_path} // $target_path;
        $super->($self, $id, $path);
    };
}

DESTROY {
    local ($!, $?, $@);
    my $self = shift;
    unlink $_ for (values %{$self->{overlay}});
}



my $server = main->new();
$server->run;

__END__

=head1 NAME

sftp-server-atomit-put

=head1 DESCRIPTION

This programs provides an sftp-server that handles put requests
writing the incoming data to a temporal file that is moved to its
final destination after the transfer completes.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
