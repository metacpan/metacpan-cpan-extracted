package Ref::List;
BEGIN {
  $Ref::List::VERSION = '0.002';
}

# ABSTRACT: Punctuation-free dereferencing of arrayrefs and hashrefs

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(reftype);

use base 'Exporter';

our (@EXPORT, @EXPORT_OK);

@EXPORT = qw(list);
@EXPORT_OK = qw(list);

sub list ($) {
    my $ref = shift;

    if (!defined($ref)) {
        return;
    }
    elsif ( reftype($ref) eq 'ARRAY') {
        return @$ref;
    }
    elsif ( reftype($ref) eq 'HASH') {
        return %$ref;
    }
    else {
        croak "Not a hashref or arrayref";
    }
}

1;


__END__
=pod

=for :stopwords Peter Shangov arrayrefs hashrefs

=head1 NAME

Ref::List - Punctuation-free dereferencing of arrayrefs and hashrefs

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Ref::List qw(list);

  my $data = {
    countries => [
        { name => 'Bulgaria', language = 'Bulgarian' },
        { name => 'Germany', language = 'German' },
    ],
  };

  print $_->{name} for list $data->{countries};

=head1 DESCRIPTION

This tiny module exports a single function, C<list>, which dereferences the arrayref or hashref passed to it as an argument. C<list $argument> is basically a synonym for C<@{$argument}>, but is less awkward when C<$argument> is a longer expression part of a nested data structure and may appeal to people with a dislike of punctuation overuse.

As of perl 5.14 you should be using the built-in C<values> function instead.

=head1 FUNCTIONS

=head2 list (HASHREF|ARRAYREF)

Given a hash or array reference, dereference it and return its contents as a list. If the argument is C<undef>, returns C<undef>.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

