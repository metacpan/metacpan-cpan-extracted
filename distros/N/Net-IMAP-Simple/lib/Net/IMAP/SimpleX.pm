package Net::IMAP::SimpleX::NIL;

use strict;
use warnings;
use overload fallback=>1, '""' => sub { "" };
sub new { return bless {}, "Net::IMAP::SimpleX::NIL" }

package Net::IMAP::SimpleX::Body;

use strict;
use warnings;
no warnings 'once'; ## no critic

our $uidm;

BEGIN {
  our @fields = qw/content_description encoded_size charset content_type format part_number id name encoding/;
  for my $attr (@fields) {
    no strict;
    *{"Net::IMAP::SimpleX::Body::$attr"} = sub { shift->{$attr}; };
  }
}

sub hasparts { return 0; } *has_parts = \&hasparts;
sub parts { return }
sub type { return }
sub body { return shift; }

package Net::IMAP::SimpleX::BodySummary;

use strict;
use warnings;
no warnings 'once'; ## no critic

sub new {
  my ($class, $data) = @_;
  my $self;

  Net::IMAP::SimpleX::_id_parts($data);

  if ($data->{parts}) {
    $self = $data;
  } else {
    $self = { body => $data };
  }

  return bless $self, $class;
}

sub hasparts { return shift->{parts} ? 1 : 0; } *has_parts = \&hasparts;
sub parts { my $self = shift; return wantarray ? @{$self->{parts}} : $self->{parts}; }
sub type { return shift->{type} || undef; }
sub body { return shift->{body}; }


package Net::IMAP::SimpleX;

use strict;
use warnings;
use Carp;
use Parse::RecDescent;
use base 'Net::IMAP::Simple';

our $VERSION = "1.1000";

# directly from http://tools.ietf.org/html/rfc3501#section-9
# try and flatten, format as best we can
our $body_grammar = q {
body:                 body_type_mpart | body_type_1part
                      { $return = bless $item[1], 'Net::IMAP::SimpleX::Body'; }
body_type_mpart:    '('body(s) subtype')'
                    { $return = bless {
                        parts => $item[2],
                        type  => $item{subtype}
                      }, 'Net::IMAP::SimpleX::BodySummary';
                    }
body_type_1part:    body_type_basic | body_type_text
                    { $return = bless $item[1], 'Net::IMAP::SimpleX::BodySummary'; }
body_type_basic:    '('media_type body_fields')'
                    { $return = {
                        content_type => $item{media_type},
                        %{$item{body_fields}}
                      };
                    }
body_type_text:     '('media_type body_fields number')'
                    { $return = {
                      content_type  => $item{media_type},
                      %{$item{body_fields}},
                    }}
body_fields:        body_field_param body_field_id body_field_desc body_field_enc body_field_octets
                    { $return = {
                        id                  => $item{body_field_id},
                        content_description => $item{body_field_desc},
                        encoding            => $item{body_field_enc},
                        encoded_size        => $item{body_field_octets},
                        $item{body_field_param} ? %{$item{body_field_param}} : ()
                      };
                    }
body_field_id:      nil | word
body_field_desc:    nil | word
body_field_enc:     word
body_field_octets:  number
body_field_param:   body_field_param_simple | body_field_param_ext | nil
body_field_param_ext:   '('word word word word')'
                    { $return = { $item[2] => $item[3], $item[4] => $item[5] }; }
body_field_param_simple:   '('word word')'
                    { $return = { $item[2] => $item[3] }; }
body_field_param:   nil
media_type:         type subtype
                    { $return = "$item{type}/$item{subtype}"; }
type:               word
subtype:            word
nil:                'NIL'
                    {$return = '';}
number:             /\d+/
key:                word
value:              word
word:               /[^\s\)\(]+/
                    { $item[1] =~ s/\"//g; $return = $item[1];}
};

our $fetch_grammar = q&
    fetch: fetch_item(s) {$return={ map {(@$_)} reverse @{$item[1]} }}

    fetch_item: cmd_start 'FETCH' '(' value_pair(s?) ')' {$return=[$item[1], {map {(@$_)} @{$item[4]}}]}

    cmd_start: '*' /\d+/ {$return=$item[2]}

    value_pair: tag value {$return=[$item[1], $item[2]]}

    tag: /BODY\b(?:\.PEEK)?(?:\[[^\]]*\])?(?:<[\d\.]*>)?/i | atom

    value: atom | string | parenthized_list

    atom:   /[^"()\s{}[\]]+/ {
            # strictly speaking, the NIL atom should be undef, but P::RD isn't going to allow that.
            # returning a null character instead
            $return=($item[1] eq "NIL" ? Net::IMAP::SimpleX::NIL->new : $item[1])
        }

    string: '"' /[^\x0d\x0a"]*/ '"' {$return=$item[2]} | '{' /\d+/ "}\x0d\x0a" {
            $return = length($text) >= $item[2]
                    ? substr($text,0,$item[2],"") # if the production is accepted, we alter the input stream
                    : undef;
        }

    parenthized_list: '(' value(s?) ')' {$return=$item[2]}
&;

sub new {
    my $class = shift;
    if (my $self = $class->SUPER::new(@_)) {

        $self->{parser}{body_summary}  = Parse::RecDescent->new($body_grammar);
        $self->{parser}{fetch}         = Parse::RecDescent->new($fetch_grammar);

        return $self;
    }
}

sub _id_parts {
    my $data  = shift;
    my $pre   = shift;
    $pre = $pre ? "$pre." : '';

    my $id = 1;
    if (my $parts = $data->{parts}) {
        for my $sub (@$parts){
          _id_parts($sub,"$pre$id") if $sub->{parts};
          $sub->{part_number} = "$pre$id";
          $id++;
        }

    } else {
        $data->{part_number} = $id;
    }

    return;
}

sub body_summary {
    my ($self, $number) = @_;

    my $bodysummary;

    return $self->_process_cmd(
        cmd => [ 'FETCH' => qq[$number BODY] ],

        final => sub { return $bodysummary; },

        process => sub {
            if ($_[0] =~ m/\(BODY\s+(.*?)\)\s*$/i) {
                my $body_parts = $self->{parser}{body_summary}->body($1);
                $bodysummary = Net::IMAP::SimpleX::BodySummary->new($body_parts);
            }
        },

    );
}

sub uidfetch {
    my $self = shift;

    local $uidm = 1; # auto-pop this after the fetch

    return $self->fetch(@_);
}

sub fetch {
    my $self = shift;
    my $msg  = shift; $msg =~ s/[^\*\d:,-]//g; croak "which message?" unless $msg;
    my $spec = "@_" || 'FULL';

    $spec = "BODY[$spec]" if $spec =~ m/^[\d\.]+\z/;

    $self->_be_on_a_box;

    # cut and pasted from ::Server
    $spec = [qw/FLAGS INTERNALDATE RFC822.SIZE ENVELOPE/]      if uc $spec eq "ALL";
    $spec = [qw/FLAGS INTERNALDATE RFC822.SIZE/]               if uc $spec eq "FAST";
    $spec = [qw/FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODY/] if uc $spec eq "FULL";
    $spec = [ $spec ] unless ref $spec;

    my $stxt = join(" ", map {s/[^()[\]\s<>\da-zA-Z.-]//g; uc($_)} @$spec); ## no critic: really? don't modify $_? pfft

    $self->_debug( caller, __LINE__, parsed_fetch=> "$msg ($stxt)" ) if $self->{debug};

    my $entire_response = "";

    return $self->_process_cmd(
        cmd => [ ($uidm ? "UID FETCH" : "FETCH")=> qq[$msg ($stxt)] ],

        final => sub {
            #open my $fh, ">", "entire_response.dat";
            #print $fh $entire_response;

            if( my $res = $self->{parser}{fetch}->fetch($entire_response) ) {
                $self->_debug( caller, __LINE__, parsed_fetch=> "PARSED") if $self->{debug};
                return wantarray ? %$res : $res;
            }

            $self->_debug( caller, __LINE__, parsed_fetch=> "PARSE FAIL") if $self->{debug};
            return;
        },

        process => sub {
            $entire_response .= $_[0];
            return 1;
        },

    );
}

1;
