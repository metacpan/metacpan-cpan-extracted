package NetHack::Menu::Item;
BEGIN {
  $NetHack::Menu::Item::AUTHORITY = 'cpan:SARTAK';
}
{
  $NetHack::Menu::Item::VERSION = '0.08';
}
use Moose;
use Moose::Util::TypeConstraints;

enum 'NetHack::Menu::Item::SelectedAll' => qw(all);

has description => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has selector => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has selected => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has _originally_selected => (
    is  => 'ro',
    isa => 'Bool',
);

has quantity => (
    is  => 'rw',
    isa => 'Int|NetHack::Menu::Item::SelectedAll',
);

has _original_quantity => (
    is  => 'ro',
    isa => 'Int|NetHack::Menu::Item::SelectedAll',
);

has user_data => (
    is  => 'rw',
    isa => 'Any',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my $params = $self->$orig(@_);

    $params->{_original_quantity} = $params->{quantity}
        if exists($params->{quantity});

    $params->{_originally_selected} = $params->{selected}
        if exists($params->{selected});

    return $params;
};

sub commit {
    my $self = shift;

    # nothing needed if it was unselected and stayed unselected
    if (!$self->_originally_selected && !$self->selected) {
        return;
    }

    # deselect
    if ($self->_originally_selected && !$self->selected) {
        return $self->selector;
    }

    # no update on this one... go ahead and let it stay as is
    if (!defined($self->quantity)) {
        return;
    }

    if ($self->quantity eq 'all') {
        if ($self->_originally_selected) {
            if (($self->_original_quantity||'') eq 'all') {
                return;
            }
            else {
                # if we want it all, send selector twice to deselect then select all
                return $self->selector . $self->selector;
            }
        }
        # it wasn't selected, now we want all, so just send selector
        else {
            return $self->selector;
        }
    }

    if ($self->quantity) {
        return $self->quantity . $self->selector;
    }

    return;

    confess "Internal inconsistency problem in NetHack::Menu::Item! " . $self->dump;
}


1;

__END__

=pod

=head1 NAME

NetHack::Menu::Item

=head1 VERSION

version 0.08

=for Pod::Coverage commit

=head1 AUTHORS

=over 4

=item *

Shawn M Moore <code@sartak.org>

=item *

Stefan O'Rear <stefanor@cox.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
