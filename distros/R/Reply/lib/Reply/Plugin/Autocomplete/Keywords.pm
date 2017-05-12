package Reply::Plugin::Autocomplete::Keywords;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Autocomplete::Keywords::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: tab completion for perl keywords

use base 'Reply::Plugin';

use B::Keywords qw/@Functions @Barewords/;


sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    my ($before, $last_word) = $line =~ /(.*?)(\w+)$/;
    return unless $last_word;
    return if $before =~ /^#/; # command
    return if $before =~ /::$/; # Package::function call
    return if $before =~ /->\s*$/; # method call
    return if $before =~ /[\$\@\%\&\*]\s*$/;

    my $re = qr/^\Q$last_word/;

    return grep { $_ =~ $re } @Functions, @Barewords;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Autocomplete::Keywords - tab completion for perl keywords

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ReadLine]
  [Autocomplete::Keywords]

=head1 DESCRIPTION

This plugin registers a tab key handler to autocomplete keywords in Perl code.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
