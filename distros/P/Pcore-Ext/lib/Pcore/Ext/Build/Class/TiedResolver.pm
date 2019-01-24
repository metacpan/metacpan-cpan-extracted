package Pcore::Ext::Build::Class::TiedResolver;

use Pcore;

sub TIEHASH ( $self, $sub ) { return bless $sub, $self }

sub FETCH ( $self, $key ) { return $self->($key) }

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Build::Class::TiedResolver

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
