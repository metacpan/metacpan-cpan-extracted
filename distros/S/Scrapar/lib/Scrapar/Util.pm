package Scrapar::Util;

use strict;
use warnings;
use List::Util qw(max);
use List::MoreUtils;
use Exporter::Lite;
use Email::Find;
use HTML::SimpleLinkExtor;
use URI::Escape;
use Scrapar::HTMLQuery 'query';
use HTML::TreeBuilder;
use HTML::Entities;
use HTML::Element;
require LWP::Simple;
use Scrapar::XMLQuery;
use Date::Parse;
use Date::Format;
use FindBin;
use IPC::Open2;
use DB_File;
use Digest::MD5 qw(md5_hex);
use Sys::MemInfo qw(totalmem freemem totalswap freeswap);
require Data::Dumper;

our @EXPORT_OK = qw(zip find_email find_links escape_uri html_query html_query_first decode_html_entities lwp_get xml_query str2time2str html2text mysql_dateformat);

our @EXPORT = qw(trim_head trim_tail parray match match_first shuffle uniq dumper);

sub shuffle (@) {
    List::Util::shuffle @_;
}

sub uniq (@) {
    List::MoreUtils::uniq @_;
}

sub dumper {
    Data::Dumper::Dumper(@_);
}

sub zip {
  my @args = @_;

  my $max = max(map { scalar @{$_} } @args);

  return map { my $ix = $_; [ map { $_->[$ix] } @args ] } 0..$max-1;
}

sub find_email {
  my @texts = @_;
  my %email;

  for my $text (@texts) {
      find_emails($text, sub { $email{$_[0]->address} = 1 });
  }
  my @emails = keys %email;

  return wantarray ? @emails : ($emails[0] || '');
}

sub find_links {
    my $content = shift || return undef;

    my @links;

    my $e = HTML::SimpleLinkExtor->new();
    $e->parse($content);

    @links = $e->links;

    return wantarray ? @links : $links[0];
}

sub escape_uri {
    my @urls = map { uri_unescape $_ } @_;

    return wantarray ? @urls : $urls[0];
}

sub html_query {
    my $content = shift;
    my $query = shift || return;

    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
    
    my @results = $tree->query($query);

    return wantarray ? @results : \@results;
}

sub html_query_first {
    my $content = shift;
    my $query = shift || return;

    my @r = html_query($content, $query);
    if (defined $r[0] && ref $r[0]) {
	return $r[0];
    }
    else {
	return HTML::Element->new('span');
    }
}
		 
sub decode_html_entities {
    my $html = shift;

    return decode_entities($html);
}

sub lwp_get {
    print "[LWP-GET] @_\n";
    LWP::Simple::get(@_);
}

sub xml_query {
    Scrapar::XMLQuery::xml_query(@_);
}

sub str2time2str {
    my $pattern = shift;
    my $time = shift;

    return time2str($pattern, str2time $time);
}

sub mysql_dateformat {
    my $time = shift;

    return time2str("%Y-%m-%d", $time);
}

sub html2text {
    my $html = shift;
    my $out;
    my $in;
    local $/;
    open2($out, $in, 'python ' . $FindBin::Bin . '/html2text.py');
    print { $in } $html . "\n";
    close $in;
    my $ret = <$out>;
    return $ret;
}

sub trim_head {
    my $string = shift;
    my $regex = shift;
    $string =~ s[^$regex][];
    return $string;
}

sub trim_tail {
    my $string = shift;
    my $regex = shift;
    $string =~ s[$regex$][];
    return $string;
}

use Scrapar::PArray;
sub parray {
    my @array_data = @_;

    # make a unique digest based on where parray() is called and on
    # the data in parray initially

    my $digest = join q//, (caller(1))[3,2]; # sub name, line number
    for my $data (sort @array_data) {
	$digest = md5_hex($data . $digest);
    }

    mkdir "/tmp/parray/";
    my $filename = "/tmp/parray/" . join q/-/, (caller)[0], $digest ;

    $ENV{SCRAPER_LOGGER}->info("parray filename: $filename");

    my $X = Scrapar::PArray->new($filename);
    $X->push(@array_data) if $X->{is_file_empty};
    return $X;
}

sub match {
    my $text = shift;
    my $regex = shift;

    if ($text =~ m[$regex]) {
	{
	    no strict 'refs';
	    my $count = 1;
	    return map { ${$count++} } @-;
	}
    }
}

sub match_first {
    (match(@_))[0];
}

sub free_mem_ratio {
    my $ratio = (freemem() + freeswap()) / (totalmem() + totalswap());
    return $ratio;
}

# deletes log files older than one month
sub recycle_log_files {
    my $log_path = shift;
    # (stat($_))[9] => mtime 
    unlink for grep { time - (stat($_))[9] > 30 * 86400 } glob("$log_path/*.log");
}

# return the usage of a disk on which a path resides
sub disk_usage {
    my $path = shift;
    my $df = `df -l -h /tmp/`;
    if ($df =~ m[(\d+)%]) {
	return $1;
    }
}

__END__

=pod

=head1 NAME

Scrapar::Util - Some utility functions/methods

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
