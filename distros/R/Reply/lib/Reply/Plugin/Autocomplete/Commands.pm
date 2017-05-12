package Reply::Plugin::Autocomplete::Commands;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Autocomplete::Commands::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: tab completion for reply commands

use base 'Reply::Plugin';


sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    my ($prefix) = $line =~ /^#(.*)/;
    return unless defined $prefix;

    my @commands = $self->publish('commands');

    return map { "#$_" } sort grep { index($_, $prefix) == 0 } @commands;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Autocomplete::Commands - tab completion for reply commands

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ReadLine]
  [Autocomplete::Commands]

=head1 DESCRIPTION

This plugin registers a tab key handler to autocomplete Reply commands.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
