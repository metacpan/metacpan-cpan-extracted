package Template::Plugin::Dumper::Perltidy;

use warnings;
use strict;

our $VERSION = '0.01';

use base 'Template::Plugin';
use Data::Dumper::Perltidy;

sub new {
    my $class   = shift;
    my $context = shift;
    bless { 
        context => $context,
    }, $class;
}

sub dump {
    my $self = shift;
    my $content = Dumper(@_);
    return $content;
}

1;
__END__

=head1 NAME

Template::Plugin::Dumper::Perltidy - Template Toolkit plugin interface to Data::Dumper::Perltidy

=head1 SYNOPSIS

    [% USE Dumper = Dumper::Perltidy %]
    
    [% Dumper.dump(myvar) %]

=head1 DESCRIPTION

A very simple Template Toolkit Plugin Interface to the L<Data::Dumper::Perltidy> module.

The Data::Dumper::Perltidy module is "Stringify and pretty print Perl data structures." like L<Data::Dumper>.

=head1 SEE ALSO

L<Template>, L<Data::Dumper::Perltidy>, L<Template::Plugin::Dumper>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
