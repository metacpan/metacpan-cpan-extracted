package NetHack::Menu;
BEGIN {
  $NetHack::Menu::AUTHORITY = 'cpan:SARTAK';
}
{
  $NetHack::Menu::VERSION = '0.08';
}
use Moose;
use Moose::Util::TypeConstraints 'enum';
use NetHack::Menu::Item;
# ABSTRACT: parse and interact with a NetHack menu

has vt => (
    is       => 'rw',
    isa      => 'Term::VT102',
    required => 1,
    handles  => {
        _row_plaintext => 'row_plaintext',
        _vt_rows       => 'rows',
    },
);

has _page_number => (
    is      => 'rw',
    isa     => 'Int',
);

has _page_count => (
    is      => 'rw',
    isa     => 'Int',
);

has _pages => (
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef[NetHack::Menu::Item]]',
    default => sub { [] },
);

has select_count => (
    is      => 'rw',
    isa     => (enum['single', 'multi']),
    default => 'multi',
);

has extra_rows => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        extra_rows     => 'elements',
        _add_extra_row => 'push',
    },
);

sub has_menu {
    my $self = shift;

    for (0 .. $self->_vt_rows) {
        if (($self->_row_plaintext($_)||'') =~ /\((end|(\d+) of (\d+))\)\s*$/) {

            my ($current, $max) = ($2, $3);
            ($current, $max) = (1, 1) if ($1||'') eq 'end';

            # this may happen if someone is trying to screw with us and gives
            # us a page number or page count of 0
            next unless $current && $max;

            return 1;
        }
    }
    return 0;
}

sub at_end {
    my $self = shift;

    for (0 .. $self->_vt_rows) {
        if (($self->_row_plaintext($_)||'') =~ /^(.*)\((end|(\d+) of (\d+))\)\s*$/) {
            my ($current, $max) = ($3, $4);
            ($current, $max) = (1, 1) if ($2||'') eq 'end';

            # this may happen if someone is trying to screw with us and gives
            # us a page number or page count of 0
            next unless $current && $max;

            $self->_page_number($current);
            $self->_page_count($max);
            $self->_parse_current_page(length($1), $_);
            last;
        }
    }

    defined($self->_page_number)
        or Carp::croak "Unable to parse a menu.";

    for (1 .. $self->_page_count) {
        if (!defined($self->_pages->[$_])) {
            return 0;
        }
    }

    return 1;
}

sub _parse_current_page {
    my $self      = shift;
    my $start_col = shift;
    my $end_row   = shift;

    # have we already parsed this one?
    return if defined $self->_pages->[ $self->_page_number ];
    my $page = $self->_pages->[ $self->_page_number ] ||= [];

    # extra space is for #enhance
    my $re = qr/^(?:.{$start_col})(.)  ?([-+#]) (.*?)\s*$/;
    for (0 .. $end_row - 1) {
        my $text = $self->_row_plaintext($_);
        if ($text =~ $re) {
            my ($selector, $sigil, $name) = ($1, $2, $3);
            my $quantity;
            my $selected;

            if ($sigil eq '+') {
                $selected = 1;
                $quantity = 'all';
            }
            elsif ($sigil eq '-') {
                $selected = 0;
                $quantity = 0;
            }
            elsif ($sigil eq '#') {
                $selected = 1;
                # unknown selected quantity, leave it undef
            }
            else {
                confess "Unknown sigil $sigil";
            }

            my $item = NetHack::Menu::Item->new(
                description => $name,
                selector    => $selector,
                selected    => $selected,
                (defined($quantity) ? (quantity => $quantity) : ()),
            );

            push @$page, $item;
        }
        else {
            $self->_add_extra_row($text);
        }
    }
}

sub next {
    my $self = shift;

    # look for the first page after the current page that hasn't been parsed
    for ($self->_page_number + 1 .. $self->_page_count) {
        if (@{ $self->_pages->[$_] || [] } == 0) {
            return join '', map {'>'} $self->_page_number + 1 .. $_;
        }
    }

    # now look for any pages we may have missed at the beginning
    for (1 .. $self->_page_number - 1) {
        if (@{ $self->_pages->[$_] || [] } == 0) {
            return '^' . join '', map {'>'} $self->_page_number + 1 .. $_;
        }
    }

    # we're done, but the user isn't following our API
    confess "$self->next called even though $self->at_end is true.";
}

sub select {
    my $self      = shift;
    my $predicate = shift;

    for my $item ($self->all_items) {
        my $select = do {
            local $_ = $item->description;
            $predicate->($item);
        };

        if ($select) {
            $item->selected(1);
            $item->quantity('all');
        }
    }
}

sub select_quantity {
    my $self      = shift;
    my $predicate = shift;

    for my $item ($self->all_items) {
        my $quantity = do {
            local $_ = $item->description;
            $predicate->($item);
        };

        next if !defined($quantity);

        $item->quantity($quantity);

        if ($quantity) {
            $item->selected(1);
        }
        else {
            $item->selected(0);
        }
    }
}

sub deselect {
    my $self      = shift;
    my $predicate = shift;

    for my $item ($self->all_items) {
        my $deselect = do {
            local $_ = $item->description;
            $predicate->($item);
        };

        if ($deselect) {
            $item->selected(0);
            $item->quantity(0);
        }
    }
}

# stop as soon as we've got the first item to select
sub _commit_single {
    my $self = shift;
    my $out = '';
    $out .= '^' if $self->_page_number != 1;

    for my $i (1 .. $self->_page_count) {
        for my $item (@{ $self->_pages->[$i] }) {
            if ($item->selected) {
                return $out . $item->selector;
            }
        }
        $out .= '>';
    }

    chop $out; # useless >
    return $out . ' ';
}

# everything and anything, baby
sub _commit_multi {
    my $self = shift;

    my $out = '';
    $out .= '^' if $self->_page_number != 1;

    for my $i (1 .. $self->_page_count) {
        for my $item (@{ $self->_pages->[$i] }) {
            my $item_commands = $item->commit
                or next;

            $out .= $item_commands;
        }

        $out .= '>';
    }

    chop $out; # useless >
    return $out . ' ';
}

sub commit {
    my $self = shift;
    my $method = '_commit_' . $self->select_count;
    $self->$method();
}

sub all_items {
    my $self = shift;
    return map { @{ $_ || [] } } @{ $self->_pages };
}

sub selected_items {
    my $self = shift;
    return grep { $_->selected } $self->all_items;
}

1;

__END__

=pod

=head1 NAME

NetHack::Menu - parse and interact with a NetHack menu

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use NetHack::Menu;
    my $menu = NetHack::Menu->new(vt => $term_vt102);

    # compile all pages of the menu
    until ($menu->at_end) {
        $term_vt102->process($nh->send_and_recv($menu->next));
    }

    # we want to stuff all blessed items into our bag
    $menu->select(sub { /blessed/ });

    # but we don't want things that will make our bag explode
    $menu->deselect(sub { /cancell|bag.*(holding|tricks)/ });

    $term_vt102->process($nh->send_and_recv($menu->commit));

=head1 DESCRIPTION

NetHack requires a lot of menu management. This module aims to alleviate the
difficulty of parsing and interacting with menus.

This module is meant to be as general and flexible as possible. You just give
it a L<Term::VT102> object, send the commands it gives you to NetHack, and
update the L<Term::VT102> object. Your code should look roughly the same as
the code given in the Synopsis.

=head1 METHODS

=head2 new (vt => L<Term::VT102>, select_count => (single|multi)) -> C<NetHack::Menu>

Takes a L<Term::VT102> (or a behaving subclass, such as
L<Term::VT102::Boundless> or L<Term::VT102::ZeroBased>). Also takes an optional
C<select_count> which determines the type of menu. C<NetHack::Menu> cannot
intuit it by itself, it depends on the application to know what it is dealing
with. Default: C<multi>.

=head2 select_count [single|multi] -> (single|multi)

Accessor for C<select_count>. Default: C<multi>.

WARNING: No-select menus are potentially ambiguous with --More--. See below.

=head2 has_menu -> Bool

Is there currently a menu on the screen?

=head2 at_end -> Bool

This will return whether we've finished compiling the menu. This must be
called for each page because this is what does all the compilation.

Note that if there's no menu, this will C<croak>.

=head2 all_items -> [ NetHack::Menu::Item ]

Returns all items in the menu.

=head2 selected_items -> [ NetHack::Menu::Item ]

Returns all selected items in the menu.

=head2 next -> Str

Returns the string to be used to get to the next page. Note that you should
not ignore this method and use C<< > >> or a space if your menu may not
start on page 1. This method will make sure everything is hunky-dory anyway,
so you should still use it.

=head2 select Code

Evaluates the code for each item on the menu and selects those which produce
a true value. The code ref receives C<$_> as the text of the item (e.g.
C<a blessed +1 quarterstaff (weapon in hands)>). The code ref also receives the
item's selector (the character you'd type to toggle the item) as an argument.

Note that you can stack up multiple selects (and deselects) before eventually
finishing the menu with C<< $menu->commit >>.

Do note that selecting is not the same as toggling.

This currently returns no useful value.

=head2 select_quantity Code

Same as select, but instead of returning a truth value the coderef should
return undef (if no change is to be made for this item), a non-negative integer
(to select a specific amount), or the special string 'all'.

=head2 deselect Code

Same as select, but different in the expected way. C<:)>

=head2 commit -> Str

This will return the string to be sent that will navigate the menu and toggle
the requested items.

=head1 TODO

=over 4

=item

Not everyone uses the default C<^>, C<|>, and C<< > >> menu accelerators.
Provide a way to change them.

=item

Not everyone uses L<Term::VT102>. Provide some way to pass in just a string or
something. This will be added on an if-needed basis. Anyone?

=back

=head1 BUGS

=head2 No-select menus

Unfortunately, NetHack uses the string C<--More--> to indicate a no-select
menu. This is ambiguous with a list of messages that spills over onto another
"page".

The expected way to handle no-select menus is to:

=over 4

=item Look at the topline

=item Decide if the topline is a no-select menu

This can be done by looking to see if it contains, for example, "Discoveries".
Note that "Things that are here" can appear on the third line. Argh!

=item If so, use NetHack::Menu

=item Otherwise, hit space

=back

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
