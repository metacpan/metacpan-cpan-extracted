package Syntax::SourceHighlight::HighlightEvent;

use 5.010;
use strict;
use warnings;
use parent 'Syntax::SourceHighlight';

our $VERSION = '2.1.2';

use Syntax::SourceHighlight::HighlightToken;

our $FORMAT        = 0;
our $FORMATDEFAULT = 1;
our $ENTERSTATE    = 2;
our $EXITSTATE     = 3;

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
  foreach ( 'type', 'token' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::SourceHighlight::HighlightEvent - Perl class for libsource-highlight's
C<srchilite::HighlightEvent>

=head1 SYNOPSIS

    use Syntax::SourceHighlight;
    my $hl = Syntax::SourceHighlight->new();
    $hl->setHighlightEventListener(
        sub {
            my $highlight_event = shift;
            print( "Event: ", $highlight_event->{type}, "\n" );
        }
    );
    $hl->highlightString( 'my $test = 42;', 'perl.lang' );

=head1 DESCRIPTION

This is the counterpart to the libsource-highlight's
C<< L<srchilite::HighlightEvent|https://www.gnu.org/software/src-highlite/api/structsrchilite_1_1HighlightEvent.html> >> class.

All of its public attributes are exported:

=over

=item

I<< L<token|Syntax::SourceHighlight/token> >>

=item

I<< L<type|Syntax::SourceHighlight/type> >>

=back

There is no Perl constructor for this package. This class does not export any
other methods.

=head1 SEE ALSO

The main documentation with examples is in the L<Syntax::SourceHighlight> POD.

=cut
