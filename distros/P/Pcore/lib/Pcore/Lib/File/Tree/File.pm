package Pcore::Lib::File::Tree::File;

use Pcore -class;

has tree => ( required => 1 );    # InstanceOf ['Pcore::Lib::File::Tree']
has path => ( required => 1 );

has source_path => ();
has content     => ( is => 'lazy' );    # ScalarRef
has meta        => ();                  # HashRef

sub _build_content ($self) {
    return \P->file->read_bin( $self->{source_path} );
}

sub remove ($self) {
    $self->{tree}->remove_file( $self->{path} );

    return;
}

sub move ( $self, $target_path ) {
    $self->{tree}->move_file( $self->{path}, $target_path );

    return;
}

sub render_tmpl ( $self, $tmpl_args ) {
    my $tmpl = P->tmpl;

    $self->{content} = $tmpl->render( $self->content, $tmpl_args );

    return;
}

sub write_to ( $self, $target_path ) {
    $target_path = P->path("$target_path/$self->{path}");

    P->file->mkpath( $target_path->{dirname} );

    if ( exists $self->{content} ) {
        P->file->write_bin( $target_path, P->text->encode_utf8( $self->{content}->$* ) );
    }
    else {
        P->file->copy( $self->{source_path}, $target_path );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::File::Tree::File

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
