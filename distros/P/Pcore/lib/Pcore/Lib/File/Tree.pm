package Pcore::Lib::File::Tree;

use Pcore -class;
use Pcore::Lib::File::Tree::File;
use Pcore::Lib::Scalar qw[is_plain_coderef];

has files => ( sub { {} }, init_arg => undef );    # HashRef [ InstanceOf ['Pcore::Lib::File::Tree::File']

sub add_dir ( $self, $dir, $prefix = undef, $meta = undef ) {
    return if !-d $dir;

    if ( !defined $prefix ) {
        $prefix = $EMPTY;
    }
    elsif ( $prefix ne $EMPTY && substr( $prefix, -1, 1 ) ne '/' ) {
        $prefix .= '/';
    }

    $dir = P->path($dir)->to_abs;

    my $files = $dir->read_dir( max_depth => 0, is_dir => 0 );

    return if !$files;

    for my $file ( $files->@* ) {
        $self->add_file( "${prefix}${file}", "$dir/$file", $meta );
    }

    return;
}

sub add_file ( $self, $path, $source, $meta = undef ) {
    my $file;

    if ( ref $source eq 'SCALAR' ) {
        $file = Pcore::Lib::File::Tree::File->new( { tree => $self, path => $path, content => $source } );
    }
    else {
        $file = Pcore::Lib::File::Tree::File->new( { tree => $self, path => $path, source_path => $source } );
    }

    $file->{meta} = $meta if defined $meta;

    $self->{files}->{$path} = $file;

    return $file;
}

sub remove_file ( $self, $path ) {
    delete $self->{files}->{$path};

    return;
}

sub move_file ( $self, $path, $target_path ) {
    if ( my $file = delete $self->{files}->{$path} ) {
        $file->{path} = $target_path;

        $self->{files}->{$target_path} = $file;
    }

    return;
}

sub move_tree ( $self, $source_path, $target_path ) {
    for my $old_path ( keys $self->{files}->%* ) {
        my $new_path;

        if ( is_plain_coderef $target_path ) {
            if ( $old_path =~ /\A\Q$source_path\E/sm ) {
                $new_path = $target_path->($old_path);

                $self->move_file( $old_path, $new_path ) if defined $new_path;
            }
        }
        else {
            $new_path = $old_path;

            $self->move_file( $old_path, $new_path ) if $new_path =~ s/$source_path/$target_path/sm;
        }
    }

    return;
}

sub render_tmpl ( $self, $tmpl_args ) {
    for my $file ( values $self->{files}->%* ) {
        $file->render_tmpl($tmpl_args);
    }

    return;
}

# manifest
sub write_to ( $self, $target_path, %args ) {
    for my $file ( values $self->{files}->%* ) {
        $file->write_to($target_path);
    }

    # write MANIFEST
    P->file->write_bin( "$target_path/MANIFEST", [ sort 'MANIFEST', keys $self->{files}->%* ] ) if $args{manifest};

    return;
}

# manifest + tempdir args
sub write_to_temp ( $self, %args ) {
    my $tempdir = P->file1->tempdir(%args);

    $self->write_to( $tempdir, manifest => $args{manifest} );

    return $tempdir;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::File::Tree

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
