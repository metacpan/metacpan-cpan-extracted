package Net::Random;

use strict;
local $^W = 1;
use vars qw($VERSION %randomness);

$VERSION = '2.31';

require LWP::UserAgent;
use Sys::Hostname;
use JSON ();

use Data::Dumper;

my $ua = LWP::UserAgent->new(
  agent   => 'perl-Net-Random/'.$VERSION,
  from  => "userid_$<\@".hostname(),
  timeout => 120,
  keep_alive => 1,
  env_proxy => 1
);

%randomness = (
  'qrng.anu.edu.au' => { pool => [], retrieve => sub {
    my $ssl = shift;
    my $response = $ua->get( 
      ($ssl ? 'https' : 'http') .
      '://qrng.anu.edu.au/API/jsonI.php?length=1024&size=1&type=uint8'
    );
    unless($response->is_success) {
      warn "Net::Random: Error talking to qrng.anu.edu.au\n";
      return ();
    }
    my $content = eval { JSON::decode_json($response->content()) };
    if($@) {
      warn("Net::Random: qrng.anu.edu.au returned bogus JSON\n");
      return();
    } elsif(!$content->{success}) {
      warn("Net::Random: qrng.anu.edu.au said 'success: ".$content->{success}."'\n");
      return();
    }
    @{$content->{data}};
  } },
  'fourmilab.ch' => { pool => [], retrieve => sub {
    my $ssl = shift;
    my $response = $ua->get( 
      ($ssl ? 'https' : 'http') .
      '://www.fourmilab.ch/cgi-bin/uncgi/Hotbits?nbytes=1024&fmt=hex'
    );
    unless($response->is_success) {
      warn "Net::Random: Error talking to fourmilab.ch\n";
      return ();
    }
    my $content = $response->content();
    if($content =~ /Error Generating HotBits/) {
      warn("Net::Random: fourmilab.ch ran out of randomness for us\n");
      return ();
    }
    map { map { hex } /(..)/g } grep { /^[0-9A-F]+$/ } split(/\s+/, $content);
  } },
  'random.org'   => { pool => [], retrieve => sub {
    my $ssl = shift;
    my $response = $ua->get(
      ($ssl ? 'https' : 'http') .
      '://random.org/cgi-bin/randbyte?nbytes=1024&format=hex'
    );

    if ( ! $response->is_success ) {
      warn "Net::Random: Error talking to random.org\n";
      return ();
    }
  
    $response = $response->content();

    if($response =~ /quota/i) {
      warn("Net::Random: random.org ran out of randomness for us\n");
      return ();
    }
    # Old scripts *always* return 200, so look for 'Error:'
    elsif($response =~ /Error:/) {
      warn "Net::Random: Server error while talking to random.org\n";
      return ();
    }

    map { hex } split(/\s+/, $response);
  } }
);

# recharges the randomness pool
sub _recharge {
  my $self = shift;
  $randomness{$self->{src}}->{pool} = [
    @{$randomness{$self->{src}}->{pool}},
    &{$randomness{$self->{src}}->{retrieve}}($self->{ssl})
  ];
}

=head1 NAME

Net::Random - get random data from online sources

=head1 SYNOPSIS

  my $rand = Net::Random->new( # use fourmilab.ch's randomness source,
    src => 'fourmilab.ch',     # and return results from 1 to 2000
    min => 1,
    max => 2000
  );
  @numbers = $rand->get(5);    # get 5 numbers

  my $rand = Net::Random->new( # use qrng.anu.edu.au's randomness source,
    src => 'qrng.anu.edu.au',  # with no explicit range - so values will
  );                           # be in the default range from 0 to 255

  my $rand = Net::Random->new( # use random.org's randomness source,
    src => 'random.org',
  );

  $number = $rand->get();      # get 1 random number

=head1 OVERVIEW

The three sources of randomness above correspond to
L<https://www.fourmilab.ch/cgi-bin/uncgi/Hotbits?nbytes=1024&fmt=hex>,
L<https://random.org/cgi-bin/randbyte?nbytes=1024&format=hex> and 
L<https://qrng.anu.edu.au/API/jsonI.php?length=1024&size=1&type=uint8>.
We always get chunks of 1024 bytes
at a time, storing it in a pool which is used up as and when needed.  The pool
is shared between all objects using the same randomness source.  When we run
out of randomness we go back to the source for more juicy random goodness.

If you have set a http_proxy variable in your environment, this will be
honoured.

While we always fetch 1024 bytes, data can be used up one, two, three or
four bytes at a time, depending on the range between the minimum and
maximum desired values.  There may be a noticeable delay while more
random data is fetched.

The maintainers of all the randomness sources claim that their data is
*truly* random.  A some simple tests show that they are certainly more
random than the C<rand()> function on this 'ere machine.

=head1 METHODS

=over 4

=item new

The constructor returns a Net::Random object.  It takes named parameters,
of which one - 'src' - is compulsory, telling the module where to get its
random data from.  The 'min' and 'max' parameters are optional, and default
to 0 and 255 respectively.  Both must be integers, and 'max' must be at
least min+1.  The maximum value of 'max'
is 2^32-1, the largest value that can be stored in a 32-bit int, or
0xFFFFFFFF.  The range between min and max can not be greater than
0xFFFFFFFF either.

You may also set 'ssl' to 0 if you wish to retrieve data using plaintext
(or outbound SSL is prohibited in your network environment for some reason)

Currently, the only valid values of 'src' are 'qrng.anu.edu.au', 'fourmilab.ch'
and 'random.org'.

=cut

sub new {
  my($class, %params) = @_;

  exists($params{min}) or $params{min} = 0;
  exists($params{max}) or $params{max} = 255;
  exists($params{ssl}) or $params{ssl} = 1;

  die("Bad parameters to Net::Random->new():\n".Dumper(\@_)) if(
    (grep {
      $_ !~ /^(src|min|max|ssl)$/
    } keys %params) ||
    !exists($params{src}) ||
    $params{src} !~ /^(fourmilab\.ch|random\.org|qrng\.anu\.edu\.au)$/ ||
    $params{min} !~ /^-?\d+$/ ||
    $params{max} !~ /^-?\d+$/ ||
    # $params{min} < 0 ||
    $params{max} > 0xFFFFFFFF ||
    $params{min} >= $params{max} ||
    $params{max} - $params{min} > 0xFFFFFFFF
  );

  if ( $params{ssl} ) {
    eval "use LWP::Protocol::https; 1;" or die "LWP::Protocol::https required for SSL connections";
  }

  bless({ %params }, $class);
}

=item get

Takes a single optional parameter, which must be a positive integer.
This determines how many random numbers are to be returned and, if not
specified, defaults to 1.

If it fails to retrieve data, we return undef.  Note that random.org and
fourmilab.ch
ration their random data.  If you hit your quota, we spit out a warning.
See the section on ERROR HANDLING below.

Be careful with context. If you call it in list context, you'll always get
a list of results back, even if you only ask for one. If you call it in
scalar context you'll either get back a random number if you asked for one
result, or an array-ref if you asked for multiple results.

=cut

sub get {
  my($self, $results) = @_;
  defined($results) or $results = 1;
  die("Bad parameter to Net::Random->get()") if($results =~ /\D/);

  my $bytes = 5; # MAXBYTES + 1
  foreach my $bits (32, 24, 16, 8) {
    $bytes-- if($self->{max} - $self->{min} < 2 ** $bits);
  }
  die("Out of cucumber error") if($bytes == 5);

  my @results = ();
  while(@results < $results) {
    $self->_recharge() if(@{$randomness{$self->{src}}->{pool}} < $bytes);
    return undef if(@{$randomness{$self->{src}}->{pool}} < $bytes);

    my $random_number = 0;
    $random_number = ($random_number << 8) + $_ foreach (splice(
      @{$randomness{$self->{src}}->{pool}}, 0, $bytes
    ));
    
    $random_number += $self->{min};
    push @results, $random_number unless($random_number > $self->{max});
  }
  if(wantarray()) {
     return @results;
  } else {
     if($results == 1) { return $results[0]; }
      else { return \@results; }
  }
}

=back

=head1 BUGS

Doesn't handle really BIGNUMs.  Patches are welcome to make it use
Math::BigInt internally.  Note that you'll need to calculate how many
random bytes to use per result.  I strongly suggest only using BigInts
when absolutely necessary, because they are slooooooow.

Tests are a bit lame.  Really needs to test the results to make sure
they're as random as the input (to make sure I haven't introduced any
bias).

=head1 SECURITY CONCERNS

True randomness is very useful for cryptographic applications.  Unfortunately,
I can not recommend using this module to produce such random data.  While
some simple testing shows that we can be fairly confident that it is random,
and the published methodologies on all the sites used looks sane, you can not,
unfortunately, trust that you are getting unique data (ie, someone else might
get the same bytes as you), that they don't log who gets what data, or that
no-one is intercepting it en route to surreptitiously make a copy..

Be aware that if you use an http_proxy - or if your upstream uses a transparent
proxy like some of the more shoddy consumer ISPs do - then that is another place
that your randomness could be compromised.  Even if using https a sophisticated
attacker may be able to intercept your data, because I make no effort to
verify the sources' SSL certificates (I'd love to receive a patch to do this)
and even if I did, there have been cases when trusted CAs issued bogus
certificates, which could be used in MITM attacks.

I should stress that I *do* trust all the site maintainers to give me data that
is sufficiently random and unique for my own uses, but I can not recommend
that you do too.  As in any security situation, you need to perform your own
risk analysis.

=head1 ERROR HANDLING

There are two types of error that this module can emit which aren't your
fault.  Those are network
errors, in which case it emits a warning:

  Net::Random: Error talking to [your source]

and errors generated by the randomness sources, which look like:

  Net::Random: [your source] [message]

Once you hit either of these errors, it means that either you have run
out of randomness and can't get any more, or you are very close to
running out of randomness.  Because this module's raison d'&ecirc;tre
is to provide a source of truly random data when you don't have your
own one available, it does not provide any pseudo-random fallback.

If you want to implement your own fallback, you can catch those warnings
by using C<$SIG{__WARN__}>.  See C<perldoc perlvar> for details.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2003 - 2012 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 THANKS TO

Thanks are also due to the maintainers of the randomness sources.  See
their web sites for details on how to praise them.

Suggestions from the following people have been included:

=over

=item Rich Rauenzahn

Suggested I allow use of an http_proxy;

=item Wiggins d Anconia

Suggested I mutter in the docs about security concerns;

=item Syed Assad

Suggested that I use the JSON interface for QRNG instead of scraping 
the web site;

=back

And patches from:

=over

=item Mark Allen

code for using SSL;

=item Steve Wills

code for talking to qrng.anu.edu.au;

=back

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
