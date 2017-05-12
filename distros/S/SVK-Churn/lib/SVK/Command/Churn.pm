package SVK::Command::Churn;
use v5.8.8;
use strict;
use base qw( SVK::Command );
use SVK::Command::Log;
use Chart::Strip;
use Date::Parse;
use IO::All;
use Quantum::Superpositions;

our $VERSION = '0.05';

sub options {
    ('q|quiet'       => 'quiet',
     't|type=s'      => 'chart_type',
     'o|output=s'    => 'output',
    );
}

sub parse_arg {
    my $self=shift;
    my @arg = @_;
    @arg = ('') if $#arg < 0;
    return $self->arg_co_maybe (@arg);
}

sub run {
    my ( $self, $target ) = @_;
    $self->{output}     ||= 'churn.png';
    $self->{chart_type} ||= "loc";
    my $method = $self->{chart_type} . "_graph";
    if ( $self->can($method) ) {
        my $chart = Chart::Strip->new(
            title            => "Churn result of $target->{path}",
            draw_data_labels => 1,
        );
        $self->$method( $chart, $self->{xd}, $target );
        io( $self->{output} )->print( eval '$chart->png()' );
        print STDERR "$self->{output} saved\n" unless $self->{quiet};
    }
    else {
        print
            "Unknown chart type: $self->{chart_type}. (Must be one of 'commits','committers', or 'loc')\n";
    }
    return 0;
}

sub trace_svklog {
    my $self = shift;
    my ( $xd, $target, $callback, $data ) = @_;
    SVK::Command::Log::_get_logs(
        root    => $target->root,
        path    => $target->path_anchor,
        fromrev => 0,
        torev   => $target->revision,
        verbose => 1,
        cross   => 0,
        cb_log  => $callback
    );
    @$data = sort { $a->{time} <=> $b->{time} } @$data;
    return $data;
}

sub loc_graph {
    my $self = shift;
    my ($chart,$xd,$target) = @_;
    my (@ladd,@lremoved,@revs);
    my $append = sub {
        my ($rev, $root, $props) = @_;
        my ($date,$author) = @{$props}{qw/svn:date svn:author/};
        my $time = str2time($date);
        push @revs,{time=>$time,value=>$rev}
            if $author && !($author eq 'svm');
    };
    $self->trace_svklog($xd, $target, $append, \@revs);

    my $full_path = "/" . $target->depotname . $target->path;
    my $output = "";
    my $svk = SVK->new(xd => $xd, output => \$output);
    for my $i (1..$#revs) {
        $svk->diff(-r => "$revs[$i-1]->{value}:$revs[$i]->{value}",
                   $full_path);

        my @lines = split/\n/,$output;
        my ($add,$rm)=(0,0);
        for(@lines) {
            next if /^[-+]{3,3} \S/;
            $add++ if/^\+/;
            $rm++  if/^\-/;
        }
        print STDERR "Rev $i, $add lines added ,$rm lines removed\n"
            unless $self->{quiet};
        push @ladd,    {time=>$revs[$i]->{time},value=>$add};
        push @lremoved,{time=>$revs[$i]->{time},value=>$rm };
        $output = "";
    }
    $chart->{y_label} = "Lines of Codes";
    $chart->add_data(\@ladd,{style=>'line',label=>'Lines Added',color=>'00FF00'});
    $chart->add_data(\@lremoved,{style=>'line',label=>'Lines Removed',color=>'FF0000'});
    return $chart;
}

sub commits_graph {
    my $self = shift;
    my ($chart,$xd,$target) = @_;
    my (@data,$commit);
    my $append = sub {
        my ($rev, $root, $props) = @_;
        my ($date,$author) = @{$props}{qw/svn:date svn:author/};
        my $time = str2time($date);
        push @data,{time=>$time,value=>$commit++}
            if $author && !($author eq 'svm');
    };
    $self->trace_svklog($xd,$target,$append,\@data);
    $chart->{y_label} = "Number of Commits";
    $chart->add_data(\@data,{style=>'line',color=>'FF0000'});
    return $chart;
}

sub committers_graph {
    my $self = shift;
    my ($chart,$xd,$target) = @_;
    my (@data,%authors);
    my $append = sub {
        my ($rev, $root, $props) = @_;
        my ($author,$date) = @{$props}{qw/svn:author svn:date/};
        my $time = str2time($date);
        if($author && !($author eq 'svm')) {
            $authors{$author}++;
            push @data,{time=>$time,value=>scalar(keys %authors)};
        }
    };
    $self->trace_svklog($xd,$target,$append,\@data);
    $chart->{y_label} = "Number of Committers";
    $chart->add_data(\@data,{style=>'line',color=>'FF0000'});
    return $chart;
}

1;

=head1 NAME

SVK::Command::Churn - Generate SVK Statistics graph.

=head1 SYNTAX

  svk [OPTIONS] churn //depotpath

=head1 OPTIONS

  -t  chart type, one of "commits","committers","loc"
      default to "loc" (lines of codes)
  -q  quiet
  -o  output filename

=head1 DESCRIPTION

This module helps you to understand yor SVK repository developing
statistics. It'll generate a file named C<churn.png> under
current directory unless C<-o> parameter is given.

SVK is a decentralized version control system built on top of the
robust Subversion filesystem. For more information, please visit
L<http://svk.elixus.org>.

=head1 API

All sub-routines defined in this modules is supposed to be invoked
by SVK internally, not to be called directly by developers. They
are all internal methods. If you must call them, please understand
what you are doing.

=over 4

=item options

Define command line options.

=item parse_arg

Parse command line argument string.

=item run

Run this churn command. This methods simply dispatch to one of the
following 3 methods according to user's command line argument.

=item commits_graph

Generate 'commits' churn graph.

=item committers_graph

Generate churn graph in the respect of comitters.

=item loc_graph

Generate churn graph in the respect of lines of code.

=item trace_svklog

General 'svk log' traversing rounine use internally inside this module.

=back

=head1 SEE ALSO

L<SVN::Churn>, L<SVK>, L<http://svk.elixus.org>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright 2005,2006,2007 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
