package Pcore::Ext::Context::Func;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr];

has ext => ( is => 'ro', isa => InstanceOf ['Pcore::Ext::Context'], required => 1 );

has func_name => ( is => 'ro', isa => Maybe [Str] );
has func_args => ( is => 'ro', isa => Maybe [ArrayRef] );
has func_body => ( is => 'ro', isa => Str, required => 1 );

sub TO_JSON ( $self ) {
    my $id = refaddr $self;

    $self->{ext}->{js_gen_cache}->{$id} = $self->to_js;

    return "__JS${id}__";
}

sub to_js ( $self ) {
    my $js = 'function';

    $js .= q[ ] . $self->{func_name} if $self->{func_name};

    $js .= q[(];

    $js .= join q[,], $self->{func_args}->@* if $self->{func_args};

    $js .= "){\n" . $self->{func_body} . "\n}";

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
