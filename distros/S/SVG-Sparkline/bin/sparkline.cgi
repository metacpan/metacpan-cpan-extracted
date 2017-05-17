#!/usr/bin/env perl

use strict;
# Reduce load time of the script.
## no critic(RequireUseWarnings)
#use warnings;

use SVG::Sparkline;
use CGI;

my $q = CGI->new;
my $type = $q->param('type');
if( !length $type )
{
    print $q->header(-status => 400 ),
          $q->start_html( 'Input error' ),
          $q->h2( 'No sparkline type supplied' ),
          $q->end_html;
    exit 0;
}
if( $type !~ m/\A[A-Z]\w+\z/ )
{
    print $q->header(-status => 400 ),
          $q->start_html( 'Input error' ),
          $q->h2( 'Not a valid sparkline type' ),
          $q->end_html;
    exit 0;
}
if( !$q->param('values') )
{
    print $q->header(-status => 400 ),
          $q->start_html( 'Input error' ),
          $q->h2( 'No sparkline values supplied' ),
          $q->end_html;
    exit 0;
}

my $svg = eval { SVG::Sparkline->new( $type => parameters_from_query( $q ) ); };
if( defined $svg )
{
    print $q->header('image/svg+xml'), $svg->to_string();
}
else
{
    print $q->header(-status => 400 ),
          $q->start_html( 'Input error' ),
          $q->h2( 'Error creating sparkline' ),
          $q->p( $q->strong( $@ || 'Invalid input parameters' ) ),
          $q->end_html;
}

exit 0;

#
# Convert query parameters into apropriate parameters for the
# SVG::Sparkline constructor.
sub parameters_from_query
{
    my ($q) = @_;
    my %params;
    foreach my $key ( $q->param )
    {
        my @value = $q->param( $key );
        if( $key eq 'sized' )
        {
            $params{'-sized'} = $value[0] || 0;
        }
        elsif( $key eq 'allns' ) {
            $params{"-$key"} = $value[0];
        }
        elsif( $key eq 'mark' )
        {
            $params{$key} = [ @value ];
        }
        elsif( $key eq 'type' )
        {
            # Already dealt with.
            next;
        }
        elsif( length $value[0] )
        {
            $params{$key} = $value[0];
        }
    }
    # Clean up values parameter

    $params{'values'} =~ tr/ /+/ if $params{'values'} =~ /^[- 0]+$/;
    $params{'values'} = [ split ',', $params{'values'} ]
        unless 'Whisker' eq $type && $params{'values'} =~ /^[-+0]+$/;
    $params{'values'} = [ map { [ split ':', $_ ] } @{$params{'values'}} ]
        if $type eq 'RangeArea' or $type eq 'RangeBar';

    # Clean up mark parameter
    $params{'mark'} = [ map { split /[=:]/, $_ } @{$params{'mark'}} ];

    return \%params;
}

