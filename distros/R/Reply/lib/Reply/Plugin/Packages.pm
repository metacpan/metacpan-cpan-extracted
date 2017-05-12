package Reply::Plugin::Packages;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Packages::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: persist the current package between lines

use base 'Reply::Plugin';


sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    $self->{package} = $opts{default_package} || 'main';

    return $self;
}

sub mangle_line {
    my $self = shift;
    my ($line) = @_;

    my $package = __PACKAGE__;
    return <<LINE;
$line
;
BEGIN {
    \$${package}::package = __PACKAGE__;
}
LINE
}

sub compile {
    my $self = shift;
    my ($next, $line, %args) = @_;

    my @result = $next->($line, %args);

    # XXX it'd be nice to avoid using globals here, but we can't use
    # eval_closure's environment parameter since we need to access the
    # information in a BEGIN block
    $self->{package} = our $package;

    return @result;
}

sub package {
    my $self = shift;
    return $self->{package};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Packages - persist the current package between lines

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [Packages]
  default_package = My::Scratchpad

=head1 DESCRIPTION

This plugin persists the state of the current package between lines. This
allows lines such as C<package Foo;> in the Reply shell to do what you'd
expect. The C<default_package> configuration option can also be used to set the
initial package to use when Reply starts up.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
