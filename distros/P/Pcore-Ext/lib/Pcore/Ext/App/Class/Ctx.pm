package Pcore::Ext::App::Class::Ctx;

use Pcore -role;
use Pcore::Lib::Scalar qw[refaddr];

requires qw[generate];

has class => ( required => 1 );

around new => sub ( $orig, $self, @args ) {
    $self = $self->$orig(@args);

    my $id = '__JS_' . refaddr($self) . '__';

    $self->{class}->{build_cache}->{$id} = $self;

    return $id;
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App::Class::Ctx

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
