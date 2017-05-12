package Template::Plugin::Emoticon;

use 5.006;
use strict;
use warnings;
use parent qw( Template::Plugin::Filter );
use Text::Emoticon;

our $VERSION = '0.01';

use constant FILTER_NAME => 'emoticon';

sub init {
    my ($self) = @_;
    my $driver = $self->{_ARGS}[0];
    my $args   = $self->{_CONFIG};

    $self->{_emoticon} = Text::Emoticon->new($driver, $args);
    $self->install_filter(FILTER_NAME);

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    return $self->{_emoticon}->filter($text);
}

1;

__END__

=head1 NAME

Template::Plugin::Emoticon - Emoticon filter for TT

=head1 VERSION

This document describes Template::Plugin::Emoticon version 0.01.

=head1 SYNOPSIS

    [% USE Emoticon('MSN', strict = 1, xhtml = 0) %]

    [% 'Hello ;)' | emoticon %]

=head1 DESCRIPTION

This is a L<Template::Toolkit> plug-in to filter text-based emoticons and
replace them with corresponding icons using L<Text::Emoticon> and supported
emoticon drivers.

=head1 SEE ALSO

Currently available emoticon drivers:
L<Text::Emoticon::GoogleTalk>,
L<Text::Emoticon::MSN>,
L<Text::Emoticon::Plurk>,
L<Text::Emoticon::Yahoo>

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
