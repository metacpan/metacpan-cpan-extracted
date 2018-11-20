package Term::Choose_HAE;

use warnings;
use strict;
use 5.010001;

our $VERSION = '0.058';
use Exporter 'import';
our @EXPORT_OK = qw( choose );

use Carp qw( croak );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use parent 'Term::Choose';


my $Plugin;

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require Term::Choose::Win32;
        $Plugin = 'Term::Choose::Win32';
    }
    else {
        require Term::Choose::Linux;
        $Plugin = 'Term::Choose::Linux';
    }
}


sub new {
    # the function 'choose' uses its own implicit new
    my $class = shift;
    my ( $opt ) = @_;
    croak "new: called with " . @_ . " arguments - 0 or 1 arguments expected" if @_ > 1;
    my $self = bless {}, $class;
    if ( defined $opt ) {
        croak "new: the (optional) argument must be a HASH reference" if ref $opt ne 'HASH';
        $self->__validate_and_add_options( $opt );
    }
    if ( $opt->{fill_up} ) {
        $opt->{color} = 1 + delete $opt->{fill_up};
    }
    $self->{backup_opt} = { defined $opt ? %$opt : () };
    $self->{plugin} = $Plugin->new();
    return $self;
}


sub choose {
    if ( ref $_[0] ne 'Term::Choose_HAE' ) {
        if ( $_[1]->{fill_up} ) {
            $_[1]->{color} = 1 + delete $_[1]->{fill_up};
        }
        return Term::Choose_HAE->new()->Term::Choose::__choose( @_ );
    }
    my $self = shift;
    if ( $_[1]->{fill_up} ) {
        $_[1]->{color} = 1 + delete $_[1]->{fill_up};
    }
    return $self->Term::Choose::__choose( @_ );
}



1;


__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose_HAE - DEPRECATED

=head1 VERSION

Version 0.058

=cut

=head1 SYNOPSIS

Functional interface:

    use Term::Choose_HAE qw( choose );
    use Term::ANSIColor;

    my $array_ref = [
        colored( 'red_string', 'red'),
        colored( 'green_string', 'green'),
        colored( 'blue_string', 'cyan'),
    ];

    my $choice = choose( $array_ref );                            # single choice
    print "$choice\n";

    my @choices = choose( [ 1 .. 100 ], { justify => 1 } );       # multiple choice
    print "@choices\n";

    choose( [ 'Press ENTER to continue' ], { prompt => '' } );    # no choice

Object-oriented interface:

    use Term::Choose_HAE;
    use Term::ANSIColor;

    my $array_ref = [
        colored( 'red_string', 'red'),
        colored( 'green_string', 'green'),
        colored( 'blue_string', 'cyan'),
    ];

    my $new = Term::Choose_HAE->new();

    my $choice = $new->choose( $array_ref );                       # single choice
    print "$choice\n";

    my @choices = $new->choose( [ 1 .. 100 ] );                    # multiple choice
    print "@choices\n";

    my $stopp = Term::Choose_HAE->new( { prompt => '' } );
    $stopp->choose( [ 'Press ENTER to continue' ] );               # no choice

=head1 DESCRIPTION

This module is DEPRECATED and will be removed. Use L<Term::Choose> with its option I<color> instead.

Choose interactively from a list of items.

C<Term::Choose_HAE> works like C<Term::Choose> except that C<choose> from C<Term::Choose_HAE> does not disable ANSI
escape sequences; so with C<Term::Choose_HAE> it is possible to output colored text. On a MSWin32 OS
L<Win32::Console::ANSI> is used to translate the ANSI escape sequences. C<Term::Choose_HAE> provides one additional
option: I<fill_up>.

Else see L<Term::Choose> for usage and options.

=head2 Occupied escape sequences

C<choose> uses the "inverse" escape sequence to mark the cursor position and the "underline" and "bold" escape sequences
to mark the selected items in list context.

=head1 OPTIONS

C<Term::Choose_HAE> inherits the options from L<Term::Choose|Term::Choose/OPTIONS> (except the option I<ll>) and adds
the option I<fill_up>:

=head2 fill_up

0 - off

1 - fill up selected items with the adjacent color. (default)

2 - fill up selected items with the default color.

If I<fill_up> is enabled, the highlighting of the cursor position and in list context the highlighting of the selected
items has always the width of the column.

=over

=item

I<fill_up> set to C<1>: the color of the highlighting of leading and trailings spaces is set to the color of
the highlighting of the adjacent non-space character of the item if these spaces are not embedded in escape sequences.

=item

I<fill_up> set to C<2>: leading and trailings spaces are highlighted with the default color for highlighting if
these spaces are not embedded in escape sequences.

=back

If I<fill_up> is disabled, leading and trailing spaces are not highlighted if they are not embedded in escape sequences.

=head1 REQUIREMENTS

The requirements are the same as with C<Term::Choose> except that the minimum Perl version for C<Term::Choose_HAE> is
5.10.1 instead of 5.8.3.

=head2 Perl version

Requires Perl version 5.10.1 or greater.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Choose_HAE

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Based on a patch for C<Term::Choose> from Stephan Sachse.

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015-2018 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
