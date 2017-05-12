package MooseX::Has::Options::Handler::Accessors;
{
  $MooseX::Has::Options::Handler::Accessors::VERSION = '0.003';
}

# ABSTRACT: Option shortcuts for ro/rw/bare

use strict;
use warnings;

sub handles
{
    return (
        ro   => { is => 'ro'   },
        rw   => { is => 'rw'   },
        bare => { is => 'bare' },
    );
}

1;


__END__
=pod

=for :stopwords Peter Shangov hashrefs

=head1 NAME

MooseX::Has::Options::Handler::Accessors - Option shortcuts for ro/rw/bare

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This module provides the following shortcut options for L<MooseX::Has::Options>:

=over

=item :ro

Translates to C<< is => 'ro' >>

=item :rw

Translates to C<< is => 'rw' >>

=item :bare

Translates to C<< is => 'bare' >>

=back

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

