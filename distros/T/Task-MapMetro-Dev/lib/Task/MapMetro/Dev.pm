use 5.16.0;
use strict;
use warnings;

package Task::MapMetro::Dev;

our $VERSION = '0.1201'; # VERSION
# ABSTRACT: Useful stuff when developing Map::Metro maps

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Task::MapMetro::Dev - Useful stuff when developing Map::Metro maps



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.16+-brightgreen.svg" alt="Requires Perl 5.16+" /></p>

=end HTML


=begin markdown

![Requires Perl 5.16+](https://img.shields.io/badge/perl-5.16+-brightgreen.svg)

=end markdown

=head1 VERSION

Version 0.1201, released 2016-01-30.

=head1 TASK CONTENTS

=head2

=head3 L<GraphViz2> 2.20

=head3 L<Dist::Zilla> 5.000

=head3 L<Map::Metro> 0.2300

=head3 L<Dist::Zilla::MintingProfile::MapMetro::Map> 0.1402

=head3 L<Dist::Zilla::Plugin::MapMetro::MakeGraphViz> 0.1101

=head3 L<Dist::Zilla::Plugin::MapMetro::MakeLinePod> 0.1201

=head1 SYNOPSIS

    # install graphviz.
    # eg:
    $ sudo apt-get install graphviz

    # and then
    $ cpanm Task::MapMetro::Dev

=head1 SEE ALSO

L<Task::MapMetro::Maps>

=head1 SOURCE

L<https://github.com/Csson/p5-Task-MapMetro-Dev>

=head1 HOMEPAGE

L<https://metacpan.org/release/Task-MapMetro-Dev>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
