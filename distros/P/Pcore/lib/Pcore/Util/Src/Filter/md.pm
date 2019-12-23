package Pcore::Util::Src::Filter::md;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];

with qw[Pcore::Util::Src::Filter];

sub decompress ($self) {
    my $res = $self->filter_prettier( parser => 'markdown' );

    return $res;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::md

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
