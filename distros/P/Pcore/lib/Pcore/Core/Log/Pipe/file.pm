package Pcore::Core::Log::Pipe::file;

use Pcore -class;
use Fcntl qw[:flock];
use IO::File;

extends qw[Pcore::Core::Log::Pipe];

has path => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Path'], required => 1 );

has h => ( is => 'lazy', isa => InstanceOf ['IO::File'], clearer => 1, init_arg => undef );

around new => sub ( $orig, $self, $args ) {
    if ( $args->{uri}->path->is_abs ) {
        P->file->mkpath( $args->{uri}->path->dirname );

        $args->{path} = $args->{uri}->path;
    }
    else {
        $args->{path} = P->path( $ENV->{DATA_DIR} . $args->{uri}->path );
    }

    return $self->$orig($args);
};

sub _build_id ($self) {
    return 'file:' . $self->path;
}

sub _build_h ($self) {
    my $h = IO::File->new( $self->path, '>>', P->file->calc_chmod(q[rw-------]) ) or die q[Unable to open "] . $self->path . q["];

    $h->binmode(':encoding(UTF-8)');

    $h->autoflush(1);

    return $h;
}

sub sendlog ( $self, $header, $data, $tag ) {

    # reopen file handle if file was removed
    $self->clear_h if !-f $self->path;

    my $h = $self->h;

    flock $h, LOCK_EX or die;

    say {$h} $header, $data;

    flock $h, LOCK_UN or die;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Log::Pipe::file

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
