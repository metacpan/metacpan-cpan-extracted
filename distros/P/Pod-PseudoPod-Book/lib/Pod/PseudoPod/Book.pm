package Pod::PseudoPod::Book;
# ABSTRACT: manages books written in the Pod::PseudoPod format

use strict;
use warnings;

use App::Cmd::Setup -app;
use Config::Tiny;

sub config
{
    my $app = shift;
    $app->{config} ||= Config::Tiny->read( 'book.conf' );
}

sub get_command
{
    my $self    = shift;
    my ($cmd, $opt, @args) = $self->SUPER::get_command( @_ );

    unshift @args, 'build_xhtml' if $cmd eq 'buildepub';

    return $cmd, $opt, @args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::Book - manages books written in the Pod::PseudoPod format

=head1 VERSION

version 1.20210620.2051

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
