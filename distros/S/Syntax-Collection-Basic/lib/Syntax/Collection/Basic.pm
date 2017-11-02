package Syntax::Collection::Basic;

use 5.010;

# ABSTRACT: (deprecated)
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0601';


use Syntax::Collector q/
    use strict 0;
    use warnings 0;
    use Modern::Perl 0 '2014';
    use true 0;
/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::Collection::Basic - (deprecated)



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.18+-blue.svg" alt="Requires Perl 5.18+" />
<a href="https://travis-ci.org/Csson/syntax-collection-basic"><img src="https://api.travis-ci.org/Csson/syntax-collection-basic.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Syntax-Collection-Basic-0.0601"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Syntax-Collection-Basic/0.0601" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Syntax-Collection-Basic%200.0601"><img src="http://badgedepot.code301.com/badge/cpantesters/Syntax-Collection-Basic/0.0601" alt="CPAN Testers result" /></a>
</p>

=end html

=head1 VERSION

Version 0.0601, released 2017-10-31.

=head1 STATUS

Deprecated.

=head1 SYNOPSIS

   use Syntax::Collection::Basic;

Is really

    use strict;
    use warnings;
    use Modern::Perl '2014';
    use true;

=head1 SOURCE

L<https://github.com/Csson/syntax-collection-basic>

=head1 HOMEPAGE

L<https://metacpan.org/release/Syntax-Collection-Basic>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
