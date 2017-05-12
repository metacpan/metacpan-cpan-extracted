package Symbol::Methods;
use strict;
use warnings;

use Carp qw/croak/;
use B;

our $VERSION = '0.000002';
our @CARP_NOT = (
    'Symbol::Alias',
    'Symbol::Delete',
    'Symbol::Extract',
    'Symbol::Move',
);

my %SIGMAP = (
    '&' => 'CODE',
    '$' => 'SCALAR',
    '%' => 'HASH',
    '@' => 'ARRAY',
    # Others are unsupported.
);

sub symbol::exists {
    my ($class, $sym) = @_;
    $sym = _parse_symbol($sym, $class);
    my $ref = _get_ref($sym);
    return $ref ? 1 : 0;
}

sub symbol::fetch {
    my ($class, $sym) = @_;
    $sym = _parse_symbol($sym, $class);
    return _get_ref($sym);
}

sub symbol::delete {
    my ($class, $sym) = @_;
    $sym = _parse_symbol($sym, $class);
    my $ref = _get_ref($sym);
    _purge_symbol($sym);
    return $ref;
}

sub symbol::alias {
    my ($class, $old_sym, $new_sym) = @_;
    $old_sym = _parse_symbol($old_sym, $class);
    $new_sym = _parse_symbol($new_sym, $class, $old_sym->{sigil});

    croak "Origin and Destination symbols must be the same type, got '$old_sym->{type}' and '$new_sym->{type}'"
        unless $old_sym->{type} eq $new_sym->{type};

    my $old_ref = _get_ref($old_sym) or  croak "Symbol $old_sym->{sym} does not exist";
    my $new_ref = _get_ref($new_sym) and croak "Symbol $new_sym->{sym} already exists";

    *{_get_glob($new_sym)} = $old_ref;
}

sub symbol::move {
    my ($class, $old_sym, $new_sym) = @_;
    $old_sym = _parse_symbol($old_sym, $class);
    $new_sym = _parse_symbol($new_sym, $class, $old_sym->{sigil});

    symbol::alias($class, $old_sym, $new_sym);

    _purge_symbol($old_sym);
}

sub _parse_symbol {
    my ($sym, $class, $def_sig) = @_;
    return $sym if ref $sym;

    my ($sig, $pkg, $name) = ($sym =~ m/^(\W)?(.*::)?([^:]+)$/);

    $sig ||= $def_sig || '&';

    $pkg ||= $class;
    $pkg = 'main' if $pkg eq '::';
    $pkg =~ s/::$//;

    my $type = $SIGMAP{$sig} || croak "Unsupported sigil '$sig'";

    return {
        sym   => "$sig$pkg\::$name",
        name  => $name,
        sigil => $sig,
        type  => $type,
        pkg   => $pkg,
    };
}

sub _get_stash {
    my ($sym) = @_;
    no strict 'refs';
    no warnings 'once';
    return \%{"$sym->{pkg}\::"};
}

sub _get_glob {
    my ($sym) = @_;
    no strict 'refs';
    no warnings 'once';
    return \*{"$sym->{pkg}\::$sym->{name}"};
}

sub _get_ref {
    my ($sym, $globref) = @_;

    unless($sym->{NO_CHECK_STASH}) {
        my $stash = _get_stash($sym);
        return undef unless exists $stash->{$sym->{name}};

        $globref = _get_glob($sym);
    }

    croak "You must pass in a globref for this usage" unless $globref;

    my $type = $sym->{type};

    return *{$globref}{$type} if $type ne 'SCALAR' && defined(*{$globref}{$type});

    if ($] < 5.010) {
        unless ($sym->{NO_CHECK_STASH}) {
            local $@;
            local $SIG{__WARN__} = sub { 1 };
            return *{$globref}{$type} if eval "package $sym->{pkg}; my \$y = $sym->{sigil}$sym->{name}; 1";
        }
        return *{$globref}{$type} if defined(*{$globref}{$type}) && defined(${*{$globref}{$type}});
        return undef;
    }

    my $sv = B::svref_2object($globref)->SV;
    return *{$globref}{$type} if $sv->isa('B::SV');
    return undef unless $sv->isa('B::SPECIAL');
    return *{$globref}{$type} if $B::specialsv_name[$$sv] ne 'Nullsv';
    return undef;
}

sub _set_symbol {
    my ($sym, $ref) = @_;
    *{_get_glob($sym)} = $ref;
}

sub _purge_symbol {
    my ($sym) = @_;

    local *GLOBCLONE = *{_get_glob($sym)};
    delete _get_stash($sym)->{$sym->{name}};
    my $new_glob = _get_glob($sym);

    for my $type (qw/CODE SCALAR HASH ARRAY FORMAT IO/) {
        next if $type eq $sym->{type};
        my $ref = _get_ref({type => $type, NO_CHECK_STASH => 1}, \*GLOBCLONE) || next;
        *$new_glob = $ref;
    }

    return *GLOBCLONE{$sym->{type}};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Symbol::Methods - Symbol manipulation methods for packages.

=head1 DESCRIPTION

This package introduces several subs that can be called as methods on packages.
These subs allow you to modify symbol tables. This module does not do anything
that can't be done with L<Package::Stash>, or other tools. What this module does
give you is a package method interface.

=head1 SYNOPSYS

    use Symbol::Methods;

    # Move a symbol, the old name will be removed
    Foo::Bar->symbol::move('&foo' => '&bar');

    # Alias a symbol, both names will work
    Foo::Bar->symbol::alias('&foo' => '&bar');

    # Get a reference to the symbol
    my $ref = Foo::Bar->symbol::fetch('%foo');

    # Delete a symbol (and return the reference that was removed)
    my $ref = Foo::Bar->symbol::delete('&foo');

    # Check if a symbol exists.
    if(Foo::Bar->symbol::exists('&foo')) {
        ...
    }

=head1 METHODS

These methods all exist in the C<symbol::> namespace. These can always be
called as methods on any package thanks to the way perl resolves methods.

=over 4

=item $PACKAGE->symbol::move($SYMBOL, $NEW_NAME)

=item $PACKAGE->symbol::alias($SYMBOL, $NEW_NAME)

These will grab the symbol specified by C<$SYMBOL> and make it available under
the name in C<$NEW_NAME>. C<alias()> will leave the symbol available under both
names, C<move()> will remove it from the original name.

C<$SYMBOL> must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in C<$PACKAGE>.

C<$NEW_NAME> must be a string identifying the symbol. The string may include a
symbol, or the sigil from the C<$SYMBOL> string will be used. The string can be
a fully qualified symbol name, or it will be assumed that the new name is in
C<$PACKAGE>.

=item $ref = $PACKAGE->symbol::fetch($SYMBOL)

=item $ref = $PACKAGE->symbol::delete($SYMBOL)

These will both find the specified symbol and return a reference to it.
C<fetch()> will simply return the reference, C<delete()> will remove the symbol
before returning the reference.

C<$SYMBOL> must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in C<$PACKAGE>.

=item $bool = $PACKAGE->symbol::exists($SYMBOL)

This will check if the specified symbol exists. If the symbol exists a true
value is returned. If the symbol does not exist a false value is returned.

C<$SYMBOL> must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in C<$PACKAGE>.

=back

=head1 SEE ALSO

=over 4

=item Symbol::Alias

L<Symbol::Alias> Allows you to set up aliases within a package at compile-time.

=item Symbol::Delete

L<Symbol::Delete> Allows you to remove symbols from a package at compile time.

=item Symbol::Extract

L<Symbol::Extract> Allows you to extract symbols from packages and into
variables at compile time.

=item Symbol::Move

L<Symbol::Move> allows you to rename or relocate symbols at compile time.

=back

=head1 SOURCE

The source code repository for symbol can be found at
F<http://github.com/exodist/Symbol-Move>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
