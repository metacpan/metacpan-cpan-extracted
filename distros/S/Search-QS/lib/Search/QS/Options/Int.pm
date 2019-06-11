package Search::QS::Options::Int;
$Search::QS::Options::Int::VERSION = '0.04';
use Moose;

# ABSTRACT: An integer object with a few methods


has name    => ( is => 'ro', isa => 'Str');
has value   => ( is => 'rw', isa => 'Int|Undef', builder => '_build_value');
has default => ( is => 'ro', isa => 'Int|Undef', default => undef);


sub to_qs() {
    my $s = shift;
    my $amp = shift || 0;
    return '' if ($s->value ~~ $s->default);
    return $s->name . '=' . $s->value . ($amp ? '&' : '');
}

sub reset() {
    my $s = shift;
    $s->value($s->default);
}

sub _build_value() {
    return shift->default;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::QS::Options::Int - An integer object with a few methods

=head1 VERSION

version 0.04

=head1 DESCRIPTION

An abstract class to incapsulate Undef|Int value

=head1 METHODS

=head2 name()

Defined in subclass, is the name of the integer value

=head2 value()

The value of the integer

=head2 default()

Defined in subclass, the default value of the integer

=head2 to_qs($append_ampersand)

Return a query string of the internal rappresentation of the object. If L<value()>
is different by L<default()> and $append_ampersand is true, it appends
an ampersand (&) at the end of the returned string

=head2 reset()

Reset the object to the L<default()> value.

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
