
package TUWF::Misc;
# Yeah, just put all miscellaneous functions in one module!
# Geez, talk about being sloppy...

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Encode 'encode_utf8';
use Scalar::Util 'looks_like_number';


our $VERSION = '1.1';
our @EXPORT = ('formValidate', 'mail');
our @EXPORT_OK = ('uri_escape', 'kv_validate');


sub uri_escape {
  local $_ = encode_utf8 shift;
  s/([^A-Za-z0-9._~-])/sprintf '%%%02X', ord $1/eg;
  return $_;
}




sub _template_validate_num {
  $_[0] *= 1; # Normalize to perl number
  return 0 if defined($_[1]{min}) && $_[0] < $_[1]{min};
  return 0 if defined($_[1]{max}) && $_[0] > $_[1]{max};
  return 1;
}

my $re_fqdn      = qr/(?:[a-zA-Z0-9][\w-]*\.)+[a-zA-Z][a-zA-Z0-9-]{1,25}\.?/;
my $re_ip4_digit = qr/(?:0|[1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])/;
my $re_ip4       = qr/($re_ip4_digit\.){3}$re_ip4_digit/;
# This monstrosity is based on http://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
# Doesn't allow IPv4-mapped-IPv6 addresses or other fancy stuff.
my $re_ip6       = qr/(?:[0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:(?:(?::[0-9a-fA-F]{1,4}){1,6})|:(?:(?::[0-9a-fA-F]{1,4}){1,7}|:)/;
my $re_domain    = qr/(?:$re_fqdn|$re_ip4|\[$re_ip6\])/;

my %default_templates = (
  # JSON number format, regex from http://stackoverflow.com/questions/13340717/json-numbers-regular-expression
  num    => { func => \&_template_validate_num, regex => qr/^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$/, inherit => ['min','max'] },
  int    => { func => \&_template_validate_num, regex => qr/^-?(?:0|[1-9]\d*)$/, inherit => ['min','max'] },
  uint   => { func => \&_template_validate_num, regex => qr/^(?:0|[1-9]\d*)$/, inherit => ['min','max'] },
  ascii  => { regex => qr/^[\x20-\x7E]*$/ },
  email  => { regex => qr/^[-\+\.#\$=\w]+\@$re_domain$/, maxlength => 254 },
  weburl => { regex => qr/^https?:\/\/$re_domain(?::[1-9][0-9]{0,5})?\/[^\s<>"]*$/, maxlength => 65536 }, # the maxlength is a bit arbitrary, but better than unlimited
);


sub kv_validate {
  my($sources, $templates, $params) = @_;
  $templates = { %default_templates, %$templates };

  my @err;
  my %ret;

  for my $f (@$params) {
    # Inherit some options from templates.
    !exists($f->{$_}) && _val_from_tpl($f, $_, $templates, $f)
      for(qw|required default rmwhitespace multi mincount maxcount|);

    my $src = (grep $f->{$_}, keys %$sources)[0];
    my @values = $sources->{$src}->($f->{$src});
    @values = ($values[0]) if !$f->{multi};

    # check each value and add it to %ret
    for (@values) {
      my $errfield = _validate_early($_, $f) || _validate($_, $templates, $f);
      next if !$errfield || $errfield eq 'default';
      push @err, [ $f->{$src}, $errfield, $f->{$errfield} ];
      last;
    }
    $ret{$f->{$src}} = $f->{multi} ? \@values : $values[0];

    # check mincount/maxcount
    push @err, [ $f->{$src}, 'mincount', $f->{mincount} ] if $f->{mincount} && @values < $f->{mincount};
    push @err, [ $f->{$src}, 'maxcount', $f->{maxcount} ] if $f->{maxcount} && @values > $f->{maxcount};
  }

  $ret{_err} = \@err if @err;
  return \%ret;
}


sub _val_from_tpl {
  my($top_rules, $field, $tpls, $rules) = @_;
  return if !$rules->{template};
  my $tpl = $tpls->{$rules->{template}};
  if(exists $tpl->{$field}) {
    $top_rules->{$field} = $tpl->{$field};
  } else {
    _val_from_tpl($top_rules, $field, $tpls, $tpl);
  }
}


# Initial validation of a value. Same as _validate() below, but this one
# validates options that need to be checked only once. (The checks in
# _validate() may run several times when templates are used).
sub _validate_early { # value, \%rules
  my($v, $r) = @_;

  $r->{required}++ if not exists $r->{required};
  $r->{rmwhitespace}++ if not exists $r->{rmwhitespace};

  # remove whitespace
  if($v && $r->{rmwhitespace}) {
    $_[0] =~ s/\r//g;
    $_[0] =~ s/^[\s\n]+//;
    $_[0] =~ s/[\s\n]+$//;
    $v = $_[0]
  }

  # empty
  if(!defined($v) || length($v) < 1) {
    return 'required' if $r->{required};
    $_[0] = $r->{default} if exists $r->{default};
    return 'default';
  }
  return undef;
}


# Internal function used by kv_validate, checks one value on the validation
# rules, the name of the failed rule on error, undef otherwise
sub _validate { # value, \%templates, \%rules
  my($v, $t, $r) = @_;

  croak "Template $r->{template} not defined." if $r->{template} && !$t->{$r->{template}};

  # length
  return 'minlength' if $r->{minlength} && length $v < $r->{minlength};
  return 'maxlength' if $r->{maxlength} && length $v > $r->{maxlength};
  # enum
  return 'enum'      if $r->{enum} && !grep $_ eq $v, @{$r->{enum}};
  # regex
  return 'regex'     if $r->{regex} && (ref($r->{regex}) eq 'ARRAY' ? ($v !~ m/$r->{regex}[0]/) : ($v !~  m/$r->{regex}/));
  # template
  if($r->{template}) {
    my $in = $t->{$r->{template}}{inherit};
    my %r = (($in ? (map exists($r->{$_}) ? ($_,$r->{$_}) : (), @$in) : ()), %{$t->{$r->{template}}});
    return 'template'  if _validate($_[0], $t, \%r);
  }
  # function
  return 'func'      if $r->{func} && (ref($r->{func}) eq 'ARRAY' ? !$r->{func}[0]->($_[0], $r) : !$r->{func}->($_[0], $r));
  # passed validation
  return undef;
}




sub formValidate {
  my($self, @fields) = @_;
  return kv_validate(
    { post   => sub { $self->reqPosts(shift)  },
      get    => sub { $self->reqGets(shift)   },
      param  => sub { $self->reqParams(shift) },
      cookie => sub { $self->reqCookie(shift) },
    }, $self->{_TUWF}{validate_templates} || {},
    \@fields
  );
}



# A simple mail function, body and headers as arguments. Usage:
#  $self->mail('body', header1 => 'value of header 1', ..);
sub mail {
  my $self = shift;
  my $body = shift;
  my %hs = @_;

  croak "No To: specified!\n" if !$hs{To};
  croak "No Subject: specified!\n" if !$hs{Subject};
  $hs{'Content-Type'} ||= 'text/plain; charset=\'UTF-8\'';
  $hs{From} ||= $self->{_TUWF}{mail_from};
  $body =~ s/\r?\n/\n/g;

  my $mail = '';
  foreach (keys %hs) {
    $hs{$_} =~ s/[\r\n]//g;
    $mail .= sprintf "%s: %s\n", $_, $hs{$_};
  }
  $mail .= sprintf "\n%s", $body;

  if(open(my $mailer, '|-:utf8', "$self->{_TUWF}{mail_sendmail} -t -f '$hs{From}'")) {
    print $mailer $mail;
    croak "Error running sendmail ($!)"
      if !close($mailer);
  } else {
    croak "Error opening sendail ($!)";
  }
}


1;
