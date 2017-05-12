package MooseX::Has::Options::Handler::NoInit;
{
  $MooseX::Has::Options::Handler::NoInit::VERSION = '0.003';
}

# ABSTRACT: Option shortcut for prohibiting init_arg

use strict;
use warnings;

sub handles
{
    return (
        no_init => { init_arg => undef }
    );
}

1;


__END__
=pod

=for :stopwords Peter Shangov hashrefs

=head1 NAME

MooseX::Has::Options::Handler::NoInit - Option shortcut for prohibiting init_arg

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This module provides the following shortcut options for L<MooseX::Has::Options>:

=over

=item :no_init

Translates to C<< init_arg => undef >>

=back

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

