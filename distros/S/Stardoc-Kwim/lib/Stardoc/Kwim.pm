##
# name:      Stardoc::Kwim
# abstract:  Stardoc Kwim Module
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

# XXX Remove this early dep on WikiText.

use 5.008003;
package Stardoc::Kwim;
use WikiText 0.15 ();
use base 'WikiText';

our $VERSION = '0.01';

sub to_html {
    my $self = shift;
    my $parser_class = ref($self) . '::Parser';
    eval "require $parser_class; 1"
      or die "Can't load $parser_class:\n$@";
    require WikiText::HTML::Emitter;
    my $parser = $parser_class->new(
        receiver => WikiText::HTML::Emitter->new(break_lines => 1),
    );

    return $parser->parse($self->{wikitext});
}

1;

=head1 SYNOPSIS

    use Stardoc::Kwim;

    my $html = Stardoc::Kwim->new($kwim)->to_html;
    
=head1 DESCRIPTION

This module can convert Kwim markup to HTML.
