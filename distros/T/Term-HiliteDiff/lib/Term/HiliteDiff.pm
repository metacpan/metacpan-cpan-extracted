package Term::HiliteDiff;
BEGIN {
  $Term::HiliteDiff::VERSION = '0.10';
}
# ABSTRACT: Highlights differences in text with ANSI escape codes

## no critic (RequireUseWarnings)
## no critic (ProhibitPunctuationVars)

use strict;
use vars qw( @EXPORT_OK %EXPORT_TAGS $DEFAULTOBJ );
use Term::HiliteDiff::_impl ();

use Exporter ();
*import      = \&Exporter::import;
@EXPORT_OK   = qw( watch hilite_diff );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

# Auto-export everything to main if I've been called as a -e program.
if ( $0 eq '-e' ) {
    ## no critic (ProhibitMultiplePackages)
    package main;
BEGIN {
  $main::VERSION = '0.10';
}
    Term::HiliteDiff->import(':all');
}

# Here are some convenience functions for pretending this module isn't
# object oriented.
$DEFAULTOBJ = __PACKAGE__->new;

sub hilite_diff {
    return $DEFAULTOBJ->hilite_diff(@_);
}

sub watch {
    return $DEFAULTOBJ->watch(@_);
}

# Hey, a class constructor.
sub new {
    return Term::HiliteDiff::_impl->new;
}

# Blatantly copied this from errantstory.com
q[What's the point of dreaming I'm a girl if I don't get a cool lesbian scene?!];



=pod

=head1 NAME

Term::HiliteDiff - Highlights differences in text with ANSI escape codes

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    # Prints a tab delimited file, with differences highlighted
    use Term::HiliteDiff;
    my $differ = Term::HiliteDiff->new;
    while ( <> ) {
        my $line = [ split /\t/, $_, -1 ];
        my $diff = $differ->hilite_diff( $line );

        print join "\t", @$diff;
    }

OR as functions

    use Term::HiliteDiff qw( hilite_diff );
    while ( <> ) {
        my $line = [ split /\t/, $_, -1 ];
        my $diff = hilite_diff( $line );

        print $diff
    }

=head1 DESCRIPTION

Term::HiliteDiff prints or formats your input with the differences
highlighted. You can choose to update your display in place or let
things scroll past like tailing a log.

You can choose to let it attempt to parse the columns out of your data
or just pass an array reference in.

It highlights differences between subsequent lines/records of text. It
was directly inspired by the --difference mode provided by the
watch(1) program on Linux.

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 INPUT

It accepts either a single array reference or a string. There is no
parsing with an array reference. Strings are split by tabs, pipes, or
lines.

=over

=item No interpretation

    use Term::HiliteDiff;
    $obj = Term::HiliteDiff->new;

    for ( [qw[ Josh Jore jjore@cpan.org ]],
          [qw[ Josh JORE jjore@cpan.org ]],
    ) {
        $diff = $obj->hilite_diff( $_ );
        print join( "\t", @$diff ), "\n";
    }

=item Split by tabs

It's OK if there's a newline at the end of your input.

    use Term::HiliteDiff;
    $obj = Term::HiliteDiff->new;

    for ( "Josh\tJore\tjjore\@cpan.org\n",
          "Josh\tJORE\tjjore\@cpan.org\n",
    ) {
        print $obj->hilite_diff( $_ );
    }

=item Split by pipes

    use Term::HiliteDiff;
    $obj = Term::HiliteDiff->new;

    for ( "Josh|Jore|jjore\@cpan.org\n",
          "Josh|JORE|jjore\@cpan.org\n",
    ) {
        print $obj->hilite_diff( $_ );
    }

=item Split by lines

    use Term::HiliteDiff;
    $obj = Term::HiliteDiff->new;

    print $obj->hilite_diff( <<STRING );
        fname=Josh
        lname=Jore
        email=jjore@cpan.org
    STRING
    print $obj->hilite_diff( <<STRING );
        fname=Josh
        lname=JJORE
        email=jjore@cpan.org
    STRING

=item Split by any 'ole words

    use Term::HiliteDiff;
    $obj = Term::HiliteDiff->new;

    for ( "Singing dang fol dee dido\n",
          "Singing dang fol dee day\n",
    ) {
        print $obj->hilite_diff( $_ );
    }

=back

=head1 OUTPUT

Both the C<hilite_diff> and C<watch> method/functions return the
output in the same format as the input. If you passed in an array, you
get an array back but if you passed in something like a tab-delimited
string, the output is going to be formatted that way too.

    watch( \@input) }; # Array!
    watch( " \t " )  ; # Tabs!
    watch( ' | ' )   ; # Pipes!
    watch( " \n " )  ; # Lines!

Each column's value is compared to the previous value of the same
column. Changed values are marked up.

Presently the only mark-up is to use the "reverse hilighting". If these
two rows were marked up then the middle value C<JORE> would be
hilighted with reverse text.

  # The middle column!
  Josh | Jore | jjore@cpan.org
  Josh | JORE | jjore@cpan.org

=head2 SCROLLING OUTPUT - hilite_diff

=over

=item $obj-E<gt>hilite_diff( ARRAY )

=item $obj-E<gt>hilite_diff( TAB DELIMITED STRING )

=item $obj-E<gt>hilite_diff( PIPE DELIMITED STRING )

=item $obj-E<gt>hilite_diff( MULTI-LINE STRING )

=item $obj-E<gt>hilite_diff( ANY 'OLE WORDS )

For output that scrolls past and merely annotated, use
C<hilite_diff>. Your input is left pretty much unchanged.

=back

=head2 REDRAWING OUTPUT

=over

=item $obj-E<gt>hilite_diff( ARRAY )

=item $obj-E<gt>hilite_diff( TAB DELIMITED STRING )

=item $obj-E<gt>hilite_diff( PIPE DELIMITED STRING )

=item $obj-E<gt>hilite_diff( MULTI-LINE STRING )

=item $obj-E<gt>hilite_diff( ANY 'OLE WORDS )

For output that updates in place, use C<watch>. The watch
method/function tags the first thing it sees with an ANSI code to save
the current cursor position and then tags all later output with
another ANSI escape code to jump back to the previous position.

I've used this when watching a stream of screen-sized chunks of data
go by that were largely identical so I just wanted the changes
annotated but I didn't really want the screen to scroll upwards.

C<watch> will also use a line-erasing escape code to ensure that
whenever newlines are printed that any printed clutter is being
cleaned up.

Consider:

    use Data::Dumper qw( Dumper );
    use Term::HiliteDiff qw( watch );
    $Data::Dumper::Sortkeys = 1;

    @thingies = (
        { a => 1, b => 2, c => 3 },
        { a => 1,       , c => 3 },
        { a => 1, b => 2, c => 3 },
        { a => 1, b => 2,        },
    );
    $obj = Term::HiliteDiff->new;

    for my $thingie ( @thingies ) {
        print $obj->watch( Data::Dumper::Dumper( $thingie ) );
    }

=back

=head1 METHODS

=over

=item Term::HiliteDiff-E<gt>new

=back

=head1 FUNCTIONS

=over

=item hilite_diff

=item watch

=back

=head1 AUTOMATIC EXPORTS

The C<watch> and C<hilite_diff> convenience functions are exported
when you've used this module from the command line. I think possibly
there ought to be an App::??? module to wrap these easy command-line
things up.

    perl -MTerm::HiliteDiff -pe '$_ = hilite_diff( $_ )'

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Term::HiliteDiff

You can also look for information at:

=over

=item RT, CPAN's request tracker L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-HiliteDiff>

=item AnnoCPAN, Annotated CPAN documentation L<http://annocpan.org/dist/Term-HiliteDiff>

=item CPAN Ratings L<http://cpanratings.perl.org/d/Term-HiliteDiff>

=item Search CPAN L<http://search.cpan.org/dist/Term-HiliteDiff>

=back

=for emacs ## Local Variables:
## mode: pod
## mode: auto-fill
## End:

=head1 AUTHOR

Josh Jore <jjore@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Josh Jore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

