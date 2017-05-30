package Reply::Plugin::Autocomplete::ExportedSymbols;
use strict;
use warnings;
use parent qw/Reply::Plugin/;
use List::MoreUtils;
use Module::Runtime qw/$module_name_rx/;
use Package::Stash;

use Reply::Util qw/$ident_rx/;

my $sigil_rx = $Reply::Util::sigil_rx;

our $VERSION = "0.01";

sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    my ($before, $module_name, $fragment) = $line =~ /(.*?)use\s+(${module_name_rx})(.*)$/ or return;
    return if $before =~ /^#/; # commands

    my @symbols = _export_symbols($module_name);
    if (my ($ident) = $fragment =~ /(:$ident_rx?|$ident_rx)$/) {
        return grep { /^\Q$ident\E/ } @symbols;
    }
    return @symbols;
}

sub _export_symbols {
    my $module_name = shift;

    eval { Module::Runtime::require_module($module_name) } or return;

    my $stash      = Package::Stash->new($module_name);
    my $stash_name = $stash->name;
    my $namespace  = $stash->namespace;

    my @symbols;
    push @symbols, @{$namespace->{EXPORT}}    if $stash->has_symbol('@EXPORT');
    push @symbols, @{$namespace->{EXPORT_OK}} if $stash->has_symbol('@EXPORT_OK');
    push @symbols, map { ":$_" } keys %{$namespace->{EXPORT_TAGS}} if $stash->has_symbol('%EXPORT_TAGS');

    # Exclude variables. Function names and variable names starting with sigil can not be mixed in completion
    @symbols = grep { !/^$sigil_rx/ } @symbols;

    return sort +List::MoreUtils::uniq(@symbols);
}

1;
__END__

=encoding utf-8

=head1 NAME

Reply::Plugin::Autocomplete::ExportedSymbols - Tab completion for exported symbol names

=head1 SYNOPSIS

In your .replyrc

  [Autocomplete::ExportedSymbols]

And use reply!

  % reply
  0> use List::Util qw/ <TAB>
  all         max         minstr      pairfirst   pairmap     product     sum         uniqnum
  any         maxstr      none        pairgrep    pairs       reduce      sum0        uniqstr
  first       min         notall      pairkeys    pairvalues  shuffle     uniq        unpairs
  0> use List::Util qw/ pair<TAB>
  pairfirst   pairgrep    pairkeys    pairmap     pairs       pairvalues

=head1 DESCRIPTION

Reply::Plugin::Autocomplete::ExportedSymbols is a plugin for L<Reply>.
It provides a tab completion for exported symbols names from L<Exporter>'s C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS>.

Note that exported variables are not included in completion.

=head1 SEE ALSO

L<Reply>

L<Exporter>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
