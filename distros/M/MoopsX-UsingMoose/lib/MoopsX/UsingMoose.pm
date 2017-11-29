use 5.14.0;
use strict;
use warnings;

package MoopsX::UsingMoose;

# ABSTRACT: A Moops that uses Moose
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0102';

use base 'Moops';

sub import {
    my $class = shift;
    my %opts = @_;

    push @{ $opts{'traits'} ||= [] } => (
        'MoopsX::TraitFor::Parser::UsingMoose',
    );
    $class->SUPER::import(%opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoopsX::UsingMoose - A Moops that uses Moose



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.14+-blue.svg" alt="Requires Perl 5.14+" />
<a href="https://travis-ci.org/Csson/p5-MoopsX-UsingMoose"><img src="https://api.travis-ci.org/Csson/p5-MoopsX-UsingMoose.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/MoopsX-UsingMoose-0.0102"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/MoopsX-UsingMoose/0.0102" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=MoopsX-UsingMoose%200.0102"><img src="http://badgedepot.code301.com/badge/cpantesters/MoopsX-UsingMoose/0.0102" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-97.4%-yellow.svg" alt="coverage 97.4%" />
</p>

=end html

=head1 VERSION

Version 0.0102, released 2017-11-28.

=head1 SYNOPSIS

    use MoopsX::UsingMoose;

    class My::Class {

        # A Moose based class

    }

=head1 DESCRIPTION

This is a thin wrapper around L<Moops> that automatically adds C<using Moose> to C<role> and C<class> statements. It does this by applying the included L<MoopsX::TraitFor::Parser::UsingMoose> C<Moops::Parser> trait.

=head2 Rationale

While this on the surface doesn't save any keystrokes it reduces cluttering of C<role>/C<class> statements. Consider the following:

    use Moops;

    class My::Project::Class
    types Types::Standard,
          Types::Path::Tiny,
          Types::MyCustomTypes
     with This::Role
    using Moose {

        # A Moose based class

    }

That is not very nice.

The first step is to get rid of C<using Moose>:

    use MoopsX::UsingMoose;

    class My::Project::Class
    types Types::Standard,
          Types::Path::Tiny,
          Types::MyCustomTypes
     with This::Role {

        # A Moose based class

    }

A minor improvement.

However, create a project specific L<Moops wrapper|Moops/"Extending-Moops-via-imports">:

    package My::Project::Moops;
    use base 'MoopsX::UsingMoose';

    use Types::Standard();
    use Types::Path::Tiny();
    use Types::MyCustomTypes();

    sub import {
        my $class = shift;
        my %opts = @_;

        push @{ $opts{'imports'} ||= [] } => (
            'Types::Standard' => ['-types'],
            'Types::Path::Tiny' => ['-types'],
            'Types::MyCustomTypes' => ['-types'],
        );

        $class->SUPER::import(%opts);
    }

And the C<class> statement becomes:

    use My::Project::Moops;

    class My::Project::Class with This::Role {

        # A Moose based class, still with all the types

    }

Happiness ensues.

=head1 SEE ALSO

=over 4

=item *

L<Moops>

=item *

L<Moose>

=item *

L<Moo>

=back

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
