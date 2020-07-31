use 5.14.0;
use strict;
use warnings;

package MoopsX::TraitFor::Parser::UsingMoose;

# ABSTRACT: A Moops::Parser traits that sets 'using Moose'
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0103';

use Moo::Role;

after parse => sub {
    shift->relations->{'using'} = ['Moose'];
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoopsX::TraitFor::Parser::UsingMoose - A Moops::Parser traits that sets 'using Moose'

=head1 VERSION

Version 0.0103, released 2020-07-29.

=head1 SYNOPSIS

    use Moops traits => ['MoopsX::TraitFor::Parser::UsingMoose'];

    class My::Class {

        # This is a Moose class

    }

=head1 DESCRIPTION

This class is a trait for L<Moops::Parser> that automatically sets 'using Moose' on C<role> and C<class> statements.

But use L<MoopX::UsingMoose> instead.

=head1 SOURCE

L<https://github.com/Csson/p5-MoopsX-UsingMoose>

=head1 HOMEPAGE

L<https://metacpan.org/release/MoopsX-UsingMoose>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
