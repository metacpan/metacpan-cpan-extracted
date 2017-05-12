use strict;
use warnings;
use Test::More tests => 4;

eval q{
  use PlugAuth::Client::Tiny;
};

my $last_url;

my $client = PlugAuth::Client::Tiny->new;

ok eval { $client->auth('primus', 'spark') }, 'auth ok primus:spark';
diag $@ if $@;

is $last_url, 'http://localhost:3000/auth', 'url = http://localhost:3000/auth';
undef $last_url;

ok eval { !$client->auth('bogus', 'bogus') }, 'auth not ok bogus:bogus';
diag $@ if $@;

is $last_url, 'http://localhost:3000/auth', 'url = http://localhost:3000/auth';

package HTTP::Tiny;

BEGIN { $INC{'HTTP/Tiny.pm'} = __PACKAGE__ };

sub new { bless {}, 'HTTP::Tiny' }

sub get 
{
  my($self, $url, $options) = @_;
  $last_url = $url;
  if($options->{headers}->{Authorization} =~ /^Basic (.*)$/)
  {
    my($user,$pass) = split /:/, decode_base64($1);
    if($user eq 'primus' && $pass eq 'spark')
    {
      return { status => 200 };
    }
    else
    {
      return { status => 403 };
    }
  }
  else
  {
    return { status => 401 };
  }
}

# implementation of decode_base64 borrowed from 
# MIME::Base64::Perl and placed in-line here to
# avoid dep.

sub decode_base64 ($)
{
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]
    use integer;

    my $str = shift;
    $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
    if (length($str) % 4) {
        #require Carp;
        #Carp::carp("Length of base64 data not a multiple of 4")
        warn "Length of base64 data not a multiple of 4";
    }
    $str =~ s/=+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    return "" unless length $str;

    ## I guess this could be written as
    #return unpack("u", join('', map( chr(32 + length($_)*3/4) . $_,
    #                   $str =~ /(.{1,60})/gs) ) );
    ## but I do not like that...
    my $uustr = '';
    my ($i, $l);
    $l = length($str) - 60;
    for ($i = 0; $i <= $l; $i += 60) {
        $uustr .= "M" . substr($str, $i, 60);
    }
    $str = substr($str, $i);
    # and any leftover chars
    if ($str ne "") {
        $uustr .= chr(32 + length($str)*3/4) . $str;
    }
    return unpack ("u", $uustr);
}

