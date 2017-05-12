package Pcore::App::Controller::Index;

use Pcore -role;

with qw[Pcore::App::Controller];

around run => sub ( $orig, $self, $req ) {
    if ( $req->{path_tail}->is_file ) {
        $self->return_static($req);

        return;
    }
    else {
        return $self->$orig($req);
    }
};

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
