package Pcore::Ext::App::Class::Ctx::Type;

use Pcore -class;

with qw[Pcore::Ext::App::Class::Ctx];

has name => ( required => 1 );

sub generate ( $self, $quote ) {
    my $alias = $self->{class}->{app}->{classes}->{ $self->{name} }->{alias};

    die qq[Alias for class "$self->{name}" can't be resolved in "$self->{class}"] if !$alias;

    return $quote . $alias . $quote;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::App::Class::Ctx::Type

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
