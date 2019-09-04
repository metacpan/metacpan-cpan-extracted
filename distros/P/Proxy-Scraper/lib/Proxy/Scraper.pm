package Proxy::Scraper;

use strict;
use warnings;
use Carp qw(carp croak);
use List::Util qw(any);
use LWP::UserAgent qw(new);
use Term::ANSIColor qw(color colored);
use WWW::UserAgent::Random qw(rand_ua);
if($^O eq 'MSWin32'){
	require Win32::Console::ANSI;
	Win32::Console::ANSI->import();
}

our @ISA=qw(Exporter);
our @EXPORT=qw(scrape_proxies);

our $VERSION='2.1.0';
our $LIBRARY=__PACKAGE__;

sub scrape_free_proxy_list{
	my ($type,$level,$output_file,$agent,$debug)=@_;
	my $proxies_scraped_total=0;
	my @types;
	if($type eq 'http'){@types=('http','https')}
	elsif($type eq 'https'){@types=('https')}
	elsif($type eq 'socks4'){@types=('socks4','socks5')}
	elsif($type eq 'socks5'){@types=('socks5')}
	my $response;
	my @levels=$level eq 'any'?('transparent','anonymous','elite'):($level);
	foreach my $current_type (@types){
		foreach my $current_level (@levels){
			print colored "[+] Scraping $current_level $current_type proxies from \"https://www.proxy-list.download/api/v1/get?type=$current_type&anon=$current_level\"\n",'green' if $debug;
			$response=$agent->get("https://www.proxy-list.download/api/v1/get?type=$current_type&anon=$current_level");
			if($response->is_success){
				print $output_file $response->decoded_content;
				my $proxies_scraped=$response->decoded_content=~tr/\n//;
				$proxies_scraped_total+=$proxies_scraped;
				print colored "[+] Successfully scraped $proxies_scraped $current_level $current_type proxies from \"https://www.proxy-list.download/api/v1/get?type=$current_type&anon=$current_level\"\n",'green' if $debug;
			}else{carp colored '[-] Server returned '.$response->code.".\n",'red' if $debug}
		}
	}
	return $proxies_scraped_total;
}
sub scrape_openproxy_space{
	my ($type,$level,$output_file,$agent,$debug)=@_;
	my $proxies_scraped_total=0;
	if(($type eq 'socks4' and any {$level eq $_} ('any','elite')) or ($type eq 'http' and $level eq 'any')){
		print colored "[+] Scraping proxies lists from \"https://openproxy.space/lists/\"\n",'green' if $debug;
		my $response=$agent->get('https://openproxy.space/lists/');
		if($response->is_success){
			my $list_type=$type=~/(http|socks)/ && $1;
			foreach($response->decoded_content=~/href="\/lists\/([\w_-]+)" rel="nofollow" class="list $list_type"/g){
				print colored "[+] Scraping proxies from \"https://openproxy.space/lists/$_\"\n",'green' if $debug;
				my $response2=$agent->get("https://openproxy.space/lists/$_");
				if($response2->is_success){
					my $proxies_scraped=0;
					foreach($response2->decoded_content=~/((?:\d+\.){3}\d+:\d+)/g){
						print $output_file "$_\n";
						$proxies_scraped++;
					}
					$proxies_scraped_total+=$proxies_scraped;
					print colored "[+] Successfully scraped $proxies_scraped $level $type proxies from \"https://openproxy.space/lists/$_\"\n",'green' if $debug;
				}else{carp colored '[-] Server returned '.$response2->code.".\n",'red' if $debug}
			}
		}else{carp colored '[-] Server returned '.$response->code.".\n",'red' if $debug}
	}
	return $proxies_scraped_total;
}
sub scrape_proxies{
	my (%args)=@_;
	my $debug=$args{'DEBUG'};
	my $type=$args{'TYPE'} or
		croak colored "[-] -t/--type option is required.\n",'red';
	$type=~/https?|socks[45]/ or
		croak colored "[-] -t/--type option has to be one of {http,https,socks4,socks5}\n",'red';
	my $level=$args{'LEVEL'}||'any';
	any {$level eq $_} ('any','transparent','anonymous','elite') or
		croak colored "[-] -l/--level option has to be one of {transparent,anonymous,elite}\n",'red';
	my $output_file_path=$args{'OUTPUT_FILE'}||'proxies.txt';
	my $agent=$args{'AGENT'}||LWP::UserAgent->new(
		agent=>rand_ua 'windows',
	);
	print colored "[+] Opening \"$output_file_path\"\n",'green' if $debug;
	open my $output_file,'>',$output_file_path or die colored "[-] Can't open \"$output_file_path\" for reading: $!.\n",'red';
	print colored "[+] Successfully opened \"$output_file_path\"\n",'green' if $debug;
	my $proxies_scraped_total=0;
	$proxies_scraped_total+=scrape_free_proxy_list $type,$level,$output_file,$agent,$debug;
	$proxies_scraped_total+=scrape_openproxy_space $type,$level,$output_file,$agent,$debug;
	print colored "[+] Successfully scraped $proxies_scraped_total $level $type proxies.\n",'green' if $debug;
	print colored "[+] Closing \"$output_file_path\"\n",'green' if $debug;
	close $output_file or die colored "[-] Can't close \"$output_file_path\": $!.\n",'red';
	print colored "[+] Successfully closed \"$output_file_path\"\n",'green' if $debug;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Proxy::Scraper - Simple Perl script for scraping proxies from multiple websites.

=head1 VERSION

Version 2.1.0

=head1 DESCRIPTION

Proxy::Scraper is simple Perl script for scraping proxies from multiple websites.

=head1 METHODS

=head2 scrape_proxies

=over 4

=item *

TYPE - Type of proxy.

=item *

LEVEL - Level of proxy.

=item *

OUTPUT - Output filename.

=item *

AGENT - Agent for requests.

=back

=head1 BUGS

Please report any bugs here:

=over 4

=item *

debos@cpan.org

=item *

L<GitHub|https://github.com/DeBos99/Proxy-Scraper/issues>

=item *

Discord: DeBos#3292

=item *

L<Reddit|https://www.reddit.com/user/DeBos99>

=back

=head1 AUTHOR

Michał Wróblewski <debos@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2019 Michał Wróblewski

=head1 LICENSE

This project is licensed under the MIT License - see the L<LICENSE|https://github.com/DeBos99/Proxy-Scraper/blob/master/LICENSE> file for details.

=cut
