package Qualys;


use LWP::UserAgent;
use HTTP::Request;
use vars qw(@ISA $VERSION);

@ISA = qw(LWP::UserAgent);
$VERSION = 0.05;

use constant SERVER => 'qualysapi.qualys.com';
use constant API_PATH => '/msp/';
use constant CONNECTION => 'https://';

sub new {
my ($class,$self) = shift;
  $self = LWP::UserAgent->new(@_);
  $class        = ref($class) || $class;
  $self->{QUALYS_SERVER} = SERVER;
  $self->{QUALYS_URI} = CONNECTION.SERVER.API_PATH;

  bless ($self,$class);
  return $self;
}

# Dealing with API attributes
#AUTOLOAD will dynamically generate the attribute functions when called

sub AUTOLOAD {

  (my $attr = our $AUTOLOAD) =~ s{^.*::}{};
   warn __PACKAGE__.': ->'.$attr.'() method not defined!' && return unless $attr =~ /[^A-Z]/;  # skip DESTROY and all-cap methods
   
   *$AUTOLOAD = sub {
   	my $self = shift;
   	$self->{QUALYS_ATTRIBUTES}{lc $attr} = shift if(@_);
        return $self->{QUALYS_ATTRIBUTES}{lc $attr};
   };

   goto &$AUTOLOAD;
   
}


sub attribs {
  my $self = shift;
  my $attr = shift; #hashref

  while(my($att,$val) = each (%$attr))
    {$self->{QUALYS_ATTRIBUTES}{lc($att)} = $val;}

    $self->{QUALYS_ATTRIBUTES};
}

sub clear_attribs {  $_[0]->{QUALYS_ATTRIBUTES} = {};}

sub connect_to {
  my $self = shift;
  my $script = shift;
  my @all_opts = ();
  my $attribs = $self->{QUALYS_ATTRIBUTES};
  
  if( index(lc($script),'.php') < 1)
    {warn "Script name must end in '.php' not $script";}
  

  while(my($k,$v) = each (%$attribs) ) {push @all_opts, $k.'='.$v;}
  
  {
    my $api_url = $self->api_path().$script.'?'.(join '&',@all_opts);
    my $request = HTTP::Request->new(GET => $api_url);
    $self->pr_status("URI = $api_url") if($self->debug);
    my $response = $self->request($request);
    
    $response->is_success or die "$api_url: ",$response->message,"\n";
    return $response->content;
    
  }#scope block


}



sub api_path {return $_[0]->{QUALYS_URI}    = $_[1] ? $_[1] : $_[0]->{QUALYS_URI};}
sub server   {return $_[0]->{QUALYS_SERVER} = $_[1] ? $_[1] : $_[0]->{QUALYS_SERVER};}
sub userid   {return $_[0]->{QUALYS_USER}   = $_[1] ? $_[1] : $_[0]->{QUALYS_USER};}
sub passwd   {return $_[0]->{QUALYS_PASS}   = $_[1] ? $_[1] : $_[0]->{QUALYS_PASS};}

sub get_basic_credentials {
    my $self = shift;
    my $realm = shift;
    $self->pr_status("Basic Authentication: '$realm'") if($self->debug);
    if($self->{QUALYS_USER} eq ''){$self->pr_status("No QualysAPI username provided");}
    if($self->{QUALYS_PASS} eq ''){$self->pr_status("No QualysAPI password provided");}

    return ($self->{QUALYS_USER},$self->{QUALYS_PASS});

}

1;

__END__
=pod


=head1 NAME

Qualys - connect to the Qualys scanner API with perl

=head1 SYNOPSIS

  use Qualys;
  
  $q = new Qualys;
  
  $q->userid($username);
  $q->passwd($password);
  
  $q->ip('{ip1,ip2}');
  $q->iscanner_name('my_qualys_scanner');
  #.... and so on
  
  #or set multiple attributes
  $q->attribs({
  save_report => 'yes',
  specific_vuln => $number
  #.. any other attributes you'd like
  });
  
  $script = 'scan.php';
  $xml_data = $q->connect_to($script); #scanning takes a while

  #now just process the XML data in $xml_data as you wish
  #maybe use XML::Twig

Again, see the L<http://www.qualys.com/docs/QualysGuard_API_User_Guide.pdf> for all the other
functions and attributes that you can use.

=head1 DESCRIPTION

This module is a wrapper for connecting and using the QualysGuard API for all Qualys partners. It
will take care of authentication and creating the correct uri based on the options provided and
the selected API script.

Using the Qualys (specifically QualysGuard) API one can integrate QualysGuard into
individual appplications using perl. The QualysGuard partners can access security auditing, network discovery, preferences,
remediation ticket updates, and user enrollment functions using this interface.

=head1 METHODS

The Qualys module inherits the LWP::UserAgent module in order to provide a specific
authentication function for get_basic_credentials(). Most likely, you are using this module because you own some Qualys scanners. Therefore,
please go through all the Qualys documentation, specifically L<http://www.qualys.com/docs/QualysGuard_API_User_Guide.pdf>.

=over 4

=item B<userid($username)>

Sets the username to use when authenticating to the QualysGuard API.

=item B<passwd($password)>

Sets the password to use when authenticating to the QualysGuard API.

=item B<server($host)>

Sets the Qualys API host. The default value is L<qualysapi.qualys.com> and it
should probably be this unless it is changed in a future release.

=item B<api_path($https_path)>

Sets the URI to the API. Please note a url should be given with the https. This is to
ensure that if the URL ever changes in the future, this module is still adaptable.
The default path is set to: C<https://qualysapi.qualys.com/msp/>.

=item B<attribs($hashref)>

Sets the attributes that will be given to the API script. Example,

 $q_api->attribs({
  iscanner_name => 'qualys_scanner_name',
  save_report => 'yes',
  ref => '{referenceCode}',
  domain => 'mycompany.com:192.168.0.1-192.168.0.25',
  ... whatever your heart desires ...

 });
 
=item B<clear_attribs()>

Clears all the attributes saved so far using set_attribs().

=item B<connect_to($script)>

Connects to the API and executes the specific script name (usually a php script) with
the given attributes (see set_attrib()) and returns the xml response from the server.
Depending on the script executed, this can take from seconds to minutes.

=back 4

=head1 ADVANCED PROGRAMMERS

For some advanced programmers that know what they are doing, I have written a fancy version C<AUTOLOAD()> that
automatically creates and sets the corresponding attributes -- this is in order to support all possible attributes.
Therefore, you can use any attributes mentioned in the Qualys API documentation, to set the attributes that will be used
when you connect to the API script.

 $qapi->asset_groups('ThisIsMyGroup'); #sets asset_groups to ThisIsMyGroup
 $qapi->loadbalancer('no'); #sets loadbalancer attribute to 'no'
 $qapi->ip('{192.168.0.1,192.168.0.2}'); #sets ip attribute to {192.168.0.1,192.168.0.2}
 .. and so on ...
 
I mention this is for advanced users, because doing this is a short cut to using set_attribs() - and therefore
watch mispellings.

=head1 SEE ALSO

L<XML::Twig>,
The Qualys Scanner website: L<http://www.qualys.com>. For all the QualysGuard API information see
L<http://www.qualys.com/docs/QualysGuard_API_User_Guide.pdf>

=head1 AUTHOR

Anthony G Persaud E<lt>apersaud@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

QualysGuard is a registered trademark of Qualys, Inc. Qualys and the Qualys logo are trademarks of
Qualys, Inc. All other trademarks are the property of their respective owners.

=cut
