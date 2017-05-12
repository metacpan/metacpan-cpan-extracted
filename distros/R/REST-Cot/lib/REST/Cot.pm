package REST::Cot;
$REST::Cot::VERSION = '0.006';
use 5.16.0;
use strict;
use warnings;

# ABSTRACT: REST easier, lay on a cot


use URI;
use REST::Client;
use REST::Cot::Fragment;

sub new {
    my $class = shift;
    my $host  = shift;

    my $ref = {};
    $ref->{parent} = undef;
    $ref->{client} = REST::Client->new({host => $host, @_});
    $ref->{root} = 1;
    $ref->{path} = sub { '' };

    bless($ref, 'REST::Cot::Fragment');

    return $ref;
}

1;

=pod

=encoding UTF-8

=head1 NAME

REST::Cot - REST easier, lay on a cot

=head1 VERSION

version 0.006

=head1 SYNOPSIS

This package is a blatant rip-off of Python's Hammock library. 

  my $metacpan = REST::Cot->new('http://api.metacpan.org/');
  my $data = $metacpan->v0->author->JMMILLS->GET();

  say $data->{email}->[0]; # jmmills@cpan.org

=head1 CAVEAT

This package was developed for an application I maintain as conviencince. It's under-documented, and under-tested.
YMMV

=head1 AUTHOR

Jason Mills <jmmills@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jason Mills.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__;
