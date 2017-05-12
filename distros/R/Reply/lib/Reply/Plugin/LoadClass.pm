package Reply::Plugin::LoadClass;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::LoadClass::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: attempts to load classes implicitly if possible

use base 'Reply::Plugin';

use Module::Runtime 'use_package_optimistically';
use Try::Tiny;


sub execute {
    my $self = shift;
    my ($next, @args) = @_;

    try {
        $next->(@args);
    }
    catch {
        if (/^Can't locate object method "[^"]*" via package "([^"]*)"/) {
            use_package_optimistically($1);
            $next->(@args);
        }
        else {
            die $_;
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::LoadClass - attempts to load classes implicitly if possible

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [LoadClass]

=head1 DESCRIPTION

If executing a line of code fails due to a method not being defined on a
package, this plugin will load the corresponding module and then try executing
the line again. This simplifies common cases like running C<< DateTime->now >>
at the prompt before loading L<DateTime> - this plugin will cause DateTime to
be loaded implicitly.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
