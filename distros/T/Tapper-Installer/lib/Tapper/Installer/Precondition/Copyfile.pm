package Tapper::Installer::Precondition::Copyfile;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::Copyfile::VERSION = '5.0.2';
use strict;
use warnings;

use Moose;
use YAML;
use File::Basename;
extends 'Tapper::Installer::Precondition';




sub install {
        my ($self, $file) = @_;

        return ('no filename given to copyfile::install') if not $file->{name};
        return ('no destination given for '.$file->{name}) if not $file->{dest};

        $file->{dest} = $self->cfg->{paths}{base_dir}.$file->{dest};

        $self->log->warn("no protocol given, try to use 'local'") and $file->{protocol}='local' if not $file->{protocol};

        my $retval;
        if ($file->{protocol} eq 'nfs') {
                $retval = $self->install_nfs($file)
        } elsif ($file->{protocol} eq 'rsync') {
                $retval = $self->install_rsync($file)
        } elsif ($file->{protocol} eq 'local') {
                $retval = $self->install_local($file)
        } elsif ($file->{protocol} eq 'scp') {
                $retval = $self->install_scp($file)
        } else {
                return 'File '.$file->{name}.' has unknown protocol type '.$file->{protocol};
        }

        $retval = $self->copy_prc($file) if $file->{copy_prc};
        return $retval;
}




sub install_local {
        my ($self, $file) = @_;

        my $dest_filename = '';   # get rid of the "uninitialised" warning
        my ($dest_path, $retval);

        if ($file->{dest} =~ m(/$)) {
                $dest_path =  $file->{dest};
        } else {
                ($dest_filename, $dest_path, undef) = fileparse($file->{dest});
                $dest_path .= '/' if $dest_path !~ m(/$);
        }
        return $retval if $retval = $self->makedir($dest_path);

        $self->log->debug("Copying ".$file->{name}." to $dest_path$dest_filename");
        my ($error, $message) = $self->log_and_exec("cp","--sparse=always","-r","-L",$file->{name},$dest_path.$dest_filename);
        return "Can't copy ".$file->{name}." to $dest_path$dest_filename:$message" if $error;

        return(0);
}



sub install_nfs {
        my ($self, $file) = @_;

        my ($filename, $path, $retval, $error);
        my $nfs_dir='/mnt/nfs';

        if ( $file->{name} =~ m,/$, ) {
                return 'File name is a directory. Installing directory preconditions is not yet supported';
        } else        {
                ($filename, $path, undef) = fileparse($file->{name});
                $path .= '/' if $path !~ m,/$,;
        }

        $self->makedir($nfs_dir) if not -d $nfs_dir;

        $self->log->debug("mount -a $path $nfs_dir");

        ($error, $retval) = $self->log_and_exec("mount $path $nfs_dir");
        return ("Can't mount nfs share $path to $nfs_dir: $retval") if $error;
        $file->{name} = "$nfs_dir/$filename";
        $retval =  $self->install_local($file);


        $self->log_and_exec("umount $nfs_dir");
        return $retval;
}



sub install_scp {
        my ($self, $file) = @_;

        my $dest = $self->cfg->{paths}{base_dir}.$file->{dest};

        #(XXX) Bad solution, find a better one
        system("scp","-r",$file->{name},$dest);
        return $self->install_local($file);
}





sub install_rsync {
        my ($self, $file) = @_;

        return "Not implemented yet.";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition::Copyfile

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Copyfile;

=head1 NAME

Tapper::Installer::Precondition::Copyfile - Install a file to a given location

=head1 FUNCTIONS

=head2 install

This function encapsulates installing one single file. scp, nfs and
local are supported protocols.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=head2 install_local

Install a file from a local source.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=head2 install_nfs

Install a file from an nfs share.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=head2 install_scp

Install a file using scp.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=head2 install_rsync

Install a file using rsync.

@param hash reference - contains all information about the file

@return success - 0
@return error   - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
