package Pod::Knit::Plugin::HeadsToSections;
our $AUTHORITY = 'cpan:YANICK';
$Pod::Knit::Plugin::HeadsToSections::VERSION = '0.0.1';
use strict;
use warnings;

use Web::Query;
use List::AllUtils qw/ part /;

use Moose;

extends 'Pod::Knit::Plugin';
with 'Pod::Knit::DOM::WebQuery';

sub preprocess {
    my( $self, $doc ) = @_;

    for my $level ( reverse 1..4 ) {
        my( $in_section, $index ) = (0,0);
        my @sections;

        $doc->find( \'./*' )->each(sub{
            if( $_->tagname =~ /^head(\d+)/ ) {
                if( $1 == $level ) {
                    $index++;
                    $in_section = 1;
                }
                elsif( $1 < $level ) {
                    $in_section = 0;
                }
            }
            push @{$sections[ $in_section && $index]}, $_;
        });

        for my $i ( 1..$#sections ) {
            my $s = shift @{ $sections[$i] };
            $s->html(
                '<title>'. $s->html . '</title>'
            );
            while( my $e = shift @{ $sections[$i] } ) {
                $e->detach;
                $s->append($e);
            }
        }
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::HeadsToSections

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

