#!/usr/bin/env perl
# ABSTRACT: update template files based on OpenDocument source file
# PODNAME: od-update.pl

use 5.010;
use utf8;
use strict;
use warnings;
use autodie;
use Getopt::Long::Descriptive;
use OpenDocument::Template;
use OpenDocument::Template::Util;

binmode STDIN,  ':utf8';
binmode STDOUT, ':utf8';

my ( $opt, $usage ) = describe_options(
    "%c %o",
    [ 'config|c=s', 'config file'     ],
    [ 'src|s=s',    'source ODT file' ],
    [
        'template-dir|t=s',
        'template directory (default: .)',
        { default => q{.} },
    ],
    [
        'prefix|p=s',
        'prefix to convert in to template ex. "(meta|person)\."',
    ],
    [ 'force|f',    'force rewrite',  ],
    [],
    [ 'verbose|v',  'print extra stuff', { default => 0 } ],
    [ 'help|h',     'print usage message and exit'        ],
);

print($usage->text), exit if $opt->help;
print($usage->text), exit unless $opt->config && -f $opt->config;
print($usage->text), exit unless $opt->src    && -f $opt->src;

my $ot = OpenDocument::Template->new(
    config       => $opt->config,
    template_dir => $opt->template_dir,
    src          => $opt->src,
);

OpenDocument::Template::Util->update_template(
    $ot,
    prefix => $opt->prefix,
    force  => $opt->force,
) or die "failed to update template\n";

__END__
=pod

=encoding utf-8

=head1 NAME

od-update.pl - update template files based on OpenDocument source file

=head1 VERSION

version 0.002

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

