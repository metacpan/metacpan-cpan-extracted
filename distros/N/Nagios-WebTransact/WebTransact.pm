package Nagios::WebTransact;

use strict;
use vars qw($VERSION) ;

$VERSION = '0.16';

use HTTP::Request::Common qw(GET POST HEAD) ;
use HTTP::Cookies ;
use LWP::UserAgent ;

use Carp ;

use constant FALSE	=> 0 ;
use constant TRUE	=> ! FALSE ;
use constant FAIL	=> FALSE ;
use constant OK		=> TRUE ;	# ie Normal Perl semantics. 'Success' is TRUE (1).
					# Caller must map this to Unix/Nagios return codes.

use constant Field_Refs	=> { Method	=> { is_ref => FALSE,	type => '' },
                             Url	=> { is_ref => FALSE,	type => '' },
                             Qs_var	=> { is_ref => TRUE,	type => 'ARRAY' },
                             Qs_fixed	=> { is_ref => TRUE,	type => 'ARRAY' },
                             Exp	=> { is_ref => FALSE,	type => 'ARRAY' },
                             Exp_Fault	=> { is_ref => FALSE,	type => '' },
			    } ;

use constant AGENT	=> 'Mozilla/4.7' ;

sub new {
  my ($obj, $urls_ar) = @_ ;

  # $urls_ar is a ref to a list of hashes (representing a request record) in a partic format.

  # If a hash is __not__ in that format it's much better to croak since it is
  # hard to interpret 'not an array ref' messages (from check::make_req) caused
  # by mis spelled or mistaken field names.

  &outahere( $urls_ar, 'URL list is not an array reference.' ) if ref $urls_ar ne 'ARRAY' ;
  my @urls = @$urls_ar ;

  foreach my $url ( @urls ) {
    &outahere( $url, 'Request record is not a hash.' ) if ref $url ne 'HASH' ;
    my @keys = keys %$url ; 
    foreach my $key ( @keys ) {
      if ( ! exists Field_Refs->{$key} ) {
        warn "Expected keys: ", join " ", keys %{ (Field_Refs) } ;
        &outahere( $url, "Unexpected key \"$key\" in record." ) ;
      }
      my $ref_type = '' ;
      if ( ($ref_type = ref $url->{$key}) && ( $ref_type ne Field_Refs->{$key}{type} ) ) {
        warn "Expected key \"$key\" to be ", Field_Refs->{$key}{type} ? Field_Refs->{$key}{type} . ' ref' : 'non ref', "\n" ;
        &outahere( $url, "Field \"$key\" has wrong reference type" ) ;
      }
      if ( ! ref $url->{$key}  and Field_Refs->{$key}{is_ref} ) {
        warn "Expected key \"$key\" to be ", Field_Refs->{$key}{type} ? Field_Refs->{$key}{type} . ' ref' : 'non ref', "\n" ;
        &outahere( $url, "Key \"$key\" not a  reference" ) ;
      }
    }
  }      

  my $class = ref($obj) || $obj ;

  my $accessor_stash_slot = $class . '::' . 'get_urls' ;

  no strict 'refs' ;
  unless ( ref *$accessor_stash_slot{CODE} eq 'CODE' ) {
    foreach my $accessor ( qw(urls matches) ) {
      my $full_name = $class . '::' . $accessor ;
      *{$full_name} = sub { my $self = shift @_ ;
                               $self->{$accessor} = shift @_ if @_ ;
  			     $self->{$accessor}
  			} ;
      foreach my $acc_pre (qw(get set)) {
        $full_name = $class . '::' . $acc_pre . '_' . $accessor ;
        *{$full_name} = $acc_pre eq 'get' ? sub { my $self = shift @_; $self->{$accessor} } :
  					  sub { my $self = shift @_; $self->{$accessor} = shift @_ } ;
      }
    }
  }


  bless { urls => $urls_ar, matches => [], number_of_images_downloaded => 0 }, $class ;

					# The field urls contains a ref to a list of (hashes)
					# records representing the web transaction.

					# self->my_match() will update $self->{matches} ;
					# with the set of matches it finds by matching 
					# patterns with memory (ie patterns in paren) from
					# the  Exp field against the request response.
					# An array ref to the array containing the matches is 
					# stored in the field 'matches'.

					# Qs_var = [ form_name_1 => 0, form_name_2 => 1 ..]
					# will lead to a query_string like
					# form_name_1=$matches[0] form_name_2=$matches[1] ..
					# in $self->make_req() by
					# @matches = $self->matches(); and using 0, 1 etc as indices
					# of @matches.

  # XXX FIXME
  # Construct the useragent object and cache it so that the check method can reuse it for
  # multiple lists of URLs

}

sub check {
  my ($self, $cgi_parm_vals_hr) = @_ ;

  my %defaults = ( cookies	=> TRUE,
		   debug	=> TRUE,
		   timeout	=> 30,
		   agent	=> AGENT,
		   proxy	=> {},
		   download_images => FALSE,
		   indent_level => 0,
                   fail_if_1	=> TRUE ) ;

					# check semantics.
					# $fail_if_1  	?	return FAIL if any URL fails
					# ! $fail_if_1	?	return FAIL if all URLs fail
					#                       (same as return OK if any URL ok)

  my %parms = (%defaults, @_) ;
					# remaining (minus first 2) elts in @_ are the check params such as debug
  my (%downloaded, $ua, $debug, $ok, $indent_level, $resp_string, $res) ; 

  keys %downloaded = 128 ;

  $debug = $parms{debug} ;
  $ok = $parms{fail_if_1} ? TRUE : FALSE ; 
  $indent_level = $parms{indent_level} ;

  unless ( exists $self->{ua} ) { 
    $ua = new LWP::UserAgent ;
    $ua->agent($parms{agent}) ;
    $ua->timeout($parms{timeout}) ;
    $ua->cookie_jar(HTTP::Cookies->new)
      if $parms{cookies} ;
    $ua->proxy(['http', 'ftp'] => $parms{proxy}{server})
      if exists $parms{proxy}{server} ;
  
    $self->{ua} = $ua ;
  } else {
    $ua = $self->{ua} ;
  }

  foreach my $url_r ( @{ $self->{urls} } ) {

    my $url =  $url_r->{Url} ? $url_r->{Url} : &next_url($res, $resp_string) ;
  
    my $req = $self->make_req( $url_r->{Method}, $url, $url_r->{Qs_var}, $url_r->{Qs_fixed}, $cgi_parm_vals_hr ) ;

    $req->proxy_authorization_basic( $parms{proxy}{account}, $parms{proxy}{pass} ) if exists $parms{proxy}{account} ;

    print STDERR '   ' x $indent_level, '... ', $req->as_string, "\n" if $debug ;
   
    $res = $ua->request($req) ;
  
    print STDERR '   ' x $indent_level, '... ', $res->as_string, "\n" if $debug ;
 
    if ( $parms{fail_if_1} ) { 
      unless ( $res->is_success or $res->is_redirect) {
        $resp_string = $res->as_string ;
        $resp_string =~ s#'#_#g ;
						# Deal with __Can't__ from LWP. 
						# Otherwise notification fails because /bin/sh is called to
						# printf '$OUTPUT' and sh cannot deal with nested quotes (eg Can't echo ''')

        return (FAIL, &error_message( $req->method . ' ' . $req->uri, 'Transaction failed: other than HTTP 200. ', $resp_string )) ;
      }
    } else {
      $ok = TRUE if $res->is_success ;
    }
  
    $resp_string = $res->as_string ;
  
  						# Check that the response is what we expect.

    if ( $self->my_match( $url_r->{Exp_Fault}, $resp_string) ) {
      my $fault_ind = $url_r->{Exp_Fault} ;
      my ($bad_stuff) = $resp_string =~ /($fault_ind.*\n.*\n)/ ;
						# Do not want to pick up any HTML with the fault indication.
      return (FAIL, &error_message( $req->method . ' ' . $req->uri, 'Transaction failed: fault indication in response. ', $bad_stuff )) ;
    } elsif ( ! $self->my_match( $url_r->{Exp}, $resp_string) ) {
      my $exp_type = ref $url_r->{Exp} ;
      my $exp_str = $exp_type eq 'ARRAY' ? "@{$url_r->{Exp}}" : $url_r->{Exp} ;
      return(FAIL, &error_message( $req->method . ' ' . $req->uri, " Transaction failed: \"$exp_str\" not in response. ", $resp_string )) ;
    }


    if ( $parms{download_images} ) {
      my ($image_dl_ok, $image_dl_msg, $number_imgs_dl ) = &download_images($res, \%parms, \%downloaded) ;
      return (FAIL, $image_dl_msg) unless $image_dl_ok ;
      $self->{number_of_images_downloaded} += $number_imgs_dl ;
    }

  }

  my $trx_ok = $parms{download_images} ? "Transaction completed Ok - downloaded $self->{number_of_images_downloaded} images." : 'Transaction completed Ok.' ;
  return ($ok, $ok ? $trx_ok : 'Transaction failed.') ;
}
  
sub error_message {
  my ($req_string, $message, $resp_string) = @_ ;

  my $failure_message = "\"$req_string\" $message $resp_string" ;
  # my $failure_message = "++ $req_string: $message $resp_string" ;
  $failure_message =~ s/\n/ /g ;		# GOTCHA
						# return here with the number of "\n" chars substituted !
  return $failure_message ;
}

sub make_req {
  my ($self, $method, $url, $qs_var_ar, $qs_fixed_ar, $name_vals_hr) = @_ ;

						# $qs_var_ar is an array reference containing
						# the name value pairs of any parameters whose
						# value is known only at run time

						# the format of $qs_var_ar is 
						# [cgi_parm_name => val, cg_parm_name => val ..]
						# where cgi_parm_name is the name of a fill out
						# form parameter and val is a string used as a
						# key in %$name_vals_hr to get the value of the
						# cgi_parameter.

						# eg [p_tm_number, tmno] has the parameter name
						# 'p_tm_number' and val 'tmno'.

						# If $name_vals_hr = { tmno = > 1 },
						# the query_sring becomes p_tm_number=1

						# when the val is a digit, that digit is
						# interpreted as a relative match in the last
						# set of matches found by ->my_match eg

						# [p_tm_number => 1] means get the 
						# second match (from the last set of matches)
						# and use it as the value of p_tm_number.

						# If the value is a array ref eg
						# [p_tm_number, [0, sub { $_[0] . 'Blah' }]
						# then the query_string becomes
						# p_tm_number => $ar->[1]( $name_vals{$ar->[0]} )

						# qs_fixed is an array_ref containing name
						# value pairs


  my ($req, @query_string, $query_string, @qs_var, @qs_fixed, %name_vals, @nvp) ;

  my @matches = @{ $self->matches() } ;

  @qs_var = @$qs_var_ar ;
  @qs_fixed = @$qs_fixed_ar ;
  %name_vals = %$name_vals_hr ;
  @name_vals{0 .. $#matches} = @matches ; 	# add the matches as (over the top if some of the
						# name_val keys are eq '0', '1' ..) keys to  %name_vals
  @query_string = () ;
  @nvp = () ;
  $query_string = '' ;

  while ( my ($name, $val) = splice(@qs_fixed, 0, 2) ) {
    splice(@query_string, scalar @query_string, 0, ($name, $val)) ;
  }
						# a cgi var name must be in qs_var for it's value to
						# be changed (otherwise it doesn't get in the form
						# query string)

  while ( my ($name, $val) = splice(@qs_var, 0, 2) ) {

    @nvp = ref $val eq 'ARRAY' ? ( $name, &{ $val->[1] }($name_vals{$val->[0]}) ) :
                                 ( $name, $name_vals{$val} ) ;

    splice(@query_string, scalar @query_string, 0, @nvp) ;
  }

  if ( $method eq 'GET' ) {
    while ( my ($name, $val) = splice(@query_string, 0, 2) ) {
      $query_string .= "$name=$val&" ;
    }
    if ($query_string) {
      chop($query_string) ;
      $req = GET $url .  '?' . $query_string ;
						# Referer header seemingly not necessary
      # $req = GET $url .  '?' . $query_string, Referer => $self->{urls}[0]{Url} ;
    } else {
      $req = GET $url ;
    }

  } elsif ( $method eq 'POST' ) {
      $req = POST $url, [ @query_string ] ;
  } elsif ( $method eq 'HEAD' ) {
      $req = HEAD $url ;
  } else {
    # do something to indicate no such method
    outahere( $self, "Unexpected method \"$method\" for url \"$url\"" ) ;
  }
}

sub next_url {
  my ($resp, $resp_string) = @_ ;


						# FIXME. Some applications (eg IIS module for
						# SAP R3) have an action field relative to
						# hostname.
						# Others (eg ADDS v2) use a refresh header
						# relative to hostname/path ..

  if ( $resp_string =~ m#META\s+http-equiv="refresh"\s+content="\d+;\s+url=([^"]+)"# ) {
    my $rel_url = $1 ;
    my  $base = $resp->base ;
    $base =~ m#(http://.+/).+?$# ;
    my $url =  $1 . $rel_url ;
    return $url ;
  }
  elsif ( $resp_string =~ m#form name="[^"]+"\s+method="post"\s+action="([^"]+)"#i or
	  $resp_string =~ m#form\s+method="post"\s+action="([^"]+)"#i )  {
						# Attachmate eVWP product doesn't have a form name.
    my $rel_url = $1 ;
    my  $base = $resp->base ;
    $base =~ m#(http://.+?)/# ;			# only want hostname
    my $url =  $1 . $rel_url ;
    return $url ;
  }
  else {
    return '' ;
  }

}

sub my_match {
  my ($self, $pat, $str) = @_ ;

  my $found = 0 ;
  my @matches = () ;


  if ( ref $pat eq 'ARRAY') {
    # foreach my $m (map { $str =~ m#$_#s; defined $1 ? $1 : '' } @$pat) {
    foreach my $p (@$pat) {

      if ( $str =~ m#$p# ) {
    
						# matches are expected to save whatever they want with
						# parentheses eg (\w+).

						# the string that matches each pattern (and is saved in $1)
						# is stored in the object as $self->{matches}[0], [1], ..
        					# If a pattern fails to match then the corresp match is ''.
        push @matches, $1 unless not defined $1 ;
        $found++ ;
      }
    }
    $self->matches(\@matches) ;

  } else {
    $found = ($str =~ m#$pat#) ;
    # $found = ($str =~ /$pat/o) ;		# Don't use /o because the pattern will be set to the
						# first value (and will never change).
  }

  return $found ;

}

sub outahere {
  my ($dumpit, $message) = @_ ;

  require Dumpvalue ;

  my $dumper = new Dumpvalue ;			# dump is a poorly chosen variable name
						# since it is also a Perl verb with a dramatic
						# effect
  $dumper->dumpValue($dumpit) ;
  croak $message ;

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
  if ( my $number_of_images_not_already_downloaded = scalar @img_urls ) {
    my $img_trx = __PACKAGE__->new(\@img_urls) ;
    my %image_dl_parms = (%$parms_hr, fail_if_1 => FALSE, download_images => FALSE, indent_level => 1) ; 
    return ( $img_trx->check( {}, %image_dl_parms), $number_of_images_not_already_downloaded ) ;
  } else {
    return (OK, 'Downloaded all __zero__ images found in ' . $res->base, 0) ;
  }
}

1 ;


__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Nagios::WebTransact - Class for generating Nagios service checks of Web transactions.



=head1 SYNOPSIS

    use Nagios::WebTransact();
    
    # Constructors
    $web_trx = Nagios::WebTransact->new(\@url_set);

=head1 DESCRIPTION

This module implements a check of a Web Transaction.

A Web transaction is a sequence of web pages, often fill out forms,
that accomplishes an enquiry or an update. Common examples are database
searches and registration activities.

A Web transaction is specified by

=over 4

=item * a list of URLs where each URL is a page in the transaction

=item * corresponding Query Strings containing the CGI names and value
pairs to post the page

=item * a means of determining from the content, whether a response is
either Ok or a failure.

=back

A new Nagios::WebTransact object must be created with the I<new> method. Once
this has been done, the check of the web transaction is done with the I<check>
method.

=head1 EXAMPLES

This example performs a primitive content check of the ADDS service, getting the page
specified by the Url field, and if there is a response from the web server, comparing
the response to the fields Exp and Exp_Fault.

If the response matches the Exp field the check succeeds; if the response matches the
Exp_Fault field the check fails.

    #!/usr/local/bin/perl -w
    
    use Nagios::WebTransact;
    
    $ar = [ { Method	=> "GET",
              Url	=> "http://Pericles.IPAustralia.Gov.AU/adds2/ADDS.ADDS_START.intro",
	      Qs_var	=> [],
	      Qs_fixed	=> [],
	      Exp	=> "Designs Data Searching - Introduction",
	      Exp_Fault => "We were unable to process your request at this time" } ] ;
    $web_trx = Nagios::WebTransact->new($ar) ;
    ($rc, $message) = $web_trx->check({}, debug => 0, proxy => { Server => 'http://Foo:3128', Account => 'lu$er', Pass => '00##00' } ) ;
    print $rc ? 'Adds Ok: ' : 'Adds b0rked: ', $message ;

This example checks if a complete ATMOSS transaction is successfull by requesting a sequence
of URLs and  checking the content against the Exp and Exp_Fault fields. Where the Qs_fixed and Qs_var fields are non null,
the corresponding Query String is generated for the URL.

For example, the POST request for 'http://Perciles.IPAustralia/atmoss/Falcon.Result' is accompanied by
the query string, S<p_tm_number_list=<current_value_of_arg_hash{'tmno'}>

    #!/usr/local/bin/perl -w
    
    use Nagios::WebTransact;

    my $Proxy = {} ;
    $Proxy = { server => "http://$proxy/" } if $proxy ;
    $Proxy->{account} = $account  if $account ;
    $Proxy->{pass}    = $pass     if $pass ;
    
    my $Intro               = 'http://Pericles.IPAustralia.Gov.AU/atmoss/falcon.application_start' ;
    my $MultiSessConn       = 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Users_Cookies.Run_Create' ;
    my $Search              = 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon.Result' ;
    my $ResultDetails       = 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Details.Show_TM_Details' ;
    my $SrchList            = 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Searches.List_Search' ;
    my $DelSrchLists        = 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Searches.SubmitChoice' ;
    my $EndSession          = 'http://Pericles.IPAustralia.Gov.AU/atmoss/Falcon_Users_Cookies.clear_User' ;
    
    my $Int                 = 'Welcome to ATMOSS' ;
    my $ConnSrch            = 'Connect to Trade Mark Search' ;
    my $MltiSess            = 'Fill in one or more of the fields below' ;
    my $Srch                = 'Your search request retrieved\s+\d+\s+match(es)?' ;
    my $ResSum              = 'Trade Mark\s+:\s+\d+' ;
    my $ResDet              = 'Indexing Details' ;
    my $SrchLs              = 'Search List' ;
    
    my $MSC_f               = [p_Anon => 'ANONYMOUS', p_user_type => 'Enter as Guest', p_JS => 'N'] ;
    
    my $Srch_v              = [p_tm_number_list => 'tmno'] ;
    
    my $RD_v                = [p_tm_number => 'tmno'] ;
    my $RD_f                = [p_Detail => 'DETAILED', p_search_no => 0];
    my $DAS_f               = [p_CmbDelete => 1, p_Button => 'Delete All Searches', p_extID => 'ANONYMOUS', p_password => '', p_CmbDisplay => 1, 
                               p_CmbRefine => 1, p_CmbCombine1 => 1, p_CmbCombineOperator => 'INTERSECT', p_CmbCombine2 => 1, p_search_used => 0 ] ;
    
    my $OraFault            = 'We were unable to process your request at this time' ;
    
    my @URLS                = (
      {Method => 'GET',  Url => $Intro,           Qs_var => [],     Qs_fixed => [],    Exp => $Int,     Exp_Fault => $OraFault},
      {Method => 'POST', Url => $MultiSessConn,   Qs_var => [],     Qs_fixed => $MSC_f,Exp => $MltiSess,Exp_Fault => $OraFault},
      {Method => 'POST', Url => $Search,          Qs_var => $Srch_v,Qs_fixed => [],    Exp => $ResSum,  Exp_Fault => $OraFault},
      {Method => 'GET',  Url => $ResultDetails,   Qs_var => $RD_v,  Qs_fixed => $RD_f, Exp => $ResDet,  Exp_Fault => $OraFault},
      {Method => 'GET',  Url => $SrchList,        Qs_var => [],     Qs_fixed => [],    Exp => $SrchLs,  Exp_Fault => $OraFault},
      {Method => 'POST', Url => $DelSrchLists,    Qs_var => [],     Qs_fixed => $DAS_f,Exp => $MltiSess,Exp_Fault => $OraFault},
      {Method => 'GET',  Url => $EndSession,      Qs_var => [],     Qs_fixed => [],    Exp => $Int,     Exp_Fault => $OraFault},
            ) ;
    
    my (@tmarks, $tmno, $i) ;
    
    @tmarks = @ARGV ? @ARGV : (3, 100092, 200099, 300006, 400075, 500067, 600076, 700066, 800061) ;
    $i = @ARGV == 1 ? 0 : int( rand($#tmarks) + 0.5 ) ;
    $tmno = $tmarks[$i] ;
    
    my $x = Nagios::WebTransact->new( \@URLS ) ;
    my ($rc, $message) =  $x->check( {tmno => $tmno}, debug => $debug, proxy => $Proxy, download_images => $download_images ) ;
    
    print $rc ? 'ATMOSS Ok. ' : 'ATMOSS b0rked: ', $message, "\n" ; 


Complete examples can be found in the t/ directory of the distribution.


=head1 CONSTRUCTOR

=over 4

=item Nagios::WebTransact->new(ref_to_array_of_hash_refs)

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

In both cases, the format of these fields is a reference to an array containing alternating CGI
variable names and values eg \(name1, v1, name2, v2, ...) produces a query string name1=v1&name2=v2&..

Qs_var allows values to be specified in three ways :-

  . a string that will be used as a key in the hash of arguments passed to
    the check method.

  . a positive integer (0, 1, ...)

In the latter case, the integer will be used as an index of the array of matches found from the
last set of patterns with memory (specified by the Exp field). So [ cgi_var_name => 0 ] leads to
a query string cgi_var_name=<the_first_match_in_the_set_of_Exp_patterns>

 . an array ref of the form [ match_index => code_ref ]

In this case, the subroutine referred to by coderef is a subroutine with one parameter and it will be
called with that parameter set to the first element in the array (the index of a former match).
One may choose to do this with very dynamic web systems such as the SAP R3 module for IIS in which the
CGI names and values may need to be dragged out of former responses.

An example may make this more comprehensible !

    use constant CmrDetailPat       => [ qw(
            name="addr1_data-name1\[1\]"\s+value="(.*?)"
        ) ] ;

    use constant Stars              => '*' x 8 ;
    my $star_pat = quotemeta( Stars ) . '$';
    use constant AddStars_to_Name   => [ 'addr1_data-name1[1]' => [0, sub { $_[0] . Stars }] ] ;
    use constant DelStars_from_Name => [ 'addr1_data-name1[1]' => [0, sub { $_[0] =~ s#$star_pat##; $_[0] }] ] ;

If 'CmrDetailPat' is used as an Exp field, then a subsequent GET or POST can make use of
Qs_var values 'AddStars_to_Name' and 'DelStars_from_Name' to either append some asterisks to the value of the
web form name addr1_data-name1[1] or remove the stars.

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the check of the web transaction was a success.
I<false> is a zero (0).

=over 4

=item check( CGI_VALUES, OPTIONS )

Performs a check of the Web transaction by getting the sequence or URLs specified in 
the constructor argument.

<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<debug> writes the string form of the request (including query_string) and the response
to STDERR.

B<proxy> is a reference to a hash like { Server => 'http://ProxyServer:Port/',
Account => account_on_proxy_server, Pass => identity_token }

B<fail_if_1> if set (the default) causes the check to fail when the first
web page fails. Clearing this flag is useful if you want to get a bunch of
pages and return a failure if they B<all> fail.

B<timeout> the default wait time for a response - to a request for B<one> page - is 30 seconds.

B<download_images> get the images found by HTML::LinkExtor in the page, provided those
images have not already been fetched.

B<agent> the default value of the User-Agent field in the HTTP request is Mozilla/4.7.

B<CGI_VALUES> is a reference to a hash whose keys are the values used in the
Qs_var lists. This allows the check method to get the value of these 
variables at run time (useful if you want to generate web parameters in
your program, using a random number generator for example [vs]).

This hash ref is B<required> and must be set to {} if there are B<no> variables.

=item matches([ match1, match2, ..])

Accessor to set or get the value of the matches field.

=item urls([ ( { Method => , Url => , Qs_var => , Qs_fixed, Exp => , Exp_Fault => } .. ) ])

Accessor to get or set or the urls field. Useful for changing the set of pages to be checked for
a subsequent conditional check (eg if first transaction, do a second with this set of pages).

Optional argument is a ref to a list of hashes like that used by the constructor.

=item set_urls, get_urls

Synonym for urls method.

=item set_matches, get_matches

Synonym for matches method.

=back

=head1 BUGS

=item * B<you> must identify the URLs and the query strings required by the transaction using tools like ethereal or
by examining the HTML source of the forms.

=item * All fields are mandatory (can't neglect Exp_Fault for example).

=item * Failing to use the correct format for the URL list can return
hard to understand errors (eg not an array reference at line ..)

=item * Timeout is B<per> page and not for the overall transaction. Further, the timeout for 
image download is applied independently of the HTML. This effectively doubles the time allowed for
the transaction to complete.

=item * All of the keys (field names) are case sensitive.

=item * patterns in Exp cannot be nested. 

=item * There can only be one pattern in each element of Exp ie
match me (.*) and me (.*) and don't forget me (.*) does not save three strings.

=head1 AUTHOR

S Hopcroft, Stanley.Hopcroft@IPAustralia.Gov.AU

=head1 SEE ALSO

  WWW::Automate
  WWW::Mechanize

  perl(1).
  Nagios http://www.Nagios.ORG

