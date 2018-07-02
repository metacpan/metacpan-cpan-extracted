package Pcore::Ext::Context::Raw;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr];

has ctx => ();    # ( is => 'ro', isa => InstanceOf ['Pcore::Ext::Context'], required => 1 );
has js  => ();    #  ( is => 'ro', isa => Str, required => 1 );

sub TO_JSON ( $self ) {
    my $id = refaddr $self;

    $self->{ctx}->{_js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self ) {
    my $js = "$self->{js}";

    return \$js;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context::Raw - ExtJS raw js generator

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
