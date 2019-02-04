package Pcore::Ext::App::Class::Ctx::Func;

use Pcore -class;

with qw[Pcore::Ext::App::Class::Ctx];

has func_body => ( required => 1 );    # Str
has func_args => ();                   # Maybe [ArrayRef]

sub generate ( $self, $quote ) {
    my $js = 'function (';

    $js .= join ',', $self->{func_args}->@* if $self->{func_args};

    my $body = "$self->{func_body}";

    $js .= ") { $body }";

    return $js;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App::Class::Ctx::Func - ExtJS function generator

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
