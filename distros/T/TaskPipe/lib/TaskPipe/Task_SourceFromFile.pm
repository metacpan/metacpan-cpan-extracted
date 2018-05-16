package TaskPipe::Task_SourceFromFile;

use Moose;
extends 'TaskPipe::Task';
with 'MooseX::ConfigCascade';

has path_settings => (is => 'rw', isa => 'TaskPipe::PathSettings', default => sub{
    TaskPipe::PathSettings->new;
});


sub action{
    my $self = shift;

    my $filepath = $self->path_settings->path( 
        'source',
        $self->param->{filename}
    );

    my $list = $self->cascade_util->parser->( $filepath );
    return $list;
}

=head1 NAME

TaskPipe::Task_SourceFromFile - use a file as a data source

=head1 DESCRIPTION

This is the standard task for reading from a yaml data file (and outputing the records as an arrayref). You can use this task directly. You should make sure the file the task is reading is in a format which will become an array when read by L<YAML::XS>. For example:

    ---
    -   url: https://www.example.com/first_record
        headers:
            Referer: https://www.example.com

    -   url: https://www.example.com/second_record
            Referer: https://www.example.com

    # ...

In your plan, specify the task as follows:

    # (tree format):

    task:

        _name: SourceFromFile
        filename: mydatafile.yml

    pipe_to:

        # ...

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__
