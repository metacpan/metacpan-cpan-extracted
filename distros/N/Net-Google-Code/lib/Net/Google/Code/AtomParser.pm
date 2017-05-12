package Net::Google::Code::AtomParser;
use strict;
use warnings;

use Params::Validate ':all';
use HTML::Entities;

sub new {
    my $class = shift;
    bless \(my $a), $class;
}

sub parse {
    my $self = shift;
    my ($content) = validate_pos( @_, 1 );

    my $feed    = {};
    my $entries = [];

    if ( $content =~ /<feed .*?>(.*?)<entry>/s ) {
        my $feed_info = $1;
        while ( $feed_info =~ m{<(?!link)(\w+).*?>(.*)</\1>}sg ) {
            $feed->{$1} = decode_entities($2);
        }
    }

    while ( $content =~ m{<entry>(.*?)</entry>}sg ) {
        my $entry_info = $1;
        my $entry      = {};
        while ( $entry_info =~ m{<(?!link)(\w+).*?>(.*)</\1>}sg ) {
            my $value = $2;
            $value =~ s!\s*<(\w+)>(.*?)</\1>\s*!$2!g;
            $entry->{$1} = decode_entities($value);
        }
        push @$entries, $entry;
    }
    return ( $feed, $entries );
}

1;

__END__

=head1 NAME

Net::Google::Code::AtomParser - AtomParser with a parsing method for gcode

=head1 DESCRIPTION

=head1 INTERFACE

=head2 new

=head2 parse( $xml_content )

return( $feed, $entries ),
$feed is a hashref like
{
    'title' => 'Issue updates for project net-google-code on Google Code',
    'id' => 'http://code.google.com/feeds/p/net-google-code/issueupdates/basic',
    'updated' => '2009-06-12T05:55:48Z'
}

$entries is an arrayref like
[
    {
        'content' => '<pre>second comment
 </pre>
 ',
        'name'  => 'sunnavy',
        'title' => 'Update 2 to issue 22 ("for sd test")',
        'id' =>
'http://code.google.com/feeds/p/net-google-code/issueupdates/basic/22/2',
        'updated' => '2009-06-12T05:55:48Z'
    },
    {
        'content' => '<pre>first comment
 </pre>
 ',
        'name'  => 'sunnavy',
        'title' => 'Update 1 to issue 22 ("for sd test")',
        'id' =>
'http://code.google.com/feeds/p/net-google-code/issueupdates/basic/22/1',
        'updated' => '2009-06-12T05:55:22Z'
    },
]

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



