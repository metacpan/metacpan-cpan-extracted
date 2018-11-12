package Pcore::App::Controller::Index;

use Pcore -role;

with qw[Pcore::App::Controller];

# around run => sub ( $orig, $self, $req ) {
#     if ( defined $req->{path_tail}->{filename} ) {
#         $self->return_static($req);

#         return;
#     }
#     else {
#         return $self->$orig($req);
#     }
# };

# sub return_static ( $self, $req ) {
#     if ( $req->{path_tail} && defined $req->{path_tail}->{filename} ) {
#         if ( my $path = $ENV->{share}->get( 'www', $req->{path} . $req->{path_tail} ) ) {
#             my $data = P->file->read_bin($path);

#             $path = P->path($path);

#             $req->( 200, [ 'Content-Type' => $path->mime_type // 'application/octet-stream' ], $data )->finish;
#         }
#         else {
#             $req->(404)->finish;    # not found
#         }
#     }
#     else {
#         $req->(403)->finish;        # forbidden
#     }

#     return;
# }

sub get_nginx_cfg ($self) {
    return <<"TXT";
    location =/ {
        error_page 418 = \@backend;
        return 418;
    }

    location / {
        rewrite ^/favicon.ico\$ /cdn/favicon.ico last;
        rewrite ^/robots.txt\$ /cdn/robots.txt last;

        error_page 418 = \@backend;
        return 418;
    }
TXT
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller::Index

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
