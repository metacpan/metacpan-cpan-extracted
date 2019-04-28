#!/usr/bin/env perl 
use strict;
use warnings;

=pod

Generates RTM API files from the official documentation.

There are too many events for me to be bothered typing them all out,
and things are almost consistent enough for autogeneration to be useful.

=cut

use Path::Tiny;
use Mojo::UserAgent;
use Scalar::Util qw(blessed);
use Template;

use HTML::TreeBuilder;

my $ua = Mojo::UserAgent->new;
my $path = path('rtm.html');
$path->spew_utf8($ua->get('https://api.slack.com/rtm')->result->body) unless $path->exists;;

my $tt = Template->new;
my $tree = HTML::TreeBuilder->new->parse_file('rtm.html');
my ($hdr) = $tree->look_down(_tag => 'h2', sub { shift->as_text eq 'Events' });
my ($tbl) = grep blessed($_) && $_->tag eq 'table', $hdr->right;
ROW:
for my $row ($tbl->look_down(_tag => 'tr')) {
    my ($type, $description, $supported_by) = map s{\v+}{}gr, map $_->as_text, $row->look_down(_tag => 'td');
    next ROW unless $type;
    my $class = ucfirst($type =~ s/[_.](\w)/\U\1/gr);

    # `Url` just looks wrong...
    $class =~ s{Url}{URL}g;
    warn "$type is $class and works with $supported_by, description: $description\n";
    my $output_filename = 'lib/Net/Async/Slack/Event/' . $class . '.pm';
    warn "output file is [$output_filename]\n";

    # Normally we only want to import these once, but things do change over time
    # next ROW if path($output_filename)->exists;

    my $tree = do {
        my $content = $ua->get('https://api.slack.com/events/' . $type)->result->body or die "no doc page for $type";
        HTML::TreeBuilder->new->parse_content($content);
    };
    my ($example) = map $_->as_text, map $_->look_down(_tag => 'code'), $tree->look_down(_tag => 'div', class => 'card');
    my $data = {
        classname => $class,
        type => $type,
        description => $description,
        supported_by => $supported_by,
        example => $example,
    };
    $tt->process(\<<'EOF', $data, $output_filename) or die $tt->error;
package Net::Async::Slack::Event::[% classname %];

use strict;
use warnings;

# VERSION

use Net::Async::Slack::EventType;

=encoding UTF-8

=head1 NAME

Net::Async::Slack::Event::[% classname %] - [% description %]

=head1 DESCRIPTION

Example input data:

[% example | indent('    ') %]

=cut

sub type { '[% type %]' }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2019. Licensed under the same terms as Perl itself.
EOF
}
