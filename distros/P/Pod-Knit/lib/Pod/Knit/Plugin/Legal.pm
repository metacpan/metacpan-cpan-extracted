package Pod::Knit::Plugin::Legal;
our $AUTHORITY = 'cpan:YANICK';
$Pod::Knit::Plugin::Legal::VERSION = '0.0.1';
use strict;
use warnings;

use Moose;

extends 'Pod::Knit::Plugin';
with 'Pod::Knit::DOM::WebQuery';

use experimental 'signatures';

has license => (
    is => 'ro',
    lazy => 1,
    default => sub ($self) { $self->stash->{license} },
);

sub munge ($self,$doc) {

    my $license = $self->license or return;

    $doc->find_or_create_section( 'COPYRIGHT AND LICENSE', 1, undef,
        'para' => $license->notice,
        'para' => [
            '"' => 'Full text of the license can be found in the ',
            'f' => 'LICENSE',
            '"' => ' file included in this distribution.'
        ]
    );
} 

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::Legal

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

