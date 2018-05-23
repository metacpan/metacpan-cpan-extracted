package Pcore::Util::File::Tree::File;

use Pcore -class;

has tree => ( is => 'ro', isa => InstanceOf ['Pcore::Util::File::Tree'], required => 1, weak_ref => 1 );
has path => ( is => 'ro', isa => Str, required => 1 );
has source_path => ( is => 'ro',   isa => Str );
has content     => ( is => 'lazy', isa => ScalarRef );

sub _build_content ($self) {
    return P->file->read_bin( $self->source_path );
}

sub remove ($self) {
    $self->tree->remove_file( $self->path );

    return;
}

sub move ( $self, $target_path ) {
    $self->tree->move_file( $self->path, $target_path );

    return;
}

sub render_tmpl ( $self, $tmpl_args ) {
    my $tmpl = P->tmpl;

    $self->{content} = $tmpl->render( $self->content, $tmpl_args );

    return;
}

sub write_to ( $self, $target_path ) {
    $target_path = P->path( $target_path . q[/] . $self->path );

    P->file->mkpath( $target_path->dirname );

    if ( exists $self->{content} ) {
        P->file->write_bin( $target_path, P->text->encode_utf8( $self->content->$* ) );
    }
    else {
        P->file->copy( $self->source_path, $target_path );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::File::Tree::File

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
