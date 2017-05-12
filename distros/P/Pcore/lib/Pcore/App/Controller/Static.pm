package Pcore::App::Controller::Static;

use Pcore -role;

with qw[Pcore::App::Controller];

sub run ( $self, $req ) {
    $self->return_static($req);

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller::Static

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
