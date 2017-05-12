package Sphinx::Log::Parser;

BEGIN {
    $Sphinx::Log::Parser::VERSION = '0.03';
}

use strict;
use warnings;

# ABSTRACT: parse Sphinx searchd log

use Carp;
use IO::File;
use IO::Handle;

sub new {
    my ( $class, $file ) = @_;

    my %data;
    if ( UNIVERSAL::isa( $file, 'IO::Handle' ) ) {
        $data{file} = $file;
    }
    elsif ( UNIVERSAL::isa( $file, 'File::Tail' ) ) {
        $data{file}     = $file;
        $data{filetail} = 1;
    }
    elsif ( !ref $file ) {
        if ( $file eq '-' ) {
            my $io = new IO::Handle;
            $data{file} = $io->fdopen( fileno(STDIN), "r" );
        }
        else {
            $data{file} = new IO::File( $file, "<" );
            defined $data{file} or croak "can't open $file: $!";
        }
    }
    else {
        croak
"argument must be either a file-name or an IO::Handle/File::Tail object.";
    }

    return bless \%data, $class;
}

sub _next_line {
    my $self = shift;
    my $f    = $self->{file};
    if ( defined $self->{filetail} ) {
        return $f->read;
    }
    else {
        return $f->getline;
    }
}

sub next {
    my ($self) = @_;

    while ( defined( my $str = $self->_next_line ) ) {

# 0.9.9
# [query-date] query-time multiquery-factor [match-mode/filters-count/sort-mode total-matches (offset,limit) @groupby-attr]  [index-name] [performances-counters] [query-comment] query
# optionals: multiquery-factor, @groupby-attr, performances-counters, query-comment

        # '[Mon Sep 20 06:25:29.979 2010] '
        # '0.005 sec x20 '
        # '[ext/3/ext 163 (0,100) @perf_id] '
        # '[index1 index2] '
        # '[ios=5 kb=45.6 ioms=65.57 cpums=2.5] '
        # '[query comment] '
        # '@author  (Days Gracie) '

        $str =~ /^
                 \[(\w{3}\s+\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\.\d{3}\s+\d{4})\]\s+
                 ([\d\.]+)\s+sec\s+(x[\d]+)?\s?
                 \[(\w+)\/(\d+)\/([\w\-\+]+)\s(\d+)\s\((\d+)\,(\d+)\)\s*\@?(\S+)?\]\s+
                 \[([\w\s\;]+)\]\s+
                 (\[ios\=[\d\.]+\s+kb\=[\d\.]+\s+ioms\=[\d\.]+[\s+cpums\=[\d\.]+]?\])?\s?
                 (\[.*\])?\s?
                 (.*)
                $/x;

        my $query_date            = $1;
        my $query_time            = $2;
        my $multiquery_factor     = $3;
        my $match_mode            = $4;
        my $filter_count          = $5;
        my $sort_mode             = $6;
        my $total_matches         = $7;
        my $offset                = $8;
        my $limit                 = $9;
        my $groupby_attr          = $10;
        my $index_name            = $11;
        my $performances_counters = $12;
        my $query_comment         = $13;
        my $query                 = $14;

        $performances_counters =~ s/\[(.*)\]/$1/ if $performances_counters;
        $query_comment         =~ s/\[(.*)\]/$1/ if $query_comment;

        return {
            query_date            => $query_date,
            multiquery_factor     => $multiquery_factor,
            query_time            => $query_time,
            match_mode            => $match_mode,
            filter_count          => $filter_count,
            sort_mode             => $sort_mode,
            total_matches         => $total_matches,
            offset                => $offset,
            limit                 => $limit,
            groupby_attr          => $groupby_attr,
            index_name            => $index_name,
            performances_counters => $performances_counters,
            query_comment         => $query_comment,
            query                 => $query
        };
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Sphinx::Log::Parser - parse Sphinx searchd log

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Sphinx::Log::Parser;
    
    my $parser = Sphinx::Log::Parser->new( '/var/log/searchd/query.log' );
    while (my $sl = $parser->next) {
        print $sl->{total_matches}, $sl->{query_date}, "\n"; # more
    }

=head1 DESCRIPTION

Sphinx::Log::Parser parse sphinx searchd query.log based on L<http://sphinxsearch.com/docs/current.html#query-log-format>

=head2 Constructing a Parser

B<new> requires as first argument a source from where to get the searchd query log lines. It can
be:

=over 4

=item *

a filename for the searchd query log to be parsed. check B<query_log> in conf file

=item *

an IO::Handle object.

=item *

a File::Tail object as first argument, in which
case the I<read> method will be called to get lines to process.

=item *

The log string, you need use L<IO::Scalar>

    use IO::Scalar;
    # 0.9.9
    my $logstr = '[Fri Oct  1 03:18:46.342 2010] 0.014 sec [ext/2/rel 55 (0,700)] [topic;topicdelta;] [ios=0 kb=0.0 ioms=0.0] @title lucky';
    my $io = new IO::Scalar \$logstr;
    my $parser = Sphinx::Log::Parser->new( $io );

=back

=head2 Parsing the file

The file is parse one line at a time by calling the B<next> method, which returns
a hash-reference containing the following keys:

   {
     'performances_counters' => 'ios=0 kb=0.0 ioms=0.0',
     'total_matches' => '55',
     'match_mode' => 'ext',
     'query' => '@title lucky',
     'query_date' => 'Fri Oct  1 03:18:46.342 2010',
     'query_comment' => undef,
     'filter_count' => '2',
     'multiquery_factor' => undef,
     'index_name' => 'topic;topicdelta;',
     'limit' => '700',
     'groupby_attr' => undef,
     'query_time' => '0.014',
     'sort_mode' => 'rel',
     'offset' => '0'
   },

The log format is

    [query-date] query-time multiquery-factor [match-mode/filters-count/sort-mode total-matches (offset,limit) @groupby-attr]  [index-name] [performances-counters] [query-comment] query
    
    # optionals: multiquery-factor, @groupby-attr, performances-counters, query-comment

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Paolo Lunazzi

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam, Paolo Lunazzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
