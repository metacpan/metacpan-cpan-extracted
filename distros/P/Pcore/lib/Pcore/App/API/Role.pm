package Pcore::App::API::Role;

use Pcore -class;
use Pcore::Util::Scalar qw[is_plain_arrayref];

has app => ( isa => q[ConsumerOf ['Pcore::App']], required => 1 );

has api_map => ( is => 'lazy', isa => 'HashRef', init_arg => undef );

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
