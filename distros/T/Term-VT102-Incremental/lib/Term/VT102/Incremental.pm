package Term::VT102::Incremental;
BEGIN {
  $Term::VT102::Incremental::VERSION = '0.05';
}
use Moose;
use Term::VT102;
# ABSTRACT: get VT updates in increments




use constant vt_class => 'Term::VT102';

has vt => (
    is      => 'ro',
    isa     => 'Term::VT102',
    handles => ['process', 'rows' ,'cols'],
);

has _screen => (
    is        => 'ro',
    isa       => 'ArrayRef[ArrayRef[HashRef]]',
    lazy      => 1,
    default   => sub {
        my $self = shift;
        my ($rows, $cols) = ($self->rows, $self->cols);

        return [
            map {
            [ map { +{} } (1 .. $cols) ]
            } (1 .. $rows)
        ];
    },
);

has rows_updated => (
    is => 'ro',
    isa => 'ArrayRef[Bool]',
    lazy => 1,
    clearer => '_clear_rows_updated',
    default => sub { [ (0) x shift->rows ] },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my @vt_args  = @_;

    my $vt = $class->vt_class->new(@vt_args);

    return $class->$orig(vt => $vt);
};


sub BUILD {
    my $self = shift;

    my $rows_updated = $self->rows_updated;
    my $rows = $self->rows - 1;

    $self->vt->callback_set(
        'ROWCHANGE', sub {
            my (undef, undef, $row) = @_;
            $self->rows_updated->[$row - 1] = 1;
        }
    );
    for my $cb (qw/SCROLL_DOWN SCROLL_UP/) {
        $self->vt->callback_set(
            $cb, sub {
                my (undef, undef, $row) = @_;
                @{$self->rows_updated}[$_] = 1 for $row-1 .. $rows;
            }
        );
    }
}


sub get_increment {
    my $self = shift;
    my ($vt, $screen) = ($self->vt, $self->_screen);

    my %updates;
    my @data;
    foreach my $row (0 .. $self->rows-1) {
        next unless $self->rows_updated->[$row];
        my $line = $vt->row_plaintext($row + 1);
        my $att = $vt->row_attr($row + 1);

        foreach my $col (0 .. $self->cols-1) {
            my $text = substr($line, $col, 1);

            $text = ' ' if ord($text) == 0;

            my %data;

            @data{qw|fg bg bo fo st ul bl rv v|}
                = ($vt->attr_unpack(substr($att, $col * 2, 2)), $text);

            my $prev = $screen->[$row]->[$col];
            $screen->[$row]->[$col] = {%data}; # clone

            if (scalar keys %$prev) {
                foreach my $attr (keys %data) {

                    delete $data{$attr}
                        if ($data{$attr} || '') eq ($prev->{$attr} || '');
                }
            }

            push @data, [$row, $col, \%data] if scalar(keys %data) > 0;
        }
    }

    $self->_clear_rows_updated;
    return \@data;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Term::VT102::Incremental - get VT updates in increments

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  my $vti = Term::VT102::Incremental->new(
    rows => 50,
    cols => 100,
  );

  $vti->process(...);
  my $updates = $vti->get_increment(); # at time X

  $vti->process(...);
  $vti->process(...);
  my $updates_since_time_X = $vti->get_increment(); # at time Y

=head1 DESCRIPTION

Term::VT102::Incremental is a thin wrapper around L<Term::VT102> with a few
internal differences. This module takes the B<exact same arguments in the constructor> as L<Term::VT102>, but has one extra method: C<get_increment>.

=head1 ATTRIBUTES

=head2 vt

Intermal L<Term::VT102> object. You can make any configurations that
any other normal L<Term::VT102> object would let you make.

=head1 METHODS

=head2 process

See L<Term::VT102>'s C<process>.

=head2 rows

See L<Term::VT102>'s C<rows>.

=head2 cols

See L<Term::VT102>'s C<cols>.

=head2 vt_class

Returns the name of the VT class that the internal
VT object will use when instantiated. Currently defaults
too L<Term::VT102> but can be overridden by extending this
class.

=head2 get_increment

After one or more updates, you can call C<get_increment> to see the incremental
series of updates you've made. It returns an arrayref of 3-element lists:
B<row>, B<cell>, and B<cell property differences>.

Cell properties consist of:

=over

=item Foreground (C<fg>)

=item Background (C<bg>)

=item Boldness (C<bo>)

=item Faint (C<fa>)

=item Standout (C<st>)

=item Underline (C<ul>)

=item Blink (C<bl>)

=item Reverse coloring (C<rv>)

=back

See the C<attr_pack> method in the L<Term::VT102> documentation for details
on this.

=for Pod::Coverage BUILD

=head1 AUTHOR

Jason May <jason.a.may@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jason May.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

