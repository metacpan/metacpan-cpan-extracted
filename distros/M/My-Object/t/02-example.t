use strict;
use warnings;

use Test::More tests => 1;

package Local::Stuff;
use My::Object;

sub entitify {
    my ($text) = @_;
    $text =~ s/\&/&amp;/g;
    $text =~ s/\</&lt;/g;
    $text =~ s/\>/&gt;/g;
    $text =~ s/"/&quot;/g;
    return $text;
}

package Local::TextNode;
use Local::Stuff;
use My::Object { content => '' };

sub BUILD_TextNode {
    my ($this, $content) = @_;
    $this->content = "$content"
        if defined $content;
}

sub toHTML { entitify shift->content }

package Local::Element;
use Local::Stuff;
use My::Object {
    name => undef,
    -attributes => sub { {} },
    -children => sub { [] },
};

sub BUILD_Element {
    my $this = shift;
    ($this->name, %{$this->attributes}) = @_;
}

sub push {
    my $this = shift;
    push @{$this->children}, @_;
    return $this;
}

sub toHTML {
    my ($this) = @_;
    my @children = @{$this->children};
    my $attributes = join ' ', map {
        sprintf '%s="%s"', $_, entitify($this->attributes->{$_});
    } keys %{$this->attributes};

    my $stag = sprintf('<%s%s%s%s>',
        $this->name,
        $attributes ? ' ' : '',
        $attributes,
        @children ? '' : '/');
    my $etag = @children ? '</'.$this->name.'>' : '';

    return $stag.join('', map { $_->toHTML } @children).$etag;
}

package main;
BEGIN {
    *element = Local::Element->NEW;
    *textNode = Local::TextNode->NEW;
}

my $html = element('a', href => 'http://google.kz')
    ->push(textNode('Google Kazakhstan'))
    ->toHTML;

is $html, '<a href="http://google.kz">Google Kazakhstan</a>';
