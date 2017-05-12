package Album::Storage::File; {

    use Moose;
    use MooseX::Types::Path::Class qw(Dir File);

    extends 'Album::Storage';

    sub items_in_source {
        my $self = shift @_;
        my $source = $self->source;
        unless(-e $source) {
            die "$source does not exist";
        }
        $source->children;
    }

    sub asset_info_from_path {
        my ($self, $path) = @_;
        unless(is_File($path)) {
            $path = to_Path($path);
        }
        unless(-e $path) {
            die "$path does not exist";
        }
        my ($title, $ext) = $path->basename =~ /^(.*)\.(.*?)$/;
        return {
            source_fh => $path->openr,
            title     => $title,
            mime_type => (
                $ext eq 'jpg' ? 'image/jpeg'
              : $ext eq 'txt' ? 'text/plain'
              :                 'application/octet-stream'
            ),
        };
    }

    has '+source' => (
        isa => Dir,
        coerce => 1,
    );
}

1;
