package Template::Plugin::XML::Unescape;
BEGIN {
  $Template::Plugin::XML::Unescape::VERSION = '0.02';
}

# ABSTRACT: unescape XML entities in Template Toolkit

use warnings;
use strict;

use base qw(Template::Plugin::Filter);
use HTML::Entities;

sub init {
    my $self = shift;
    my $name = $self->{_ARGS}->[0] || 'xml_unescape';
    $self->install_filter($name);
    return $self;
}

sub filter { decode_entities($_[1]) }

1;

__END__

=head1 NAME

Template::Plugin::XML::Unescape

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    [% USE XML::Unescape %]
    [% 'Frank amp; Beans' | xml_unescape %]

=head1 DESCRIPTION

Template Toolkit has support for doing entity escaping, but not the other way
around -- because why would you ever need to do that? HA. HA.

=begin Pod::Coverage

init
filter

=end Pod::Coverage