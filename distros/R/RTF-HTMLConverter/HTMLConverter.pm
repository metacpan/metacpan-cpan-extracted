package RTF::HTMLConverter;
use 5.8.0;
use strict;
use warnings;
use Error qw(:try);
use Encode;
use Encode::CN;
use Encode::KR;
use Encode::Symbol;
use RTF::Lexer qw(:all);

our @ISA = qw(RTF::Lexer);
our $VERSION = '0.05';

# The values provided by DOM implementation are not imported into current
# namespace in this realization. Also there is no guarantee that these
# values are defined in the namespace specified in 'DOMImplementation'
# parameter. So the most reliable way is to specify them by hand (see W3C
# DOM spec).
use constant {
      ELEMENT_NODE => 1,
      TEXT_NODE    => 3,
      COMMENT_NODE => 8,
};

sub init {
  my ($self, %opts) = @_;
  $self->SUPER::init(%opts);
  $self->{debug_level}   = exists $opts{debug} ? $opts{debug} : 0;
  $self->{optimize_html} = exists $opts{optimize_html} ? $opts{optimize_html} : 1;

  $self->{DOMImplementation} = $opts{DOMImplementation} || 'XML::GDOME';

  unless(($self->{discard_images} = $opts{discard_images})){
    require File::Spec;
    require File::Temp;
    require Image::Info;
    $self->{image_count}       = 0;
    $self->{image_names}       = $opts{image_names} || 'img%d';
    $self->{image_dir}         = $opts{image_dir} || '';
    $self->{image_uri}         = $opts{image_uri} || '';
    $self->{image_convert}     = $opts{image_convert} if exists $opts{image_convert};
    $self->{image_mogrify}     = $opts{image_mogrify} if exists $opts{image_mogrify};
    $self->{image_wmf2eps}     = $opts{image_wmf2eps} if exists $opts{image_wmf2eps};
    $self->{screen_resolution} = $opts{screen_resolution} || 100; # dpi
  }

  if(exists $opts{out} && !ref($opts{out})){
    open my $fh, "> $opts{out}" or throw Error::Simple("Can't open '$opts{out}': $!!\n");
    $opts{out} = $fh;
  }
  $self->set_sink(exists $opts{out} ? $opts{out} : \*STDOUT);
  if(exists $opts{err} && !ref($opts{err})){
    open my $fh, "> $opts{err}" or throw Error::Simple("Can't open '$opts{err}': $!!\n");
    $opts{err} = $fh;
  }
  $self->set_log(exists $opts{err} ? $opts{err} : sub { print STDERR $_[1] });

  $self->{parse_stack}   = [];
  $self->{doc_codepage}  = 'iso-8859-1';
  $self->{notes}         = {};
  $self->{on_leave1}     = [];
  $self->{on_leave2}     = [];
  $self->{sect_on_leave} = [];
  $self->{char_stack}    = $self->get_char_stack_class()->new($self);
  $self->{par_stack}     = [];
  $self->{sect_stack}    = [];

  my $root          = $self->init_dom(%opts);
  $self->{doc_head} = $self->create_element('head', $root);
  $self->{doc_body} = $self->create_element('body', $root);

  $self->{buffers}        = [];
  $self->set_new_buffer();
  $self->{tables}         = [];

  $self->{final_out}      = $self->set_sink(sub { shift()->append_text(@_) });
}

# DOM Implementation support
{
  my %dom_supported = (
         'XML::GDOME' => '_init_xml_gdome',
         'XML::DOM'   => '_init_xml_dom',
  );
  sub is_dom_supported  { $dom_supported{$_[1]}         }
  sub add_dom_supported { $dom_supported{$_[1]} = $_[2] }
  sub del_dom_supported { delete $dom_supported{$_[1]}  }

  sub init_dom {
    my $self = shift;
    my $impl = $self->getDOMImplementation();
    my $meth = $dom_supported{$impl};
    throw Error::Simple("Unsupported DOM Implementation: '$impl'\n") unless $meth;
    throw Error::Simple("DOM initialization method is not defined for Implementation '$impl' \n")
      unless UNIVERSAL::can($self, $meth);
    return $self->$meth(@_);
  }

  sub _init_xml_gdome {
    my ($self, %opts) = @_;
    my $doctype         = $opts{doctype} || ['HTML', '-//W3C//DTD HTML 4.01 Transitional//EN',
                                             'http://www.w3.org/TR/html4/loose.dtd'];
    my $dtd             = $self->getDOMImplementation()->createDocumentType(@$doctype);
    $self->{doc}        = $self->getDOMImplementation()->createDocument(undef, 'html', $dtd);
    $self->{codepage}   = $opts{codepage} || 'utf8';
    $self->{formatting} = exists $opts{formatting} ? $opts{formatting} : 1;
    return $self->{doc}->documentElement();
  }

  sub _init_xml_dom {
    my ($self, %opts) = @_;
    my $doc = XML::DOM::Document->new();
    $self->{doc} = $doc;
    my $doctype = $opts{doctype} || ['HTML', 'http://www.w3.org/TR/html4/loose.dtd',
                                     '-//W3C//DTD HTML 4.01 Transitional//EN'];
    my $dtd = $doc->createDocumentType(@$doctype);
    $doc->setDoctype($dtd);
    my $el = $doc->createElement('html');
    $doc->appendChild($el);
    return $el;
  }

  my %dom_stringify = (
         'XML::GDOME' => '_stringify_xml_gdome',
         'XML::DOM'   => '_stringify_xml_dom',
  );
  sub is_dom_stringify  { $dom_stringify{$_[1]}         }
  sub add_dom_stringify { $dom_stringify{$_[1]} = $_[2] }
  sub del_dom_stringify { delete $dom_stringify{$_[1]}  }
  
  sub _stringify_document {
    my $self = shift;
    my $impl = $self->getDOMImplementation();
    my $meth = $dom_stringify{$impl};
    throw Error::Simple("Stringify method is not defined for DOM Implementation '$impl'\n")
      unless $meth && UNIVERSAL::can($self, $meth);
    return $self->$meth(@_);
  }

  sub _stringify_xml_gdome{
    $_[0]->get_document()->toStringEnc($_[0]->{codepage}, $_[0]->{formatting})
  }

  sub _stringify_xml_dom { $_[0]->get_document()->toString() }
}

## OO methods

sub getDOMImplementation { $_[0]->{DOMImplementation}        }
sub get_buffer_class     { 'RTF::HTMLConverter::Buffer'      }
sub get_char_stack_class { 'RTF::HTMLConverter::CharStack'   }
sub get_element_class    { 'RTF::HTMLConverter::Element'     }
sub get_modelement_class { 'RTF::HTMLConverter::ModElement'  }
sub get_table_buf_class  { 'RTF::HTMLConverter::TableBuffer' }
sub get_token_class      { 'RTF::HTMLConverter::Token'       }

## IO methods

sub out { $_[0]->{_OUT}(@_) if $_[0]->{_OUT} }
sub log { $_[0]->{_LOG}(@_) if $_[0]->{_LOG} && $_[0]->{debug_level} >= $_[2] }

sub debug {
  if(@_ > 1){
    my $old = $_[0]->{debug_level};
    $_[0]->{debug_level} = $_[1];
    return $old;
  }
  return $_[0]->{debug_level}
}

sub get_log { $_[0]->{_LOG} }

sub set_log {
  my ($self, $log) = @_;
  my $oldlog = $self->{_LOG};
  if(ref($log) eq 'CODE' || !$log){
    $self->{_LOG} = $log;
  }elsif(ref($log) eq 'SCALAR'){
    $self->{_LOG} = sub { $$log .= $_[1] };
  }elsif(fileno $log){
    $self->{_LOG} = sub { print $log $_[1] };
  }else{
    die "set_log: second argument is not a subroutine ref, scalar ref or filehandle.\n";
  }
  return $oldlog;
}

sub get_sink { $_[0]->{_OUT} }

sub set_sink {
  my ($self, $sink) = @_;
  my $oldsink = $self->{_OUT};
  if(ref($sink) eq 'CODE' || !$sink){
    $self->{_OUT} = $sink;
  }elsif(ref($sink) eq 'SCALAR'){
    $self->{_OUT} = sub { $$sink .= $_[1] };
  }elsif(fileno $sink){
    $self->{_OUT} = sub { print $sink $_[1] };
  }else{
    die "set_sink: second argument is not a subroutine ref, scalar ref or filehandle.\n";
  }
  return $oldsink;
}

## Core methods

{
  my %enter_tokens = map { $_ => 1 } (ENTER);
  sub is_enter_token  { $enter_tokens{ref($_[1]) ? $_[1]->type() : $_[1]}        }
  sub add_enter_token { $enter_tokens{ref($_[1]) ? $_[1]->type() : $_[1]} = 1    }
  sub del_enter_token { delete $enter_tokens{ref($_[1]) ? $_[1]->type() : $_[1]} }
}

{
  my %leave_tokens = map { $_ => 1 } (LEAVE, DESTN);
  sub is_leave_token  { $leave_tokens{ref($_[1]) ? $_[1]->type() : $_[1]}        }
  sub add_leave_token { $leave_tokens{ref($_[1]) ? $_[1]->type() : $_[1]} = 1    }
  sub del_leave_token { delete $leave_tokens{ref($_[1]) ? $_[1]->type() : $_[1]} }
}

sub get_token {
  my $self = shift;
  my $token = $self->get_token_class()->new(@{$self->SUPER::get_token() || []});
  return $token if $_[0];
  if($self->is_enter_token($token)){
    $self->{parse_stack}[0]++;
  }elsif($self->is_leave_token($token)){
    $self->{parse_stack}[0]--;
  }
  return $token;
}

{
  my %symfunc = (
                  q[-]  => 'cs_dash',
                  q[~]  => 'cs_tilde',
                  q[']  => 'cs_quoteright',
                  q[*]  => 'cs_asterisk',
                  q[\\] => 'cs_backslash',
                  q[:]  => 'cs_colon',
                  q[_]  => 'cs_underscore',
                  q[{]  => 'cs_braceleft',
                  q[|]  => 'cs_bar',
                  q[}]  => 'cs_braceright',
                  "\r"  => 'cs_par',
                  "\n"  => 'cs_par',
                );
  sub get_symfunc { $symfunc{ref($_[1]) ? $_[1]->text() : $_[1]}        }
  sub del_symfunc { delete $symfunc{ref($_[1]) ? $_[1]->text() : $_[1]} }
  sub set_symfunc {
    my ($self, $symb, $func) = @_;
    $symb = $symb->text() if ref($symb);
    my $old = $symfunc{$symb};
    $symfunc{$symb} = $func;
    return $old;
  }
}

{
  my %token_handlers = (
                         CWORD, 'th_cword',   # Control word
                         CSYMB, 'th_csymb',   # Control symbol
                         CUNDF, 'th_cundf',   # Undefined control symbol
                         PTEXT, 'th_ptext',   # Text or binary data
                         ENTER, 'th_enter',   # Start group
                         LEAVE, 'th_leave',   # End group
                         DESTN, 'th_leave',   # End destination group
                         UNBRC, 'th_unbrc',   # Unexpected right brace
                         UNEOF, 'th_uneof',   # Unexpected end of file
                         OKEOF, 'th_okeof',   # End of file
  );
  sub get_token_handler { $token_handlers{ref($_[1]) ? $_[1]->type() : $_[1]}        }
  sub del_token_handler { delete $token_handlers{ref($_[1]) ? $_[1]->type() : $_[1]} }
  sub set_token_handler {
    my ($self, $type, $handler) = @_;
    $type = $type->type() if ref($type);
    my $old = $token_handlers{$type};
    $token_handlers{$type} = $handler;
    return $old;
  }
}

{
## Destinations defined in the March 1987 RTF Specification
  my %destwords = ( map { $_ => 1 }
                    qw(author buptim colortbl comment creatim doccomm fonttbl
                       footer footerf footerl footerr footnote ftncn ftnsep
                       ftnsepc header headerf headerl headerr info keywords
                       operator pict printim revtim rxe stylesheet subject tc
                       title txe xe)
                  );
  sub is_destword  { $destwords{$_[1]}        }
  sub add_destword { $destwords{$_[1]} = 1    }
  sub del_destword { delete $destwords{$_[1]} }
}

sub parse {
  my $self = shift;
  $self->{parse_stack} ||= [];
  unshift @{$self->{parse_stack}}, 0;
  while(my $token = $self->get_token()){
    my $meth = $self->get_token_handler($token);
    if($meth && $self->can($meth)){
      $self->$meth($token);
    }else{
      $self->log("Unhandled token: ".$token->type()."!\n", 1);
    }
    last if $self->is_stop_token($token) || $self->{parse_stack}[0] < 0;
  }
  shift @{$self->{parse_stack}};
  $self->{parse_stack}[0]--;
}

sub unget_tokens { $_[0]->unget_token($_) foreach @{$_[1]} }

## Token Handlers

sub th_cword {
  my ($self, $token) = @_;
  return unless $token;
  my $word = $token->text() || return;
  my $meth = 'cw_'.$word;
  if(UNIVERSAL::can($self, $meth)){
    $self->$meth($token->param())
  }elsif($self->is_destword($word)){
    $self->set_destination();
  }
}

sub th_csymb {
  my ($self, $token) = @_;
  my $meth = $self->get_symfunc($token);
  $self->$meth if $meth && UNIVERSAL::can($self, $meth);
}

sub th_cundf {
  my ($self, $token) = @_;
  my $symb = $token->text();
  $self->log("Undefined control symbol: '$symb'.\n", 1);
  $self->out($symb);
}

sub th_enter {
  my $self = shift;
  for my $name (qw(sect_stack par_stack)){
    my $top = $self->{$name}[0];
    unshift @{$self->{$name}}, $top ? $top->clone() : $self->get_element_class()->new();
  }
  $self->{char_stack}->dup();
  unshift @{$self->{$_}}, [] foreach (qw(on_leave1 on_leave2));
}

sub th_leave {
  my $self = shift;
  $self->{char_stack}->drop();
  shift @{$self->{par_stack}};
  shift @{$self->{sect_stack}};
  $self->_do_on_leave();
}

sub th_ptext {                                   # Binary data in HEX
  my ($self, $token) = @_;
  my $text = $token->text();
  unless($self->hex_mode()){
    $text = $self->_encode_text($text) unless $self->raw_mode();
    $self->out($text);
    return;
  }
  my $pc = $self->{hex_char};
  $text = $pc.$text if defined($pc) && length($pc);
  return unless defined($text) && length($text);
  $self->{hex_char} = chop($text) if length($text)%2;
  $self->out(pack("H*", $text));
}

sub _call_okeof {
  my ($self, $caller) = @_;
  my $meth = $self->get_token_handler(OKEOF);
  if(ref($meth)){
    $caller = UNIVERSAL::can($self, $caller);
    return if $caller && $caller == $meth;
  }else{
    return if $meth eq $caller;
  }
  $self->$meth() if UNIVERSAL::can($self, $meth);
}

sub th_uneof {
  $_[0]->log("Unexpected end of file!\n", 1);
  $_[0]->_call_okeof('th_uneof');
}

sub th_unbrc {                                   ### { - to match in text editors
  $_[0]->log("Extra '}' found!\n", 1);
  $_[0]->_call_okeof('th_unbrc');
}

sub th_okeof {
  my $self = shift;
  $self->flush_section();
  return unless $self->{final_out};
  $self->optimize_tree($self->{doc_body}) if $self->{optimize_html};
  for my $tag (qw(body head title)){
    my $el = $self->get_document()->getElementsByTagName($tag)->item(0);
    next unless $el;
    $self->_check_paired_tag($el);
  }
  $self->set_sink($self->{final_out});
  $self->out($self->_stringify_document());
}

sub pth_cword {                                  # th_cword with another prefixes
  my ($self, $token) = @_;
  my $word;
  return unless $token && ($word = $token->text());
  my $param = $token->param();
  my $meth = ($self->{cword_prefix} || 'hcw_').$word;
  my $nm   = 'cw_'.$word;
  if(UNIVERSAL::can($self, $meth)){
    $self->$meth($param);
  }elsif($self->is_destword($word)){
    $self->set_destination();
  }elsif($word eq 'u'){
    $self->$nm($param) if UNIVERSAL::can($self, $nm);
  }elsif(UNIVERSAL::can($self, $nm) && (my $cwmeth = $self->{orig_cword_handler})){
    $self->$cwmeth($word, $param);
  }
}

## Accessory Methods

sub get_document { $_[0]->{doc} }

sub get_char_stack { $_[0]->{char_stack} }
sub get_par_stack  { $_[0]->{par_stack}  }
sub get_sect_stack { $_[0]->{sect_stack} }

sub get_par { $_[0]->{par_stack}[0] }

sub set_group_token_handler {
  my ($self, $type, $handler) = @_;
  my $oldh = $self->set_token_handler($type, $handler);
  $self->add_on_leave_handler('set_token_handler', [$type, $oldh]);
  return $oldh;
}

sub hex_mode {
  my $self = shift;
  return $self->{hex_mode} unless @_;
  $self->{hex_char} = '';
  my $old = $self->{hex_mode};
  $self->{hex_mode} = $_[0] ? 1 : 0;
  return $old;
}

sub raw_mode {
  my $self = shift;
  return $self->{raw_mode} unless @_;
  my $old = $self->{raw_mode};
  $self->{raw_mode} = $_[0] ? 1 : 0;
  return $old;
}

sub _current_stack {
  my ($self, $name, $el) = @_;
  return $self->{$name}[0] unless $el;
  unshift @{$self->{$name}}, $el;
  return $el;
}

sub current_buffer { shift()->_current_stack('buffers', @_) }
sub current_table  { shift()->_current_stack('tables', @_)  }

sub _set_new_stack {
  my ($self, $class, $name) = splice(@_, 0, 3);
  my $buf = $class->new(@_);
  return unless $buf;
  unshift @{$self->{$name}}, $buf;
  return $buf;
}

sub set_new_buffer { $_[0]->_set_new_stack($_[0]->get_buffer_class(),   'buffers', $_[0]) }
sub set_new_table  { $_[0]->_set_new_stack($_[0]->get_table_buf_class(), 'tables', $_[0]) }

sub remove_buffer {
  my ($self, $buf) = @_;
  return unless $buf;
  @{$self->{buffers}} = grep { $_ != $buf } @{$self->{buffers}};
}

sub set_new_group_buffer {
  my $self = shift;
  my $buf = $self->set_new_buffer();
  $self->add_on_leave_handler('remove_buffer', [$buf]);
  return $buf;
}

sub get_parsed_group_text {
  my $self = shift;
  my $buf = $self->set_new_group_buffer();
  $self->parse();
  return $buf->get_text();
}

sub get_parsed_group_pcdata { $_[0]->set_pcdata_mode(); $_[0]->get_parsed_group_text() }

sub set_group_cwhandler {
  my ($self, $prefix) = @_;
  my @oldvalues;
  $oldvalues[0] = $self->set_token_handler(CWORD, 'pth_cword');
  $oldvalues[1] = $self->{cword_prefix};
  $self->{cword_prefix} = $prefix;
  $self->add_on_leave_handler('_restore_cwhandler', \@oldvalues);
}

sub _restore_cwhandler {
  $_[0]->set_token_handler(CWORD, $_[1]);
  $_[0]->{cword_prefix} = $_[2];
}

sub set_group_orig_cword_handler {
  my ($self, $handler) = @_;
  my $oldh = $self->{orig_cword_handler};
  $self->{orig_cword_handler} = $handler;
  $self->add_on_leave_handler(sub { $_[0]->{orig_cword_handler} = $_[1] }, [$oldh]);
}

sub set_group_sink {
  my ($self, $sink) = @_;
  my $old_sink = $self->set_sink(ref($sink) eq 'SCALAR' ? sub { $$sink .= $_[1] } : $sink);
  $self->add_on_leave_handler(sub { $_[0]->set_sink($_[1]) }, [$old_sink]);
}

sub _encode_text {
  my ($self, $text, $enc) = @_;
  $enc ||= $self->_get_text_encoding();
  return $enc eq 'utf8' ? $text : Encode::decode($enc, $text);
}

sub notes {
  my $self = shift;
  my $notes = $self->{notes};
  if(@_ == 2){
    my $old = $notes->{$_[0]};
    $notes->{$_[0]} = $_[1];
    return $old;
  }
  return $notes->{$_[0]};
}

sub del_note { delete $_[0]->{notes}{$_[1]} }

sub group_notes {
  my ($self, $key, $value) = @_;
  unless(exists $self->{notes}{$key}){
    $self->notes($key => $value);
    $self->_add_on_leave('on_leave2', sub { $_[0]->del_note($_[1]) }, [$key]);
    return;
  }
  my $old = $self->notes($key => $value);
  $self->_add_on_leave('on_leave2', sub { $_[0]->notes($_[1], $_[2]) }, [$key, $old]);
  return $old;
}

sub store_notes {
  my ($self, $arr) = splice(@_, 0, 2);
  $self->add_on_leave_handler(sub { push @{$_[1]}, map { $_[0]->notes($_) } @{$_[2]} }, [$arr, [@_]]);
}

sub set_pcdata_mode { $_[0]->group_notes(pcdata => 1) }

sub _add_on_leave { unshift @{$_[0]->{$_[1]}[0]}, [$_[2], $_[3] || []] }

sub add_on_leave_handler { shift()->_add_on_leave('on_leave1', @_) }

sub add_sect_on_leave_handler {
  my ($self, $sub, $args) = @_;
  unshift @{$self->{sect_on_leave}}, [$sub, $args || []];
}

sub _do_on_leave {
  my $self = shift;
  for my $name (qw(on_leave1 on_leave2)){
    my $on_leave = shift @{$self->{$name}};
    next unless $on_leave && @$on_leave;
    my $meth;
    for my $rec (@$on_leave){
      $meth = $rec->[0];
      $self->$meth(@{$rec->[1]});
    }
  }
}

sub exec_program {
  shift if ref($_[0]);
  local $/;
  my $dirname = shift;
  my $pid = open(my $fh, '-|');
  throw Error::Simple("Can't fork: $!!\n") unless defined $pid;
  unless($pid){
    throw Error::Simple("Can't dup STDERR: $!!\n") unless open(STDERR, ">&STDOUT");
    if($dirname){
      throw Error::Simple("Can't chdir to '$dirname': $!!\n") unless chdir $dirname;
    }
    no warnings 'syntax';
    exec @_;
    throw Error::Simple("Can't exec '".join(' ', @_)."': $!!\n");
  }
  my $output = <$fh>;
  $fh->close();
  return $output;
}

sub get_next_image_name {
  my ($self, $extn) = @_;
  $self->{image_count}++;
  my $name = '';
  if(ref($self->{image_names}) eq 'CODE'){
    $name = $self->{image_names}($self->{image_count});
  }else{
    $name = sprintf($self->{image_names}, $self->{image_count});
  }
  $name .= ".$extn" if length $extn;
  my $url = join('/', grep { length } ($self->{image_uri}, $name));
  $name = File::Spec->catfile($self->{image_dir}, $name) if length $self->{image_dir};
  return ($name, $url);
}

sub get_color_triplet {
  my ($self, $num) = @_;
  my $triplet = ($self->notes('colortbl') || [])->[$num];
  return unless $triplet && scalar(grep { defined $_ } @$triplet) == 3;
  return '#'.join('', @$triplet);
}

sub split_color_triplet { map { substr($_[1], $_, 2) } (1, 3, 5) }

sub twips2pt { shift; wantarray ? map { sprintf("%.0f", $_/12) } @_ : sprintf("%.0f", $_[0]/12) }

## Tree Manipulation Methods

sub get_head_element { $_[0]->{doc_head} }
sub get_body_element { $_[0]->{doc_body} }

sub get_style_element {
  my $self = shift;
  my $style = $self->get_document()->getElementsByTagName('style')->item(0);
  return $style if $style;
  my $head = $self->get_document()->getElementsByTagName('head')->item(0);
  return unless $head;
  $style = $self->create_element('style', $head);
  $style->setAttribute(type => 'text/css');
  my $comm = $self->get_document()->createComment("\n");
  $style->appendChild($comm);
  return $style;
}


sub append_text_node {
  my ($self, $el, $text, $is_comment) = @_;
  return unless $el && defined($text);
  my $type = $is_comment ? COMMENT_NODE : TEXT_NODE;
  my $child = $el->getLastChild();
  if($child && $child->getNodeType() == $type){
    $child->appendData($text);
    return;
  }
  my $create = $is_comment ? 'createComment' : 'createTextNode';
  $child = $self->get_document()->$create($text);
  $el->appendChild($child);
}

sub create_element {
  my ($self, $tag, $parent) = @_;
  my $el = $self->get_document()->createElement($tag);
  $parent->appendChild($el) if $parent;
  return $el;
}

sub _check_paired_tag {
  my ($self, $el) = @_;
  return if $el->hasChildNodes();
  $el->appendChild($self->get_document()->createTextNode(''));
  return $el;
}


sub append_text {
  my ($self, $txt, $enc) = @_;
  return unless $self->current_buffer() && defined($txt) && length($txt);
  $txt = $self->_encode_text($txt, $enc) if $enc || !$self->raw_mode();
  $self->current_buffer()->add_text($txt);
}

sub append_element {
  my ($self, $el) = @_;
  return unless $self->current_buffer() && defined($el) && ref($el);
  return $self->current_buffer()->add_node($el);
}

sub append_tag {
  my ($self, $tag) = @_;
  return unless $self->current_buffer() && defined($tag) && length($tag);
  return $self->current_buffer()->add_tag($tag);
}

sub append_entity {
  my ($self, $name) = @_;
  return unless $self->current_buffer() && defined($name) && length($name);
  return $self->current_buffer()->add_entity($name);
}

sub open_char_tag  { shift()->get_char_stack()->open_tag(@_)  }
sub close_char_tag { shift()->get_char_stack()->close_tag(@_) }
sub char_tag_notes { shift()->get_char_stack()->tag_notes(@_) }
sub char_tag_attr  { shift()->get_char_stack()->tag_attr(@_)  }
sub char_tag_style { shift()->get_char_stack()->tag_style(@_) }

sub _apppend_paragraphs {
  my ($self, $root, $buf) = @_;
  my $pars = $buf->get_paragraphs();
  my $pe;
  for my $par (@$pars){
    $pe = $par->data();
    $pe->appendChild($self->get_document()->createEntityReference('nbsp'))
      unless $pe->hasChildNodes();
    $root->appendChild($pe);
  }
}

sub flush_section {
  my $self = shift;
  my $body = $self->get_body_element();
  $self->_apppend_paragraphs($body, $self->{buffers}[-1]);
  my $meth;
  for my $rec (@{$self->{sect_on_leave}}){
    $meth = $rec->[0];
    $self->$meth(@{$rec->[1]});
  }
  $self->{sect_on_leave} = [];
}

# DOM tree optimization.
{
  ## This lists the tags that can't be removed or merged while optimizing document tree.
  my %fixed_tags = map { $_ => 1 } qw(body p table tr td th ol ul li pre dd dt dl);
  sub is_fixed_tag  { $fixed_tags{ref($_[1]) ? $_[1]->getNodeName() : $_[1]}        }
  sub add_fixed_tag { $fixed_tags{ref($_[1]) ? $_[1]->getNodeName() : $_[1]} = 1    }
  sub del_fixed_tag { delete $fixed_tags{ref($_[1]) ? $_[1]->getNodeName() : $_[1]} }
}

{
  my $stcount = 0;
  my %styles = ();

  sub _style_to_class {
    my ($self, $style) = @_;
    return $styles{$style} if $styles{$style};
    my $el = $self->get_style_element();
    return unless $el;
    my $comm = $el->getFirstChild();
    while($comm && $comm->getNodeType() != COMMENT_NODE){
      $comm = $comm->getNextSibling();
    }
    unless($comm){
      $comm = $self->get_document()->createComment("\n");
      $el->appendChild($comm);
    }
    my $cname = 'c'.++$stcount;
    $styles{$style} = $cname;
    $comm->appendData("  .$cname { $style }\n");
    return $cname;
  }
}

{
  my %skip_styles = map { $_ => 1 } qw(width height);
  sub is_skip_style  { $skip_styles{$_[1]}        }
  sub add_skip_style { $skip_styles{$_[1]} = 1    }
  sub del_skip_style { delete $skip_styles{$_[1]} }
}

sub optimize_tree {
  my ($self, $node) = @_;
  return unless $node && $node->getNodeType() == ELEMENT_NODE && $node->hasChildNodes();
  my $parent = $node->getParentNode();
  unless($self->is_fixed_tag($node)){            # <b>qq</b><b>ww</b> => <b>qqww</b>
    while(my $sibling = $node->getNextSibling()){
      last unless $self->_nodes_are_equal($node, $sibling);
      my $nlist = $sibling->getChildNodes();
      while($nlist->getLength()){
        $node->appendChild($nlist->item(0));
      }
      $parent->removeChild($sibling);
    }
  }
  my $child = $node->getFirstChild();
  my $prevcld;
  while($child){
    if($child->getNodeType() == TEXT_NODE){
      if($child->getNodeValue() eq '' && !$self->is_fixed_tag($node)){
        $node->removeChild($child);              # <b></b>qq => qq
        unless($node->hasChildNodes()){
          $parent->removeChild($node);
          return;
        }
      }
    }else{
      $self->optimize_tree($child);
    }
    if($child->getParentNode()){
      $prevcld = $child;
      $child = $child->getNextSibling();
    }else{
      $child = $prevcld ? $prevcld->getNextSibling() : $node->getFirstChild();
    }
  }
  if(my $st = $node->getAttribute('style')){     # <b style="..."> => <b class="...">
    my %sh = $self->get_element_class()->style_hash($st);
    my @ss = grep { $self->is_skip_style($_) } keys %sh;
    if(@ss){
      $node->setAttribute(style => $self->get_element_class()->style_value({map {$_ => $sh{$_}} @ss}));
      delete @sh{@ss};
    }else{
      $node->removeAttribute('style');
    }
    if(keys %sh){
      my $class = $self->_style_to_class($self->get_element_class()->style_value(\%sh));
      my $ca = $node->getAttribute('class');
      $ca .= ' ' if $ca;
      $ca .= $class;
      $node->setAttribute(class => $ca);
    }
  }
  return if $self->is_fixed_tag($parent);
  if($self->_nodes_are_equal($parent, $node)){# <b><b>qq</b></b> => <b>qq</b>
    $self->_move_children_nodes_up($parent, $node);
    $parent->removeChild($node);
  }else{                                         # <b><i><b>qq</b></i></b> => <b><i>qq</i></b>
    $child = $node->getFirstChild();
    while($child){
      if($self->_nodes_are_equal($parent, $child)){
        $self->_move_children_nodes_up($node, $child);
        my $nextcld = $child->getNextSibling();
        $node->removeChild($child);
        $child = $nextcld;
      }else{
        $child = $child->getNextSibling();
      }
    }
  }
}

sub _move_children_nodes_up {
  my ($self, $parent, $node) = @_;
  my $nlist = $node->getChildNodes();
  while($nlist->getLength()){
    $parent->insertBefore($nlist->item(0), $node);
  }
}

sub _nodes_are_equal {
  my ($self, $n1, $n2) = @_;
  return unless $n1->getNodeType() == $n2->getNodeType();
  return unless $n1->getNodeName() eq $n2->getNodeName();
  my $attrs1 = $n1->getAttributes();
  my $attrs2 = $n2->getAttributes();
  my $len = $attrs1->getLength();
  return unless $len == $attrs2->getLength();
  my (%h1, %h2, $attr);
  for (my $i = 0; $i < $len; $i++){
    $attr = $attrs1->item($i);
    $h1{$attr->getNodeName()} = $attr->getNodeValue();
    $attr = $attrs2->item($i);
    $h2{$attr->getNodeName()} = $attr->getNodeValue();
  }
  for my $k (keys %h1){
    return unless exists $h2{$k} && $h1{$k} eq $h2{$k};
  }
  return 1;
}

# RTF control handlers

## Special Character Handlers

sub cs_asterisk {
  my $self = shift;
  my $token = $self->get_token();
  if($token && $token->type() == CWORD && defined(my $text = $token->text())){
    if($self->can('cw_'.$text)){
      $self->unget_token($token);
    }else{
      $self->set_destination();
    }
  }else{
    $self->unget_token($token);
  }
}

sub cs_quoteright{
  my $self = shift;
  my $text;
  my $token = $self->get_token();
  unless($token && $token->type() == ENHEX && length($text = $token->text())){
    $self->unget_token($token);
    $self->log("Hex code expected!\n", 1);
    return;
  }
  my $char = chr(hex($text));
# Either the spec is not clear at this point or I can't read it :-)
# Anyway it seems that characters with accents are accompanied with
# their ASCII equivalents without accents. So we need not output
# characters in [A-Za-z] range.
  $self->out($char) unless $char =~ /[A-Za-z]/;
}

sub cs_backslash  { $_[0]->out('\\') }
sub cs_braceleft  { $_[0]->out('{')  }
sub cs_braceright { $_[0]->out('}')  }
sub cs_underscore { $_[0]->out('-')  }
sub cs_tilde      { $_[0]->append_entity('nbsp') }
sub cs_par        { $_[0]->cw_par if UNIVERSAL::can($_[0], 'cw_par') }
sub cs_colon      { }
sub cs_dash       { }
sub cs_bar        { }

## Contents of an RTF File

#### RTF Header

###### Character Set

sub cw_ansi { $_[0]->{doc_codepage} = 'iso-8859-1' }
sub cw_mac  { $_[0]->{doc_codepage} = 'iso-8859-1' }
sub cw_pc   { $_[0]->{doc_codepage} = 'cp437'      }
sub cw_pca  { $_[0]->{doc_codepage} = 'cp850'      }

###### Unicode RTF

{
  my %supported_cp = map { $_ => 1 } qw(437 850 852 860 862 863 864 865
                                        866 874 932 936 949 950 1250 1251
                                        1252 1253 1254 1255 1256 1257 1258);
# Unsupported: 708 709 710 711 720 819 1361 (see perldoc Encode::Supported)
  sub is_supported_cp  { $supported_cp{$_[1]}        }
  sub add_supported_cp { $supported_cp{$_[1]} = 1    }
  sub del_supported_cp { delete $supported_cp{$_[1]} }

  sub cw_ansicpg { $_[0]->notes(ansicpg => 'cp'.$_[1]) if $supported_cp{$_[1]} }
}

sub cw_upr {
  my $self = shift;
  while(1) {
    my $token = $self->get_token();
    if(!$token || $self->is_stop_token($token)){
      $self->unget_token($token);
      last;
    }
    if($token->type() == ENTER){
      my $h = $self->get_token_handler(ENTER);
      $self->$h($token) if $h && $self->can($h);
      $self->set_destination();
      last;
    }
  }
}

sub cw_ud { }                                    # By default this is destination word.

sub cw_u {
  my ($self, $char) = @_;
  $char = 65536 + $char if $char < 0;
  $self->out(pack('U', $char), 'utf8');
  my $uc = $self->notes('uc');
  $uc = 1 unless defined $uc;
  my $string = '';
  while(length($string) < $uc){
    my $token = $self->get_token(1);
    my ($type, $text) = ($token->type(), $token->text());
    if($type == PTEXT){
      $string .= $text;
      next;
    }elsif($self->is_enter_token($token) || $self->is_leave_token($token) || $self->is_stop_token($token)){
      $self->unget_token($token);
      return;
    }elsif($type == CWORD){
      if($text eq 'bin'){
        while(my $tk = $self->get_token()){
          last if $tk->type() == ENBIN || $self->is_stop_token($tk);
        }
      }
    }elsif($type == CSYMB){
      if($text eq "'" && ($token = $self->get_token())){
        unless($token->type() == ENHEX){
          $self->unget_token($token);
        }
      }
    }
    $string .= ' ';                              # Count tokens
  }
  substr($string, 0, $uc) = '';
  $self->out($string) if length $string;
}

sub cw_uc { $_[0]->group_notes(uc => $_[1]) }

###### Font Table

sub cw_fonttbl {
  my $self = shift;
  $self->set_pcdata_mode();
  $self->set_new_group_buffer();
  $self->set_group_cwhandler('fcw_');
  $self->parse();
  my $deff = $self->notes('deff');
  if(length $deff){
    my $font = $self->notes('f'.$deff);
    return unless $font;
    $self->notes(f => $font);
    my $ff = $self->_get_font_family($font);
    return unless $ff;
    my $style = $self->get_style_element();
    $self->append_text_node($style, "  BODY { font-family: $ff; font-size: 10pt }\n", 1) if $style;
  }
}

sub fcw_f {
  my ($self, $num) = @_;
  my $font = {};
  $self->notes(f => $font);
  $self->notes('f'.$num => $font);
  my $txt = $self->get_parsed_group_pcdata();
  $txt =~ s/;$//;
  $font->{face} = $txt;
}

sub fcw_fnil    { delete (($_[0]->notes('f') || {})->{family})       }
sub fcw_froman  { ($_[0]->notes('f') || {})->{family} = 'serif'      }
sub fcw_fswiss  { ($_[0]->notes('f') || {})->{family} = 'sans-serif' }
sub fcw_fmodern { ($_[0]->notes('f') || {})->{family} = 'monospace'  }
sub fcw_fscript { ($_[0]->notes('f') || {})->{family} = 'cursive'    }
sub fcw_fdecor  { ($_[0]->notes('f') || {})->{family} = 'fantasy'    }

sub cw_deff {
  my ($self, $num) = @_;
  $self->notes(deff => $num);
  my $font = $self->notes('f'.$num);
  return unless $font;
  $self->notes(f => $font);
}

{
  my %charsets = (
                   0   => 'iso-8859-1',    # ?? ANSI
                   1   => 'iso-8859-1',    # ?? Default
                   2   => 'symbol',        # Symbol
                   #3  => '??',            # Invalid
                   #77 => '??',            # Mac
                   128 => 'Shift_JIS',     # Shift JIS
                   #129 => '??',           # Hangul
                   130 => 'johab',         # Johab
                   134 => 'euc-cn',        # GB2312
                   136 => 'Big5',          # Big5
                   161 => 'cp1253',        # Greek
                   162 => 'cp1254',        # Turkish
                   163 => 'cp1258',        # Vietnamese
                   177 => 'cp1255',        # Hebrew
                   178 => 'cp1256',        # Arabic
                   #179 => '??',           # Arabic Traditional
                   #180 => '??',           # Arabic user
                   #181 => '??',           # Hebrew user
                   186 => 'cp1257',        # Baltic
                   204 => 'cp1251',        # Russian
                   222 => 'cp874',         # Thai
                   238 => 'cp1250',        # Eastern European
                   254 => 'cp437',         # PC 437
                   #255 => '??',           # OEM
                 );
  sub fcw_fcharset {
    my ($self, $num) = @_;
    my $font = $self->notes('f');
    return unless $font;
    $font->{codepage} = $charsets{$num};
  }
}

sub fcw_falt {
  my $self = shift;
  my $font = $self->notes('f');
  my $txt = $self->get_parsed_group_pcdata();
  ($font || {})->{falt} = $txt;
}

sub _get_text_encoding {
  ($_[0]->notes('pcdata') ? {} : $_[0]->notes('f') || {})->{codepage}
        || $_[0]->notes('ansicpg')  || $_[0]->{doc_codepage}
}

sub _get_font_family { $_[1]->{family} }

###### Color Table

sub cw_colortbl {
  my $self = shift;
  $self->set_pcdata_mode();
  $self->notes(colortbl => []);
  $self->group_notes(colortbl_current => [(undef)x3]);
  $self->set_group_token_handler(PTEXT, 'th_ptext_colortbl');
}

sub cw_red   { ($_[0]->notes('colortbl_current') || [])->[0] = sprintf("%02x", $_[1]) }
sub cw_green { ($_[0]->notes('colortbl_current') || [])->[1] = sprintf("%02x", $_[1]) }
sub cw_blue  { ($_[0]->notes('colortbl_current') || [])->[2] = sprintf("%02x", $_[1]) }

sub th_ptext_colortbl {
  my ($self, $token) = @_;
  my $text = $token->text();
  return unless $text =~ /;/;
  push @{$self->notes('colortbl')}, $self->notes('colortbl_current');
  $self->notes(colortbl_current => [(undef)x3]);
}

###### Style Sheet

sub cw_stylesheet {
  my $self = shift;
  $self->set_pcdata_mode();
  $self->set_new_group_buffer();
  $self->set_group_cwhandler('scw_');
  my $oldh = $self->set_group_token_handler(ENTER, 'th_enter_style');
  $self->group_notes(stylesheet_enter => $oldh);
}

sub th_enter_style {
  my $self = shift;
  my $oldh = $self->notes('stylesheet_enter');
  $self->$oldh();
  my $style = { formatting => [] };
  $self->notes(style => $style);
  $self->notes(style_name => ['s', '0']) unless $self->notes('s0');
  $self->set_group_orig_cword_handler('_style_format_collector');
  $self->set_group_token_handler(ENTER, $oldh);
  $self->parse();
  my $stname = $self->notes('style_name');
  return unless $stname;
  $style->{type} = $stname->[0];
  $self->notes($stname->[0].$stname->[1] => $style);
  $self->del_note('style_name');
}

sub _style_format_collector {
  my ($self, $word, $param) = @_;
  my $style = $self->notes('style');
  return unless $style;
  $style->{formatting} = [] unless $style->{formatting};
  push @{$style->{formatting}}, $self->get_token_class()->new(CWORD, $word, $param);
}

sub scw_cs { $_[0]->notes(style_name => ['cs', $_[1]]) }
sub scw_s  { $_[0]->notes(style_name => ['s',  $_[1]]) }
sub scw_ds { $_[0]->notes(style_name => ['ds', $_[1]]) }
sub scw_ts { $_[0]->notes(style_name => ['ts', $_[1]]) }

sub scw_additive { ($_[0]->notes('style') || {})->{additive} = 1 }

sub scw_sbasedon {
  my ($self, $num) = @_;
  return if $num == 222;
  my $curstyle = $self->notes('style');
  return unless $curstyle;
  my $sn = $self->notes('style_name');
  return unless $sn;
  my $basestyle = $self->notes($sn->[0].$num);
  return unless $basestyle;
  unshift @{$curstyle->{formatting}}, @{$basestyle->{formatting} || []};
  for my $key (keys %$basestyle){
    next if exists $curstyle->{$key};
    $curstyle->{$key} = $basestyle->{$key};
  }
}

###### Table Styles

sub _ts_set_padding {
  my ($self, $num, $val) = @_;
  my $dim = $self->notes($val);
  return unless defined($dim) && $dim == 3;
  $self->_td_style($self->twips2pt($num).'pt');
}

sub cw_tscellpaddt { $_[0]->_ts_set_padding($_[1], 'tscellpaddft') }
sub cw_tscellpaddl { $_[0]->_ts_set_padding($_[1], 'tscellpaddfl') }
sub cw_tscellpaddr { $_[0]->_ts_set_padding($_[1], 'tscellpaddfr') }
sub cw_tscellpaddb { $_[0]->_ts_set_padding($_[1], 'tscellpaddfb') }

sub cw_tscellpaddft { $_[0]->group_notes(tscellpaddft => $_[1]) }
sub cw_tscellpaddfl { $_[0]->group_notes(tscellpaddfl => $_[1]) }
sub cw_tscellpaddfr { $_[0]->group_notes(tscellpaddfr => $_[1]) }
sub cw_tscellpaddfb { $_[0]->group_notes(tscellpaddfb => $_[1]) }

sub cw_tsvertalt { $_[0]->_td_attr(valign => 'top'   ) }
sub cw_tsvertalc { $_[0]->_td_attr(valign => 'center') }
sub cw_tsvertalb { $_[0]->_td_attr(valign => 'bottom') }

sub cw_tsnowrap { $_[0]->_td_style('white-space' => 'nowrap') }

sub cw_tscellcfpat { $_[0]->_td_cfpat($_[1], 'tscellpct') }
sub cw_tscellpct   { $_[0]->_td_shdng($_[1], 'tscellpct') }

sub cw_tsbrdrt { $_[0]->_set_td_border_style('top')    }
sub cw_tsbrdrb { $_[0]->_set_td_border_style('bottom') }
sub cw_tsbrdrl { $_[0]->_set_td_border_style('left')   }
sub cw_tsbrdrr { $_[0]->_set_td_border_style('right')  }

###### List Table

sub _get_current_list { $_[0]->notes($_[0]->notes('list_name') || 'list') }

sub cw_listtable {
  my $self = shift;
  $self->set_new_group_buffer();
  $self->set_group_cwhandler('ltcw_');
  $self->set_group_orig_cword_handler('_list_format_collector');
}

sub _list_format_collector {
  my ($self, $word, $param) = @_;
  my $list = $self->_get_current_list();
  return unless $list && @{$list->{levels}};
  $list->{levels}[-1]{formatting} ||= [];
  push @{$list->{levels}[-1]{formatting}}, $self->get_token_class()->new(CWORD, $word, $param);
}

######## Top-Level List Properties

sub ltcw_list { $_[0]->group_notes(list => { levels => [] }) }

sub ltcw_listid {
  my ($self, $num) = @_;
  my $list = $self->notes('list');
  return unless $list;
  $list->{id} = $num;
  $self->notes('list'.($num || 0) => $list);
}

sub ltcw_listtemplateid { ($_[0]->notes('list') || {})->{templateid}  = $_[1] }

sub ltcw_listsimple { ($_[0]->notes('list') || {})->{simple} = $_[1] }
sub ltcw_listhybrid { ($_[0]->notes('list') || {})->{hybrid} = 1     }

sub ltcw_listname {
  my $self = shift;
  my $txt = $self->get_parsed_group_pcdata();
  $txt =~ s/;$//;
  ($self->notes('list') || {})->{name} = $txt;
}

######## List Levels

sub ltcw_listlevel {
  my $self = shift;
  my $list = $self->_get_current_list();
  unless($list){
    $self->set_destination();
    return;
  }
  push @{$list->{levels}}, {};
}

sub _set_list_level_prop {
  my ($self, $name, $value) = @_;
  my $list = $self->_get_current_list();
  return unless $list && @{$list->{levels}};
  $list->{levels}[-1]{$name} = $value;
}

sub ltcw_levelstartat { shift()->_set_list_level_prop('start', @_) }

{
  my %list_numbering = (
                         0  => ['decimal', '1', 'ol'],
                         1  => ['upper-roman', 'I', 'ol'],
                         2  => ['lower-roman', 'i', 'ol'],
                         3  => ['upper-alpha', 'A', 'ol'],
                         4  => ['lower-alpha', 'a', 'ol'],
                         12 => ['katakana'],
                         13 => ['katakana-iroha'],
                         22 => ['decimal-leading-zero'],
                         23 => ['disk', 'disk'],
                         45 => ['hebrew'],     ## ??
                         47 => ['hebrew'],     ## ??
                       );
  sub get_list_numbering { $list_numbering{$_[1]}         }
  sub add_list_numbering { $list_numbering{$_[1]} = $_[2] }
  sub del_list_numbering { delete $list_numbering{$_[1]}  }
}

sub ltcw_levelnfc { shift()->_set_list_level_prop('num', @_) }

sub ltcw_levelnfcn { shift()->ltcw_levelnfc(@_) }

sub ltcw_leveljc { shift()->_set_list_level_prop('align', { 0 => 'left', 1 => 'center', 2 => 'right' }->{$_[0]}) }

sub ltcw_leveljcn { shift()->ltcw_leveljc(@_) }

sub ltcw_leveltext    { $_[0]->set_destination() }
sub ltcw_levelnumbers { $_[0]->set_destination() }

######## List Override Table

sub cw_listoverridetable {
  my $self = shift;
  $self->group_notes(list_name => 'listoverride');
  $self->set_new_group_buffer();
  $self->set_group_cwhandler('lotcw_');
  $self->set_group_orig_cword_handler('_list_format_collector');
}

sub lotcw_listoverride { $_[0]->group_notes(listoverride => { levels => [] }) }

sub lotcw_listid { ($_[0]->notes('listoverride') || {})->{lid} = $_[1] }

sub lotcw_ls {
  my ($self, $num) = @_;
  my $lo = $self->notes('listoverride');
  return unless $lo;
  $lo->{id} = $num;
  $self->notes('listoverride'.($num || 0) => $lo);
}

######## List Override Level

sub lotcw_lfolevel {
  my $self = shift;
  unless($self->_get_current_list()){
    $self->set_destination();
    return;
  }
  $self->set_group_cwhandler('ltcw_');
}

sub ltcw_listoverridestartat {
  my $self = shift;
  my $lo = $self->_get_current_list();
  return unless $lo;
  push @{$lo->{lists}}, {};
}

###### Paragraph Group Properties


#### Document Area

###### Information Group

sub cw_info { }

sub cw_title {
  my $self = shift;
  my $text = $self->get_parsed_group_pcdata();
  my $head = $self->get_head_element();
  return unless $head;
  my $title = $self->create_element('title', $head);
  $self->append_text_node($title, $text);
}

###### Document Formatting Properties

sub cw_private { $_[0]->set_destination() if $_[1] == 1 }

###### Section Text

sub cw_sect { $_[0]->flush_section() }

sub cw_sectd { $_[0]->get_sect_stack()->[0] = $_[0]->get_element_class()->new() }

######## Headers and Footers

###### Paragraph Text

######## Paragraph Formatting Properties

sub cw_par {
  my $self = shift;
  my ($ls, $ilvl) = map { $self->get_par()->notes($_) } qw(ls ilvl);
  unless(defined $ls){
    $self->current_buffer()->create_paragraph();
    return;
  }
  my $buf = $self->current_buffer();
  $buf->create_paragraph('li');
  my $pl = $buf->get_paragraphs();
  my ($ppar, $par) = @{$pl}[-3,-2];
  $ilvl = 0 if $ilvl < 0;
  my $listlevels = $self->notes('par_listlevels');
  if($ppar && $listlevels && $listlevels->[0] == $ppar->data()){
    splice @$listlevels, $ilvl+1 if $#$listlevels > $ilvl;
    for (my $i = @$listlevels; $i<=$ilvl; $i++){
      $self->_append_list_levels($listlevels, $ls, $i);
    }
    splice @$pl, @$pl-2, 1;
  }else{
    $listlevels = [];
    $self->notes(par_listlevels => $listlevels);
    for (my $i=0; $i<=$ilvl; $i++){
      $self->_append_list_levels($listlevels, $ls, $i);
    }
    my $el = $self->get_element_class()->new();
    $el->data($listlevels->[0]);
    splice @$pl, @$pl-2, 1, $el;
  }
  $listlevels->[$ilvl]->appendChild($par->data());
}

sub _append_list_levels {
  my ($self, $listlevels, $ls, $i) = @_;
  my $start = $self->get_list_level_prop($ls, $i, 'start');
  my $num = $self->get_list_level_prop($ls, $i, 'num');
  my $lnum = $self->get_list_numbering($num) || [];
  my $le = $self->get_document()->createElement($lnum->[2] || 'ul');
  $le->setAttribute(type => $lnum->[1]) if $lnum->[1];
  $le->setAttribute(style => $self->get_element_class()->style_value({'list-style-type' => $lnum->[0]})) if $lnum->[0];
  $le->setAttribute(start => $start) if $lnum->[2] && $start && $lnum->[2] eq 'ol';
  $listlevels->[$i-1]->appendChild($le) if $i;
  $listlevels->[$i] = $le;
}

sub cw_pard { $_[0]->get_par_stack()->[0] = $_[0]->get_element_class()->new() }

sub cw_intbl { $_[0]->get_par()->notes(intbl => 1)          }
sub cw_qc    { $_[0]->get_par()->attr(align => 'center')    }
sub cw_qj    { $_[0]->get_par()->attr(align => 'justified') }
sub cw_ql    { $_[0]->get_par()->attr(align => 'left')      }
sub cw_qr    { $_[0]->get_par()->attr(align => 'right')     }

######## Bullets and Numbering

########## Word 6.0 and Word 95 RTF

sub cw_pntext { $_[0]->set_destination() }

########## Word 97 through Word 2002 RTF

sub get_list_level_prop {
  my ($self, $ls, $ilvl, $name) = @_;
  my $lo = $self->notes('listoverride'.($ls || 0));
  return unless $lo;
  my $lolevel = $lo->{levels}[$ilvl];
  my $lilevel;
  if(defined($lo->{lid}) && (my $list = $self->notes('list'.($lo->{lid} || 0)))){
    $lilevel = $list->{levels}[$ilvl];
  }
  return $lolevel->{$name} if exists $lolevel->{$name};
  return $lilevel->{$name} if $lilevel && exists $lilevel->{$name};
  return;
}

sub cw_ls {
  my ($self, $ls) = @_;
  my $tokens = [];
  my $ilvl = 0;
  while((my $token = $self->get_token(1))){
    if($token->type() == CWORD && $token->text() eq 'ilvl'){
      $ilvl = $token->param();
      last;
    }
    push @$tokens, $token;
    last if $token->type() != CWORD || $token->text() eq 'par';
  }
  $self->get_par()->notes(ls => $ls);
  $self->get_par()->notes(ilvl => $ilvl);
  $self->unget_tokens($tokens);
}

sub cw_listtext { $_[0]->set_destination() }

######## Paragraph Borders

sub _set_border_style {
  my ($self, $type, $value) = @_;
  my $bname = $self->notes('border_name');
  return unless $bname;
  $bname .= '-'.$type;
  my $el = $self->notes('border_element');
  return if !$el || $el->style($bname);
  $el->style($bname => $value);
}

sub cw_brdrs { $_[0]->_set_border_style(style => 'solid') }
sub cw_brdrw { $_[0]->_set_border_style(width => $_[0]->twips2pt($_[1]).'pt') }

######## Table Definitions

sub _get_table_node {
  my ($self, $skip_last_par) = @_;
  my $buf = $self->current_buffer();
  my $pl = $buf->get_paragraphs();
  my $table = $self->current_table();
  return undef unless $table;
  my $tab = $table->get_element();
  for my $par (reverse @$pl){
    if($par->notes('table_element')){
      last unless $par == $tab;
      return $par->data();
    }
    last unless $par->notes('intbl') || ($skip_last_par && $par == $pl->[-1]);
  }
  return undef;
}

sub _table_collect_pars {
  my $self = shift;
  my $buf = $self->current_buffer();
  my $pb = $buf->get_paragraphs();
  my $pl = [];
  while(@$pb){
    my $par = $pb->[-1];
    last if !$par->notes('intbl') || $par->notes('table_element');
    unshift @$pl, pop @$pb;
  }
  return $pl;
}

sub _start_table {
  my $self = shift;
  my $table = $self->get_table_buf_class()->new($self);
  $self->current_table($table);
  my $tab = $table->get_element();
  $tab->notes(table_element => 1);
  $tab->notes(no_par_stack  => 1);
  $tab->attr(cellpadding => 0);
  $tab->attr(cellspacing => 0);
  $tab->attr(border      => 0);
  $tab->set_element_attrs($self->get_document());
  my $buf = $self->current_buffer();
  my $pb = $buf->get_paragraphs();
  my $lastpar = pop @$pb;
  $buf->add_paragraphs([$tab, $lastpar]);
  return $tab;
}

sub _td_meth {
  my ($self, $meth) = splice(@_, 0, 2);
  my $table = $self->current_table();
  return unless $table;
  my $td = $table->get_cellx();
  return unless $td;
  $td->$meth(@_);
}

sub _td_notes { shift()->_td_meth('notes', @_) }
sub _td_attr  { shift()->_td_meth('attr',  @_) }
sub _td_style { shift()->_td_meth('style', @_) }

sub _tr_meth {
  my ($self, $meth) = splice(@_, 0, 2);
  my $table = $self->current_table();
  return unless $table;
  my $tr = $table->get_row();
  return unless $tr;
  $tr->$meth(@_);
}

sub _tr_notes { shift()->_tr_meth('notes', @_) }
sub _tr_attr  { shift()->_tr_meth('attr',  @_) }
sub _tr_style { shift()->_tr_meth('style', @_) }

sub cw_trowd {
  my $self = shift;
  unless($self->_get_table_node(1)){
    $self->_start_table();
    return;
  }
  my $table = $self->current_table();
  $table->clear_row_formatting();
}

sub cw_trrh {
  my ($self, $val) = @_;
  return unless $val;
  $self->_tr_notes(height => $self->twips2pt(abs($val)).'pt');
}

sub cw_row {
  my $self = shift;
  my $buf = $self->current_buffer();
  my $tab = $self->_get_table_node();
  my $table = $self->current_table();
  return unless $tab && $table;
  $self->_table_collect_pars();                  # Discard anything between \cell and \row.
  $buf->create_paragraph();
  $table->add_row($self->get_document());
}

sub cw_cellx {
  my $self = shift;
  my $table = $self->current_table();
  return unless $table;
  $table->add_cellx(@_)
}

sub cw_cell {
  my $self = shift;
  my $buf = $self->current_buffer();
  my $doc = $self->get_document();
  my $pb = $buf->get_paragraphs();
  my $par = $pb->[-1]->clone();
  $par->data($doc->createElement('p'));
  my $pars = $self->_table_collect_pars();
  $buf->add_paragraphs([$par]);
  $self->_start_table() unless $self->_get_table_node();
  my $table = $self->current_table();
  my $cell;
  if(@$pars == 1){
    $cell = $pars->[0];
    $cell->set_element_attrs($doc, 'td');
  }else{
    $cell = $self->get_element_class()->new();
    my $td = $doc->createElement('td');
    $cell->data($td);
    for my $p (@$pars){
      $td->appendChild($p->set_element_attrs($doc));
    }
  }
  $table->add_cell($cell);
}

sub cw_clvmgf { $_[0]->_td_notes(clvmgf => 1) }
sub cw_clvmrg { $_[0]->_td_notes(clvmrg => 1) }

sub _set_td_width {
  my ($self, $width, $clfts) = @_;
  if($clfts == 2){
    $self->_td_notes(width => sprintf("%.0f%%", $width/50));
  }elsif($clfts == 3){
    $self->_td_notes(width => $self->twips2pt($width).'pt');
  }
}

sub cw_trftsWidth { $_[0]->_tr_notes(trftsWidth => $_[1]) }
sub cw_clftsWidth { $_[0]->_td_notes(clftsWidth => $_[1]) }

sub cw_clwWidth {
  my ($self, $val) = @_;
  my $fts = $self->_td_notes('clftsWidth');
  $fts = $self->_td_notes('trftsWidth') unless defined $fts;
  $self->_set_td_width($val, $fts) if defined $fts;
}

sub _set_td_border_style {
  my ($self, $loc) = @_;
  my $table = $self->current_table();
  return unless $table;
  my $cx = $table->get_cellx();
  $self->group_notes(border_element => $cx);
  $self->group_notes(border_name => 'border-'.$loc);
}

sub cw_clbrdrb { $_[0]->_set_td_border_style('bottom') }
sub cw_clbrdrt { $_[0]->_set_td_border_style('top')    }
sub cw_clbrdrl { $_[0]->_set_td_border_style('left')   }
sub cw_clbrdrr { $_[0]->_set_td_border_style('right')  }

sub _get_shdng_color {
  my ($self, $color, $shad) = @_;
  $shad /= 10000;
  my @clrs = $self->split_color_triplet($color);
  return '#'.join('', map { sprintf("%02x", 255-(255-$_)*$shad) } @clrs);
}

sub _td_shdng {
  my ($self, $val, $name) = @_;
  return if $val == 10000;
  my $color = $self->_td_attr('bgcolor');
  if($color){
    $color = $self->_get_shdng_color($color, $val);
    $self->_td_attr(bgcolor => $color);
  }else{
    $self->_td_notes($name => $val);
  }
}

sub _td_cfpat {
  my ($self, $par, $name) = @_;
  my $color = $self->get_color_triplet($par);
  return unless $color;
  if($self->_td_notes($name)){
    $color = $self->_get_shdng_color($color, $self->_td_notes($name));
  }
  $self->_td_attr(bgcolor => $color) if $color;
}

sub cw_clshdng { $_[0]->_td_shdng($_[1], 'clshdng') }
sub cw_clcfpat { $_[0]->_td_cfpat($_[1], 'clshdng') }

sub cw_clvertalt { $_[0]->_td_attr(valign => 'top')    }
sub cw_clvertalc { $_[0]->_td_attr(valign => 'center') }
sub cw_clvertalb { $_[0]->_td_attr(valign => 'bottom') }

###### Character Text

sub _apply_style {
  my ($self, $type, $num) = @_;
  my $style = $self->notes($type.$num);
  return unless $style;
  $self->unget_tokens($style->{formatting});
}

sub cw_cs  { 
  my ($self, $n) = @_;
  return unless defined $n;
  my $style = $self->notes('cs'.$n);
  return unless $style;
  $self->_clear_char_format() unless $style->{additive};
  $self->_apply_style('cs', $n)  ;
}

sub cw_s   { $_[0]->_apply_style('s', $_[1])   }
sub cw_ds  { $_[0]->_apply_style('ds', $_[1])  }
sub cw_ts  { $_[0]->_apply_style('ts', $_[1])  }

######## Font (Character) Formatting Properties

sub cw_plain {
  my $self = shift;
  my $deff = $self->notes('deff') || '0';
  my $font = $self->notes('f'.$deff);
  $self->group_notes(f => $font) if $font;
  $self->_clear_char_format();
}

sub _clear_char_format { $_[0]->get_char_stack()->clear(sub {$_[0]->notes('not_char_format')}) }

sub _manage_tag {
  defined($_[2]) && $_[2] eq '0' ? $_[0]->close_char_tag($_[1]) : $_[0]->open_char_tag($_[1])
}

sub cw_b { shift()->_manage_tag('b', @_) }

sub cw_cb {
  my ($self, $num) = @_;
  my $color = $self->get_color_triplet($num);
  return unless $color;
  $self->char_tag_style('font', 'background-color' => $color);
}

sub cw_f {
  my ($self, $num) = @_;
  my $font = $self->notes('f'.$num);
  return unless $font;
  $self->group_notes(f => $font);
  my $deff = $self->notes('deff');
  unless(length($deff) && $num == $deff){
    my $ff = $self->_get_font_family($font);
    $self->char_tag_style('font', 'font-family' => $ff) if $ff;
  }
}

sub cw_cf {
  my ($self, $num) = @_;
  my $color = $self->get_color_triplet($num);
  return unless $color;
  $self->char_tag_attr('font', color => $color);
}

sub cw_fs { $_[0]->char_tag_style('font', 'font-size' => (int($_[1]/2)+$_[1]%2).'pt') }

sub cw_i     { shift()->_manage_tag('i', @_) }
sub cw_sub   { $_[0]->open_char_tag('sub')   }
sub cw_super { $_[0]->open_char_tag('sup')   }
sub cw_ul    { shift()->_manage_tag('u', @_) }

######## Special Characters

sub cw_line { $_[0]->append_tag('br') }

sub cw_lbr {
  my ($self, $par) = @_;
  my $el = $self->append_tag('br');
  my $clear = $par == 3 ? 'all'   :
              $par == 2 ? 'right' :
              $par == 1 ? 'left'  : 0;
  $el->setAttribute(clear => $clear) if $clear;
}

sub cw_tab       { $_[0]->append_entity('nbsp') foreach 1..8 }
sub cw_emdash    { $_[0]->append_entity('mdash')  }
sub cw_endash    { $_[0]->append_entity('ndash')  }
sub cw_emspace   { $_[0]->append_entity('emsp')   }
sub cw_enspace   { $_[0]->append_entity('ensp')   }
sub cw_qmspace   { $_[0]->append_entity('thinsp') }
sub cw_bullet    { $_[0]->append_entity('bull')   }
sub cw_lquote    { $_[0]->append_entity('lsquo')  }
sub cw_rquote    { $_[0]->append_entity('rsquo')  }
sub cw_ldblquote { $_[0]->append_entity('ldquo')  }
sub cw_rdblquote { $_[0]->append_entity('rdquo')  }
sub cw_zwj       { $_[0]->append_entity('zwj')    }
sub cw_zwnj      { $_[0]->append_entity('zwnj')   }

###### Bookmarks

sub _get_ancor_name {
  my ($self, $txt) = @_;
  $self->{ancor_count} = 0 unless defined $self->{ancor_count};
  $self->{ancors} ||= {};
  my $name = $self->{ancors}{$txt};
  return $name if defined $name;
  return $self->{ancors}{$txt} = 'a'.$self->{ancor_count}++;
}

sub cw_bkmkstart {
  my $self = shift;
  $self->set_pcdata_mode();
  my $txt = $self->get_parsed_group_text();
  my $name = $self->_get_ancor_name($txt);
  my $el= $self->create_element('a');
  $el->setAttribute(name => $name);
  $self->append_text_node($el, ' ');
  $self->append_element($el);
}

###### Pictures

sub cw_shppict { $_[0]->notes(shppict => -1) }

sub cw_nonshppict {
  my $self = shift;
  my $shppict = $self->notes(shppict => 0);
  $self->set_destination() if $shppict > 0;
}

sub cw_pict {
  my $self = shift;
  if($self->{discard_images}){
    $self->set_destination();
  }else{
    my $buf = $self->set_new_group_buffer();
    $self->group_notes(pict_buf => $buf);
  }
}

sub cw_picscalex { $_[0]->group_notes(picscalex => $_[1]) }
sub cw_picscaley { $_[0]->group_notes(picscaley => $_[1]) }
sub cw_picwgoal  { $_[0]->group_notes(picwgoal  => $_[1]) }
sub cw_pichgoal  { $_[0]->group_notes(pichgoal  => $_[1]) }

{
  my %res_coeff = (i => 1, m => 0.0254, cm => 2.54);
  sub _get_image_dim {
    my ($self, $w, $h, $sx, $sy, $res) = @_;
    my ($rx, $ry, $un);
    my $scr = $self->{screen_resolution} || 100; # dpi
    if($res =~ /(\d+)\s+dp(\w+)/){
      $rx = $ry = $1;
      $un = $res_coeff{$2};
    }elsif($res =~ m|(\d+)\s+/\s+(\d+)\s+dp(\w+)|){
      $rx = $1;
      $ry = $2;
      $un = $res_coeff{$3};
    }elsif($res eq '1/1'){
      $rx = $ry = $scr;
      $un = 1;
    }
    return unless $rx && $ry && $un;
    return ($scr/$un/$rx*$sx/100*$w, $scr/$un/$ry*$sy/100*$h);
  }
}

sub _picblib {
  my ($self, $ext) = @_;
  my ($imgname, $imgurl) = $self->get_next_image_name($ext);
  return unless open my $fh, '>', $imgname;
  $self->set_group_sink($fh);
  my $hm = $self->hex_mode(1);
  $self->add_on_leave_handler('_convert_picture', [$imgname, $imgurl, $fh, $hm]);
}

sub cw_pngblip  { shift()->_picblib('png') }
sub cw_jpegblip { shift()->_picblib('jpg') }

sub get_image_scale_command {
  my ($self, $w, $h, $imgname) = @_;
  my $mogrify = exists $self->{image_mogrify} ? $self->{image_mogrify} : 'mogrify';
  return unless $mogrify;
  return ($mogrify, '-geometry', sprintf("%dx%d!", $w, $h), $imgname);
}

sub get_wmf2ps_command {
  my ($self, $wmfname, $psname) = @_;
  my $wmf2eps = exists $self->{image_wmf2eps} ? $self->{image_wmf2eps} : 'wmf2eps';
  return unless $wmf2eps;
  return ($wmf2eps, qw(--ps --centre --maxpect -o), $psname , $wmfname);
}

sub get_ps2gif_command {
  my ($self, $psname, $gifname, $w, $h) = @_;
  my $convert = exists $self->{image_convert} ? $self->{image_convert} : 'convert';
  return unless $convert;
  my @geom = $w && $h ? ('-geometry', sprintf("%dx%d!", $w, $h)): ();
  return ($convert, qw(-crop 0x0 -page +0+0), @geom, $psname, $gifname);
}

sub _convert_picture {
  my ($self, $imgname, $imgurl, $fh, $hexmode) = @_;
  $fh->close();
  $self->hex_mode($hexmode);
  return unless -s $imgname;
  my $info = Image::Info::image_info($imgname);
  my ($width, $height, $res) = @{$info}{qw(width height resolution)};
  my ($w, $h);
  if($width && $height){
    my ($sx, $sy) = map { $self->notes($_) } qw(picscalex picscaley);
    ($w, $h) = $self->_get_image_dim($width, $height, $sx, $sy, $res);
    ($w, $h) = map { sprintf("%.0f", $_) } ($w || $width, $h || $height);
    if($w != $width || $h != $height){
      my @cmd = $self->get_image_scale_command($w, $h, $imgname);
      return unless @cmd;
      if(my $err = $self->exec_program(undef, @cmd)){
        $self->log($err, 1);
        return;
      }
    }
  }
  $self->remove_buffer($self->notes('pict_buf'));
  my $img = $self->append_tag('img');
  $img->setAttribute(src    => $imgurl);
  $img->setAttribute(width  => $w) if $w;
  $img->setAttribute(height => $h) if $h;
  $img->setAttribute(alt    => '');
  $self->notes(shppict => 1) if $self->notes('shppict');
}

sub cw_wmetafile {
  my ($self, $type) = @_;
  my ($gifname, $gifurl) = $self->get_next_image_name('gif');
  my ($w, $h);
  my $hexmode = $self->hex_mode();
  try {
    my $wmf = File::Temp->new(SUFFIX => '.wmf', UNLINK => 1);
    throw Error::Simple("Can't open wmf file: $!!\n") unless $wmf;
    $self->set_group_sink($wmf);
    $self->hex_mode(1);
    my @dims;
    $self->store_notes(\@dims, qw(picwgoal pichgoal picscalex picscaley));
    $self->parse();
    $wmf->close();
    $self->hex_mode($hexmode);
    my $ps = File::Temp->new(SUFFIX => '.ps', UNLINK => 1);
    throw Error::Simple("Can't open ps file: $!!\n") unless $ps;
    $ps->close();
    my @command = $self->get_wmf2ps_command($wmf->filename(), $ps->filename());
    return unless @command;
    my $err = $self->exec_program(undef, @command);
    throw Error::Simple($err) if length $err;
    return unless -s $ps->filename();
    my ($width, $height, $sx, $sy) = @dims;
    if($width && $height){
      ($w, $h) = $self->twips2pt($sx?$width*$sx/100:$width, $sy?$height*$sy/100:$height);
    }
    @command = $self->get_ps2gif_command($ps->filename(), $gifname, $w, $h);
    return unless @command;
    $err = $self->exec_program(undef, @command);
    throw Error::Simple($err) if length $err;
  } catch Error::Simple with {
    my $err = shift;
    $self->hex_mode($hexmode);
    $self->log($err, 1) if length $err;
    return;
  };
  return unless -s $gifname;
  $self->remove_buffer($self->notes('pict_buf'));
  my $img = $self->append_tag('img');
  $img->setAttribute(src    => $gifurl);
  $img->setAttribute(width  => $w) if $w;
  $img->setAttribute(height => $h) if $h;
  $img->setAttribute(alt    => '');
  $self->notes(shppict => 1) if $self->notes('shppict');
}

sub cw_bin {
  my $self = shift;
  while(my $token = $self->get_token()){
    $self->out($token->text());
    last if $token->type() == ENBIN || $self->is_stop_token($token);
  }
}

###### Word 97 through Word 2002 RTF for Drawing Objects (Shapes)

sub cw_shp { $_[0]->notes(shp => 0) }

sub cw_shpinst {
  my $self = shift;
  my $buf = $self->set_new_group_buffer();
  $self->parse();
  return if $buf->is_empty();
  $self->notes(shp => 1);
  my $cbuf = $self->current_buffer();
  $cbuf->merge($buf);
}

sub cw_sn { $_[0]->notes(sn => $_[0]->get_parsed_group_text()) }

sub cw_sv {
  my $self = shift;
  unless($self->notes('sn') eq 'pib'){
    $self->set_destination();
    return;
  }
}

# This is not correct, but it looks like \shptxt duplicates the information.
sub cw_shptxt { $_[0]->set_destination() }

sub cw_shprslt { $_[0]->set_destination() if $_[0]->notes('shp') }

###### Footnotes

sub cw_footnote {
  my $self = shift;
  unless($self->notes('footnote_list')){
    $self->notes(footnote      => 1);
    $self->notes(footnote_list => []);
    $self->add_sect_on_leave_handler('_add_footnotes');
  }
  my $buf = $self->set_new_group_buffer();
  $self->parse();
  my $num = $self->notes('footnote');
  $self->notes(footnote => $num+1);
  push @{$self->notes('footnote_list')}, [$num, $buf];
  my $name = $self->_get_footnote_name($num);
  my $el = $self->create_element('a');
  $el->setAttribute(href => '#'.$name);
  $el->setAttribute(name => $name.'u');
  $self->append_text_node($el, $num);
  $self->append_element($el);
}

sub _get_footnote_name { 's'.($_[0]->notes('footnote_snum') || 0).'f'.$_[1] }

sub _add_footnotes {
  my $self = shift;
  my $list = $self->notes('footnote_list');
  return unless $list && @$list;
  my $body = $self->get_body_element();
  my $table = $self->create_element('table');
  $table->setAttribute(cellpadding => 0);
  $table->setAttribute(cellspacing => 3);
  $table->setAttribute(border      => 0);
  for my $item (@$list){
    my $tr = $self->create_element('tr', $table);
    $tr->setAttribute(valign => 'top');
    my $td = $self->create_element('td', $tr);
    my $el = $self->create_element('a', $td);
    my $name = $self->_get_footnote_name($item->[0]);
    $el->setAttribute(href => '#'.$name.'u');
    $el->setAttribute(name => $name);
    $self->append_text_node($el, '['.$item->[0].']');
    $td = $self->create_element('td', $tr);
    $self->_apppend_paragraphs($td, $item->[1]);
  }
  $body->appendChild($table) if $table->hasChildNodes();
  my $sectnum = $self->notes('footnote_snum') || 0;
  $self->notes(footnote_snum => $sectnum+1);
  $self->del_note('footnote');
  $self->del_note('footnote_list');
}

###### Fields

sub cw_field { $_[0]->group_notes(fldrslt_skip => 0) }

sub cw_fldinst {
  my $self = shift;
  my $txt = $self->get_parsed_group_text();
  if($txt =~ /HYPERLINK\s+"?([^\s"]+)"?\s*$/){
    $self->char_tag_attr('a', href => "$1");
    $self->char_tag_notes('a', not_char_format => 1);
  }elsif($txt =~ /HYPERLINK\s+\\l\s+"?([^"]+)"?\s*$/){
    my $name = $self->_get_ancor_name($1);
    $self->char_tag_attr('a', href => '#'.$name);
    $self->char_tag_notes('a', not_char_format => 1);
  }elsif($txt =~ /SYMBOL\s+(\d+)/){
    my $code = $1;
    my ($fname) = $txt =~ /\\f\s+"([^"]+)"/;
    if($fname && (my ($font) = grep { $_->{face} eq $fname }
                               map  { $self->{notes}{$_}   }
                               grep { /^f\d+$/ } keys %{$self->{notes}})){
      $self->notes(fldrslt_skip => 1);
      my $oldf = $self->notes(f => $font);
      if($txt =~ /\\s\s+(\d+)/){
        my $size = $1;
        my $el= $self->create_element('font');
        $el->setAttribute(style => "font-size: ${size}pt");
        $self->append_text_node($el, $self->_encode_text(chr($code)));
        $self->append_element($el);
      }else{
        $self->append_text(chr($code));
      }
      $self->notes(f => $oldf);
    }
  }elsif($txt =~ /PAGEREF\s+(\S+)\s*\\h/){
    my $href = $1;
    $self->notes(fldrslt_skip => 1);
    my $name = $self->_get_ancor_name($href);
    my $el = $self->create_element('a');
    $el->setAttribute(href => '#'.$name);
    $self->append_text_node($el, '*');
    $self->append_element($el);
  }elsif($txt =~ /\\import\s+([^}]+)/){
    my $fname = $1;
    return if $self->{discard_images};
    my $imgname = $fname;
    $imgname = File::Spec->catfile($self->{image_dir}, $imgname) if length $self->{image_dir};
    return unless -s $imgname;
    my $info = Image::Info::image_info($imgname);
    my ($w, $h) = @{$info}{qw(width height)};
    return unless $w && $h;
    $self->notes(fldrslt_skip => 1);
    my $url = join('/', grep { length } ($self->{image_uri}, $fname));
    my $img = $self->append_tag('img');
    $img->setAttribute(src => $url);
    $img->setAttribute(width => $w);
    $img->setAttribute(height => $h);
    $img->setAttribute(alt => '');
  }
}

sub cw_fldrslt { $_[0]->set_destination() if $_[0]->notes('fldrslt_skip') }

package RTF::HTMLConverter::Token;

sub new {
  my $class = shift;
  return bless [@_], ref($class) || $class;
}

sub type  { $_[0]->[0] }
sub text  { $_[0]->[1] }
sub param { $_[0]->[2] }

package RTF::HTMLConverter::Element;

use constant {
      _NTS => 0,
      _ATR => 1,
      _STY => 2,
      _DAT => 3,
};

sub new { bless [{}, {}, {} ], ref($_[0]) || $_[0] }

sub modified { }

sub _notes {
  my ($self, $i) = splice(@_, 0, 2);
  if(@_ == 2){
    my $old = $self->[$i]{$_[0]};
    $self->[$i]{$_[0]} = $_[1];
    $self->modified(1);
    return $old;
  }
  $self->[$i]{$_[0]};
}

sub notes { shift()->_notes(_NTS, @_) }
sub attr  { shift()->_notes(_ATR, @_) }
sub style { shift()->_notes(_STY, @_) }

sub data {
  my $self = shift;
  if(@_){
    my $old = $self->[_DAT];
    $self->[_DAT] = $_[0];
    $self->modified(1);
    return $old;
  }
  return $self->[_DAT];
}

# This method does not clone associated data in case the data is an
# object or complex structure - it just stores a reference to the data.
sub clone {
  my ($self, $wd) = @_;
  my $el = $self->new();
  for my $i (_NTS, _ATR, _STY){
    @{$el->[$i]}{keys %{$self->[$i]}} = values %{$self->[$i]} if %{$self->[$i]};
  }
  $el->[_DAT] = $self->[_DAT] if $wd && exists $self->[_DAT];
  return $el;
}

# See comment to 'clone' method.
sub merge {
  my ($self, $el, $wd) = @_;
  return unless $el;
  for my $i (_NTS, _ATR, _STY){
    if(%{$el->[$i]}){
      @{$self->[$i]}{keys %{$el->[$i]}} = values %{$el->[$i]};
      $self->modified(1);
    }
  }
  if($wd && exists $el->[_DAT]){
    $self->[_DAT] = $el->[_DAT];
    $self->modified(1);
  }
}

{
  my $pv = ': ';
  my $st = '; ';
  sub style_value { my $s=$_[1]||$_[0]->[_STY];join($st, map { $_.$pv.$s->{$_} } sort keys %$s) }
  sub style_hash  { map { split(/\Q$pv/, $_) } split(/\Q$st/, $_[1] || $_[0]->[2])              }
}

# This method assumes $elem->data() to be a DOM Node or a string.
# In the latter case the string is assumed to be a tag name.
sub set_element_attrs {
  my ($self, $doc, $name) = @_;
  my $el;
  if($name){
    $el = $doc->createElement($name);
    my $dat = $self->data();
    if(ref($dat) && UNIVERSAL::can($dat, 'getFirstChild')){
      while((my $child = $dat->getFirstChild())){
        $el->appendChild($child);
      }
    }
  }else{
    $el = $self->data();
    $el = $doc->createElement($el) unless ref $el;
  }
  my $hr = $self->[_ATR];
  while(my ($k, $v) = each %{$hr || {}}){
    $el->setAttribute($k => $v);
  }
  my $style = $self->style_value();
  $el->setAttribute(style => $style) if length $style;
  $self->data($el);
  return $el;
}

package RTF::HTMLConverter::ModificationTracker;

sub modified {
  my $self = shift;
  return $self->[$self->_MOD] unless @_;
  my $old = $self->[$self->_MOD];
  $self->[$self->_MOD] = $_[0];
  return $old;
}

package RTF::HTMLConverter::ModElement;

use constant _MOD => 4;

our @ISA = qw(RTF::HTMLConverter::Element RTF::HTMLConverter::ModificationTracker);

sub clone {
  my $self = shift;
  my $el = $self->SUPER::clone(@_);
  $el->[_MOD] = $self->[_MOD];
  return $el;
}

package RTF::HTMLConverter::CharStack;

use constant {
      _STK => 0,
      _MST => 1,
      _MOD => 2,
      _CLA => 3,
};

our @ISA = qw(RTF::HTMLConverter::ModificationTracker);

sub new { bless [[[]], [0], 0, $_[1]->get_modelement_class()], ref($_[0]) || $_[0] }

sub _get_top { $_[0]->[_STK][0] || [] }

sub get_element_class { $_[0]->[_CLA] }

sub item { [ map { $_->clone(1) } @{$_[0]->_get_top()} ] }

sub modified { $_[0]->[_MST][0] = 1 if $_[1]; shift()->SUPER::modified(@_) }

sub dup {
  my $self = shift;
  my $top = $self->_get_top();
  my $new = [];
  unshift @{$self->[_STK]}, $new;
  unshift @{$self->[_MST]}, 0;
  my $nel;
  for my $el (@$top) {
    $nel = $el->clone(1);
    push @$new, $nel;
  }
}

sub drop { $_[0]->[_MOD] = 1 if shift @{$_[0]->[_MST]}; shift @{$_[0]->[_STK]} }

sub clear {
  my ($self, $sub) = @_;
  my $top = $self->_get_top();
  my $count = @$top;
  return unless $count;
  if($sub){
    @$top = grep { $sub->($_) } @$top;
  }else{
    @$top = ();
  }
  $self->modified(1) if @$top != $count;
}

sub _get_element { (grep { $_->data() eq $_[1] } @{$_[0]->_get_top()})[0] }

sub open_tag {
  my ($self, $tag) = @_;
  return if $self->_get_element($tag);
  my $el = $self->get_element_class()->new();
  $el->data($tag);
  push @{$self->_get_top()}, $el;
  $self->modified(1);
  return;
}

sub close_tag {
  my ($self, $tag) = @_;
  my $els = $self->_get_top();
  my $count = @$els;
  @$els = grep { $_->data() ne $tag } @$els;
  $self->modified(1) if @$els != $count;
  return undef;
}

sub _tag_notes {
  my ($self, $meth, $tag) = splice(@_, 0 , 3);
  my $created;
  my $el = $self->_get_element($tag);
  unless($el){
    $el = $self->get_element_class()->new();
    $el->data($tag);
    $created = 1;
  }
  my $ret = $el->$meth(@_);
  if($el->modified() || $created){
    $self->modified(1);
    $el->modified(0);
    push @{$self->_get_top()}, $el if $created;
  }
  return $ret;
}

sub tag_notes { shift()->_tag_notes('notes', @_) }
sub tag_attr  { shift()->_tag_notes('attr',  @_) }
sub tag_style { shift()->_tag_notes('style', @_) }

package RTF::HTMLConverter::Buffer;

# See comment before analogous definition in package RTF::HTMLConverter.
use constant {
      ELEMENT_NODE => 1,
      TEXT_NODE    => 3,
};

use constant {
      _DOC => 0,
      _CPS => 1,
      _DFR => 2,
      _TXT => 3,
      _CST => 4,
      _PST => 5,
      _FMT => 6,
      _ELC => 7,
};

sub new {
  my ($class, $conv) = @_;
  $conv = $class->get_document() if !$conv && ref($class);
  my $doc = $conv->get_document();
  my $self = bless [
    $doc,
    [],                                          # Collection of paragraphs (of type 'Element')
    $doc->createDocumentFragment(),              # Latest text mixed with tags and/or entities
    '',                                          # Current plain text
    $conv->get_char_stack(),                     # converter's Character STack
    $conv->get_par_stack(),                      # converter's Paragrapth STack
    undef,                                       # current character stack top (ForMaTting)
    $conv->get_element_class(),                  # ELement Class
  ], ref($class) || $class;
  $self->_create_par();
  $self->[_FMT] = $self->[_CST]->item();
  return $self;
}

sub _create_par {
  my $self = shift;
  my $par = $self->[_ELC]->new();
  $par->data($self->[_DOC]->createElement('p'));
  push @{$self->[_CPS]}, $par;
  return $par;
}

sub _flush_text {
  my $self = shift;
  return unless length($self->[_TXT]);
  my $child = $self->[_DFR]->getLastChild();
  if($child && $child->getNodeType() == TEXT_NODE){
    $child->appendData($self->[_TXT]);
  }else{
    $child = $self->[_DOC]->createTextNode($self->[_TXT]);
    $self->[_DFR]->appendChild($child);
  }
  $self->[_TXT] = '';
  return 1;
}

sub _flush_fragment {
  my $self = shift;
  $self->_flush_text();
  my $fmt = $self->[_FMT];
  $self->[_FMT] = $self->[_CST]->item();
  return unless $self->[_DFR]->hasChildNodes() && @{$self->[_CPS]};
  $self->[_CST]->modified(0);
  my $parent = $self->[_CPS][-1]->data();
  for my $t (@{$fmt || []}){
    my $el = $t->set_element_attrs($self->[_DOC]);
    $parent->appendChild($el);
    $parent = $el;
  }
  $parent->appendChild($self->[_DFR]);
}

sub _flush_par {
  my $self = shift;
  $self->_flush_fragment();
  my $par = $self->[_CPS][-1];
  return unless $par;
  my $pe = $par->data();
  $par->merge($self->[_PST][0]) unless $par->notes('no_par_stack');
  $par->set_element_attrs($self->[_DOC], @_);
  return $par;
}

sub _check_mod { $_[0]->_flush_fragment() if $_[0]->[_CST]->modified() }

sub get_document { $_[0]->[_DOC] }

sub add_text { $_[0]->_check_mod(); $_[0]->[_TXT] .= $_[1] }

sub add_node { $_[0]->_check_mod(); $_[0]->_flush_text(); $_[0]->[_DFR]->appendChild($_[1]) }

sub add_tag {
  my ($self, $tag) = @_;
  my $node = $self->[_DOC]->createElement($tag);
  $self->add_node($node);
  return $node;
}

sub add_entity {
  my ($self, $name) = @_;
  my $entity = $self->[_DOC]->createEntityReference($name);
  $self->add_node($entity);
  return $entity;
}

sub create_paragraph {
  my $self = shift;
  $self->_flush_par(@_);
  $self->_create_par();
  return $self->[_CPS][-2];
}

sub _get_text_contents {
  my ($self, $el) = @_;
  my $txt = '';
  my $child = $el->getFirstChild();
  return $txt unless $child;
  do {
    my $type = $child->getNodeType();
    if($type == TEXT_NODE){
      $txt .= $child->getNodeValue();
    }elsif($type == ELEMENT_NODE){
      $txt .= $self->_get_text_contents($child);
    }
  } while($child = $child->getNextSibling());
  return $txt;
}

sub get_text {
  my $self = shift;
  my $txt = '';
  for my $p (@{$self->[_CPS]}){
    $txt .= $self->_get_text_contents($p->data());
  }
  $txt .= $self->_get_text_contents($self->[_DFR]);
  $txt .= $self->[_TXT];
  return $txt;
}

sub get_paragraphs { $_[0]->_flush_par(); $_[0]->[_CPS] }

sub add_paragraphs { $_[0]->_flush_par(); push @{$_[0]->[_CPS]}, @{$_[1] || []} }

sub is_empty {
  @{$_[0]->[_CPS]} < 2                       &&
  !$_[0]->[_CPS][0]->data()->hasChildNodes() &&
  !$_[0]->[_DFR]->hasChildNodes()            &&
  !length($_[0]->[_TXT])
}

sub merge {
  my ($self, $buf) = @_;
  $self->_flush_fragment();
  my $cp = $self->[_CPS][-1]->data();
  my $pars = $buf->get_paragraphs();
  my $par = shift @$pars;
  my $p = $par->data();
  while(my $child = $p->getFirstChild()){
    $cp->appendChild($child);
  }
  push @{$self->[_CPS]}, @$pars;
  @$pars = ();
}

package RTF::HTMLConverter::TableBuffer;

use constant {
      _TAB => 0,
      _TCS => 1,
      _TCP => 2,
      _CTR => 3,
      _CTC => 4,
      _CTX => 5,
      _CCC => 6,
      _CXC => 7,
      _CCL => 8,
};

sub new {
  my ($class, $conv) = @_;
  my $self = bless [
    $conv->get_element_class()->new($conv),      # TABle node
    [],                                          # Table Cell nodeS
    [],                                          # Table Cell Positions
    $conv->get_element_class()->new($conv),      # Current Table Row node
    [],                                          # Current Table row Cells
    [$conv->get_element_class()->new($conv)],    # Current Table row cellXes
    0,                                           # Current Cell Count
    0,                                           # Current cellX Count
    ref($conv) || $conv,                         # Converter's CLass
  ], ref($class) || $class;
  $self->[_TAB]->data('table');
  $self->[_CTR]->data('tr');
  return $self;
}

sub get_element { $_[0]->[_TAB] }
sub get_row     { $_[0]->[_CTR] }

sub clear_row_formatting {
  my $self = shift;
  $self->[_CTR] = $self->get_element()->new();
  $self->[_CTR]->data('tr');
  $self->[_CTX] = [$self->get_element()->new()];
  $self->[_CXC] = 0;
}

sub get_cellx { $_[0]->[_CTX][$_[0]->[_CXC]] ||= $_[0]->get_element()->new() }

sub add_cellx {
  my ($self, $pos) = @_;
  my $cell = $self->get_cellx();
  $cell->notes(cellx => $pos);
  unless(grep { $_ == $pos } @{$self->[_TCP]}){
    @{$self->[_TCP]} = sort { $a <=> $b } @{$self->[_TCP]}, $pos;
    $self->get_element()->notes(cellx_new => 1);
  }
  $self->[_CXC]++;
}

sub get_cell { $_[0]->[_CTC][$_[0]->[_CCC]] }

sub add_cell {
  my ($self, $cell) = @_;
  $self->[_CTC][$self->[_CCC]] = $cell;
  $self->[_CCC]++;
  return $cell;
}

# Currently we use only '\cellxN' to determine cells' width.
# 'trftsWidth' and 'clftsWidth' will be taken into account later.
sub add_row {
  my ($self, $doc) = @_;
  my $row = $self->get_row();
  my $tr = $row->set_element_attrs($doc);
  my $row_height = $row->notes('height');
  for (my $i = 0; $i < @{$self->[_CTC]}; $i++){
    my $c = $self->[_CTC][$i];
    my $fc = $self->[_CTX][$i];
    $c->merge($fc) if $fc;
    if($c->notes('clvmrg')){
      my $cx = $c->notes('cellx');
      my $prevrow = $self->[_TCS][-1];
      for my $pc (@$prevrow){
        my $pcx = $pc->notes('cellx');
        next if $pcx < $cx;
        last if $pcx > $cx;
        if($pc->notes('clvmgf') || $pc->notes('clvmrg')){
          my $td = $pc->data();
          last unless $td;
          my $rs = $td->getAttribute('rowspan');
          $rs ||= 1;
          $rs++;
          $td->setAttribute(rowspan => $rs);
          $c->data($td);
        }
        last;
      }
      next;
    }
    next unless $c->data();
    $c->style(height => $row_height) if $row_height;
    $c->set_element_attrs($doc);
    $tr->appendChild($c->data());
  }
  if($self->get_element()->notes('cellx_new')){
    $self->get_element()->notes(cellx_new => 0);
    push @{$self->[_TCS]}, $self->[_CTC];
    for my $rw (@{$self->[_TCS]}){
      $self->_format_row($rw);
    }
  }else{
    $self->_format_row($self->[_CTC]);
    push @{$self->[_TCS]}, $self->[_CTC];
  }
  $self->get_element()->data()->appendChild($tr);
  $self->[_CTR] = $row->clone();
  $self->[_CTR]->data('tr');
  $self->[_CTC] = [];
  $self->[_CCC] = 0;
}

sub _format_row {
  my ($self, $row) = @_;
  my $cp = 0;
  my $px = 0;
  for my $c (@$row){
    my $cx = $c->notes('cellx');
    return unless defined $cx;
    my $td = $c->data();
    next unless $td;
    $td->setAttribute(width => $self->[_CCL]->twips2pt($cx-$px));
    $px = $cx;
    if($self->[_TCP][$cp] == $cx){
      $cp++;
      next;
    }
    my $ci = 0;
    while($self->[_TCP][$cp] && $self->[_TCP][$cp] <= $cx){
      $ci++;
      $cp++;
    }
    $td->setAttribute(colspan => $ci) if $ci > 1;
  }
}

1;

=head1 NAME

RTF::HTMLConverter - Converter from RTF format to HTML.

=head1 SYNOPSIS

  use XML::GDOME;
  use RTF::HTMLConverter;
  my $parser = RTF::HTMLConverter->new(in  => 'test.rtf',
                                       out => 'test.html');
  $parser->parse();

  use XML::DOM;
  use RTF::HTMLConverter;
  open my $in, 'test.rtf' or die;
  my $parser = RTF::HTMLConverter->new(
    in  => $in,
    out => 'test.html',
    DOMImplementation => 'XML::DOM',
    image_uri => "http://somewhere.net/images",
    codepage => 'iso-8859-1',
  );
  $parser->parse();

  use XML::GDOME;
  use RTF::HTMLConverter;
  my $html = '';
  my $parser = RTF::HTMLConverter->new(
    in => 'test.rtf',
    out => \$html,
    discard_images => 1,
  );
  $parser->parse();


=head1 DESCRIPTION

RTF::HTMLConverter is a high-level RTF to HTML format converter. It is
based on the low-level RTF parser module RTF::Lexer. Additionally, it
requires the W3C's DOM implementation and it is known to work with either
XML::DOM or XML::GDOME.

=head1 METHODS

=over 4

=item new

The constructor. The following parameters are recognized:

=over 8

=item in

Input file handle or a file name. Default value is C<\*STDIN>.
See C<RTF::Lexer> for more information.

=item out

Output file handler or file name or scalar reference. If this parameter
is a string it is treated as a file name and the constructor tries to
open that file. If that file already exists, it is truncated. In the
case of failure while opening the file an exception is thrown. If this
parameter is a scalar reference the resulting html is stored in that
scalar.

=item DOMImplementation

The DOM implementation module name. Supported values are C<XML::DOM> and
C<XML::GDOME>. The default value is C<XML::GDOME>.

=item codepage

The charset of the resulted html-document. By default is C<utf8>.
This parameter is recognized only if DOMImplementation is C<XML::GDOME>.

=item formatting

The formatting of the resulted html-document. This parameter is recognized
only if DOMImplementation is C<XML::GDOME>. Possible values are:
C<GDOME_SAVE_STANDARD> and C<GDOME_SAVE_LIBXML_INDENT>. See C<XML::GDOME::Document>
for more information. Default value is C<GDOME_SAVE_LIBXML_INDENT>.

=item doctype

A reference to an array (C<$name>, C<$publicId>, C<$systemId>) if
DOMImplementation is C<XML::GDOME> or (C<$name>, C<$systemId>, C<$publicId>)
if DOMImplementation is C<XML::DOM>. Default values are:

=over 12

=item $name

C<HTML>

=item $publicId

C<-//W3C//DTD HTML 4.01 Transitional//EN>

=item $systemId

C<http://www.w3.org/TR/html4/loose.dtd>

=back

=item discard_images

Being set, this parameter disables any image processing. By default
it is unset.

=item image_uri

The string that being concatenated with the image name gives this
image's URL. Default value is empty string.

=item image_dir

A directory name where the images are generated. Default value is empty
string which means the current directory.

=item image_names

The pattern for generating image names from there number. Default value
is C<img%d>.

=item image_convert

A path to ImageMagick's C<convert> utility. Default value is simply
C<convert> assuming it is in one of the $ENV{PATH} directories.

=item image_mogrify

A path to ImageMagick's C<mogrify> utility. If the value is C<undef> or
the specified file does not exists, the images extracted from RTF will
not be scaled. Default value is C<mogrify>.

=item image_wmf2eps

A path to libwmf's C<wmf2eps> utility. If the value is C<undef> or the
specified file does not exists, the WMF-images will not be extracted
from RTF. Default value is C<wmf2eps>.

=item screen_resolution

The display resolution in dpi. Default value is 100.

=back

=item parse

Parses the input RTF stream until the end of file.

=back

=head1 SEE ALSO

RTF::Lexer, Rich Text Format (RTF) Specification (version 1.7), The_RTF_Cookbook,
RTF::Parser, RTF::Tokenizer.

=head1 KNOWN BUGS

=over 4

=item -

The symbols that absent in Unicode character set will be displayed incorrectly.

=item -

The images that are stored in RTF file in WMF format may be scaled incorrectly.

=item -

The text in WMF images in non-ASCII charset may be displayed incorrectly.

=back

And there should be lots of unknown bugs;)

=head1 AUTHOR

Vadim O. Ustiansky <ustiansky@cpan.org>

