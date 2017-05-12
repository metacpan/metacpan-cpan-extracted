package Railsish;
our $VERSION = '0.21';

# ABSTRACT: A web application framework.

use strict;
use warnings;

use HTTP::Engine::Response;
use UNIVERSAL::require;

my $app_package;

sub import {
    $app_package = caller;

    no strict;
    for (qw(handle_request)) {
        *{"$app_package\::$_"} = \&$_;
    }
}

1;



__END__
=head1 NAME

Railsish - A web application framework.

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This is a web app framework that is still very experimental.

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

=head1 EXAMPLE

At this moment, see t/SimpleApp for how to use this web framework.

