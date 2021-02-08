package Mojolicious::Plugin::TagHelpers::MailToChiffre;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Mojo::Collection 'c';
use Mojo::URL;

our $VERSION = '0.11';

# Cache for generated CSS and JavaScript
has [qw/js css pattern_rotate/];

# Register Plugin
sub register {
  my ($plugin, $app, $plugin_param) = @_;

  # Load random string plugin with specific profile
  $app->plugin('Util::RandomString' => {
    mail_to_chiffre => {
      alphabet => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
      entropy => 128
    }
  });

  delete $plugin->{js};
  delete $plugin->{css};

  # Load parameters from Config file
  if (my $config_param = $app->config('TagHelpers-MailToChiffre')) {
    $plugin_param = { %$config_param, %$plugin_param };
  };

  # Generate method name in case it is not given
  my $method_name = $plugin_param->{method_name} // $app->random_string('mail_to_chiffre');

  # Set pattern shift in case it is not given
  my $pattern_rotate = 2;
  if ($plugin_param->{pattern_rotate} && $plugin_param->{pattern_rotate} =~ /^\d+$/) {
    $pattern_rotate = $plugin_param->{pattern_rotate};
  };
  $plugin->pattern_rotate($pattern_rotate);

  # Add pseudo condition for manipulating the stash for the fallback
  my $routes = $app->routes;

  # Add fallback shortcut
  $routes->add_shortcut(
    mail_to_chiffre => sub {
      my $r = shift;

      state $name = 'mailToChiffre';

      # In case method name is given, set asset paths
      if ($plugin_param->{method_name}) {

        # Styles
        $r->get('/style.css')->to(
          cb => sub {
            my $c = shift;
            $c->render(
              text   => $c->mail_to_chiffre_css,
              format => 'css'
            );
          }
        )->name($name . 'CSS');

        # Styles
        $r->get('/script.js')->to(
          cb => sub {
            my $c = shift;
            $c->render(
              text   => $c->mail_to_chiffre_js,
              format => 'js'
            );
          }
        )->name($name . 'JS');
      };

      # Fallback path
      $r->under('/:xor/:host')->to(
        cb => sub {
          $plugin->_chiffre_to_mail(shift)
        }
      )->get('/')->name($name)->to(@_);
    }
  );


  # Add obfuscation tag helper
  $app->helper(
    mail_to_chiffre => sub {
      my $c = shift;

      my $address = shift or return b('');

      # Create one time pad
      my $xor = substr($c->random_string('mail_to_chiffre'), 0, length($address));

      # Get embedded code
      my $text;
      if (ref($_[-1]) && ref($_[-1]) eq 'CODE') {
        $text = pop;
      };

      my %param = @_;

      # Split the address and do some encodings
      my $obf_address = b($address)->xml_escape->split('@');
      my $account = $obf_address->first;

      my $host = join '@', @{$obf_address}[1 .. $obf_address->size - 1];

      # Reget the pattern rotate (maybe)
      my $pattern_rotate = $plugin->pattern_rotate;

      # Obfuscate address parts
      $host = $plugin->to_sequence(
        $host,
        $xor,
        $pattern_rotate
      );

      $account = $plugin->to_sequence(
        $account,
        $xor,
        $pattern_rotate
      );

      # Create Mojo::URL for path
      my ($url, $no_fallback);
      if ($routes->lookup('mailToChiffre')) {
        $url = $c->url_for('mailToChiffre', xor => $xor, host => $host);
      }
      else {
        $url = $c->url_for("/$xor/$host");
        $no_fallback = 1;
      };

      # Encrypt certain mail parameters
      foreach (qw/to cc bcc/) {

        # No parameter
        next unless exists $param{$_};

        # Parameter invalid
        unless ($param{$_}) {
          delete $param{$_};
          next;
        };

        # Array for this parameter
        if (ref $param{$_}) {
          my @temp;
          foreach (@{$param{$_}}) {
            push(@temp, $plugin->to_sequence($_, $xor, $pattern_rotate)) if $_;
          };

          # Check if there are converted parameters
          if (@temp) {
            $param{$_} = \@temp;
          }
          # Remove parameter from list
          else {
            delete $param{$_};
          };
        }

        # Single value
        else {
          $param{$_} = $plugin->to_sequence(
            $param{$_},
            $xor,
            $pattern_rotate
          );
        };
      };

      # Return path
      $url->query({sid => $account, %param});

      if ($no_fallback) {
        $url = qq!javascript:$method_name(false,'$url')!;
      };

      # Create anchor link
      my $str = qq!<a href="$url" rel="nofollow" onclick="!;
      $str .= 'return true;' if $no_fallback;
      $str .= 'return ' . $method_name . '(this,false)';

      # Obfuscate display string using css
      unless ($text) {
        my ($pre, @post) = split('@', reverse($address));
        $str .= '">' .
          '<span>' . b($pre)->xml_escape . '</span>' .
          '<span>' . b($xor)->split('')->reverse->join . '</span>' .
          c(@post)->join->xml_escape;
      }
      else {
        $str .= ';' . int(rand(50)) . '">' . $text->();
      };

      $str .= '</a>';

      return b($str);
    }
  );

  # Create css code helper
  $app->helper(
    mail_to_chiffre_css => sub {
      return $plugin->css if $plugin->css;
      my $css = qq!a[onclick\$='return $method_name(this,false)']!;
      $css = $css . '{direction:rtl;unicode-bidi:bidi-override;text-align:left}'.
        $css . '>span:nth-child(1n+2){display:none}' .
       $css . '>span:nth-child(1):after{content:\'@\'}';
      $plugin->css(b($css));
      return $plugin->css;
    }
  );


  # Create javascript code helper
  $app->helper(
    mail_to_chiffre_js => sub {
      my $c = shift;

      return $plugin->js if $plugin->js;

      # Replacement variables
      my $v = c(qw/o s u c p n t r g f a x e d q b l m k/)->shuffle;

      # Template variables
      my ($i, %v) = (0);
      foreach (qw/obj seq url char pos num str regex string_obj
      from_char_code param_array temp to_seq
      path_array query padded str_len pow bool/) {
        $v{$_} = $v->[$i++];
      };

      # Obfuscate pattern rotate
      my $factor_pattern_rotate = _factorize($plugin->pattern_rotate, $v{pow});

      # Create javascript code
      my $js = qq!function ${method_name}($v{obj},$v{bool}){
  if($v{bool}){
    $v{obj}=document.createElement('a');$v{obj}.href=$v{bool}
  }
  var $v{query}=$v{obj}.search,$v{regex}=RegExp,$v{from_char_code}=String.fromCharCode,$v{url}='il',$v{param_array}=[],$v{temp},$v{pow}=Math.pow;
  $v{path_array}=$v{obj}.pathname.match(/([^\\/]+)\\/([^\\/]+)\$/);
  $v{to_seq}=function($v{seq}){
    var $v{pos}=0,$v{num},$v{str}='',$v{char};
    while($v{pos}<$v{seq}.length){
      $v{char}=$v{seq}.charAt($v{pos}++);
      if($v{char}.match(/[A-Za-z]/)){
        $v{str}+=$v{from_char_code}(($v{char}<='Z'?90:122)>=($v{char}=$v{char}.charCodeAt(0)+13)?$v{char}:$v{char}-26)
      }
      else if($v{char}=='-'){
        $v{num}='';
        $v{char}=$v{seq}.charAt($v{pos}++);
        while($v{char}.match(/\\d/)){
      $v{num}+=$v{char};
    $v{char}=$v{seq}.charAt($v{pos}++)
        }
        $v{pos}--;
        $v{str}+=$v{from_char_code}(parseInt($v{num}))
      }
      else return
    }
    $v{str_len}=$v{str}.length;
    $v{padded}=Math.abs(${factor_pattern_rotate}%$v{str_len}-$v{str_len});
    $v{str}=$v{str}.substr($v{padded})+$v{str}.substr(0,$v{padded});
    $v{temp}='';
    for(i=0;i<$v{str_len};i++){
      $v{temp}+=$v{from_char_code}($v{str}.charCodeAt(i)^$v{path_array}\[1\].charCodeAt($v{path_array}\[1\].length%(i+1)))
    }
    return $v{temp}
  };
  while($v{query}){
    $v{query}=$v{query}.replace(/^[\\?\\&]([^\\&]+)/,'');
    $v{temp}=$v{regex}.\$1;
    if($v{temp}.match(/^(sid|b?cc|to)=(.+)\$/)){
      if($v{regex}.\$1=='sid')
        $v{param_array}.push('to='+$v{to_seq}($v{regex}.\$2)+'\@'+$v{to_seq}($v{path_array}\[2\]));
      else $v{param_array}.push($v{regex}.\$1+'='+$v{to_seq}($v{regex}.\$2));
    }else $v{param_array}.push($v{temp}.replace(/\\+/g,' '))
  }
  location.href='ma'+$v{url}+'to:?'+$v{param_array}.join('&');
  return false
}!;
      $js =~ s/\s*\n\s*//g;
      $plugin->js(b($js));
      return $plugin->js;
    }
  );
};


sub _chiffre_to_mail {
  my ($plugin, $c) = @_;
  my $xor = $c->stash('xor');
  my $p = $c->req->url->query;

  # Set header for searc engines
  $c->res->headers->header('X-Robots-Tag' => 'noindex,nofollow');

  # Deobfuscate host
  my $host = $plugin->to_string(
    $c->stash('host'),
    $xor,
    $plugin->pattern_rotate
  );

  # Deobfuscate account
  my $account = $plugin->to_string(
    scalar $p->param('sid'),
    $xor,
    $plugin->pattern_rotate
  );
  $p->remove('sid');

  # Something went wrong
  unless ($host && $account) {
    $c->app->log->warn('Path doesn\'t contain a valid email address');
    return;
  };

  # Create url
  my $url = Mojo::URL->new;
  $url->scheme('mailto');
  $url->path($account . '@' . $host);

  # Deobfuscate further address parameters
  foreach my $type (qw/to cc bcc/) {
    if (my @val = @{$p->every_param($type)}) {

      # Delete obfuscated parameters
      $p->remove($type);

      # Append new deobfuscated parameters
      $p->append($type => [map {
        $plugin->to_string(
          $_,
          $xor,
          $plugin->pattern_rotate
        )
      } @val]);
    };
  };

  $url->query->append($p);

  # Store the deobfuscated mail in the stash
  $c->stash(mail_to_chiffre => $url);

  return 1;
};


# Simple string based xor function with looping key
sub _xor {
  my $str = '';
  for (my $i = 0; $i < length($_[0]); $i++) {
    $str .= substr($_[0], $i, 1) ^ substr($_[1], length($_[1]) % ($i + 1), 1);
  };
  return $str;
};


# Rotate with pattern
sub _rotate {
  my $p = $_[1] % length($_[0]);
  substr($_[0], $p) . substr($_[0], 0, $p)
};


# Unrotate with pattern_rotate
sub _unrotate {
  my $p = abs($_[1] % length($_[0]) - length($_[0]));
  substr($_[0], $p) . substr($_[0], 0, $p);
};


# Obfuscate the pattern shift a little bit
# by simple prime factorization
sub _factorize {
  my $x = shift;
  my %factors;
  foreach (qw/2 3 5 7/) {
    while (!($x % $_)) {
      $factors{$_}++;
      $x = $x / $_;
    };
  };
  my @factors;
  foreach (keys %factors) {
    if ($factors{$_} > 1) {
      push(@factors, $_[0] . '(' . $_ . ',' . $factors{$_} . ')');
    }
    else {
      push(@factors, $_);
    };
  };
  push(@factors, $x) unless $x == 1;
  return join('*', @factors);
};


# Serialize to string
sub to_string {
  shift;
  my $seq = shift or return;
  my ($xor, $p) = @_;

  my ($str, $c, $num);
  my $pos = 0;

  my $length = length $seq;

  # parse sequence
  while ($pos < $length) {
    $c = substr($seq, $pos++, 1);

    # Parse alphabetical character (ROT13)
    if ($c =~ tr/n-za-mN-ZA-M/a-zA-Z/) {
      $str .= $c;
    }

    # Parse number
    elsif ($c eq '-') {
      $num = '';
      $c = substr($seq, $pos++, 1);

      # Collect number segments
      while ($c =~ /[0-9]/) {
        $num .= $c;
        $c = substr($seq, $pos++, 1);
      };

      $pos--;
      $str .= chr($num);
    }

    # Error
    else {
      return;
    };
  };
  return _xor(_unrotate($str, $p), $xor);
};


# Serialize to sequence
sub to_sequence {
  shift;
  my ($s, $k, $p) = @_;

  # _xor is not allowed to be null
  my $src = _rotate(_xor($s, $k), $p);
  my $str;

  # Parse string
  foreach my $c (split('', $src)) {

    # Change alphabetical character (ROT13)
    if ($c =~ /[a-zA-Z]/) {
      $c =~ tr/a-zA-Z/n-za-mN-ZA-M/;
      $str .= $c;
    }

    # Add numerical value
    else {
      $str .= '-' . ord($c);
    };
  };

  return $str;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::TagHelpers::MailToChiffre - Obfuscate Email Addresses in Templates

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin 'TagHelpers::MailToChiffre' => {
    pattern_rotate => 720
  };

  # Path to index page
  get '/' => 'index';

  # Add fallback for non-JavaScript users
  get('/contactme')->mail_to_chiffre(cb => sub {
    my $c = shift;
    # Of course - don't display it this way:
    $c->render(text => 'You tried to ' . $c->stash('mail_to_chiffre')->to_string);
  });

  app->start;

  __DATA__
  @@ layouts/default.html.ep
  <!DOCTYPE html>
  <html>
    <head>
      <title><%= title %></title>
      %# Add javascript and stylesheet information
      <%= javascript begin %><%= mail_to_chiffre_js %><% end %>
      <%= stylesheet begin %><%= mail_to_chiffre_css %><% end %>
    </head>
    <body><%= content %></body>
  </html>

  @@ index.html.ep
  % layout 'default', title => 'Welcome';
  <p>
    Mail me at <%= mail_to_chiffre 'akron@sojolicio.us', subject => 'Hi!' %>
    or
    <%= mail_to_chiffre 'test@sojolicio.us', begin %>Write me<% end %>
  </p>


=head1 DESCRIPTION

L<Mojolicious::Plugin::TagHelpers::MailToChiffre> is a L<Mojolicious> plugin
helping you to obfuscate email adresses visible on your website
to make it less easy for spam bots to grab them.

It uses JavaScript to obfuscate mailto-links (while providing
a fallback option for users without JavaScript)
and in case you want to show the email
address in plain text it is obfuscated using CSS.
Although modern spam bots may be capable of parsing and executing
JavaScript and interpreting CSS, it is more likely,
that they don't try to do it, as it takes time and power
better be invested in sites with less protected emails.
This is just my assumption for the moment - it may not held entirely true.
The idea is to make the obfuscation easy for modern browser
and expensive for spam bots, by making it necessary to parse
and execute CSS and JavaScript without giving too much hints,
that this is necessary to deobfuscate email addresses
(i.e. not creating too obvious patterns for the obfuscation,
so in case a spambot programmer knows this scheme it is
more expensive to search for than simply scan for an email pattern
using a regular expression).

This plugin is not useful for obfuscating millions
of email addresses on your site,
as once a bot has adapted the scheme and your parameters,
parsing and deobfuscating is rather trivial.

The plugin supports utf-8 domain names, utf-8 usernames
and tries to be compatible with L<RFC2368|http://tools.ietf.org/html/rfc2368>,
including obfuscated C<to>, C<cc> and C<bcc> addresses.

Please be aware of the environment you use email obfuscation in and
make sure your human visitors will always be able to deobfuscate your address!
And please keep in mind that it's arguable if email obfuscation is
useful at all
(see L<pro|https://utkusen.com/blog/security-by-obscurity-is-underrated.html>
and
L<contra|http://www.theguardian.com/technology/2010/dec/21/keeping-email-address-secret-spambots>).


=head2 Mailto Obfuscation

The mailto obfuscation merely follows the basic principle of
L<this alistapart.com article|http://alistapart.com/article/gracefulemailobfuscation>.
The mailto-link is build using JavaScript with information stored in a harmless looking
http-URL. Instead of a simple rot13 obfuscation, the obfuscation
uses a XOR operation on a rotating public One Time Pad, a variable character shift,
and afterwards applys an ASCII encoding scheme on the result
(similar to base64; currently using rot13 for alphanumericals and a cheap ordinal
number print for all other characters - a scheme likely to be changed).

Using the One Time Pad guarantees that all email addresses look different
each time they are obfuscated to make it harder to leave a simple pattern
for finding these strings (especially the recurring domain part).

The character shift with a variable number of characters makes it necessary
to parse the JavaScript, even if the spambot knows the scheme and the
obfuscated URL.

The JavaScript method name can be set manually,
otherwise it defaults to a random string.


=head2 Display Obfuscation

In case you want to make the email address visual,
it is obfuscated using CSS with
L<reversed directionality|http://techblog.tilllate.com/2008/07/20/ten-methods-to-obfuscate-e-mail-addresses-compared/> and non-displayed span segments.

Although the left string tries to not leave too many hints of its email address nature,
this obfuscation is obviously easier to deobfuscate than the javascript obfuscation,
i.e. less protected.


=head1 METHODS

L<Mojolicious::Plugin::TagHelpers::MailToChiffre> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.


=head2 register

  # Mojolicious
  $app->plugin('TagHelpers::MailToChiffre');

  # Mojolicious::Lite
  plugin 'TagHelpers::MailToChiffre' => {
    method_name => 'deobfuscate',
    pattern_rotate => 720
  };

Called when registering the plugin.
Accepts the attributes C<method_name> and C<pattern_rotate>.

The C<method_name> is the name of the JavaScript function called to deobfuscate
your email addresses. It defaults to a random string.
The C<pattern_rotate> numeral value will rotate the characters of the obfuscated
email address and is stored directly in the javascript.
It default to C<2>.

All parameters can be set either on registration or
as part of the configuration file with the key C<TagHelpers-MailToChiffre>.


=head1 HELPERS

=head2 mail_to_chiffre

  # In Templates
  <%= mail_to_chiffre 'akron@sojolicio.us', subject => 'Hello!' %>
  <%= mail_to_chiffre 'akron@sojolicio.us', cc => 'metoo@sojolicio.us' %>
  %= mail_to_chiffre 'akron@sojolicio.us' => begin
    <img src="mailme.gif" />
  % end

Creates an anchor link with the resulting obfuscated email address
(i.e. the fallback path defined by the shortcut).
Accepts an email address and further query parameters of the mailto-link
as defined in L<RFC2368|http://tools.ietf.org/html/rfc2368>.
Multiple values can be denoted using an array reference (e.g. C<to> and C<cc>).
C<to>, C<cc> and C<bcc> links are obfuscated, too.

In case the helper embeds further HTML, this is used for the link content,
otherwise the first email address is used obfuscated as the link text.


=head2 mail_to_chiffre_css

  # In Templates
  <%= stylesheet begin %><%= mail_to_chiffre_css %><% end %>

Returns the deobfuscating CSS code.


=head2 mail_to_chiffre_js

  # In Templates
  <%= javascript begin %><%= mail_to_chiffre_js %><% end %>

Returns the deobfuscating JavaScript code.


=head1 SHORTCUTS

=head2 mail_to_chiffre

  # Mojolicious
  my $r = $app->routes;
  $r->any('/contactme')->mail_to_chiffre('Mail#capture');

  # Mojolicious::Lite
  any('/contactme')->mail_to_chiffre(
    cb => sub {
      # ...
      # The plain mailto-link is as a Mojo::URL object
      # stored in the stash value 'mail_to_chiffre'
    }
  );

Define the URL prefix for the obfuscated anchor link,
which also serves as the fallback path for users without
JavaScript.
Accepts all parameters of L<Mojolicious::Routes::Route/to>.
The plain mailto-link is present as a L<Mojo::URL> in the stash
value C<mail_to_chiffre>.

You can present a security question or a capture before you relocate
the user to the deobfuscated mailto-link, or you may provide an
email form instead.

The fallback response will contain a header to ban search engines.


=head1 KNOWN BUGS AND LIMITATIONS

This plugin works best in a demon environment (and worse in a CGI environment).
The output may change in further versions, which means the CSS and JavaScript
files (in case they are external) may have to be updated.


=head1 DEPENDENCIES

L<Mojolicious>,
L<Mojolicious::Plugin::Util::RandomString>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-TagHelpers-MailToChiffre


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
