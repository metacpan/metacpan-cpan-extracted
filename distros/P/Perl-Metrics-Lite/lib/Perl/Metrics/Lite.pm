package Perl::Metrics::Lite;
use strict;
use warnings;

use Perl::Metrics::Lite::FileFinder;
use Perl::Metrics::Lite::Report::Text;
use Perl::Metrics::Lite::Analysis;
use Perl::Metrics::Lite::Analysis::File;

our $VERSION = "0.092";

sub new {
    my ( $class, %args ) = @_;
    my $self = bless( {}, $class );
    my $report_module
        = exists $args{report_module}
        ? $args{report_module}
        : Perl::Metrics::Lite::Report::Text->new;
    $self->{report_module} = $report_module;
    return $self;
}

sub analyze_files {
    my ( $self, @dirs_and_files ) = @_;
    my @results = ();
    my @objects = grep { ref $_ } @dirs_and_files;
    @dirs_and_files = grep { not ref $_ } @dirs_and_files;
    my $perl_file_finder = Perl::Metrics::Lite::FileFinder->new;
    foreach my $file (
        (   scalar(@dirs_and_files)
            ? @{ $perl_file_finder->find_files(@dirs_and_files) }
            : ()
        ),
        @objects
        )
    {
        my $file_analysis
            = Perl::Metrics::Lite::Analysis::File->new( path => $file );
        push @results, $file_analysis;
    }
    my $analysis = Perl::Metrics::Lite::Analysis->new( \@results );
    return $analysis;
}

sub report {
    my ( $self, $analysis ) = @_;
    my $report_module = $self->{report_module};
    $report_module->report($analysis);
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Metrics::Lite - Pluggable Perl Code Metrics System

=head1 SYNOPSIS

  use Perl::Metrics::Lite;
  my $analzyer   = Perl::Metrics::Lite->new;
  my $analysis   = $analzyer->analyze_files(@ARGV);
  my $file_stats = $analysis->file_stats;
  my $sub_stats = $analysis->sub_stats;

=head1 DESCRIPTION

B<Perl::Metrics::Lite> is the pluggable perl code metrics system.

B<Perl::Metrics::Lite> provides just enough methods to run static analysis
of one or many Perl files and obtain a few metrics.

B<Perl::Metrics::Lite> is far simpler than L<Perl::Metrics> 
and more extensible than L<Perl::Metrics::Simple>.

=head1 USAGE

See the F<measureperl> and F<measureperl-checkstyle>  script 
(included with this distribution) for a simple example of usage.

=head1 CLASS METHODS

=head2 new

Takes no arguments and returns a new L<Perl::Metrics::Lite> object.

=head1 OBJECT METHODS

=head2 analyze_files( @paths, @refs_to_file_contents )

Takes an array of files and or directory paths, and/or
SCALAR refs to file contents and returns
an L<Perl::Metrics::Lite::Analysis> object.

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-perl-metrics-lite

=head1 CONTRIBUTORS

Many thanks to:


=head1 AUTHOR

Dann E<lt>techmemo{at}gmail.comE<gt>

=head1 SEE ALSO

L<Perl::Metrics>
L<Perl::Metrics::Simple>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
