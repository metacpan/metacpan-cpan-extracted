package Pcore::Ext::Build::Class::Ctx::Class;

use Pcore -class;

with qw[Pcore::Ext::Build::Class::Ctx];

has name => ( required => 1 );

sub generate ( $self, $quote ) {
    my $class_name;

    if ( index( $self->{name}, '.' ) != -1 ) {
        $class_name = $self->{name};
    }
    else {
        $class_name = $self->{class}->{app}->{classes}->{ $self->{name} }->{name};
    }

    die qq[Class name "$class_name" can't be resolved in "$self->{class}"] if !$class_name;

    return $quote . $class_name . $quote;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Build::Class::Ctx::Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
