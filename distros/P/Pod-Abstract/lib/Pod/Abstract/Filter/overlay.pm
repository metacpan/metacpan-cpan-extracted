package Pod::Abstract::Filter::overlay;
use strict;
use warnings;

use base qw(Pod::Abstract::Filter);
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node);

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Filter::overlay - paf command to perform a method
documentation overlay on a Pod document.

=begin :overlay

=overlay METHODS Pod::Abstract::Filter

=end :overlay

=head1 METHODS

=head2 filter

Inspects the source document for a begin/end block named
":overlay". The overlay block will be inspected for "=overlay"
commands, which should be structured like:

 =begin :overlay
 
 =overlay METHODS Some::Class::Or::File
 
 =end :overlay

Each overlay is processed in order. It will add any headings for the
matched sections in the current document from the named source, for
any heading that is not already present in the given section.

If that doesn't make sense just try it and it will!

The main utility of this is to specify a superclass, so that all the
methods that are not documented in your subclass become documented by
the overlay. The C<sort> filter makes a good follow up.

The start of overlaid sections will include:

 =for overlay from <class-or-file>

You can use these markers to set sections to be replaced by some other
document, or to repeat an overlay on an already processed Pod
file. Changes to existing marked sections are made in-place without
changing document order.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    my ($overlay_list) = $pa->select("//begin[. =~ {^:overlay}](0)");
    unless($overlay_list) {
        die "No overlay defined in document\n";
    }
    my @overlays = $overlay_list->select("/overlay");
    foreach my $overlay (@overlays) {
        my $o_def = $overlay->body;
        my ($section, $module) = split " ", $o_def;

        # This should be factored into a method.
        my $ovr_module = $module; # Keep original value
        unless(-r $module) {
            # Maybe a module name?
            $module =~ s/::/\//g;
            $module .= '.pm' unless $module =~ m/.pm$/;
            foreach my $path (@INC) {
                if(-r "$path/$module") {
                    $module = "$path/$module";
                    last;
                }
            }
        }
        my $ovr_doc = Pod::Abstract->load_file($module);
        
        my ($t) = $pa->select("//[\@heading =~ {$section}](0)");
        my ($o) = $ovr_doc->select("//[\@heading =~ {$section}](0)");

        my @t_headings = $t->select("/[\@heading]");
        my @o_headings = $o->select("/[\@heading]");
        
        my %t_heading = map { 
            $_->param('heading')->pod => $_ 
        } @t_headings;
        
        foreach my $hdg (@o_headings) {
            my $hdg_text = $hdg->param('heading')->pod;
            if($t_heading{$hdg_text}) {
                my @overlay_from = 
                    $t_heading{$hdg_text}->select(
                        "/for[. =~ {^overlay from }]");
                my @from_current = grep {
                    substr($_->body, -(length $ovr_module)) eq $ovr_module
                } @overlay_from;
                
                if(@from_current) {
                    my $dup = $hdg->duplicate;
                    my @overlay_from = 
                        $hdg->select("/for[. =~ {^overlay from }]");
                    $_->detach foreach @overlay_from;
                    
                    $dup->unshift(node->for("overlay from $ovr_module"));
                    
                    $dup->insert_after($t_heading{$hdg_text});
                    $t_heading{$hdg_text}->detach;
                    $t_heading{$hdg_text} = $dup;
                }
            } else {
                my $dup = $hdg->duplicate;
                
                # Remove existing overlay markers;
                my @overlay_from = 
                    $hdg->select("/for[. =~ {^overlay from }]");
                $_->detach foreach @overlay_from;

                $dup->unshift(node->for("overlay from $ovr_module"));

                $t->push($dup);
                $t_heading{$hdg_text} = $dup;
            }
        }
    }
    return $pa;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
