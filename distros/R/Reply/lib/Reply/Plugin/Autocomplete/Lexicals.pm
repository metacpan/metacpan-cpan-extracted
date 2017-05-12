package Reply::Plugin::Autocomplete::Lexicals;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Autocomplete::Lexicals::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: tab completion for lexical variables

use base 'Reply::Plugin';

use Reply::Util qw($varname_rx);


sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    my ($var) = $line =~ /($varname_rx)$/;
    return unless $var;

    my ($sigil, $name_prefix) = $var =~ /(.)(.*)/;

    # these can't be lexicals
    return if $sigil eq '&' || $sigil eq '*';

    my $env = { map { %$_ } $self->publish('lexical_environment') };
    my @env = keys %$env;

    my @results;
    for my $env_var (@env) {
        my ($env_sigil, $env_name) = $env_var =~ /(.)(.*)/;

        next unless index($env_name, $name_prefix) == 0;

        # this is weird, not sure why % gets stripped but not $ or @
        if ($sigil eq $env_sigil) {
            push @results, $sigil eq '%' ? $env_var : $env_name;
        }
        elsif ($env_sigil eq '@' && $sigil eq '$') {
            push @results, "$env_name\[";
        }
        elsif ($env_sigil eq '%') {
            push @results, "$env_name\{";
        }
    }

    return @results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Autocomplete::Lexicals - tab completion for lexical variables

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ReadLine]
  [Autocomplete::Lexicals]

=head1 DESCRIPTION

This plugin registers a tab key handler to autocomplete lexical variables in
Perl code.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
