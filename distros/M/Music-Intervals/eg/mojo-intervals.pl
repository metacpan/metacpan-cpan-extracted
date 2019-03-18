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
      notes    => $notes,
      size     => $size,
      chords   => $c->param('chords'),
      justin   => $c->param('justin'),
      equalt   => $c->param('equalt'),
      freqs    => $c->param('freqs'),
      interval => $c->param('interval'),
      cents    => $c->param('cents'),
      prime    => $c->param('prime'),
      integer  => $c->param('integer'),
    );
     
    $m->process;

    # Input form
    $c->stash( notes => join( ' ', @{ $m->notes } ) );
    for my $attr (qw/ size chords justin equalt freqs interval cents prime integer /) {
        $c->stash( $attr => $m->$attr() );
    }
    # Results
    for my $method (qw/
        chord_names
        natural_frequencies natural_intervals natural_cents natural_prime_factors
        eq_tempered_frequencies eq_tempered_intervals eq_tempered_cents
        integer_notation
    /) {
        $c->stash( $method => keys %{ $m->$method() } ? Dumper $m->$method() : '' );
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
    <label for="chords">Chord names:</label>
    <input type="checkbox" name="chords" id="chords" value="1" <% if ($chords) { %>checked<% } %>>
    <br>
    <label for="justin">Just intonation:</label>
    <input type="checkbox" name="justin" id="justin" value="1" <% if ($justin) { %>checked<% } %>>
    |
    <label for="equalt">Equal temperament:</label>
    <input type="checkbox" name="equalt" id="equalt" value="1" <% if ($equalt) { %>checked<% } %>>
    <br>
    <label for="freqs">Frequencies:</label>
    <input type="checkbox" name="freqs" id="freqs" value="1" <% if ($freqs) { %>checked<% } %>>
    |
    <label for="interval">Intervals:</label>
    <input type="checkbox" name="interval" id="interval" value="1" <% if ($interval) { %>checked<% } %>>
    |
    <label for="cents">Cents:</label>
    <input type="checkbox" name="cents" id="cents" value="1" <% if ($cents) { %>checked<% } %>>
    |
    <label for="prime">Prime:</label>
    <input type="checkbox" name="prime" id="prime" value="1" <% if ($prime) { %>checked<% } %>>
    <br>
    <label for="integer">Integer:</label>
    <input type="checkbox" name="integer" id="integer" value="1" <% if ($integer) { %>checked<% } %>>
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
