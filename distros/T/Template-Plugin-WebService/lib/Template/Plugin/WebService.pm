package Template::Plugin::WebService;

use strict;

use base qw(Template::Plugin);

use vars qw($VERSION);

$VERSION = '0.16';

use CGI::Ex;

use Carp qw(confess);
use CGI::Cookie;
use Storable qw(thaw);
use WWW::Mechanize;

sub new {
    my $class   = shift;
    my $context = shift;
    bless { _CONTEXT => $context, }, $class;
}

sub load {
    my ($class, $context) = @_;
    return $class;
}

sub URLEncode {
    my $arg = shift;
    my ($ref, $return) = ref($arg) ? ($arg, 0) : (\$arg, 1);

    $$ref =~ s/([^\w\.\ -])/sprintf("%%%02X",ord($1))/eg;
    $$ref =~ tr/\ /+/;

    return $return ? $$ref : '';
}

sub get_outserial {
    my $self = shift;
    my $url = shift;
    my $form = shift;

    my $outserial_key = $self->outserial_key;
    
    my $outserial = 'json';

    if($form->{$outserial_key}) {
        $outserial = $form->{$outserial_key};
    } elsif($url =~ /\b$outserial_key=(\w+)/) {
        $outserial = $1;
    }

    return $outserial;
}

sub make_form {
    return '' if !@_;
    my ($hash, $keys);
    if (ref $_[0]) {
        $hash = shift;
        $keys = shift() if @_ && ref $_[0];
    } else {
        $hash = {@_};
    }
    $keys ||= [ sort keys %$hash ];
    my $str = "";
    foreach my $key (@$keys) {
        $hash->{$key} = "" if !exists($hash->{$key});
        my $ref = ref($hash->{$key});
        next if $ref && $ref eq 'HASH';
        my $array = ($ref eq 'ARRAY') ? $hash->{$key} : [ $hash->{$key} ];
        foreach my $val (@$array) {
            my $ref2 = ref($val);
            next if $ref2 && $ref2 eq 'HASH';
            my $array2 = ($ref2 eq 'ARRAY') ? $val : [$val];
            foreach (@$array2) {
                $str .= URLEncode($key) . "=" . URLEncode($_ . '') . "&";
            }
        }
    }
    chop $str;
    return $str;
}

sub content_cleanup {
    my $self = shift;
    my $content_ref = shift;
}

sub default_host {
    return '127.0.0.1';
}

sub outserial_key {
    return 'outserial';
}

sub webservice_call {
    my $self = shift;
    my $url  = shift || confess 'need a url';
    my $form = shift || {};

    confess 'form needs to be a hash ref' unless(UNIVERSAL::isa($form, 'HASH'));

    my $host;

    if($url =~ m@^https?://([^/]+)@) {
        $host = $1;
    } else {
        $host = $self->default_host;
        $url = "http://$host$url";
    }

    if (scalar keys %$form) {
        $url .= ($url =~ /\?/) ? '&' : '?';
        $url .= make_form($form);
    }

    my $mech = WWW::Mechanize->new;

    my %cookies = fetch CGI::Cookie;

    my $content;

    if(%cookies && scalar keys %cookies) {
        require HTTP::Cookies;
        require WWW::Mechanize;

        my $cj = HTTP::Cookies->new();
        foreach my $cookie_key (keys %cookies) {
            $cj->set_cookie(0, $cookie_key, $cookies{$cookie_key}->value, '/', $host);
        }
        $mech = WWW::Mechanize->new(cookie_jar => $cj);
        $content = $mech->get($url)->content;
    } else {
        require LWP::Simple;
        $content = LWP::Simple::get($url);
    }

    $self->content_cleanup(\$content);

    my $obj;

    my $outserial = $self->get_outserial($url, $form);

    if($outserial eq 'storable') {
        require Storable;
        $obj = Storable::thaw($content);
    } elsif($outserial eq 'xml') {
        require XML::Simple;
        $obj = XML::Simple::XMLin($content);
    } elsif($outserial eq 'yaml') {
        require YAML;
        $obj = YAML::Load($content);
    } else {
        require JSON;
        $obj = JSON::from_json($content);
    }

    return $obj;
}

1;

__END__

=head1 NAME

Template::Plugin::WebService - plugin to allow webservice calls
from Template and Template::Alloy

=head1 SYNOPSIS

  [% USE web_service = WebService %]
  [% form = { 'outserial' => 'xml' } %]
  [% stuff = web_service.webservice_call(url, form) %]
  # url is the url to hit

  [% stuff = web_service.webservice_call('/path/to/api', form) %]
  # form is a hash ref that gets appended to the url
  # url can be relative, where the domain defaults to $self->default_host (127.0.0.1)

  [% stuff = web_service.webservice_call('http://domain.com/path/to/api', form) %]

=head1 DESCRIPTION

Template::Plugin::WebService helps handle HTTP from a template.

=head1 FEATURES

 - handles web requests from your template
 - passes along a passed in form
 - passes along any cookies
 - specify serialization via form or just in the url's query_string
 - handles many serializations (JSON, Storable, XML::Simple, YAML)
 - defaults to JSON

=head1 OVERRIDABLE METHODS

content_cleanup - gets sent a Template::Plugin::WebService object and a 
reference to the response content

default_host - gets prepended to your url if your url doesn't start with 
http://.  Defaults to 127.0.0.1

outserial_key - server sends out a key which defines serialization.  
Defaults to outserial.

=head1 AUTHOR

Copyright 2008, Earl J. Cahill. All rights reserved.

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

Address bug reports and comments to: cahille@yahoo.com

When sending bug reports, please provide the version of 
Template::Plugin::WebService, the version of Perl, and the name
and version of the operating system you are using.

Earl Cahill, cahille@yahoo.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Earl Cahill

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

