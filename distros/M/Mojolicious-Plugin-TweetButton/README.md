[![Build Status](https://travis-ci.org/vti/mojolicious-plugin-tweet_button.svg?branch=master)](https://travis-ci.org/vti/mojolicious-plugin-tweet_button)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-TweetButton.png)](http://cpants.charsbar.org/dist/overview/Mojolicious-Plugin-TweetButton)
[![GitHub issues](https://img.shields.io/github/issues/vti/mojolicious-plugin-tweet_button.svg)](https://github.com/vti/mojolicious-plugin-tweet_button/issues)

TweetButton which is described on twitter page http://twitter.com/goodies/tweetbutton
is now available for Mojolicious. After simply loading a plugin you get an html
helper that inserts TweetButton using various setup arguments.

    $self->plugin('tweet_button');
    $self->plugin('tweet_button' => {via => 'vtivti'});

    plugin 'tweet_button';
    plugin 'tweet_button' => {via => 'vtivti'};

Arguments
---------

All the arguments can be set globally (when loading a plugin) or locally (in the
template).

* count

    <%= tweet_button count => 'horizontal' %>

Location of the tweet count box (can be "vertical", "horizontal" or "none";
"vertical" by default).

* url

    <%= tweet_button url => 'http://example.com' %>

The URL you are sharing (HTTP Referrer by default).

* text

    <%= tweet_button url => 'Wow!' %>

The text that will appear in the tweet (Content of the <title> tag by default).

* via

    <%= tweet_button via => 'vtivti' %>

The author of the tweet (no default).

* related

    <%= tweet_button related => 'kraih:A robot' %>

Related twitter accounts (no default).

* lang

    <%= tweet_button lang => 'fr' %>

The language of the tweet (no default).

Installation
------------

    perl Makefile.PL
    make
    make test
    make install

Copyright And License
---------------------

Copyright (C) 2010, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
