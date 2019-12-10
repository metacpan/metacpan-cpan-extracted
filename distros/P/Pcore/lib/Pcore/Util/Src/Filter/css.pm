package Pcore::Util::Src::Filter::css;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];

with qw[Pcore::Util::Src::Filter];

sub decompress ($self) {
    my $res = $self->filter_prettier('--parser=css');

    return $res;
}

sub compress ($self) {
    my $res = $self->filter_css_packer;

    return $res;
}

sub filter_css_packer ($self) {
    state $packer = do {
        require CSS::Packer;

        CSS::Packer->init;
    };

    $packer->minify( \$self->{data}, { compress => 'minify' } );

    return $SRC_OK;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::css

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
