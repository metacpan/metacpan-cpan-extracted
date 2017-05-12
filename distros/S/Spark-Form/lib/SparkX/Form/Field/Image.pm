package SparkX::Form::Field::Image;
our $VERSION = '0.2102';


# ABSTRACT: An image field for SparkX::Form

use Moose;
use HTML::Tiny;

extends 'Spark::Form::Field';
with 'Spark::Form::Field::Role::Printable::HTML',
  'Spark::Form::Field::Role::Printable::XHTML';

has '+value' => (
    isa => 'Str',
);

## no critic (ProhibitMagicNumbers)
has 'names' => (
    lazy => 1,
    (Moose->VERSION >= 0.84) ? (is => 'bare') : (),
    default => sub {
        my $self = shift;

        return [$self->name . '.x', $self->name . '.y'];
    },
);
## use critic

sub to_html {
    return shift->_render(HTML::Tiny->new(mode => 'html'));
}

sub to_xhtml {
    return shift->_render(HTML::Tiny->new(mode => 'xml'));
}

sub _render {
    my ($self, $html) = @_;

    return $html->input({type => 'image', name => $self->name});
}
__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

SparkX::Form::Field::Image - An image field for SparkX::Form

=head1 VERSION

version 0.2102

=head1 DESCRIPTION

Note that this does not support server-side image map functionality but will be treated as a submit. Patches welcome that don't break this (99% of the time desired) behaviour.

=head1 METHODS

=head2 to_html() => Str

Renders the field to HTML

=head2 to_xhtml() => Str

Renders the field to XHTML

=head2 validate() => Bool

Validates the field. Before composition with validators, always returns 1.

=head1 SEE ALSO

=over 4

=item L<SparkX::Form> - The forms module this is to be used with

=item L<SparkX::Form::BasicFields> - A collection of fields for use with C<Spark::Form>

=back 



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

