package Pod::Knit::PodParser;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: parse POD into an XML documen
$Pod::Knit::PodParser::VERSION = '0.0.1';

use strict;
use warnings;

use Pod::Simple::PullParser;
use XML::Writer::Simpler;
use List::AllUtils qw/ first_index /;

use Moose;

use experimental 'smartmatch', 'signatures', 'postderef';

extends 'Pod::Simple::PullParser';

has levels => (
    traits => [ 'Array' ],
    handles => { all_levels => 'elements' },
    is => 'ro',
    lazy => 1,
    default => sub { [
        [], 
        [ qw/ B L / ],
        [qw/ Para Verbatim /],
        [qw/ item-text /],
        [qw/ over-text /],
        ( map { ["head$_"] } reverse 1..4),
        [ 'Document' ],
    ]
    },
);

has commands => (
    is => 'ro',
    lazy => 1,
    default => sub {
        +{
            'Document' => { },
            'item-text' => { section => 1, },
            'verbatim' => { section => 0, },
            map {( "head$_" => { section => 1, } )} 1..4,
        }
    },
);

has xml => (
    is => 'ro',
    lazy => 1,
    default => sub {
        XML::Writer::Simpler->new( OUTPUT => 'self' );
    },
    clearer => 'clear_xml',
);

has to_xml => (
    is => 'ro',
    lazy => 1,
    default => sub($self) {
        $self->run;
    },
);

sub parse($self,$source) {
    $self->set_source( \$source );
    $self->strip_verbatim_indent(sub {
        my $lines = shift;
        (my $indent = $lines->[0]) =~ s/\S.*//;
        return $indent;
    });

    $self->parse_pod;
    my $xml = $self->xml->to_string;
    $self->clear_xml;
    return $xml;
}

sub podname ( $self, $token ) {
    $self->commands->{$token}{alias} || $token;
}

sub node_level($self,$token) {
    $token = $self->podname($token);
    first_index { $token ~~ @$_ } $self->all_levels;
}

sub parse_pod($self, $end_cond = undef ) {
    while( my $token = $self->get_token ) {
        if( $end_cond and $end_cond->($token) ) {
            $self->unget_token($token);
            return;
        }

       if( $token->is_text) {
           $self->xml->characters( $token->text );
           next;
       }

       my $tag = $token->tagname;
    
       next if $token->is_end;

       my $normalized = $tag;
       if( my $alias = $self->commands->{$tag}{alias} ) {
           $normalized = $alias;
           $token->attr( class => $tag );
       }

       $self->xml->tag( $self->commands->{$normalized}{section} ? 'section' : $normalized, [ 
               map { s/~//gr } $token->attr_hash->%* 
        ], sub {
            if( $self->commands->{$normalized}{section} ) {

                $self->xml->tag( $normalized, sub { 
                    $self->parse_pod( sub($tag) { 
                        $tag->is_end and $tag->is_tag( $token->tagname) 
                    });
                });

                my $level = $self->node_level($normalized);

                $self->parse_pod( sub($tag) { 
                    return $tag->is_start && $level <= $self->node_level( $tag->tagname )
                });
            }
            else {
                $self->parse_pod( sub($tag) { $tag->is_end and $tag->is_tag( 
                    $token->tagname
                ) } );
            }
        });
    }
}

1;

__END__

=pod

=encoding UTF-8

Uses L<Pod::Simple::PullParser> to convert a POD document into XML.

=head1 NAME

Pod::Knit::PodParser - parse POD into an XML documen

=head1 VERSION

version 0.0.1

=head1 POD ERRORS

Hey! B<The above document had some coding errors, which are explained
below:>

=over

=item Around line 5:

Unknown directive: =descriptio

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

