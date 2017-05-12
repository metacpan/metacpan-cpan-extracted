#!/usr/bin/env perl
use strict;

=head1 NAME

metavars - interpolate metadata C<{{field}} references

=head1 DESCRIPTION

Pandoc filter to allow interpolation of metadata fields into a document.  Field
references such as C<{{field}}> will be replaced by the field's value or by an
empty string. Spaces in, before, and after field names are not allowed.

Metadata fields of type L<MetaString|Pandoc::Elements/MetaString> and
L<MetaInlines|Pandoc::Elements/MetaInlines> are always replaced in inline
elements (L<string elements|Pandoc::Elements/Str>). Metadata fields of type
L<MetaBlocks|Pandoc::Elements/MetaBlocks> are also replaced in block elements
if the reference is the only content of the block.

To literally include a field reference, define and include another field with
content C<'{{field}}'>.

=cut

use Pandoc::Filter;
use Pandoc::Elements qw(element Str);

pandoc_filter 
    'Plain|Para' => sub {
        my ($e, $f, $m) = @_;
        return if @{$e->content} != 1 or $e->content->[0]->name ne 'Str';
        return if $e->content->[0]->content !~ /^{{(.+?)}}$/;

        my $var = $m->{$1};
        if ($var) {
            if ($var->name eq 'MetaInlines') {
                return element($e->name, $var->content);
            } elsif ($var->name eq 'MetaString') {
                return element($e->name, [ Str $var->content ]);
            } elsif ($var->name eq 'MetaBlocks') {
                return $var->content;
            }
        }

        return element($e->name, []); # keep element but empty
    },
    Str => sub {
        my ($e, $f, $m) = @_;

        return unless $e->content =~ /{{(.+?)}}/;

        my @parts = split /{{(.+?)}}/, $e->content;
        return if @parts < 2; 

        my @inlines;

        while (@parts) {
            my $str   = shift @parts;
            my $field = shift @parts;

            push @inlines, Str($str) if $str ne '';
            
            next unless defined $field and $field ne '';

            my $var = $m->{$field} or next;

            if ($var->name eq 'MetaInlines') {
                push @inlines, @{$var->content};
            } elsif ($var->name eq 'MetaString') {
                push @inlines, Str $var->content;
            }
        }

        return \@inlines;
    },
;

=head1 SYNOPSIS

  pandoc --filter metavars.pl -o output.html < input.md

=head1 SEE ALSO

This is an improved port of
L<metavars.py|https://github.com/jgm/pandocfilters/blob/master/examples/metavars.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
