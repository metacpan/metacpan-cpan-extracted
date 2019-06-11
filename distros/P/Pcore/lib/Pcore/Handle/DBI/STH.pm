package Pcore::Handle::DBI::STH;

use Pcore -class;

has query => ( required => 1 );    # Str

has id => ( sub { P->uuid->v1mc_str }, init_arg => undef );    # Str

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::STH

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
