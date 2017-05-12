# Aug 27 2012
# reddit interface
package Net::Reddit;
our $VERSION = '1.2';
use Moose;
use Data::Dumper;
use Net::SSL (); # From Crypt-SSLeay
use LWP::UserAgent;
use HTTP::Cookies;
use JSON qw( decode_json ); 
use DeathByCaptcha::SocketClient;


$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL for proxy compatibility

{
has 'username', is => 'rw', isa => 'Str',default => '';	
has 'password', is => 'rw', isa => 'Str',default => '';	
has 'cookie', is => 'rw', isa => 'Str',default => '';	
has 'modhash', is => 'rw', isa => 'Str',default => '';	

has 'Captcha_username', is => 'rw', isa => 'Str',default => '';	
has 'Captcha_pass', is => 'rw', isa => 'Str',default => '';	

has proxy_host      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_port      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_user      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_pass      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_env      => ( isa => 'Str', is => 'rw', default => '' );
has browser  => ( isa => 'Object', is => 'rw', lazy => 1, builder => '_build_browser' );

##### login #######       
sub login
{
my $self = shift;


my $username = $self->username;
my $password = $self->password;


my $post_data = {'user' => $username, 
				'passwd' => $password, 
				'api_type' => 'json',				
				'op' => 'login'
				};

$self->browser->default_header('Referer' => "http://www.reddit.com/");
$self->browser->default_header('Connection' => 'keep-alive');
$self->browser->default_header('Accept' => 'application/json, text/javascript, */*; q=0.01');
$self->browser->default_header('X-Requested-With' => 'XMLHttpRequest');
$self->browser->default_header('Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8');
$self->browser->default_header('Origin' => 'http://www.reddit.com');


my $response = $self->dispatch(url =>"https://ssl.reddit.com/api/login/".$username,method => 'POST',post_data =>$post_data);									  
my $content = $response->content;
my $decoded_json = decode_json( $content );

my $cookie = $decoded_json->{'json'}{'data'}{'cookie'};
my $modhash = $decoded_json->{'json'}{'data'}{'modhash'};
$self->cookie($cookie);
$self->modhash($modhash);

}

##### post ####### 
sub submit
{	
my $self = shift;
my ($title,$url,$subreddit) = @_;
print "submitting link \n";

my $Captcha_username = $self->Captcha_username;
my $Captcha_pass = $self->Captcha_pass;

my $client = DeathByCaptcha::SocketClient->new($Captcha_username, $Captcha_pass);

POST:
my $response = $self->dispatch(url => "http://www.reddit.com/submit",method => 'GET');
my $content = $response->content;

#open (SALIDA,">reddit.html") || die "ERROR: No puedo abrir el fichero google.html\n";
#print SALIDA $content;
#close (SALIDA);


$content =~ s/name="iden" value=""//g; # delete first match (empty value)
$content =~ /name="iden" value="(.*?)"/;
my $iden = $1; 
print "iden $iden \n";
my $recaptcha_response='';
my $captcha;
if ($iden ne '')
{
  my $captcha_url = "http://www.reddit.com/captcha/".$iden.".png";
  system ("wget $captcha_url --output-document=captcha.png");  
  $captcha = $client->decode('captcha.png',+DeathByCaptcha::Client::DEFAULT_TIMEOUT);  
  print "Solving captcha \n";
  $recaptcha_response=$captcha->{"text"};   
  print "Captcha: $recaptcha_response iden $iden \n"; 
}  

$content =~ /name="uh" value="(.*?)"/;
my $h = $1; 

my $post_data = {'uh' => $h, 
				'title' => $title,
				'kind' => 'link',
				'url' => $url,
				'sr' => $subreddit,
				'iden' => $iden,
				'captcha' => $recaptcha_response,
				'id' => '%23newlink',
				'renderstyle' => 'html'};
								
$self->browser->default_header('Referer' => "http://www.reddit.com/submit");
$self->browser->default_header('Connection' => 'keep-alive');
$self->browser->default_header('X-Requested-With' => 'XMLHttpRequest');
	
$response = $self->dispatch(url => "http://www.reddit.com/api/submit",method => 'POST',post_data =>$post_data);
$content = $response->content;


if($content =~ /care to try these again/m)
{
   print "Captcha failed \n"; 
   $client->report($captcha->{"captcha"});
   goto POST;
}
else
{
  my $response_json = $response->content;
  my $decoded_json = decode_json( $response_json );
  #print Dumper $decoded_json;
  my $url_post = $decoded_json->{'jquery'}[16][3][0];
  
  return $url_post;
}


}    

##### comment in a post ####### 
sub comment
{
my $self = shift;
my ($url,$comment) = @_;

print "comment on $url \n";
my $response = $self->dispatch(url => $url,method => 'GET');
my $content = $response->content;

$content =~ /name="uh" value="(.*?)"/;
my $h = $1; 

$content =~ /thing id-(.*?) odd/;
my $thing_id = $1; 

$content =~ /comment\'\)" id="form(.*?)"><input/;
my $id = "#form".$1; 

$url =~ /r\/(.*?)\/comments/;
my $subreddit = $1; 

#print "id $id \n thing_id $thing_id \n h $h \n  subreddit  $subreddit \n";


my $post_data = {'thing_id' => $thing_id, 
				'text' => $comment,
				'id' => $id,
				'r' => $subreddit,				
				'uh' => $h,
				'renderstyle' => 'html'};
				


$self->browser->default_header('Referer' => "http://www.reddit.com/submit");
$self->browser->default_header('Connection' => 'keep-alive');
$self->browser->default_header('Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8');
$self->browser->default_header('Accept' => 'application/json, text/javascript, */*; q=0.01');
$self->browser->default_header('X-Requested-With' => 'XMLHttpRequest');


	
$response = $self->dispatch(url => "http://www.reddit.com/api/comment",method => 'POST',post_data =>$post_data);
my $status_line = $response->status_line;
#my $content = $response->decoded_content;
#print " content  $content \n";
return $status_line;
}  


##### vote for a post ####### 
sub vote
{
my $self = shift;
my ($url,$dir) = @_;

print "vote for $url \n";
my $response = $self->dispatch(url => $url,method => 'GET');
my $content = $response->content;

#$content =~ /vote\(\'(.*?)\'/;
#my $vh = $1;

$url =~ /r\/(.*?)\/comments/;
my $subreddit = $1; 

$url =~ /comments\/(.*?)\//;
my $id = "t3_".$1; 

$content =~ /name="uh" value="(.*?)"/;
my $h = $1; 

#print "id $id \n subreddit $subreddit \n  h  $h \n  \n";

my $post_data = {'id' => $id, 
				'dir' => $dir,				
				'r' => $subreddit,				
				'uh' => $h,
				'renderstyle' => 'html'};


$self->browser->default_header('Referer' => "http://www.reddit.com");
$self->browser->default_header('Connection' => 'keep-alive');
$self->browser->default_header('X-Requested-With' => 'XMLHttpRequest');

$response = $self->dispatch(url => "http://www.reddit.com/api/vote",method => 'POST',post_data =>$post_data);
my $status_line = $response->status_line;
return $status_line;

}  


###################################### internal functions ###################
sub dispatch {    
my $self = shift;
my %options = @_;

my $url = $options{ url };
my $method = $options{ method };

my $response = '';
if ($method eq 'GET')
  { $response = $self->browser->get($url);}
  
if ($method eq 'POST')
  {     
   my $post_data = $options{ post_data };        
   $response = $self->browser->post($url,$post_data);
  }  
  
if ($method eq 'POST_MULTIPART')
  {    	   
   my $post_data = $options{ post_data };        
   $response = $self->browser->post($url,Content_Type => 'multipart/form-data', Content => $post_data);           
  }   
  
return $response;
}

sub _build_browser {    

print "building browser \n";
my $self = shift;

my $proxy_host = $self->proxy_host;
my $proxy_port = $self->proxy_port;
my $proxy_user = $self->proxy_user;
my $proxy_pass = $self->proxy_pass;
my $proxy_env = $self->proxy_env;


my $browser = LWP::UserAgent->new;
$browser->timeout(20);
$browser->cookie_jar(HTTP::Cookies->new(file => "cookies.txt", autosave => 1));
$browser->show_progress(1);
$browser->default_header('User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:11.0) Gecko/20100101 Firefox/11.0'); 


print "proxy_env $proxy_env \n";

if ( $proxy_env eq 'ENV' )
{
$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
$ENV{HTTPS_PROXY} = "http://".$proxy_host.":".$proxy_port;
}
elsif (($proxy_user ne "") && ($proxy_host ne ""))
{
 $browser->proxy(['http', 'https'], 'http://'.$proxy_user.':'.$proxy_pass.'@'.$proxy_host.':'.$proxy_port); # Using a private proxy
}
elsif ($proxy_host ne "")
   { $browser->proxy(['http', 'https'], 'http://'.$proxy_host.':'.$proxy_port);} # Using a public proxy
 else
   { 
      $browser->env_proxy;} # No proxy       

return $browser;     
}
    
}
1;

__END__

=head1 NAME

Net::Reddit - reddit interface (No API) .


=head1 SYNOPSIS


Usage:

   use Net::Reddit;
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
   my $reddit = Net::Reddit->new( username =>  'Reddit_user' ,
					password => 'Reddit_pass',
					Captcha_username => "deathcaptcha_user",
					Captcha_pass => "deathcaptcha_pass");	                                 
                                 							
You need a valid deathcaptcha account to solve reddit captchas


=head1 DESCRIPTION

reddit interface (No API)

=head1 FUNCTIONS

=head2 constructor

       my $reddit = Net::Reddit->new( username =>  'Reddit_user' ,
					password => 'Reddit_pass',
					Captcha_username => "deathcaptcha_user",
					Captcha_pass => "deathcaptcha_pass!");	

To get your deathcaptcha account

www.deathbycaptcha.com

=head2 login

   $reddit->login;
   
Login to the site. You MUST call this function before to do anything

=head2 submit

    $title = "new title";
    $subreddit = "linux";
    $url = "http://linux.com";
    $url_post = $reddit->submit($title,$url,$subreddit);
    print "url_post $url_post \n";


Submit a url

=head2 comment

    $reddit_url = "http://www.reddit.com/r/linux/comments/XXXXX";
	$comment = "Linux forever ";
	$reddit->comment($reddit_url,$comment);  

Comment a reddit entry

=head2 vote

    $reddit_url = "http://www.reddit.com/r/linux/comments/XXXXX";
    $reddit->vote($reddit_url,1);

Vote for a reddit entry
   
=head2 dispatch

 Internal function         
                  
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
=cut
