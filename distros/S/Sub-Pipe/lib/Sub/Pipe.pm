package Sub::Pipe;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;
use base 'Exporter';
our @EXPORT = qw/joint/;

use overload '|' => sub { $_[0]->( $_[1] ) };

sub joint(&) { bless $_[0], __PACKAGE__ };

if ( $0 eq __FILE__ ) {
    local $\ = "\n";
    my $uri = joint {
        require URI::Escape;
        URI::Escape::uri_escape_utf8(shift);
    };
    my $html = joint {
        my $str = shift;
        $str =~ s{([&<>"])}{
            '&' . { qw/& amp  < lt > gt " quot/ }->{$1} . ';' ;
        }msgex;
        $str;
    };
    my $html_line_break = joint {
        local $_ = $_[0];
        s{\r*\n}{<br/>}g;
        $_;
    };
    my $replace = sub {
        my ( $regexp, $replace ) = @_;
        joint {
            my $str = shift;
            $str =~ s{$regexp}{$replace}g;
            $str;
        }
    };
    print "dankogai" | joint { uc shift };
    print "<pre>" | $html;
    print "Perl & Me" | $uri;
    print "PHP" | $replace->( 'HP', 'erl' );
    print "Rock\nRoll" | $html_line_break | $uri;
}

1; # End of Sub::Pipe

=head1 NAME

Sub::Pipe - chain subs with | (pipe)

=head1 VERSION

$Id: Pipe.pm,v 0.1 2009/05/22 06:36:59 dankogai Exp dankogai $

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Sub::Pipe;
    print "dankogai" | joint { uc shift }; # DANKOGAI

=head1 EXPORT

C<joint>

=head1 FUNCTIONS

=head2 joint

  joint { ... }
  joint(\&sub)

Bless the subroutine to this package so that the overloaded C<|> works.

=head1 AUTHOR

FUJIWARA Shunichiro C<< <fujiwara at cpan.org> >>

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-pipe at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Pipe>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Pipe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Pipe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Pipe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-Pipe>

=item * Search CPAN

L<http://search.cpan.org/dist/Sub-Pipe/>

=back

=head1 ACKNOWLEDGEMENTS

L<http://d.hatena.ne.jp/sfujiwara/20090521/1242921474>

=head1 COPYRIGHT & LICENSE

Copyright 2009 FUJIWARA Shunichiro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
