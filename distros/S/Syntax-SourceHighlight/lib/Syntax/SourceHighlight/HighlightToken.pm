package Syntax::SourceHighlight::HighlightToken;

use 5.010;
use strict;
use warnings;
use parent 'Syntax::SourceHighlight';

our $VERSION = '2.1.3';

sub new {
    die "Invalid call to "
      . __PACKAGE__
      . "->new(): "
      . "this object is created internally by Syntax::SourceHighlight.\n";
}

sub DESTROY {
}

eval "
    sub $_ {
        my \$self = shift;
        return \$self->{$_};
    }
"
  foreach ( 'prefix', 'suffix', 'isPrefixOnlySpaces', 'matched',
    'matchedSize' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::SourceHighlight::HighlightToken - Perl class for libsource-highlight's
C<srchilite::HighlightToken>

=head1 SYNOPSIS

    use Syntax::SourceHighlight;
    my $hl = Syntax::SourceHighlight->new();
    $hl->setHighlightEventListener(
        sub {
            my $highlight_event = shift;
            my $highlight_token = $highlight_event->{token};
            print( "Prefix: '$highlight_token->{prefix}'; tokens" );
            foreach ( @{ $highlight_token->{matched} } ) {
                m/^(.*?):(.*)$/s;
                print(" '$2' ($1)");
            }
            print("\n");
        }
    );
    $hl->highlightString( 'my $test = 42;', 'perl.lang' );

=head1 DESCRIPTION

This is the counterpart to the libsource-highlight's
C<< L<srchilite::HighlightEvent|https://www.gnu.org/software/src-highlite/api/structsrchilite_1_1HighlightToken.html> >> class.

The following public attributes are exported:

=over

=item

I<< L<prefix|Syntax::SourceHighlight/prefix> >>

=item

I<< L<prefixOnlySpaces|Syntax::SourceHighlight/prefixOnlySpaces> >>

=item

I<< L<suffix|Syntax::SourceHighlight/suffix> >>

=item

I<< L<matched|Syntax::SourceHighlight/matched> >> (exported as an array of
strings where the pair is concatenated and separated with colon)

=item

I<< L<matchedSize|Syntax::SourceHighlight/matchedSize> >>

=back

These are not implemented:

=over

=item

I<matchedSubExps>

=item
 
I<rule>

=back

There is no Perl constructor for this package. None of its public methods are
implemented:

=over

=item

C<copyFrom()>

=item

C<clearMatched()>

=item

C<addMatched()>

=back

=head1 SEE ALSO

The main documentation with examples is in the L<Syntax::SourceHighlight> POD.

=cut
