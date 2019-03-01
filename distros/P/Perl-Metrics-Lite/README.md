# NAME

Perl::Metrics::Lite - Pluggable Perl Code Metrics System

# SYNOPSIS

    use Perl::Metrics::Lite;
    my $analzyer   = Perl::Metrics::Lite->new;
    my $analysis   = $analzyer->analyze_files(@ARGV);
    my $file_stats = $analysis->file_stats;
    my $sub_stats = $analysis->sub_stats;

# DESCRIPTION

**Perl::Metrics::Lite** is the pluggable perl code metrics system.

**Perl::Metrics::Lite** provides just enough methods to run static analysis
of one or many Perl files and obtain a few metrics.

**Perl::Metrics::Lite** is far simpler than [Perl::Metrics](https://metacpan.org/pod/Perl::Metrics) 
and more extensible than [Perl::Metrics::Simple](https://metacpan.org/pod/Perl::Metrics::Simple).

# USAGE

See the `measureperl` and `measureperl-checkstyle`  script 
(included with this distribution) for a simple example of usage.

# CLASS METHODS

## new

Takes no arguments and returns a new [Perl::Metrics::Lite](https://metacpan.org/pod/Perl::Metrics::Lite) object.

# OBJECT METHODS

## analyze\_files( @paths, @refs\_to\_file\_contents )

Takes an array of files and or directory paths, and/or
SCALAR refs to file contents and returns
an [Perl::Metrics::Lite::Analysis](https://metacpan.org/pod/Perl::Metrics::Lite::Analysis) object.

# SOURCE AVAILABILITY

This source is in Github:

    http://github.com/dann/p5-perl-metrics-lite

# CONTRIBUTORS

Many thanks to:

# AUTHOR

Dann &lt;techmemo{at}gmail.com>

# SEE ALSO

[Perl::Metrics](https://metacpan.org/pod/Perl::Metrics)
[Perl::Metrics::Simple](https://metacpan.org/pod/Perl::Metrics::Simple)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
