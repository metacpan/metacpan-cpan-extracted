package String::Incremental::String;
use 5.008005;
use warnings;
use Mouse;
use Data::Validator;
use MouseX::Types::Mouse qw( Str CodeRef is_CodeRef );

use overload (
    '""' => \&as_string,
    '='  => sub { $_[0] },
);

has 'format' => ( is => 'ro', isa => Str );
has 'value' => ( is => 'ro', isa => CodeRef|Str );

sub BUILDARGS {
    my ($class, %args) = @_;
    my $v = Data::Validator->new(
        format => { isa => Str },
        value  => { isa => CodeRef|Str },
    );
    %args = %{$v->validate( \%args )};
    return \%args;
}

sub as_string {
    my ($self) = @_;
    my $val = $self->value;
    if ( is_CodeRef( $val ) ) { $val = $val->() }
    return sprintf( $self->format, $val );
}

sub re {
    my ($self) = @_;
    my $re;
    if ( is_CodeRef( $self->value ) ) {
        $re = '.*?';  # tmp
    }
    else {
        $re = "$self";
    }

    return qr/$re/;
}

__PACKAGE__->meta->make_immutable();
__END__

=encoding utf-8

=head1 NAME

String::Incremental::String

=head1 SYNOPSIS

    use String::Incremental::String;

    my $str = String::Incremental::String->new(
        format => '%04s',
        value  => sub { (localtime)[5] - 100 },
    );

    print "$str";  # -> '0014'


=head1 DESCRIPTION

String::Incremental::String is ...


=head1 CONSTRUCTORS

=over 4

=item new( %args ) : String::Incremental::String

%args:

format : Str

value : CodeRef|Str

=back


=head1 METHODS

=over 4

=item as_string() : Str

returns "current" string.

following two variables are equivalent:

    my $a = $str->as_string();
    my $b = "$str";

=back


=head1 LICENSE

Copyright (C) issm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=cut
