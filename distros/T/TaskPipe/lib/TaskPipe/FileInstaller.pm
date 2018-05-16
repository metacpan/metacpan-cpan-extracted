package TaskPipe::FileInstaller;

use Moose;
use File::Path 'make_path';
use Try::Tiny;

has dirs_created => (is => 'rw', isa => 'ArrayRef', default => sub{[]});
has files_created => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

has on_rollback => (is => 'rw', isa => 'CodeRef');


sub create_dir{
    my ($self,$dir) = @_;

    return if -d $dir;

    try {

        make_path( $dir );

    } catch {

        confess "Could not create directory $dir: $_";

    };

    unshift @{$self->dirs_created}, $dir;

}


sub create_file{
    my ($self,$path,$text) = @_;

    return if -f $path;

    open my $fh,">",$path or confess "Could not open path $path for writing: $!\nSetup operations have been rolled back";

    print $fh $text;
    close $fh;
    unshift @{$self->files_created}, $path;
}


sub rollback{
    my ($self) = @_;

    if ( $self->on_rollback ){
        $self->on_rollback->();
    }

    foreach my $filepath (@{$self->files_created}){
        unlink $filepath or warn "An error occurred during rollback. I wasn't able to remove the file $filepath: $!";
    }

    foreach my $dir (@{$self->dirs_created}){
        next unless -d $dir;
        rmdir $dir or warn "An error occurred during rollback. I wasn't able to remove the directory $dir: $!"
    }
}

=head1 NAME

TaskPipe::FileInstaller - handles file installs for TaskPipe

=head1 DESCRIPTION

It is not recommended to use this module directly. See the general manpages for TaskPipe

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;

