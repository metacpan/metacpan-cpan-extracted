package Syntax::Keyword::Junction::Base;
use strict;
use warnings;

our $VERSION = '0.003009';

BEGIN {
  *_WANT_SMARTMATCH = ("$]" >= 5.010001 && "$]" < 5.041000) ? sub(){1} : sub(){0};
  my $category
    = "$]" >= 5.041000 ? undef
    : "$]" >= 5.037011 ? 'deprecated::smartmatch'
    : "$]" >= 5.017011 ? 'experimental::smartmatch'
    : undef;
  *_SMARTMATCH_WARNING_CATEGORY = sub(){$category};
}

use overload(
    '=='   => "num_eq",
    '!='   => "num_ne",
    '>='   => "num_ge",
    '>'    => "num_gt",
    '<='   => "num_le",
    '<'    => "num_lt",
    'eq'   => "str_eq",
    'ne'   => "str_ne",
    'ge'   => "str_ge",
    'gt'   => "str_gt",
    'le'   => "str_le",
    'lt'   => "str_lt",
    'bool' => "bool",
    '""'   => sub {shift},
    ('~~' => 'match') x!! _WANT_SMARTMATCH,
);


sub new { bless \@_, shift }

sub values {
    my $self = shift;
    return wantarray ? @$self : [ @$self ];
}

sub map {
    my ( $self, $code ) = @_;
    my $class = ref $self;
    $class->new( map { $code->( $_ ) } $self->values );
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt Carl Franks

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Syntax-Keyword-Junction/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Carl Franks

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
