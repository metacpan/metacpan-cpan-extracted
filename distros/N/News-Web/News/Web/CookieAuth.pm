$VERSION = "0.4";     
package News::Web::CookieAuth;
our $VERSION = "0.4";

# -*- Perl -*-          # Fri Oct 10 11:29:51 CDT 2003 
#############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>.  Copyright 2003, Tim
# Skirvin.  Redistribution terms are below.
#############################################################################

=head1 NAME

News::Web::CookieAuth - authentication for News::Web via cookies

=head1 SYNOPSIS

  use News::Web::CookieAuth;
  use CGI;
  
  my $cookie = CGI->cookie('nntpauthinfo') || "";
  my $authinfo = News::Web::CookieAuth->new($cookie);

See 'setcookie.cgi' for a fairly comprehensive tutorial.

=head1 DESCRIPTION

This documentation is far from complete.  However, the module itself is
just meant to be glue; if you're using it, you can probably spend some
time and work out how it works.

The cookie itself contains these fields:

  nntpuser	The NNTP user to connect to the server as 
  nntppass	The NNTP password, in clear text (these things are 
		generally passed in cleartext anyway, and so shouldn't
		be considered secure in the first place
  realname	The user's real name (half of the From: heaer)
  emailadd	The user's email address (half of the From: heaer)
  signature 	The user's signature file
  version	Not currently used, but useful if we decide to use
		different versions of the cookie.

=head1 USAGE

=cut

###############################################################################
### main() ####################################################################
###############################################################################

use strict;
use CGI;

use vars qw( %HTMLFIELDS );
%HTMLFIELDS = (
	'nntpuser'	=> [ "NNTP Username", 'text', 30 ],
	'nntppass'	=> [ "NNTP Password", 'password', 30 ],
	'emailadd'	=> [ "Email Address", 'text', 30 ],
	'realname'	=> [ "Real Name", 'text', 30 ],
	'signature'	=> [ "Signature", 'textarea', 4, 80 ],
	'version'	=> [ '', 'hidden'],	# Hidden field
	# Possible other fields for the future - killfile, newsrc, select, 
	#					 scorefile
	  );

=head2 Functions 

=over 4

=item new ( [COOKIE] ) 

Creates the News::Web::CookieAuth object, based on the string C<COOKIE>.
If not passed, then you can later add it with read_cookie().

=cut

sub new {
  my ($proto, $cookie, %other) = @_;
  my $class = ref($proto) || $proto;
  my $self = { 'cookie'	=> $cookie };
  bless $self, $class;
  $self->read_cookie();
}

=item version   ( [DATA] )

=item nntpuser  ( [DATA] )
 
=item nntppass  ( [DATA] )
 
=item realname  ( [DATA] )

=item emailadd  ( [DATA] )

=item signature ( [DATA] )

Reads or manipulates the given field.  If C<DATA> is passed, sets the
field as appropriate; either way, it returns the value of the field.

=cut

sub version   { defined $_[1] ? $_[0]->{version}   = $_[1] 
	 	              : $_[0]->{version}   || 0     } 
sub nntpuser  { defined $_[1] ? $_[0]->{nntpuser}  = $_[1] 
	 	              : $_[0]->{nntpuser}  || 0     } 
sub nntppass  { defined $_[1] ? $_[0]->{nntppass}  = $_[1] 
	 	              : $_[0]->{nntppass}  || 0     } 
sub realname  { defined $_[1] ? $_[0]->{realname}  = $_[1] 
	 	              : $_[0]->{realname}  || 0     } 
sub emailadd  { defined $_[1] ? $_[0]->{emailadd}  = $_[1] 
	 	              : $_[0]->{emailadd}  || 0     } 
sub signature { defined $_[1] ? $_[0]->{signature} = $_[1] 
	 	              : $_[0]->{signature} || 0     } 

=item cookie ()

Returns or manipulates the cookie itself, as above.  Not as good an idea
to do this, since without read_cookie() the other values are not
manipulated.

=cut

sub cookie    { defined $_[1] ? $_[0]->{cookie}    = $_[1] 
	 	              : $_[0]->{cookie}    || 0     } 

=item set ()

=cut

sub set {
  my ($self, $field, $value) = @_;
  delete $self->{lc $field} unless $value;
  $self->{lc $field} = $value;
}

=item value ( FIELD )

Reads the specific C<FIELD>.

=cut

sub value { my ($self, $field) = @_; $self->{lc $field} || ""; }

=item make_cookie ()

=cut

sub make_cookie { 
  my ($self, $cookie) = @_;  $cookie ||= $self->cookie;
  join("::", _escape($self->nntpuser, $self->nntppass, 
		     $self->realname, $self->emailadd,
		     $self->signature, $self->version));
}

=item read_cookie ( [COOKIE] )

Reads the information from C<COOKIE> (defaults to the value of cookie()) 
into the object.  

=cut

sub read_cookie {
  my ($self, $cookie) = @_;  $cookie ||= $self->cookie;
  my ($nntpuser, $nntppass, $realname, $emailadd, $signature, $version) 
	= _unescape(split("::", $cookie));

  $self->nntpuser($nntpuser);   $self->nntppass($nntppass);
  $self->realname($realname);   $self->emailadd($emailadd);
  $self->signature($signature); $self->version($version);

  $self;
}

=item fields ()

Returns a hash of the fields stored in the object.

Returns either either a hashref (when invoked in scalar context) or the
hash itself. 

=cut

sub fields { 
  my ($self) = @_;
  my %return; 
  foreach (keys %HTMLFIELDS) { 
    $return{$_} = @{$HTMLFIELDS{$_}}[0] 
  }
  wantarray ? %return : \%return;
}

=item html ()

=cut

sub html {
  my ($self, $field, $default) = @_;
  return "" unless ($field);
  my ($desc, $type, @args) = @{$HTMLFIELDS{$field}};
  if ($type eq 'text') { 
    CGI->textfield($field, $default || "", @args);
  } elsif ($type eq 'password') { 
    CGI->password_field($field, $default || "", @args);
  } elsif ($type eq 'textarea') { 
    CGI->textarea(-name=>$field, -default=>$default || "",
		  -rows=>$args[0] || 2, -cols=> $args[1] || 80,
		  -wrap=>$args[2] || 'hard');
  } 
}

###############################################################################
### Internal Functions ########################################################
###############################################################################

### _escape ( @_ )
# This is not enough escaping and I know it.  Grr.
sub _escape   { 
  map { $_ =~ s/\\/\\\\/g } @_;
  map { $_ =~ s/::/:\\:/g } @_;
  @_;
}

### _unescape ( @_ )
sub _unescape { 
  map { $_ =~ s/:\\:/::/g } @_;
  map { $_ =~ s/\\\\/\\/g } @_;
  @_;
}

=head1 REQUIREMENTS

B<CGI.pm>

=head1 SEE ALSO

B<CGI.pm>, B<News::Web>

=head1 NOTES

This is hardly the ideal form of authentication; however, it's a lot
simpler to implement generally than a database-backed solution would be.
This doesn't change the fact that I'd rather use the database-backed
solution in the future, though, which is why this module is fairly general
and could be re-implemented as some other class...

=head1 AUTHOR

Tim Skirvin <tskirvin@killfile.org>

=head1 COPYRIGHT

Copyright 2003 by Tim Skirvin <tskirvin@killfile.org>.  This code may be
distributed under the same terms as Perl itself.

=cut

1;

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.3b		Fri Oct 10 16:12:45 CDT 2003 
### First commented version.
# v0.4		Thu Apr 22 14:11:58 CDT 2004 
### Code clean-up.
