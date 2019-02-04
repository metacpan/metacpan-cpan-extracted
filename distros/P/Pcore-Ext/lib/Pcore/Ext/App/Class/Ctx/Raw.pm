package Pcore::Ext::App::Class::Ctx::Raw;

use Pcore -class;

with qw[Pcore::Ext::App::Class::Ctx];

has js => ( required => 1 );    # Str

sub generate ( $self, $quote ) {
    return $self->{js};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App::Class::Ctx::Raw - ExtJS raw js generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
