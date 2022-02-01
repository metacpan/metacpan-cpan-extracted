#!/usr/bin/env perl

use Mojolicious::Lite;
use Music::Intervals;
use Data::Dumper::Concise;

any '/' => sub {
    my $c = shift;

    my $notes = $c->param('notes') || 'C E G';
    $notes = [ split /[\s,]+/, $notes ];

    my $size = $c->param('size') || 3;

    my $m = Music::Intervals->new(
      notes => $notes,
      size  => $size,
    );

    # Input form
    $c->stash( notes => join( ' ', @{ $m->notes } ) );
    $c->stash( size => $m->size() );

    # Results
    for my $method (qw/
        chord_names
        natural_frequencies natural_intervals natural_cents natural_prime_factors
        eq_tempered_frequencies eq_tempered_intervals eq_tempered_cents
        integer_notation
    /) {
        $c->stash( $method => Dumper $m->$method() );
    }

    $c->render('index');
};

app->start;
__DATA__

@@ index.html.ep
<form action="/" method="post">
    <label for="notes">Notes:</label>
    <input type="text" name="notes" id="notes" value="<%= $notes %>">
    <label for="size">Size:</label>
    <input type="text" name="size" id="size" value="<%= $size %>" size="3">
    <br>
    <input type="submit" name="submit" id="submit" value="Submit">
</form>

% if ($chord_names) {
<pre><%= $chord_names %></pre>
% }

% if ($natural_frequencies) {
<pre><%= $natural_frequencies %></pre>
% }

% if ($natural_intervals) {
<pre><%= $natural_intervals %></pre>
% }

% if ($natural_cents) {
<pre><%= $natural_cents %></pre>
% }

% if ($natural_prime_factors) {
<pre><%= $natural_prime_factors %></pre>
% }

% if ($eq_tempered_frequencies) {
<pre><%= $eq_tempered_frequencies %></pre>
% }

% if ($eq_tempered_intervals) {
<pre><%= $eq_tempered_intervals %></pre>
% }

% if ($eq_tempered_cents) {
<pre><%= $eq_tempered_cents %></pre>
% }

% if ($integer_notation) {
<pre><%= $integer_notation %></pre>
% }
