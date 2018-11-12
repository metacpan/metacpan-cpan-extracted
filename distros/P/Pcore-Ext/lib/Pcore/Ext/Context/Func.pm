package Pcore::Ext::Context::Func;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr];

has ctx       => ( required => 1 );    # InstanceOf ['Pcore::Ext::Context']
has func_args => ();                   # Maybe [ArrayRef]
has func_body => ( required => 1 );    # Str

sub TO_JSON ( $self ) {
    my $id = refaddr $self;

    $self->{ctx}->{_js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self ) {
    my $js = 'function (';

    $js .= join q[,], $self->{func_args}->@* if $self->{func_args};

    my $body = "$self->{func_body}";

    $js .= ") { $body }";

    return \$js;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Context::Func - ExtJS function generator

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
