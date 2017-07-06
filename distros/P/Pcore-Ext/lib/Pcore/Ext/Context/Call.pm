package Pcore::Ext::Context::Call;

use Pcore -class;
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Scalar qw[refaddr];

has ext => ( is => 'ro', isa => InstanceOf ['Pcore::Ext::Context'], required => 1 );

has func_name => ( is => 'ro', isa => Str, required => 1 );
has func_args => ( is => 'ro', isa => Maybe [ArrayRef] );

sub TO_JSON ( $self, @ ) {
    my $id = refaddr $self;

    $self->{ext}->{js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self ) {
    my $js;

    if ( my $args = $self->{func_args} ) {
        $js = "$self->{func_name}(" . join( q[,], map { to_json( $_, json => { ascii => 1, latin1 => 0, utf8 => 1, pretty => 0, canonical => 1 } )->$* } $args->@* ) . q[)];
    }
    else {
        $js = "$self->{func_name}()";
    }

    return \$js;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context::Call - ExtJS function call generator

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
