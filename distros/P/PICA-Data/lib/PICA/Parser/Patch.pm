package PICA::Parser::Patch;
use v5.14.1;

our $VERSION = '2.12';

use parent 'PICA::Parser::Plain';

use Carp qw(croak);

sub _new {
    my $self = PICA::Parser::Base::_new(@_);
    $self->annotated = undef;
    $self->strict    = 1;
    $self;
}

sub parse_field {
    my ($self, $field) = @_;
    $field = $self->SUPER::parse_field($field);

    return [@$field, " "] unless @$field % 2;

    my $char = $field->[$#$field];
    croak "Invalid annotation: '$char'" if $char !~ /^[ +-]$/;

    return $field;
}

1;
__END__

=head1 NAME

PICA::Parser::Plain - Plain PICA+ format serializer

=head2 DESCRIPTION

This is basically L<PICA::Parser::Plain> with option C<strict> enabled and required
or empty annotation character C<+>, C<-> or space for each field.

The counterpart of this module is L<PICA::Writer::Patch>.

=cut
