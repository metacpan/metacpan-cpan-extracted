package Reply::Plugin::Autocomplete::Packages;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Autocomplete::Packages::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: tab completion for package names

use base 'Reply::Plugin';

use Module::Runtime '$module_name_rx';

use Reply::Util 'all_packages';


sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    # $module_name_rx does not permit trailing ::
    my ($before, $package_fragment) = $line =~ /(.*?)(${module_name_rx}:?:?)$/;
    return unless $package_fragment;
    return if $before =~ /^#/; # command
    return if $before =~ /->\s*$/; # method call
    return if $before =~ /[\$\@\%\&\*]\s*$/;

    return sort grep { index($_, $package_fragment) == 0 } all_packages();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Autocomplete::Packages - tab completion for package names

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [ReadLine]
  [Autocomplete::Packages]

=head1 DESCRIPTION

This plugin registers a tab key handler to autocomplete package names in Perl
code.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
