package Reply::Plugin::Autocomplete::Functions;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Autocomplete::Functions::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: tab completion for function names

use base 'Reply::Plugin';

use Module::Runtime '$module_name_rx';
use Package::Stash;


sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    my ($before, $fragment) = $line =~ /(.*?)(${module_name_rx}(::)?)$/;
    return unless $fragment;
    return if $before =~ /^#/; # commands

    my $current_package = ($self->publish('package'))[-1];

    my ($package, $func);
    if ($fragment =~ /:/) {
        ($package, $func) = ($fragment =~ /^(.+:)(\w*)$/);
        $func = '' unless defined $func;
        $package =~ s/:{1,2}$//;
    }
    else {
        $package = $current_package;
        $func = $fragment;
    }

    return
        map  { $package eq $current_package ? $_ : "$package\::$_" }
        grep { $func ? /^\Q$func/ : 1 }
        'Package::Stash'->new($package)->list_all_symbols('CODE');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Autocomplete::Functions - tab completion for function names

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ReadLine]
  [Autocomplete::Functions]

=head1 DESCRIPTION

This plugin registers a tab key handler to autocomplete function names in Perl
code, including imported functions.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
