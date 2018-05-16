package TaskPipe::Template;

use Moose;
use File::Spec;

has path_settings => (is => 'ro', isa => 'TaskPipe::PathSettings', lazy => 1, default => sub{
    TaskPipe::PathSettings->new;
});


sub target_filename{
    my ($self) = @_;

    my $target_filename = $self->path_settings->filename( $self->filename_label );
    return $target_filename;
}


sub target_dir{
    my ($self) = @_;

    my $target_dir = $self->path_settings->path( $self->dir_label );
    confess "Target dir $target_dir does not exist" unless -d $target_dir;
    return $target_dir;
}


sub target_path{
    my ($self) = @_;

    return +File::Spec->catdir( $self->target_dir, $self->target_filename );
}


sub deploy{
    my ($self) = @_;

    my $nest = Template::Nest->new;

    $nest->template_hash({
        template => +$self->template
    });
        
    my $to_render = { NAME => 'template' };

    if ( $self->can('template_vars') && $self->template_vars ){
        $to_render = { %$to_render, %{$self->template_vars} };
    }
    
    $self->write_file( $nest->render($to_render) );
}




sub write_file{
    my ($self,$text) = @_;

    my $target_path = $self->target_path;

    confess "target path $target_path already exists" if -f $target_path;

    my $fh;
    open $fh,'>',$target_path or confess "Could not open $target_path: $!";

    print $fh $text;
    close $fh;
}


=head1 NAME

TaskPipe::Template - the base class for file templates

=head1 DESCRIPTION

Inherit from this class to create a new file template for deployment. You need to add a C<deploy> method, which will write the file at C<target_path>.

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;


