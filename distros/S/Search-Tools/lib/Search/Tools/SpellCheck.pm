package Search::Tools::SpellCheck;
use Moo;
use Carp;
extends 'Search::Tools::Object';
use Text::Aspell;
use Search::Tools::QueryParser;

our $VERSION = '1.007';

has 'query_parser' =>
    ( is => 'rw', default => sub { Search::Tools::QueryParser->new() } );
has 'max_suggest' => ( is => 'rw', default => sub {4} );
has 'dict'        => ( is => 'rw' );
has 'lang'        => ( is => 'rw' );
has 'aspell'      => ( is => 'rw' );

sub BUILD {
    my $self = shift;
    $self->aspell(
               Text::Aspell->new
            or croak "can't get new() Text::Aspell"
    );

    $self->aspell->set_option( 'lang',
        ( $self->{lang} || $self->{query_parser}->lang ) );
    $self->_check_err;
    $self->aspell->set_option( 'sug-mode', 'fast' );
    $self->_check_err;
    $self->aspell->set_option( 'master', $self->dict ) if $self->dict;
    $self->_check_err;

}

sub _check_err {
    my $self = shift;
    carp $self->aspell->errstr if $self->aspell->errstr;
}

sub suggest {
    my $self      = shift;
    my $query_str = shift;
    confess "query required" unless defined $query_str;
    my $suggest     = [];
    my $phr_del     = $self->query_parser->phrase_delim;
    my $ignore_case = $self->query_parser->ignore_case;
    my $query       = $self->query_parser->parse($query_str);

    for my $term ( @{ $query->terms } ) {

        $term =~ s/$phr_del//g;
        my @w = split( m/\ +/, $term );

    WORD: for my $word (@w) {

            my $s = { word => $word };
            if ( $self->aspell->check($word) ) {
                $self->_check_err;
                $s->{suggestions} = 0;
            }
            else {
                my @sg = $self->aspell->suggest($word);
                $self->_check_err;
                if ( !@sg or !defined $sg[0] ) {
                    $s->{suggestions} = [];
                }
                else {

                    if ($ignore_case) {

                        # make them unique but preserve order
                        my $c = 0;
                        my %u = map { lc($_) => $c++ } @sg;
                        @sg = sort { $u{$a} <=> $u{$b} } keys %u;
                    }

                    $s->{suggestions}
                        = [ splice( @sg, 0, $self->max_suggest ) ];
                }
            }
            push( @$suggest, $s );

        }
    }

    return $suggest;
}

1;

__END__


=head1 NAME

Search::Tools::SpellCheck - offer spelling suggestions

=head1 SYNOPSIS

 use Search::Tools::SpellCheck;
 
 my $query = 'the quick fox color:brown and "lazy dog" not jumped';
  
 my $spellcheck = 
    Search::Tools::SpellCheck->new(
                        dict        => 'path/to/my/dictionary',
                        max_suggest => 4,
                        );
                        
 my $suggestions = $spellcheck->suggest($query);
 
 
=head1 DESCRIPTION

This module offers suggestions for alternate spellings using Text::Aspell.

=head1 METHODS

=head2 new( %I<opts> )

Create a new SpellCheck object.
%I<opts> should include:

=over

=item dict

Path(s) to your dictionary.

=item lang

Language to use. Default is C<en_US>.

=item max_suggest

Maximum number of suggested spellings to return. Default is C<4>.

=item query_parser

A Search::Tools::QueryParser object.

=back

=head2 BUILD

Called internally by new().

=head2 suggest( @I<terms> )

Returns an arrayref of hashrefs. Each hashref is composed of the following
key/value pairs:

=over

=item word

The keyword used.

=item suggestions

If value is C<0> (zero) then the word was found in the dictionary
and is spelled correctly.

If value is an arrayref, the array contains a list of suggested spellings.

=back

=head2 aspell

If you need access to the Text::Aspell object used internally,
this accessor will get/set it.

__END__

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of this module.

Thanks to Bill Moseley, Text::Aspell maintainer, for the API
suggestions for this module.

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools::QueryParser, Text::Aspell
