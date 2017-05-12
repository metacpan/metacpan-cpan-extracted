package Nagios::WebTransact::Timed;

use strict;

use vars qw($VERSION @ISA) ;

$VERSION = '0.06';

@ISA = qw(Nagios::WebTransact) ;

use HTTP::Request::Common qw(GET POST) ;
use HTTP::Cookies ;
use LWP::UserAgent ;
use Time::HiRes qw(gettimeofday tv_interval) ;
use Carp ;

use Nagios::WebTransact ;

use constant FALSE			=> 0 ;
use constant TRUE			=> ! FALSE ;
use constant FAIL			=> FALSE ;
use constant OK				=> TRUE ;
					# ie Normal Perl semantics. 'Success' is TRUE (1).
					# Caller must map this to Unix/Nagios return codes.

use constant GET_TIME_THRESHOLD		=> 10 ;
use constant FAIL_RATIO_PERCENT		=> 50 ;

sub check {
  my ($self, $cgi_parm_vals_hr) = @_ ;

  my %defaults = ( cookies => TRUE,
		  debug => TRUE,
		  timeout => GET_TIME_THRESHOLD,
		  agent => 'Mozilla/4.7',
		  proxy => {},
                  fail_if_1 => FALSE,
		  verbose => 1,
                  download_images => FALSE,
                  indent_level => 0,
		  fail_ratio_percent => FAIL_RATIO_PERCENT
		) ;
					# check semantics.
					# $fail_if_1  	?	return FAIL if any URL fails
					# ! $fail_if_1	?	return FAIL if all URLs fail
					#                       (same as return OK if any URL ok)

  my %parms = (%defaults, @_) ;

  
  my $debug	= $parms{debug} ;
  my $verbose	= $parms{verbose} ;
  my $indent	= $parms{indent_level} ;
  my $fail_ratio_percent = $parms{fail_ratio_percent}  || FAIL_RATIO_PERCENT ;
     croak("Expecting fail_ratio_percent as a percentage (0-100%), got \$fail_ratio:_percent: $fail_ratio_percent\n")
       if $fail_ratio_percent < 0 or $fail_ratio_percent > 100 ;
  my $fail_ratio = $fail_ratio_percent / 100 ;
  my $timeout	= $parms{timeout} ;
     croak("Expecting timeout as a natural number (0 ... not_too_big), got \$timeout: $timeout.\n")
       if $timeout < 0 ;

  my ($ua, %downloaded) ; 
  keys %downloaded = 128 ;

  $ua = new LWP::UserAgent ;
  $ua->agent($parms{agent}) ;
  $ua->timeout($timeout) ;
  $ua->cookie_jar(HTTP::Cookies->new)
    if $parms{cookies} ;
  $ua->proxy(['http', 'ftp'] => $parms{proxy}{server})
    if exists $parms{proxy}{server} ;

  my @urls = @{ $self->{urls} } ;
  my $Fault_Threshold = int( scalar @urls * $fail_ratio + 0.5 ) * $timeout ;
  my $check_time = 0 ;
  my @get_times = () ;

  foreach my $url_r ( @urls ) {

    my $req = $self->make_req( $url_r->{Method}, $url_r->{Url}, $url_r->{Qs_var}, $url_r->{Qs_fixed}, $cgi_parm_vals_hr ) ;

    $req->proxy_authorization_basic( $parms{proxy}{account}, $parms{proxy}{pass} )
      if exists $parms{proxy}{account} ;

    print STDERR  '   ' x $indent, '... ' ,$req->as_string, "\n" if $debug ;

    my $t0 = [gettimeofday] ;
  
    my $res = $ua->request($req) ;
  
    my $elapsed = tv_interval ($t0) ;
    my $rounded_elapsed = ( ($elapsed < GET_TIME_THRESHOLD and $res->is_success) ? sprintf('%3.2f',  $elapsed ) : GET_TIME_THRESHOLD ) ;
    push @get_times, $rounded_elapsed ;
    $check_time += $rounded_elapsed ;

    print STDERR '   ' x $indent,  '... ' , $res->as_string ,"\n" if $debug ;

    if ( $verbose ) {
      my $url_report = sprintf("%-95s%10s%-5.2f%-40s\n", substr('   ' x $indent . (! $indent ? '--getting ' : '') . $url_r->{Url}, 0, 95),
				        	      , ' ' x 10, 
						      , $rounded_elapsed,
						      , (! $indent  ? 'Total check time: ' 
								    : '  image download time: ') . sprintf('%5.2f', $check_time)) ;
      print STDERR  $url_report ;
    }
  
    unless ( $check_time <= $Fault_Threshold ) {
      my $i = 0 ;
      foreach (@urls) {
        $get_times[$i] = GET_TIME_THRESHOLD if not defined $get_times[$i] ;
        $i++ ;
      }
      return (FAIL, 'Transaction failed. Timeout', \@get_times) ;
    }

    if ( $parms{download_images} ) {
      my ($image_dl_ok, $image_dl_msg, $image_get_times_ar, $number_imgs_dl ) = &download_images($res, \%parms, \%downloaded) ;
      return (FAIL, $image_dl_msg)
        unless $image_dl_ok ;
      $self->{number_of_images_downloaded} += $number_imgs_dl ;
      $get_times[-1] += $_
        foreach @$image_get_times_ar ;
      # &download_images() will call check() which returns here the list of image download times in @$image_get_times_ar.
      # Each elt in this list is added to the last html download time ($get_times[-1]) leaving @get_times containing
      # the total download time for the page (downloaded sequentially and without heed to 'if modified' headers).
      printf "%137s%5.2f\n", 'Total page download time: ', $get_times[-1] 
        if $verbose ;
    }
  
  }
  return (OK, 'Transaction completed Ok.', \@get_times) ;
}

sub download_images {

  my ($res, $parms_hr, $downloaded_hr)  = @_ ;

  require HTML::LinkExtor ;
  require URI::URL ;
  URI::URL->import(qw(url)) ;

  my @imgs = () ;

  my $cb = sub {
      my($tag, %attr) = @_;
      return if $tag ne 'img';  # we only look closer at <img ...>
      push(@imgs, $attr{src});
  } ;

  my $p = HTML::LinkExtor->new($cb) ;
  $p->parse($res->as_string) ;

  my $base = $res->base;
  my @imgs_abs = grep ! $downloaded_hr->{$_}++, map { my $x = url($_, $base)->abs; } @imgs;

  my @img_urls = map { Method => 'GET', Url => $_->as_string, Qs_var => [], Qs_fixed => [], Exp => '.',  Exp_Fault => 'NeverInAnImage' }, @imgs_abs ;
                                                # url() returns an array ref containing the abs url and the base.
  if ( my $number_of_images_not_already_downloaded =scalar @img_urls ) {
    # If there are no images that have not been downloaded, then don't try to call ->check([]) since it will return FAIL.
    my $img_trx = __PACKAGE__->new(\@img_urls) ;
    my %image_dl_parms = (%$parms_hr, fail_if_1 => FALSE, download_images => FALSE, indent_level => 1) ; 
    return ( $img_trx->check({}, %image_dl_parms), $number_of_images_not_already_downloaded ) ;
  } else {
    return (OK, 'Downloaded all __zero__ images found in ' . $res->base, [], 0) ;
  }

}
  
1 ;


__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Nagios::WebTransact::Timed - An object that provides a check method (usually called by a Nagios service check) to
determine if a sequence of URLs can be got inside a time threshold, returning the times for each.


=head1 SYNOPSIS

  use Nagios::WebTransact::Timed;

  # Constructors
  $web_trx = Nagios::WebTransact::Timed->new(\@url_set);

=head1 DESCRIPTION

WebTransact::Timed is a subclass of WebTransact that checks web performance by downloading a sequence
of URLs.

The check is successfull if no more than B<fail_ratio> of the URLs fail ie a URL is downloaded
inside the timeout period with a successfull HTTP return code and no indications of invalid content.

Note that unlike WebTransact, this object only returns FAIL if all URLs fail or timeout.

=head1 CONSTRUCTOR

=over 4

=item Nagios::WebTransact::Timed->new(ref_to_array_of_hash_refs)

E<10>

This is the constructor for a new Nagios::WebTransact object. C<ref_to_array_of_hash_refs
> is a reference to an array of records (anon hash refs) in the format :-

{ Method   => HEAD|GET|POST,
  Url      => 'http://foo/bar',
  Qs_fixed => [cgi_var_name_1 => val1, ... ]  NB that now square brackets refer to a Perl array ref
  Qs_var   => [cgi_var_name_1 => val_at_run_time],
  Exp      => blah,
  Exp_Fault=> blurb
}

Exp and Exp_Fault are normal Perl patterns without pattern match delimiters. Most often they are strings.

=item B<Exp> is the pattern that when matched against the respose to the URL (in the same hash) indicates
success.

=item B<Exp_Fault> is the pattern that indicates the response is a failure.

If these patterns contain parentheses eg 'match a lot (.*)', then the match is saved for use by 
Qs_var. Note that there should be only B<one> pattern per element of the Exp list. Nested patterns
( C<yada(blah(.+)blurble(x|y|zz(top.*))> ) will not work as expected.

Qs_fixed and Qs_var are used to generate a query string.

=item B<Qs_fixed> contains the name value pairs that are known at compile time whereas

=item B<Qs_var> contains placeholders for values that are not known until run time.

=back

In both cases, the format of these fields is a reference to an array containing alternating CGI
variable names and values eg \(name1, v1, name2, v2, ...) produces a query string name1=v1&name2=v2&..

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the check of the web transaction was a success.
I<false> is a zero (0).

=over 4

=item check( CGI_VALUES, OPTIONS )

Performs a check of the Web transaction by getting the sequence or URLs specified in 
the constructor argument.

<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options other than those specified by the super class are

B<timeout> specifies a timeout different to the default (10 seconds) for each URL. When a URL B<canno>t be fetched,
it is recorded as having taken B<10> (ten) seconds.

B<fail_ratio_percent> specifies that the check will return immediately (with a failure) if the proportion of failures
(ie if HTTP::Response::is_success says it is or a timeout) as a percentage, is greater than this threshold.
eg if fail_ratio_percent is 100, fetching all the URls must fail before the check returns false.

B<verbose> is meant for CLI use (or in a CGI). It reports the time taken for each URL on standard B<error>.

B<download_images> is meant for CLI use (or in a CGI). It reports the time taken to download each of the images found
in the page provided that image has not been downloaded by the Nagios::WebTransact object session. Download time is
displayed on standard B<error>.

check returns a boolean indication of success and a reference to an array containing the time taken for each URL.
If a URL cannot be download (invalid content, HTTP failure or timeout), the time is marked as 10. 

=back



=head1 EXAMPLE

see check_inter_perf.pl in t directory.

=head1 BUGS

=over 4

=item 1 Timeout is B<approximate> and applies independently to image download and HTML - if you ask for S<image download>,
the timeout is applied to the images and the HTML separately effectively doubling the timeout. 

=item 2 A more flexible approach may be for this module to decorate the super class,

=item 3 Having to supply the list of URLs to the constructor is strange.

=back

=head1 AUTHOR

S Hopcroft, Stanley.Hopcroft@IPAustralia.Gov.AU

=head1 SEE ALSO

  perl(1).
  Nagios::WebTransact
  Nagios   http://www.Nagios.ORG

=cut
