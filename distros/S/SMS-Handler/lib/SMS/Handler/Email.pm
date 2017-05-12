package SMS::Handler::Email;

require 5.005_62;

use Carp;
use strict;
use warnings;
use IO::File;
use Net::SMTP;
use Net::POP3;
use Mail::Audit;
use Date::Parse;
use Digest::MD5;
use SMS::Handler;
use MIME::Parser;
use Text::Abbrev;
use HTML::Parser;
use Mail::Address;
use Unicode::Map8;
use Net::SMPP 1.04;
use POSIX qw(strftime);
use Fcntl qw(SEEK_SET);
use SMS::Handler::Utils;
use SMS::Handler::Dispatcher;
use Params::Validate qw(:all);
use MIME::WordDecoder qw(unmime);

# $Id: Email.pm,v 1.55 2003/03/13 20:41:54 lem Exp $

our $VERSION = q$Revision: 1.55 $;
$VERSION =~ s/Revision: //;

our @ISA = qw(SMS::Handler::Dispatcher);

our $Debug = 0;

=pod

=head1 NAME

SMS::Handler::Email - Process Email related commands

=head1 SYNOPSIS

  use SMS::Handler::Email;

  my $h = SMS::Handler::Email->new(-queue => $queue_obj,
				   -state => $ref_to_hash,
				   -secret => $my_secret_phrase,
				   -addr => '9.9.5551212',
				   -pop => 'pop.your.com',
				   -smtp => 'smtp.your.com',
				   -maxlen => 160,
				   -maxfetch => 1024,
				   -compact => 1,
				   -spamcheck => $obj,
				   -cmds => { ... },
    				   -help => { ... },
    				   -maxspam => 10,
				   );

 $h->handle({ ... });

=head1 DESCRIPTION

This module implements a simple responder class. It will respond to
any message directed to the specified phone number, with the specified
message.

The Email message is assumed to be in ISO-8859-1 (Latin1)
encoding. Mappings are provided to convert the messages to a safe
7-Bit character set which is believed to be compatible with any SMS
receiver. This mapping is lossy in the sense that accents and special
characters are converted to a close but incorrect representation. For
instance, an B<a with a tilde> is converted to a plain B<a>.

=head2 SUPPORTED COMMANDS

The following commands are supported in the first line of the
SMS. Commands can be abbreviated to any unique substring. The first
line can be separated by the rest of the message either with a
new-line or two consecutive space characters.

=over 2

=item B<.ACCOUNT login password>

Associates the given account with the source address of the
SMS. Further commands coming from this address are attempted with
these supplied credentials, which are the login or username and
password of the POP server.

=item B<.CHECK>

Checks all the messages in the mailbox looking for spam. This requires
that a B<spamcheck> item be passed to C<-E<gt>new()> at object
creation time. A specially formatted response message, suitable to
remove all the SPAM messages will be returned.

If this command is followed by the B<!> symbol, messages recognized as
SPAM will be erased automatically.

=item B<.SEND to subject>

Sends the remainder of the SMS as a message to the address(es)
specified in the B<to> field. Multiple addresses can be specified by
separating them with commas. No spaces are allowed in the addresses.

Before the actual sending of the message, a POP authentication is
attempted. Only if this authentication succeeds will the message be
sent.

=item B<.LIST>

Retrieves the current list of messages in the POP server.

=item B<.DELETE msg>

Deletes the message B<msg> from the POP server. When omitting B<msg>,
the command will refer to the most recent message. 0 is a synonim to
1.

=item B<.REPLY msg>

Replies to the message specified by B<msg>. When omitting B<msg>, the
command will refer to the most recent message. 0 is a synonim to 1.

=item B<.ALL msg>

Replies to the message specified by B<msg>. When omitting B<msg>, the
command will refer to the most recent message. 0 is a synonim to
1. All recipients of the original message are copied of the response.

=item B<.FORWARD msg to>

Forwards the message specified by B<msg> to the addresses specified in
B<to>. When omitting B<msg>, the command will refer to the most recent
message. 0 is a synonim to 1.

=item B<.GET msg [block]>

Retrieves the message B<msg> from the POP server. Only the first chars
of the body are retrieved. If a numeric block is specified, that block
of octets is presented to the user. The first block is 1. The first
block of the most recent message can be requested by omitting B<msg>
and B<block>. B<msg> must be specified in order for B<block> to be
specified too. A B<msg> 0 is synonim to 1.

=item B<.ALIAS [address] nick>

Creates a nick for the user whose address is specified. If no address
is specified, erases the nick. Nick names or aliases, are used as
shorthand for the complete email address of a user.

=item B<.HELP>

Sends a (very) short usage summary.

=back

The variable C<$SMS::Handler::Email::DefaultLanguage> can be used to
choose the default language of all the answers.

=pod

=head2 HELP TABLE

The help table is a hash stored in C<%SMS::Handler::Email::Help>. Each
key of the hash, is a command name. Each corresponding value is the
reference to a hash, whose key is a language code and its value is a
brief explanation of what the command does in the corresponding
language.

Probably it is wise to avoid explanations that use 8 bit characters,
as those are not safely handled by all the phones out there.

=cut

our %Help =
    (
     ACCOUNT	=> 
     {
	 en => q{+ login & password for the wanted account},
	 es => q{+ login y clave de la cuenta deseada},
     },
     ALIAS	=>
     {
	 en => q{+ nick erases or creates an alias for the given address},
	 es => q{+ nick borra o crea un alias para la direccion dada},
     },
     CHECK	=> 
     {
	 en => q{checks mailbox for spam. With !, removes it},
	 es => q{revisa el buzon buscando spam. Con ! lo borra},
     },
     SEND	=> 
     {
	 en => q{+ recipients and subject in the first line sends email},
	 es => q{+ destinatarios y asunto en la 1a linea envia un email},
     },
     INTERFACE	=>
     {
	 en => q{+ language, changes the language for the responses},
	 es => q{+ lenguage, cambia el lenguaje para las respuestas},
     },
     LIST	=> 
     { 
	 en => q{returns the amount of messages in the registered account},
	 es => q{contesta la cantidad de mensajes en la cuenta registrada},
     },
     DELETE	=> 
     { 
	 en => q{+ msg number removes it from the mailbox},
	 es => q{+ numero de mens lo remueve del buzon},
     },
     REPLY	=> 
     { 
	 en => q{+ msg number replies the remainder of the SMS},
	 es => q{+ numero de mens contesta el resto del SMS},
     },
     ALL	=> 
     { 
	 en => q{+ msg number replies the remainder of the SMS to all},
	 es => q{+ numero de mens contesta el resto del SMS a todos},
     },
     FORWARD	=> 
     { 
	 en => q{+ msg number + dest addr + the remainder of the SMS},
	 es => q{+ numero de mens + dest + el resto del SMS},
     },
     GET	=> 
     { 
	 en => q{+ msg number fetches it from the mailbox},
	 es => q{+ numero de mens lo trae del buzon},
     },
     HELP	=> 
     { 
	 en => q{sends this help text},
	 es => q{envia estos textos de ayuda},
     },
     );

			     
=pod
			     
=head2 RESPONSE TABLE

The commands must supply responses to the user based on its
success. In order to support multiple languages, responses are stored
in a hash table (C<%SMS::Handler::Email::Messages>). Each key on this
hash table correspond to a language tag as described in
L<I18N::LangTags>. The corresponding value, is a reference to a hash
whose keys are message tags (ie, an identifier for the message) and a
message in the required language.

Please see the source code for the specific message identifiers
used. Note that you must call C<init()> if this table is changed.

Supported languages must be added to the
C<%SMS::Handler::Email::SupportedLangages> hash before calling the
init method.

=cut
    ;

my %SupportedLanguages = 
(
 'SPANISH'	=> 'es',
 'ESPAÑOL'	=> 'es',
 'CASTELLANO'	=> 'es',
 'ESPANOL'	=> 'es',
 'INGLÉS'	=> 'en',
 'INGLES'	=> 'en',
 'ENGLISH'	=> 'en',
 );

my %Languages;

my $DefaultLanguage = 'en';

our %Messages =
    (
     en =>
     {
	 HANDLE_CMD_ERR	=> q{Command error},
	 ACCOUNT_OK	=> q{ok},	 
	 ALIAS_OK	=> q{updated},
	 LANG_OK	=> q{interface set to},
	 SEND_OK	=> q{Send ok},
	 DELETE_OK	=> q{deleted ok},
	 REPLY_OK	=> q{replied ok},
	 FWD_OK		=> q{forwarded ok},
	 LIST_NO_REG	=> q{Use .ACCOUNT to register an email account},
	 HEAD_SUBJECT	=> q{Sub:},
	 HEAD_DATE	=> q{Date:},
	 HEAD_FROM	=> q{From:},
	 HEAD_PHONE	=> q{Phone:},
	 REPLY_YOU	=> q{You},
	 REPLY_SAID	=> q{said:},
	 MSG_COUNT_ONE	=> q{Message},
	 MSG_COUNT_MANY	=> q{Messages},
	 MSG_COUNT_LAST	=> q{Last},
	 HTML_TRANS	=> q{[Translated from HTML]},
	 FETCH_NOMSG	=> q{POP Error. No message},
	 FETCH_MIME	=> q{Error parsing MIME message},
	 FETCH_BODY	=> q{POP Error in fetching body},
	 POP_CONNECT	=> q{POP Error connecting to server},
	 POP_USER	=> q{POP Error in USER},
	 POP_PASS	=> q{POP Error in PASS (Invalid password?)},
	 POP_DELE	=> q{POP Error in DELE},
	 POP_POPSTAT	=> q{POP Error in STAT},
	 POP_QUIT	=> q{POP Error in QUIT},
	 SMTP_CONNECT	=> q{Error connecting to SMTP server},
	 SMTP_MAIL	=> q{SMTP Error in MAIL FROM},
	 SMTP_RCPT	=> q{SMTP: Check your destination addresses},
	 SMTP_DATA	=> q{SMTP Error in DATA},
	 SMTP_HDATASEND	=> q{SMTP Error sending message header},
	 SMTP_BDATASEND	=> q{SMTP Error sending message body},
	 SMTP_DATAEND	=> q{SMTP Error committing message},
	 SMTP_QUIT	=> q{SMTP Error in QUIT},
	 CHK_SPAM_ONE	=> q{spam message},
	 CHK_SPAM_MANY	=> q{spam messages},
	 CHK_DEL_ONE	=> q{message deleted},
	 CHK_DEL_MANY	=> q{messages deleted},
	 TRUNC_START	=> q{[only },
	 TRUNC_END	=> q{octets shown]},
	 ATTACH		=> q{attach},
	 MSG_SHORT	=> q{Message does not have that many segments},
     },
     es =>
     {
	 HANDLE_CMD_ERR	=> q{Error en el comando},
	 ACCOUNT_OK	=> q{ok},
	 ALIAS_OK	=> q{ha sido actualizado},
	 LANG_OK	=> q{Interfaz en},
	 SEND_OK	=> q{Enviado correctamente},
	 DELETE_OK	=> q{borrado correctamente},
	 REPLY_OK	=> q{contestado correctamente},
	 FWD_OK		=> q{re-enviado ok},
	 LIST_NO_REG	=> q{Use .ACCOUNT para asociar una cuenta de correo},
	 HEAD_SUBJECT	=> q{Asunto:},
	 HEAD_DATE	=> q{Fecha:},
	 HEAD_FROM	=> q{De:},
	 HEAD_PHONE	=> q{Tel:},
	 REPLY_YOU	=> q{Usted},
	 REPLY_SAID	=> q{dijo:},
	 MSG_COUNT_ONE	=> q{Mensaje},
	 MSG_COUNT_MANY	=> q{Mensajes},
	 MSG_COUNT_LAST	=> q{Ultimo},
	 HTML_TRANS	=> q{[Traducido de HTML]},
	 FETCH_NOMSG	=> q{Error POP. No existe el mensaje},
	 FETCH_MIME	=> q{Error interpretando mensaje MIME},
	 FETCH_BODY	=> q{Error POP en la extraccion del mensaje},
	 POP_CONNECT	=> q{Error POP conectandose al servidor},
	 POP_USER	=> q{Error POP en comando USER},
	 POP_PASS	=> q{Error POP en comando PASS (Clave incorrecta?)},
	 POP_DELE	=> q{Error POP en comando DELE},
	 POP_POPSTAT	=> q{Error POP en comando STAT},
	 POP_QUIT	=> q{Error POP en comando QUIT},
	 SMTP_CONNECT	=> q{Error en conexion al servidor SMTP},
	 SMTP_MAIL	=> q{Error SMTP en comando MAIL FROM},
	 SMTP_RCPT	=> q{SMTP: Revise direcciones de destino},
	 SMTP_DATA	=> q{Error SMTP en comando DATA},
	 SMTP_HDATASEND	=> q{Error SMTP enviando encabezado del mensaje},
	 SMTP_BDATASEND	=> q{Error SMTP enviando el cuerpo del mensaje},
	 SMTP_DATAEND	=> q{Error SMTP terminando el envio},
	 SMTP_QUIT	=> q{Error SMTP terminando la sesion},
	 CHK_SPAM_ONE	=> q{mensaje spam},
	 CHK_SPAM_MANY	=> q{mensajes spam},
	 CHK_DEL_ONE	=> q{mensaje borrado},
	 CHK_DEL_MANY	=> q{mensajes borrados},
	 TRUNC_START	=> q{[solo se muestra un bloque de },
	 TRUNC_END	=> q{octetos]},
	 ATTACH		=> q{anexo},
	 MSG_SHORT	=> q{El mensaje no contiene tantos segmentos},
     },
     );

sub _msg
{
    my $self	= shift;
    my $code	= shift;

    my $lang = $self->{_state}->{lang} || $DefaultLanguage;
    return ${$self->{messages}}{$lang}->{$code} || "*** NO MESSAGE $lang/$code ***";
}

sub _init_state
{
    my $self	= shift;

    $self->{pops} && $self->{pops}->quit;
    $self->{e} && $self->{e}->purge;

    $self->{trunc}	= undef;
    $self->{mime}	= undef;
    $self->{body}	= undef;
    $self->{pops}	= undef;
    $self->{msg}	= undef;
    $self->{num}	= undef;
    $self->{e}		= undef;

    $self->{part}	= 1;
}

sub _fetch_state
{
    my $self	= shift;
    my $source	= shift;
    warn "Email: Fetch state for $source\n" if $Debug;
    $self->{_state} = $self->{state}->{$source};
    $self->{_state} || $self->fixup_state($source);
    $self->{_state} ||= {};
}

sub _store_state
{
    my $self	= shift;
    my $source	= shift;
    warn "Email: Store state for $source\n" if $Debug;
    $self->{state}->{$source} = $self->{_state};
}

sub _canon_ref
{
    my $ref	= shift;
    $$ref = lc $$ref unless $$ref =~  m/[[:lower:]]/;
    return $ref;
}

sub init
{
    my $self = shift;
    %Languages = abbrev keys %SupportedLanguages;
    $self->{abbrevs} = { abbrev keys %{$self->{cmds}} };

				# These are used to convert messages back
				# to plain ASCII

    $self->{map} = Unicode::Map8->new('ASCII');

    for my $m (
	       [ ' ', [ 160 ] ], [ '!', [ 161 ] ], [ 'c', [ 162, 231 ] ],
	       [ 'L', [ 163 ] ], [ '*', [ 164, 188 .. 190 ] ], 
	       [ 'Y', [ 165 ] ], [ '|', [ 166 ] ], [ 'S', [ 167 ] ],
	       [ '^', [ 168 ] ], [ 'C', [ 169, 199 ] ], 
	       [ 'a', [ 170, 224 .. 230 ] ], [ '<', [ 171 ] ],
	       [ '!', [ 172 ] ], [ '-', [ 173, 175 ] ], [ 'R', [ 174 ] ],
	       [ 'o', [ 176, 186 ] ], [ '+', [ 177 ] ], [ '2', [ 178 ] ],
	       [ '3', [ 179 ] ], [ 'u', [ 181 ] ], [ 'P', [ 182, 222, 254 ] ],
	       [ '.', [ 183 ] ], [ ',', [ 184 ] ], [ '1', [ 185 ] ],
	       [ '>', [ 187 ] ], [ '?', [ 191 ] ], [ 'A', [ 192 .. 198 ] ],
	       [ 'E', [ 200 .. 203, 208 ] ], [ 'I', [ 204 .. 207 ] ],
	       [ 'N', [ 209 ] ], [ 'O', [ 210 .. 214, 216 ] ],
	       [ 'x', [ 215 ] ], [ 'U', [ 217 .. 220 ] ], [ 'Y', [ 221 ] ],
	       [ 'B', [ 223 ] ], [ 'e', [ 232 .. 235, 240 ] ],
	       [ 'i', [ 236 .. 239 ] ], [ 'n', [ 241 ] ],
	       [ 'o', [ 242 .. 246, 248 ] ], [ '/', [ 247 ] ],
	       [ 'u', [ 249 .. 251 ] ], [ 'y', [ 252, 255 ] ],
	       )
    {
	for (@{$m->[1]})
	{
	    $self->{map}->addpair($_, ord($m->[0]));
	}
    }

    $self->{map}->default_to16(ord('?'));
    $self->{map}->default_to8(ord('?'));
    return $self;
}

=pod

The following methods are provided:

=over 4

=item C<-E<gt>new()>

Creates a new C<SMS::Handler::Email> object. It accepts parameters as a
number of key / value pairs. The following parameters are supported.

=over 2

=item C<queue =E<gt> $queue_obj>

An object obeying the interface defined in L<Queue::Dir>, where the
response message generated by this module will be stored.

=item C<state =E<gt> $ref_to_hash>

Reference to a (potentially C<tie()>d) hash where state about the user
will be stored. Passwords will be stored in this hash, under the
protection of reversible crypto. Therefore, care must be taken to
prevent unauthorized access to this.

=item C<secret =E<gt> $my_secret_phrase>

A secret phrase used to obscure the passwords stored for the users.

=item C<addr =E<gt> $my_addr>

The address assigned to this service, in B<pon.npi.phone> format. The
destination address of the SMS, must match this argument. If this
address is left unspecified, the SMS will be accepted no matter what
destination address is used.

=item C<pop =E<gt> $your_pop_server>

The name or IP address of the POP server.

=item C<smtp =E<gt> $your_smtp_server>

The name or IP address of the SMTP server.

=item C<maxlen =E<gt> $max_sms_length>

Maximum length of an SMS. Defaults to 160.

=item C<maxfetch =E<gt> $max_message_length>

The amount of bytes to fetch from the body of the email. Defaults to
1024 bytes.

=item C<compact =E<gt> $fold_whitespace>

If set to a true value (the default) forces successions of whitespace
to be folded into single spaces. This generally improves readability
of the SMS.

=item C<spamcheck =E<gt> $obj>

If passed, this is assumed to be an object supporting a
C<-E<gt>check()> method as described in L<Mail::SpamAssassin>. This is
used to test fetched messages for SPAM-iness.

=item C<cmds -E<gt> $hashref>

Allows the specification of a new command table which overrides the
default.

=item C<maxspam -E<gt> $max>

Defines the maximum number of messages to check for spamminess for
each B<CHECK> command. Defaults to test all the messages. Note that
checking a large number of messages at once can take very long.

=back

=cut

sub new 
{
    my $name	= shift;
    my $class	= ref($name) || $name;

    my %self = validate_with 
	( 
	  params	=> \@_,
	  ignore_case	=> 1,
	  strip_leading	=> '-',
	  spec => 
	  {
	      queue =>
	      {
		  type		=> OBJECT,
		  can		=> [ qw(store) ],
	      },
	      state =>
	      {
		  type		=> HASHREF,
	      },
	      secret =>
	      {
		  type		=> SCALAR,
	      },
	      addr =>
	      {
		  type		=> SCALAR,
		  default	=> undef,
		  callbacks	=>
		  {
		      'address format' => sub { $_[0] =~ /^\d+\.\d+\.\d+$/; }
		  }
	      },
	      pop =>
	      {
		  type		=> SCALAR,
	      },
	      smtp =>
	      {
		  type		=> SCALAR,
	      },
	      maxlen =>
	      {
		  type		=> SCALAR,
		  default	=> 160,
	      },
	      maxfetch =>
	      {
		  type		=> SCALAR,
		  default	=> 1024,
	      },
	      compact =>
	      {
		  type		=> SCALAR,
		  default	=> 1,
	      },
	      spamcheck =>
	      {
		  type		=> OBJECT,
		  default	=> undef,
		  can		=> [ qw(check) ],
	      },
	      spammax =>
	      {
		  type		=> SCALAR,
		  default	=> undef,
		  callbacks	=>
		  {
		      'must be possitive' => sub {
			  $_[0] > 0;
		      },
		  },
	      },
	      cmds =>
	      {
		  type		=> HASHREF,
		  default	=>
		  {
		      ACCOUNT	=> \&_CMD_ACCOUNT, 
		      ALIAS	=> \&_CMD_ALIAS, 
		      CHECK	=> \&_CMD_CHECK, 
		      SEND	=> \&_CMD_SEND, 
		      INTERFACE	=> \&_CMD_INTERFACE,
		      LIST	=> \&_CMD_LIST,
		      DELETE	=> \&_CMD_DELETE,
		      REPLY	=> \&_CMD_REPLY,
		      ALL	=> \&_CMD_REPLY_ALL,
		      FORWARD	=> \&_CMD_FORWARD,
		      GET	=> \&_CMD_GET,
		      HELP	=> \&_CMD_HELP,
		  }
	      },
	      help =>
	      {
		  type         => HASHREF,
                  default      => \%Help
	      },
              messages =>
              {
                  type         => HASHREF,
                  default      => \%Messages
              }
	  }
	  );
    if ($self{addr}) 
    {
	($self{ton}, $self{npi}, $self{number}) = split(/\./, $self{addr}, 3);
    }

    $self{mp} = new MIME::Parser;
    $self{mp}->ignore_errors(1);
    $self{mp}->extract_uuencode(1);

    $self{body}	= '';
    $self{head}	= undef;
    $self{wd}	= undef;
    $self{part} = 0;

    my $ret = bless \%self, $class;

    $self{parser} = 
    {
	'text/html' => 
	  HTML::Parser->new
	      (
	       api_version => 3,
	       default_h		=> [ "" ],
	       start_h		=>
	       [ sub 
		 {
		     my $p	= shift;
		     my $tag	= shift;
		     my $attr	= shift;
		     
		     return unless ($tag eq 'img');
		     $ret->{body} .= '[IMG';
		     $ret->{body} .= ' ' . $attr->{alt} if $attr->{alt};
		     $ret->{body} .= ']';
		     
		     $p->eof if length($ret->{body})
			 > $ret->{part} * $ret->{maxfetch};
		 }, 
		 "self, tagname, attr" ],
	       
	       text_h =>
	       [ sub
		 {
		     my $p = shift;
		     $ret->{body} .= shift;
		     $p->eof if length($ret->{body})
			 > $ret->{part} * $ret->{maxfetch};
		 },
		 "self, dtext" ],
	       ),
    };

    $ret->{parser}->{'text/html'}->ignore_elements(qw(script style));
    $ret->{parser}->{'text/html'}->strict_comment(1);
    return $ret->init;
}

=pod

=item C<-E<gt>handle()>

Process the given SMS. Commands are taken from a dispatch table and
appropiate handlers are called. Commands must be in the first line of
the SMS.

An exception to this rule, is the fancy syntax supported by some
phones, that looks like

    you@some.where(subject)this is the message body
    you@some.where (subject) this is the message body
    you(subject)this is the message body
    you (subject) this is the message body

This syntax is transparently converted to our command based syntax.

=cut

sub handle
{
    my $self = shift;
    my $hsms = shift;

    warn "Email: handle for ", $hsms->{source_addr}, "\n" if $Debug;

    $self->fixup_sms($hsms);

    return $self->SUPER::handle($hsms, @_);
}

=pod

=item C<-E<gt>dispatch_error>

Produce an error when a given command does not exist. Causes the
current SMS to be discarded from the queue.

=cut

sub dispatch_error
{
    my $self = shift;
    my $hsms = shift;
    my $source = shift;
    my $msg = shift;

    warn "Email: command not understood in $$msg\n" if $Debug;
    $self->_answer($hsms, \ ($self->_msg('HANDLE_CMD_ERR') 
			     . " <$$msg>"));
    return SMS_STOP | SMS_DEQUEUE;
}

=pod

=item C<-E<gt>_CMD_ACCOUNT>

Handler method for the ACCOUNT command. Note that access to the
underlying hash (C<$self-E<gt>{state}>) must be done in a manner that
C<MLDBM> likes, as most likely the passed hash is tied using this
class.

Also, the implementation must assume that other items of state
information might be stored in that hash. Those items should be
preserved.

=cut

sub _CMD_ACCOUNT
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

#    warn "# I'm here with msg = $$r_msg\n";
#    warn "# I'm here with body = $$r_body\n";

    $$r_msg =~ s/^\.\w+\s+(\S+)\s+(.+)\s*//;

    return unless defined $1 and defined $2;

    warn "Email: account map $source -> $1\n" if $Debug;
    $self->_init_state;
    $self->_fetch_state($source);
    $self->{_state}->{login} = $1;
    $self->{_state}->{passwd} = $self->_crypt($2);
    $self->{_state}->{ac_time} = time;
    $self->_store_state($source);
    $self->_init_state;
    $self->_answer($hsms, \ ($self->{_state}->{login} 
			     . ' ' . $self->_msg('ACCOUNT_OK')));
    return 1;
}

=pod

=item C<-E<gt>_CMD_ALIAS>

Handler method for the ALIAS command.

=cut

sub _CMD_ALIAS
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s+([^\s]+))?\s+(\w+)\s*//;

    return unless defined $1;

    my $alias = lc $3;
    my $email = lc $1;
    
    warn "Email: _CMD_ALIAS $alias $email\n" if $Debug;

    $self->_init_state;
    $self->_fetch_state($source);

    unless ($self->_authen($hsms, $source))
    {
	warn "Email: authentication failed for $source\n" if $Debug;
	return;
    }

    if ($email)
    {
	$self->{_state}->{alias}->{$alias} = $email;
	warn "Email: stored $alias => $email\n" if $Debug;
    }
    else
    {
	delete $self->{_state}->{alias}->{$alias};
	warn "Email: deleted $alias\n" if $Debug;
    }

    $self->_store_state($source);

    $self->_answer($hsms, \ ($alias . ' ' . $self->_msg('ALIAS_OK') 
			     . ". $self->{num} " . 
			     ($self->{num} == 1 ? 
			      $self->_msg('MSG_COUNT_ONE') :
			      $self->_msg('MSG_COUNT_MANY'))));
    $self->_init_state;
    return 1;
}
=pod

=item C<-E<gt>_CMD_INTERFACE>

Handler for setting the interface language.

=cut

sub _CMD_INTERFACE
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

#    warn "# I'm here with msg = $$r_msg\n";
#    warn "# I'm here with body = $$r_body\n";
    
    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^\s+(\S+)\s*//;

    return unless defined $1;

    $self->_init_state;
    $self->_fetch_state($source);

    unless (exists $SupportedLanguages{$Languages{uc $1}})
    {
	warn "Email: unsupported language map $source -> $1\n" if $Debug;
	return 0;
    }

    my $lang = $SupportedLanguages{$Languages{uc $1}};

    warn "Email: language map $source -> $lang\n" if $Debug;

    $self->{_state}->{lang} = $lang;
    $self->_store_state($source);
    
    $self->_answer($hsms, \ ( $self->_msg('LANG_OK') . " <$lang>"));
    $self->_init_state;
    return 1;
}

=pod

=item C<-E<gt>_CMD_SEND>

Handler method for the SEND command.

=cut

sub _CMD_SEND
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^\s+(\S+)\s*(.*)\s*$//;

    return unless defined $1 and defined $2;

    my $to	= $1;
    my $subject	= $2;

    warn "Email: _CMD_SEND $to $subject\n" if $Debug;

    $self->_init_state;
    $self->_fetch_state($source);

    $self->{body} = $ { _canon_ref($r_body)};

    if ($self->_authen($hsms, $source)
	and $self->_deliver($hsms, $source, $self->_expanded_addresses($to), 
			    $subject))
   {
	warn "Email: send from $source to $to ok with $self->{num} msgs\n" 
	    if $Debug;
	if ($self->{num} == 1)
	{
	    $self->_answer($hsms, \ ( $self->_msg('SEND_OK') 
				      . ". $self->{num} " 
				      . $self->_msg('MSG_COUNT_ONE')));
	}
	else
	{
	    $self->_answer($hsms, \ ( $self->_msg('SEND_OK') 
				      . ". $self->{num} " 
				      . $self->_msg('MSG_COUNT_MANY')));
	}
	$self->_init_state;
	return 1;
    }

    warn "Email: deliver for $source failed\n";
    $self->_init_state;
    return;
}

=pod

=item C<-E<gt>_CMD_LIST>

Handler method for the LIST command.

=cut

sub _CMD_LIST
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+\s*//;

    $self->_init_state;
    $self->_fetch_state($source);

    if (exists $self->{_state}->{login})
    {
	if ($self->_authen($hsms, $source))
	{
	    my $last = $self->{pops}->last;
	    warn "Email: list with $self->{num} msgs\n" if $Debug;
	    if ($self->{num} == 1)
	    {
		$self->_answer($hsms, 
			       \ ($self->{num} . " " .
				  $self->_msg('MSG_COUNT_ONE')
				  . ($last ? ". " 
				     . $self->_msg('MSG_COUNT_LAST')
				     . " $last" : '')));
	    }
	    else
	    {
		$self->_answer($hsms, 
			       \ ($self->{num} . " " .
				  $self->_msg('MSG_COUNT_MANY')
				  . ($last ? ". " 
				     . $self->_msg('MSG_COUNT_LAST')
				     . " $last" : '')));
	    }
	    $self->_init_state;
	    return 1;
	}

	warn "Email: authentication failed for $source\n" if $Debug;
	$self->_init_state;
	return;
    }
    else
    {
	warn "Email: No account for $source\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('LIST_NO_REG')));
	$self->_init_state;
	return;
    }
}

=pod

=item C<-E<gt>_CMD_HELP>

Handler method for the HELP command. Sends a SMS message for each
supported command, containing the help messages defined.

=cut

sub _CMD_HELP
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s+(\w+))?\s*//;

    my $cmd = $2;

    warn "Email: $source wants help on ", 
    (defined $cmd ? $cmd : 'all commands '), 
    "\n" if $Debug;

    $self->_init_state;
    $self->_fetch_state($source);

    my $lang = $self->{_state}->{lang} || $DefaultLanguage;
    my @list;

    if ($cmd)
    {
	$cmd = uc $cmd;
	$cmd = $self->{abbrevs}->{$cmd} unless exists $self->{cmds}->{$cmd};
	@list = grep { $cmd eq $_ } keys %{ $self->{cmds} };
    }

    @list = keys %{$self->{help}} unless @list;

    $self->_answer($hsms, \ ($_ . "\n" . 
			     ${$self->{help}}{$_}->{$lang})) for (sort @list);

    $self->_init_state;
    return 1;
}

=pod

=item C<-E<gt>_CMD_DELETE>

Handler method for the DELETE command.

=cut

sub _CMD_DELETE
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^\s*(\S+)?\s*//;

    $self->_init_state;
    $self->_fetch_state($source);
    $self->{msg} = $1 || $self->{num} || 1;
    
    if ($self->_dele($hsms, $source)
	and $self->_quit($hsms, $source))
    {
	warn "Email: $source delete $source $self->{msg}\n" if $Debug;
	if ($self->{num} == 1)
	{
	    $self->_answer($hsms, \ ( $self->{msg} . " " 
				      . $self->_msg('DELETE_OK') 
				      . ". $self->{num} " 
				      . $self->_msg('MSG_COUNT_ONE')));
	}
	else
	{
	    $self->_answer($hsms, \ ( $self->{msg} . " "
				      . $self->_msg('DELETE_OK') 
				      . ". $self->{num} " 
				      . $self->_msg('MSG_COUNT_MANY')));
	}
	$self->_init_state;
	return 1;
    }
    $self->_init_state;
    return;
}



=pod

=item C<-E<gt>_CMD_REPLY>

Handler method for the REPLY command.

=cut

sub _CMD_REPLY
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s*!)?\s*(\d+)?\s*//;

				# Fetch the selected message
    $self->_init_state;
    $self->_fetch_state($source);

    $self->{trunc} = !$1;
    $self->{mime} = $1;
    $self->{msg} = $2;

    if (defined $self->{msg})
    {
	$self->{msg} ||= 1;
    }
    else
    {
	$self->_authen($hsms, $source);
	$self->{msg} ||= $self->{num} || 1;
    }

    
    if ($self->_fetch($hsms, $source))
    {
	
	my $from = $self->d_m($self->{head}->get('From'))
		|| $self->_msg('REPLY_YOU');

	my $sub = $self->d_m($self->{head}->get('Subject'));

	my $text = '';
	
	substr($text, 0, 0, "\n");	
	substr($text, 0, 0, $sub);
	substr($text, 0, 0, 'Subject: ');

	substr($text, 0, 0, $self->{head}->get('Date'));
	substr($text, 0, 0, 'Date: ');

	if ($self->{head}->get('Cc'))
	{
	    substr($text, 0, 0, $self->d_m($self->{head}->get('Cc')));
	    substr($text, 0, 0, 'Cc: ');
	}

	if ($self->{head}->get('To'))
	{
	    substr($text, 0, 0, $self->d_m($self->{head}->get('To')));
	    substr($text, 0, 0, 'To: ');
	}

	substr($text, 0, 0, $from);
	substr($text, 0, 0, 'From: ');

	chomp $from;

	substr($text, 0, 0, "\n\n");	
	substr($text, 0, 0, $self->_msg('REPLY_SAID'));	
	substr($text, 0, 0, "$from ");

	substr($text, 0, 0, "\n\n\n");	
	substr($text, 0, 0, $ {_canon_ref($r_body)});

	substr($sub, 0, 0, "Re: ");

	$self->{e}->add_part
	    (MIME::Entity->build(Type => 'text/plain',
				 Data => $text),
	     0);
	$self->{e}->sync_headers(Length => 'COMPUTE');

	if ($self->{mime})
	{
	    $self->{body} = '';
	}
	else 
	{
	    $self->_truncate($hsms, $source);
	}

	if ($self->_deliver($hsms, $source, 
			    _addresses($self->{head}->get('Reply-To')
				       || $self->{head}->get('From')), 
			    $sub))
	{
	    warn "Email: $source reply $self->{msg}\n" if $Debug;
	    $self->_answer($hsms, \ ( $self->{msg} . " "
				      . $self->_msg('REPLY_OK')));
	    $self->_init_state;
	    return 1;
	}
    }    
    
    warn "Email: Failed $source reply $self->{msg}\n" if $Debug;
    $self->_init_state;
    return 0;
}

=pod

=item C<-E<gt>_CMD_REPLY_ALL>

Handler method for the ALL command.

=cut

sub _CMD_REPLY_ALL
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s*!)?\s*(\d+)?\s*//;

				# Fetch the selected message
    $self->_init_state;
    $self->_fetch_state($source);

    $self->{trunc} = !$1;
    $self->{mime} = $1;
    $self->{msg} = $2;

    if (defined $self->{msg})
    {
	$self->{msg} ||= 1;
    }
    else
    {
	$self->_authen($hsms, $source);
	$self->{msg} ||= $self->{num} || 1;
    }

    if ($self->_fetch($hsms, $source))
    {
	
	my $from = $self->d_m($self->{head}->get('From'))
		|| $self->_msg('REPLY_YOU');

	my $sub = $self->d_m($self->{head}->get('Subject'));

	my $text = '';
	
	substr($text, 0, 0, "\n");	
	substr($text, 0, 0, $sub);
	substr($text, 0, 0, 'Subject: ');

	substr($text, 0, 0, $self->{head}->get('Date'));
	substr($text, 0, 0, 'Date: ');

	if ($self->{head}->get('Cc'))
	{
	    substr($text, 0, 0, $self->d_m($self->{head}->get('Cc')));
	    substr($text, 0, 0, 'Cc: ');
	}

	if ($self->{head}->get('To'))
	{
	    substr($text, 0, 0, $self->d_m($self->{head}->get('To')));
	    substr($text, 0, 0, 'To: ');
	}

	substr($text, 0, 0, $from);
	substr($text, 0, 0, 'From: ');

	chomp $from;

	substr($text, 0, 0, "\n\n");	
	substr($text, 0, 0, $self->_msg('REPLY_SAID'));	
	substr($text, 0, 0, "$from ");

	substr($text, 0, 0, "\n\n\n");	
	substr($text, 0, 0, $ {_canon_ref($r_body)});

	substr($sub, 0, 0, "Re: ");

	$self->{e}->add_part
	    (MIME::Entity->build(Type => 'text/plain',
				  Data => $text),
	     0);
	$self->{e}->sync_headers(Length => 'COMPUTE');

	if ($self->{mime})
	{
	    $self->{body} = '';
	}
	else 
	{
	    $self->_truncate($hsms, $source);
	}

	if ($self->_deliver($hsms, $source, 
			    _addresses(($self->{head}->get('Reply-To')
					|| $self->{head}->get('From')) 
				       . ($self->{head}->get('Cc') ?
					  ',' . $self->{head}->get('Cc') :
					  '')), 
			    $sub))
	{
	    warn "Email: $source reply $self->{msg}\n" if $Debug;
	    $self->_answer($hsms, \ ( $self->{msg} . " "
				      . $self->_msg('REPLY_OK')));
	    $self->_init_state;
	    return 1;
	}
    }    
    
    warn "Email: Failed $source reply $self->{msg}\n" if $Debug;
    $self->_init_state;
    return 0;
}

=pod

=item C<-E<gt>_CMD_FORWARD>

Handler method for the FORWARD command.

=cut

sub _CMD_FORWARD
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s*!)?(\s+(\d+))?\s*(\S+)\s*$//;

    return unless defined $4;

				# Fetch the selected message
    $self->_fetch_state($source);
    $self->_init_state;

    $self->{mime} = $1;
    $self->{trunc} = !$1;
    $self->{msg} = $3;
    my $to  = $4;

    if (defined $self->{msg})
    {
	$self->{msg} ||= 1;
    }
    else
    {
	$self->_authen($hsms, $source);
	$self->{msg} ||= $self->{num} || 1;
    }

    if ($self->_fetch($hsms, $source))
    {
	my $from = $self->d_m($self->{head}->get('From'))
		|| $self->_msg('REPLY_YOU');

	my $sub = $self->d_m($self->{head}->get('Subject'));

	my $text = '';
	
	substr($text, 0, 0, "\n");	
	substr($text, 0, 0, $sub);
	substr($text, 0, 0, 'Subject: ');

	substr($text, 0, 0, $self->{head}->get('Date'));
	substr($text, 0, 0, 'Date: ');

	if ($self->{head}->get('Cc'))
	{
	    substr($text, 0, 0, $self->d_m($self->{head}->get('Cc')));
	    substr($text, 0, 0, 'Cc: ');
	}

	if ($self->{head}->get('To'))
	{
	    substr($text, 0, 0, $self->d_m($self->{head}->get('To')));
	    substr($text, 0, 0, 'To: ');
	}

	substr($text, 0, 0, $from);
	substr($text, 0, 0, 'From: ');

	chomp $from;

	substr($text, 0, 0, "\n\n");	
	substr($text, 0, 0, $self->_msg('REPLY_SAID'));	
	substr($text, 0, 0, "$from ");

	substr($text, 0, 0, "\n\n\n");	
	substr($text, 0, 0, $ { _canon_ref($r_body)});

	substr($sub, 0, 0, "Fwd: ");

	my %mime = ();

	$self->{e}->add_part(MIME::Entity->build(Type => 'text/plain',
						 Data => $text),
			     0);
	$self->{e}->sync_headers(Length => 'COMPUTE');

	if ($self->{mime})
	{
	    $self->{body} = '';
	}
	else 
	{
	    $self->_translate($hsms, $source);
	    $self->_truncate($hsms, $source);
	}

	if ($self->_deliver($hsms, $source, 
			    $self->_expanded_addresses($to), $sub))
	{
	    warn "Email: $source forward $self->{msg}\n" if $Debug;
	    $self->_answer($hsms, \ ( $self->{msg} . " " . 
				      $self->_msg('FWD_OK')));
	    $self->_init_state;
	    return 1;
	}
    }    
    
    warn "Email: Failed $source forward $self->{msg}\n" if $Debug;
    $self->_init_state;
    return 0;
}

=pod

=item C<-E<gt>_CMD_GET>

Handler method for the GET command.
    
=cut

sub _CMD_GET
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s+(\d+))?(\s+(\d+))?\s*//;

    $self->_init_state;
    $self->_fetch_state($source);

    $self->{msg} = $2;
    $self->{part} = $4 || 1;

    if (defined $self->{msg})
    {
	$self->{msg} ||= 1;
    }
    else
    {
	$self->_authen($hsms, $source);
	$self->{msg} ||= $self->{num} || 1;
    }

    if ($self->_fetch($hsms, $source)
	and $self->_translate($hsms, $source)
        and $self->_truncate($hsms, $source))
    {
				# Place the required headers in the email,
				# in as compact a way as possible.

	substr($self->{body}, 0, 0, "\n");
	substr($self->{body}, 0, 0, $self->d_m($self->{head}->get('Subject')));
	substr($self->{body}, 0, 0, " ");
	substr($self->{body}, 0, 0, $self->_msg('HEAD_SUBJECT'));
	
	substr($self->{body}, 0, 0,
	       strftime "%d/%m/%y %H:%M\n", 
	       localtime(str2time($self->{head}->get('Date'))));
	substr($self->{body}, 0, 0, " ");
	substr($self->{body}, 0, 0, $self->_msg('HEAD_DATE'));
	
	substr($self->{body}, 0, 0, $self->d_m($self->{head}->get('From')));
	substr($self->{body}, 0, 0, " ");
	substr($self->{body}, 0, 0, $self->_msg('HEAD_FROM'));
	if ($self->{head}->get('X-SMS-From'))
	{
	    substr($self->{body}, 0, 0, 
		   $self->{head}->get('X-SMS-From'));
	    substr($self->{body}, 0, 0, " ");
	    substr($self->{body}, 0, 0, $self->_msg('HEAD_PHONE'));
	}

	warn "Email: Get $self->{msg}\n" if $Debug;
	$self->_answer($hsms, \$self->{body});
	$self->_init_state;
	return 1;
    }
    $self->_init_state;
    return 0;
}


=pod

=item C<-E<gt>_CMD_CHECK>

Handler method for the CHECK command. Only makes sense if
C<-E<gt>new()> is called with B<spamcheck> defined. Currently a noop.

=cut

sub _CMD_CHECK
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $r_msg	= shift;
    my $r_body	= shift;

    $$r_msg =~ s/^\.\w+//;
    $$r_msg =~ s/^(\s+(!))?\s*//;

    warn "Email: CHECK: Temporarily out of order\n";
    return;

}

				###########################################
				# Utility functions related to SMS handling
				###########################################

				# Decode a string

sub d_r 
{ 
    my $self	= shift;

    $self->{body} = $self->{map}->to8
	($self->{map}->to16($self->{wd}->decode($self->{body})));

    return 1;
}

sub d_t
{
    my $self	= shift;

    return $self->{map}->to8
	($self->{map}->to16($self->{wd}->decode(shift||'')));

}

sub d_m 
{ 
    my $self = shift;
    return $self->{map}->to8
	($self->{map}->to16($self->{wd}->decode(shift||'')));
}

sub _do_answer
{
    my $self = shift;
    my $hsms = shift;
    my $r_part = shift;

    my $pdu = new Net::SMPP::PDU;

    $pdu->source_addr_ton($self->{ton});
    $pdu->source_addr_npi($self->{npi});
    $pdu->source_addr($self->{number});
    $pdu->dest_addr_ton($hsms->{source_addr_ton});
    $pdu->dest_addr_npi($hsms->{source_addr_npi});
    $pdu->destination_addr($hsms->{source_addr});
    $pdu->short_message($$r_part);
	
    my ($fh, $qid) = $self->{queue}->store;
    
    $pdu->nstore_fd($fh);
    
    unless ($fh->close)
    {
	warn "Email: Invalid response $qid: $!\n" if $Debug;
	$self->{queue}->unlock($qid);
	return;
    }
    
    warn "Email: Response $qid ok\n" if $Debug;
    $self->{queue}->unlock($qid);
    return 1;
}

sub _addresses
{
    my $addr = shift;
    warn "Email: parsing addresses from $addr\n" if $Debug;
    my @ret = map { $_->address } Mail::Address->parse($addr);
    warn "Email: addresses are ", join(', ', @ret), "\n" if $Debug;
    return \@ret;
}

sub _expanded_addresses
{
    my $self = shift;
    my $addr = shift;

    warn "Email: expanding addresses from $addr\n" if $Debug;

    my @ret = ();
    for my $a (Mail::Address->parse($addr))
    {
	if (defined $self->{_state}->{alias}->{lc $a->address})
	{
	    my ($t) = Mail::Address->parse
		($self->{_state}->{alias}->{lc $a->address});
	    push @ret, $t->address;
	}
	else
	{
	    push @ret, $a->address;
	}
    }
    warn "Email: expanded addresses are ", join(', ', @ret), "\n" if $Debug;
    return [ @ret ];
}

				# This method produces an answer
				# containing $msg as the short message
sub _answer
{
    my $self	= shift;
    my $hsms	= shift;
    my $msg	= shift;

    if (length($$msg) > $self->{maxlen})
    {


				# Here we'll split the message in actual
				# chunks and iterate through them until
				# we get the lengths right.

	my $r_msg = SMS::Handler::Utils::Split_msg($self->{maxlen}, $msg);
	$self->_do_answer($hsms, \$_) || return for @$r_msg;
    }
    else
    {
	$self->_do_answer($hsms, $msg) || return;
    }

    return 1;
}

sub _add_trunc
{
    my $self	= shift;
    my $source	= shift;

    $self->{body} .= "\n\n";
    $self->{body} .= $self->_msg('TRUNC_START');
    $self->{body} .= " " . $self->{maxfetch} . " ";
    $self->{body} .= $self->_msg('TRUNC_END');
    1;
}
				######################################
				# Utility function related to POP3 and
				# SMTP protocols
				######################################
sub _fetch
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;

    $self->{e} = undef;
    $self->{mp}->filer->purge;		# Get rid of old files

    return unless $self->{pops}
	or $self->_authen($hsms, $source);

    my $fh = new_tmpfile IO::File;

    unless ($self->{pops}->get($self->{msg}, $fh))
    {
	warn "Email: POP failure at GET $self->{msg}\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('FETCH_NOMSG')
				 . " ($self->{msg})"));
	return;
    }

    $fh->seek(0, SEEK_SET);

    my $error;			# MIME::Parser error
    
    eval { $self->{e} = $self->{mp}->parse($fh); };
    $error = ($@ || $self->{mp}->last_error);

    if ($error)
    {
	warn "Email: $source MIME parsing of $self->{msg}: $error\n" 
	    if $Debug;
	$self->_answer($hsms, \ ($self->_msg('FETCH_MIME')
				 . " ($self->{msg})"));
	$fh->close;
	$self->{e} = undef;
	$self->{mp}->filer->purge;
	return;
    }

    $fh->close;

    $self->_remove_alternatives
	if (lc $self->{e}->head->get('Content-Type') 
	    eq 'multipart/alternative');

    $self->{e}->make_multipart;
    $self->{head} = $self->{e}->head;

    $self->_setup_decoder($self->{e});

    return 1;
}

				# This might be a multipart/alternative
				# message. In this case, get rid of all
				# redundant parts and keep just one.

sub _remove_alternatives
{
    my $self = shift;

    warn "Email: Stripping multipart/alternative\n"
	if $Debug;

    $self->{e}->parts([$self->{e}->parts(0)]);
}

sub _setup_decoder
{
    my $self = shift;
    my $e = shift;
    
    if ($e 
	and $e->head->get('Content-Type')
	and $e->head->get('Content-Type') =~ m!charset="([^\"]+)"!)
    {
	$self->{wd} = MIME::WordDecoder->supported($1) 
	    || MIME::WordDecoder->supported('ISO-8859-1'); 
	warn "wd for $1 is $self->{wd}\n" if $Debug;
    }
    elsif ($self->{head}->get('Content-Type')
	   and $self->{head}->get('Content-Type') =~ m!charset="([^\"]+)"!)
    {
	$self->{wd} = MIME::WordDecoder->supported($1) 
	    || MIME::WordDecoder->supported('ISO-8859-1'); 
	warn "wd for $1 is $self->{wd}\n" if $Debug;
    }
    else
    {
        $self->{wd} = supported MIME::WordDecoder "ISO-8859-1";
	warn "default wd is $self->{wd}\n" if $Debug;
    }
}

sub _translate
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;

				# At this point, $self->{e} should be a 
				# MIME::Entity (always Multipart)

    unless ($self->_fetch_helper($hsms, $source, $self->{e}))
    {
	$self->{e} = undef;
	$self->{mp}->filer->purge;
	return;
    }
				# Fold whitespace as much as possible
				# if requested
    if ($self->{compact})
    {
	$self->{body} =~ s/^[[:space:]]*$/\n/mg;
	$self->{body} =~ s/[[:blank:]]+/ /g;
	$self->{body} =~ s/[\r\n]+/\n/msg;
    }
	
    return 1;
}

sub _truncate
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;

    $self->d_r();

    if (length($self->{body}) < ($self->{part} - 1) * $self->{maxfetch})
    {
	$self->_answer($hsms, \ ($self->_msg('MSG_SHORT')));
	return;
    }
    
    substr($self->{body}, 0, ($self->{part} - 1) * $self->{maxfetch}, '');

    if (length($self->{body}) > $self->{maxfetch})
    {
	$self->{body} = substr($self->{body}, 0, $self->{maxfetch});
	$self->_add_trunc($source);
    }

    return 1;
}

sub _fetch_helper
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $ent	= shift;

    return 1 if length($self->{body}) > $self->{part} * $self->{maxfetch};

    $self->_setup_decoder($ent);

    if (my @parts = $ent->parts)
    {
	for (@parts)
	{
	    return 1 if length($self->{body}) 
		> $self->{part} * $self->{maxfetch};
	    my $ret = $self->_fetch_helper($hsms, $source, $_);
	    return unless $ret;
	}
    }
    elsif (my $body = $ent->bodyhandle)
    {
	my $type = $ent->head->mime_type;
	warn "Email: $type: ", Digest::MD5::md5_hex($body->as_string), "\n"
	    if $Debug;
	if ($type eq 'text/plain')
	{
	    $self->{body} .= $body->as_string;
	}
	elsif ($type eq 'text/html')
	{
				# XXX - The assignment to $waste below
				# prevents the decoding process to turn
				# crazy after its first invocation. Looks
				# like a bug to me, but I'm unable to
				# replicate it with a smaller piece of code.
	    my $text = $body->as_string;
	    my $waste = Digest::MD5::md5_hex($text);
	    $self->{parser}->{$type}->parse($text);
	}
	else
	{
	    $self->{body} .= '[';
	    $self->{body} .= $self->_msg('ATTACH');
	    $self->{body} .= " $type ";
	    $self->{body} .= $ent->head->recommended_filename || '';
	    $self->{body} .= ']';
	}
    }
    return 1;
}

sub _dele
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my @msg	= map { /(\d+)-(\d+)/ ? $1 .. $2 : $_ } split /,/, 
    $self->{msg};

    return unless $self->{pops}
	or $self->_authen($hsms, $source);

    foreach (@msg)
    {
	unless ($self->{pops}->delete($_))
	{
	    warn "Email: POP failure at DELE $_\n" if $Debug;
	    $self->_answer($hsms, \ ($self->_msg('POP_DELE')
				     . " ($_)"));
	    return;
	}
    }

    unless (defined ($self->{num} = ($self->{pops}->popstat)[0]))
    {
	warn "Email: POP failure at POPSTAT\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('POP_POPSTAT')));
	return;
    }
    return 1;
}

sub _quit
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;

    return unless defined $self->{pops};

    unless ($self->{pops}->quit)
    {
	warn "Email: POP failure at QUIT\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('POP_QUIT')));
	return;
    }
    
    return 1;
}

sub _authen
{
    my $self = shift;
    my $hsms = shift;
    my $source = shift;

    $self->{pops} = Net::POP3->new($self->{pop},
				  Timeout => 30);
    unless ($self->{pops})
    {
	warn "Email: Can't connect to POP server: $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('POP_CONNECT')));
	return;
    }
    
    unless ($self->{pops}->user($self->{_state}->{login}))
    {
	warn "Email: POP failure at USER\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('POP_USER')));
	return;
    }

    unless ($self->{num} = $self->{pops}->pass
	    ($self->_crypt($self->{_state}->{passwd})))
    {
	warn "Email: POP failure at PASS\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('POP_PASS')));
	return;
    }

    $self->{num} += 0;
    return 1;
}

sub _deliver
{
    my $self	= shift;
    my $hsms	= shift;
    my $source	= shift;
    my $to	= shift;
    my $subject	= shift;
    my $r_head	= shift || {};

    my $smtp = Net::SMTP->new($self->{smtp},
			      Timeout => 30,
			      );

    unless ($smtp)
    {
	warn "Email: Can't connect to SMTP server: $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('SMTP_CONNECT')));
	return;
    }

    unless ($smtp->mail($self->{_state}->{login}))
    {
	warn "Email: SMTP error (MAIL FROM): $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('SMTP_MAIL')));
	return;
    }

    foreach (@$to)
    {
#	warn "Email: SMTP deliver $_\n";
	unless($smtp->to($_))
	{
	    warn "Email: SMTP error (RCPT TO $_): $!\n" if $Debug;
	    $self->_answer($hsms, \ ($self->_msg('SMTP_RCPT')
				     . " ($_)"));
	    return;
	}
    }

    my $e = MIME::Entity->build(Type => 'multipart/mixed',
				From => $self->{_state}->{login},
				'Reply-To' => $self->{_state}->{login},
				To => shift @$to,
				Cc => join(', ', @$to),
				Subject => $subject,
				'X-Mailer' => 'SMS::Handler::Email ' 
				. $VERSION,
				'X-SMS-From' => 
				$self->fixup_phone($hsms, $source),
				);

    $e->attach(Type => 'text/plain',
	       Data => $self->{body});

    if ($self->{e})
    {
	$e->add_part($_) for $self->{e}->parts;
    }

    $e->sync_headers(Length => 'COMPUTE');

    unless ($smtp->data)
    {
	warn "Email: SMTP error (DATA): $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('SMTP_DATA')));
	return;
    }

    unless ($smtp->datasend($e->as_string))
    {
	warn "Email: SMTP error (DATASEND header): $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('SMTP_HDATASEND')));
	return;
    }

    unless ($smtp->dataend)
    {
	warn "Email: SMTP error (DATAEND): $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('SMTP_DATAEND')));
	return;
    }

    unless ($smtp->quit)
    {
	warn "Email: SMTP error (QUIT): $!\n" if $Debug;
	$self->_answer($hsms, \ ($self->_msg('SMTP_QUIT')));
	return;
    }

    return 1;
}

=pod

=head2 CUSTOMIZABLE HANDLERS

To further enhance the customization of this class, the following
functions can be overriden to tweak the behavior of this module.

=over

=item C<fixup_state($self, $source)>

This method is invoked after issuing the call to
C<-E<gt>_fetch_state()> (and failing). Its main purpose is to allow
the definition of default credentials for every user. It can return a
false value (the default) to cause an error to be reported when no
credentials are available. This function should provide values to
C<$self-E<gt>{_state}>. It is called with the source address of the
cellular phone in the format C<NPI.TON.NUMBER>.

=cut

sub fixup_state { return; }

=pod

=item C<fixup_phone($self, $hsms, $phone)>

This function is used to convert a number in C<NPI.TON.NUMBER> format
to a phone number as expected by cellular users. It must return the
phone number as expected by the user.

=cut

sub fixup_phone { return (split(/\./, $_[2], 3))[2]; }

=pod

=item C<fixup_sms($self, $hsms)>

This function is invoked from within the C<-E<gt>handle> method,
before dispatching to the handlers. This can be used to perform custom
transformations in the messages before processing. The default method,
provides a translation from Nokia-like syntax into the expected
B<.SEND> syntax.

=cut

sub fixup_sms
{
    my $self = shift;
    my $hsms = shift;

				# This handles a somewhat common syntax
				# for writing an email on an SMS.
    
    if ($hsms->{short_message}
	=~ s/^(\(\d+\) )?\s*([^\.\(\)][^\(]*)\(([^\)]*)\)\s*//)
    {	
	warn "Email: Converting to .SEND syntax\n" if $Debug;
	substr($hsms->{short_message}, 0, 0, 
	       ".SEND $2 " . (defined($3) ? $3 : 'No Subject') . "\n");
    }
}

=pod

=back

=head2 ENCRYPTION OF THE USER PASSWORDS

The encription of the user passwords is intended to prevent a casual
observer looking at the hash, from getting the passwords. Since the
crypto is both, simplistic and reversible, you should assume that any
compromise of the hash containing the passwords lead directly to
password compromise.

=cut

sub _crypt
{
    my $self = shift;
    my $text = reverse shift;

    my $key = '';
    my $ret = '';

    $key .= $self->{secret} while length($key) < length($text);
    $key = substr($key, 0, length($text));
    
    while (my $k = chop ($key))
    {
	my $t = chop $text;
	$ret .= chr(ord($k) ^ ord($t));
    }

    return $ret;
}

1;

__END__

=pod

=back

=head2 EXPORT

None by default.

=head1 LICENSE AND WARRANTY

This code comes with no warranty of any kind. The author cannot be
held liable for anything arising of the use of this code under no
circumstances.

This code is released under the terms and conditions of the
GPL. Please see the file LICENSE that accompains this distribution for
more specific information.

This code is (c) 2002 Luis E. Muñoz.

=head1 HISTORY

$Log: Email.pm,v $
Revision 1.55  2003/03/13 20:41:54  lem
Fixed case where a command was not followed by any options or any whitespace

Revision 1.54  2003/03/10 22:07:31  lem
Messages were being mixed under certain conditions

Revision 1.53  2003/03/09 16:24:52  lem
Patch mpicone

Revision 1.52  2003/02/26 14:50:46  lem
Improved readability of replies and forwards.

Revision 1.51  2003/02/26 02:45:18  lem
Changed .ALIAS order as per compadre's patch

Revision 1.50  2003/02/19 15:25:12  lem
Fix for _setup_decoder bug

Revision 1.49  2003/02/18 20:50:30  lem
Added patch from luis

Revision 1.48  2003/02/18 15:57:29  lem
Reinstate msg number 0 == 1

Revision 1.47  2003/02/18 15:52:35  lem
Omitting the message number, tries to use the latest message

Revision 1.46  2003/02/17 18:48:28  lem
First attempt at handling multipart/alternative correctly

Revision 1.45  2003/02/13 13:12:23  lem
Fix typo in the docs. Added fixup_sms(). Changed the calling protocol for the rest of the remaining fixup_* methods (more power to them).

Revision 1.44  2003/02/12 15:22:39  lem
Patch from compadre. The help can be passed to ->new() and also, fixed a typo in the docs

Revision 1.43  2003/02/12 14:38:02  lem
Improved clean-up of attachments left behind

Revision 1.42  2003/02/12 00:50:33  lem
Message truncation is now working

Revision 1.41  2003/02/11 15:45:04  lem
Added fixup_phone and fixup_state

Revision 1.40  2003/02/10 17:34:01  lem
Added .ALL

Revision 1.39  2003/02/06 19:49:42  lem
Various variables and refs factored in the object

Revision 1.38  2003/02/04 21:33:16  lem
Added ! to .REPLY and .FORWARD. Testing is needed

Revision 1.37  2003/02/04 16:01:26  lem
Omitting msg now means "last". 0 == 1

Revision 1.36  2003/01/28 18:10:47  lem
Added lowercasing when the message body is in ALL CAPS. Added display of the origin phone number when the email was sent from a cellular.

Revision 1.35  2003/01/27 20:44:27  lem
.ACCOUNT now stores the date in which it executed in the hash

Revision 1.34  2003/01/14 20:32:34  lem
Got rid of Net::SMPP::XML

Revision 1.33  2003/01/08 02:39:03  lem
Body was not being updated by _CMD_SEND. "Nokia" format send command is now properly understood. First segment of the message is being sent by .FORWARD and .REPLY.

Revision 1.32  2003/01/05 00:49:08  lem
It seems that the bug is not in HTML::Parser either. Taking the md5_hex() of its input before invoking ->parse() seems to get rid of the problem under darwin. More testing is needed to find out where the bug manifests. I am guessing that Perl might be the culprit.

Revision 1.31  2003/01/04 03:38:03  lem
Current 8-bit conversion bug has been traced to HTML::Parser. Unable to reproduce in smaller sample program. Testing needed in another platform. The HTML::Parser, Unicode::Map8 and MIME::Decode as well as other items are now kept in $self and initialized only once (and reused) when possible.

Revision 1.30  2003/01/04 00:15:31  lem
Fixed some bugs related to stopping the HTML parser when the desired chunk has been parsed.

Revision 1.29  2003/01/03 01:33:44  lem
Added .ALIAS. Fixed minor bug with alternate syntax for .SEND.

Revision 1.28  2003/01/02 18:17:26  lem
Added -spammax to control how many messages can be check for spamminess

Revision 1.27  2002/12/31 17:08:33  lem
Minor fixes in error messages

Revision 1.26  2002/12/31 15:46:10  lem
Introduced Map8 workaround using tr///. Looks ugly but seems to work

Revision 1.25  2002/12/31 05:27:16  lem
Documented the Unicode::Map8 bug (?) in a newly added BUGS section

Revision 1.24  2002/12/31 05:15:15  lem
Factoring of code that access ->{state} (_fetch_state and _store_state). GET now can fetch message chunks to read in entirely. Minor fix in the reply message legend.

Revision 1.23  2002/12/29 22:11:54  lem
Improved decoding of MIME QP. Non-MIME messages are now handled by MIME::Parser. Dropped superfluous MIME module

Revision 1.22  2002/12/27 20:10:40  lem
Updated docs

Revision 1.21  2002/12/27 19:43:42  lem
Added ::Dispatcher and ::Utils to better distribute code. This should make easier the writting of new methods easier

Revision 1.20  2002/12/26 19:11:31  lem
Two spaces can be used instead of \n to separate a command from the body of the SMS

Revision 1.19  2002/12/24 08:21:54  lem
$Debug = 0. Improved HTML parsing by ignoring <script> and <style> stuff. Better message truncation support.

Revision 1.18  2002/12/23 06:36:04  lem
Huge rewrite of the message parsing. Now MIME is handled properly, including fancy multipart messages. Attachments are detected and signalled when within the message size boundary. Message fetching process is lighter and uses on-disk files for caching (and to reduce memory hungriness). .CHECK is more efficient now.

Revision 1.17  2002/12/23 03:17:49  lem
Wrapped call to check_message_text() in a special eval{} to avoid the nasty warns of non-essential modules being loaded by Mail::SpamAssassin

Revision 1.16  2002/12/23 01:18:13  lem
Added .CHECK command. Also updated the license to GPL

Revision 1.15  2002/12/22 19:04:18  lem
Changed license to GPL. Preliminary SPAM tagging support. Needs testing

Revision 1.14  2002/12/22 04:08:19  lem
Added README to MANIFEST. Added .FORWARD. We understand HTML messages now, complete with MIME/QuotedPrintable support. Minor fixes in the treatment of MIME messages in .REPLY and .FORWARD. Included some left-over messages into the multi-language support.

Revision 1.13  2002/12/21 23:29:09  lem
Added multilanguage support (en, es). Added .INTERFACE and .HELP for specific commands

Revision 1.12  2002/12/20 01:25:57  lem
Changed emails for redistribution

Revision 1.11  2002/12/19 18:44:39  lem
MIME-Version must be pushed only once

Revision 1.10  2002/12/19 18:40:31  lem
Added .REPLY. Also, added MIME headers to outgoing messages. MIME types are preserved in .REPLY. For .SEND, ISO-8859-1 is assumed

Revision 1.9  2002/12/19 17:12:45  lem
Added conditional whitespace folding

Revision 1.8  2002/12/19 16:39:30  lem
Added truncation indicator at end of large messages

Revision 1.7  2002/12/19 16:12:21  lem
Added Date::Parse. This helps us reduce the size of the Date header, saving space in the SMS

Revision 1.6  2002/12/19 06:00:12  lem
Fixed minor issues with regexps. Also improved the foo@bar.baz syntax to allow messages with no subject

Revision 1.5  2002/12/19 05:10:41  lem

- Added foo@bar.baz(subject)body notation through a simple transform

Revision 1.4  2002/12/19 04:54:44  lem
Added last() to the result of .LIST

Revision 1.3  2002/12/19 04:43:16  lem

- handle() is now a dispatch handler
- Commands are handled through self-contained methods (_CMD_*)
- Improved error handling a bit

Revision 1.2  2002/12/18 22:01:46  lem
More functionality added. Some is still missing

Revision 1.1  2002/12/18 08:45:13  lem

- Added prereqs for Net::SMTP and Net::POP3
- Added SMS::Handler::Email. Still not completely functional
- Added some tests for ::Email

=head1 BUGS

=over 4

=item *

It looks like HTML::Parser 3.26 is returning the 8-bit data mungled
after its first use. This is currently being investigated and no
work-around exists.

=back

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

L<SMS::Handler>, L<Queue::Dir>, perl(1).

=cut



