#!/usr/bin/perl

use Pod::ParseUtils;

while (my $link = <>) {
    chomp $link;

    my $link_parser = Pod::Hyperlink->new( $link );

    next if not $link_parser;

    about_link( $link, $link_parser );
}

sub about_link {
    my  $original       =   shift;
    my  $link_parser    =   shift;
    my  $type;

    printf "Link: %s\n", $original;

    printf "\tType: %s\n",  $type = $link_parser->type();
    printf "\tText: %s\n",  $link_parser->text();
    printf "\tAlt: %s\n",   $link_parser->alttext();

    my  $ikiwiki_link = undef;

    if ($type eq 'hyperlink') {
        $ikiwiki_link = sprintf '<%s>', $link_parser->node();
    }
    elsif ($type eq 'page') {
        if ($link_parser->alttext()) {
            $ikiwiki_link = sprintf '[[%s|%s]]', $link_parser->alttext(),
                                    $link_parser->page();
        }
        else {
            $ikiwiki_link = sprintf '[[%s]]', $link_parser->page();
        }
    }
    elsif ($type eq 'section') {
        $ikiwiki_link = sprintf "[[%s#%s]]", $link_parser->page(), 
                                    $link_parser->node();
        
    }
    elsif ($type eq 'item') {
        1;
    }


    printf "\tIn ikiwiki: %s\n", $ikiwiki_link;
    printf "\n";

    return;
}

