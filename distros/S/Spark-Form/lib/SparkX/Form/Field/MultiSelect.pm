package SparkX::Form::Field::MultiSelect;
our $VERSION = '0.2102';


# ABSTRACT: A multiple select drop-down field for SparkX::Form

use Moose;
use HTML::Tiny;
use List::Util 'first';

extends 'Spark::Form::Field';
with 'Spark::Form::Field::Role::Printable::HTML',
  'Spark::Form::Field::Role::Printable::XHTML';

has '+value' => (
    isa => 'ArrayRef[Str]',
);

has options => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 0,
    lazy     => 1,
    default  => sub { return shift->value },
);

sub to_html {
    return shift->_render(HTML::Tiny->new(mode => 'html'));
}

sub to_xhtml {
    return shift->_render(HTML::Tiny->new(mode => 'xml'));
}

sub _is_selected {
    my ($self, $value) = @_;

    return first { $value eq $_ } @{$self->value};
}

sub _render_option {
    my ($self, $html, $option) = @_;
    return $html->option({
            value => $option,
            ($self->_is_selected($option) ? (selected => 'selected') : ()),
    });
}

sub _render {
    my ($self, $html) = @_;
    my @options = map { $self->_render_option($html, $_) } @{$self->options};

    return $html->select(
        {name => $self->name, multiple => 'multiple'}, join q{ }, @options
    );
}
__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

SparkX::Form::Field::MultiSelect - A multiple select drop-down field for SparkX::Form

=head1 VERSION

version 0.2102

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

