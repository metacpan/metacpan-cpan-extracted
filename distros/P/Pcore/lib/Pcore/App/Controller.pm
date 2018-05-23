package Pcore::App::Controller;

use Pcore -role;

has app  => ( required => 1, isa => q[ConsumerOf ['Pcore::App']] );
has host => ( required => 1, isa => 'Str' );                          # HTTP controller host
has path => ( required => 1, isa => 'Str' );                          # HTTP controller url path, always finished with "/"

sub run ( $self, $req ) {
    $req->(404)->finish;

    return;
}

sub get_nginx_cfg ($self) {
    return;
}

sub return_static ( $self, $req ) {
    if ( $req->{path_tail} && $req->{path_tail}->is_file ) {
        if ( my $path = $ENV->{share}->get( 'www', $req->{path} . $req->{path_tail} ) ) {
            my $data = P->file->read_bin($path);

            $path = P->path($path);

            $req->( 200, [ 'Content-Type' => $path->mime_type ], $data )->finish;
        }
        else {
            $req->(404)->finish;    # not found
        }
    }
    else {
        $req->(403)->finish;        # forbidden
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
