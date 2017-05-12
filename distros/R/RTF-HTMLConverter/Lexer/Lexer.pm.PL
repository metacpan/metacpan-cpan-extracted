use strict;
use warnings;

open my $out, "> Lexer.pm" or die "Can't open Lexer.pm: $!!\n";
print $out <<'EOT';
package RTF::Lexer;
use strict;
use Exporter;
use DynaLoader;

our @ISA = qw(DynaLoader Exporter);
our $VERSION = '0.03';

EOT

open my $fh, 'rtfparser.h' or die "Can't open rtfparser.h: $!!\n";
while(my $line = <$fh>){
  next unless $line =~ /#define\s+(\w+)\s+(\d+)/;
  print $out "use constant $1 => $2;\n";
}
close $fh;

print $out <<'EOT';

our @EXPORT_OK;
our %EXPORT_TAGS;
{
  my $package  = __PACKAGE__;
  @EXPORT_OK   = (grep { $_ } map { /^$package\::(\w+)$/ } keys %constant::declared);
  %EXPORT_TAGS = (all => [@EXPORT_OK]);
}

sub new {
  my $proto = shift;
  my $self = bless({}, ref($proto) || $proto);
  $self->init(@_);
  return $self;
}

sub init{
  my ($self, %opts) = @_;
  $self->{RTF_Lexer_backpack}    = [];
  $self->{_RTF_Lexer_backpack}   = undef;
  if($opts{in}){
    unless(ref $opts{in}){
      open my $fh, "< $opts{in}" or die "Can't open '$opts{in}': $!!\n";
      $opts{in} = $fh;
    }
    $self->_set_source($opts{in});
    $self->{_RTF_Lexer_IN} = $opts{in};
  }
}

bootstrap RTF::Lexer $VERSION;

sub get_token {
  my $self = shift;
  my $token;
  if(@{$self->{RTF_Lexer_backpack}}){
    $token = shift @{$self->{RTF_Lexer_backpack}};
  }else{
    if($self->{_RTF_Lexer_backpack}){
      $token = $self->{_RTF_Lexer_backpack};
      $self->{_RTF_Lexer_backpack} = undef;
    }else{
      $token = [0, ''];
      $token->[0] = $self->_get_token($token->[1]);
    }
    if($token->[0] == CWORD){
      my ($type, $text);
      $type = $self->_get_token($text);
      if($type == CPARM){                             # Parameter that follows
        $token->[2] = $text;
        $type = $self->_get_token($text);         # Space delimiter if any
        $self->{_RTF_Lexer_backpack} = [$type, $text] unless $type == CNOPR;
      }elsif($type != CNOPR){                         # Not a space delimiter
        $self->{_RTF_Lexer_backpack} = [$type, $text];
      }
    }
  }
  return $token->[0] ? $token : undef;
}

sub unget_token { push @{$_[0]->{RTF_Lexer_backpack}}, $_[1] }

{
  my %stop_tokens = map { $_ => 1 } (OKEOF, UNBRC, UNEOF);
  sub is_stop_token  { $stop_tokens{ref($_[1]) ? $_[1]->[0] : $_[1]}        }
  sub add_stop_token { $stop_tokens{ref($_[1]) ? $_[1]->[0] : $_[1]} = 1    }
  sub del_stop_token { delete $stop_tokens{ref($_[1]) ? $_[1]->[0] : $_[1]} }
}


1;

=head1 NAME

RTF::Lexer - Rich Text Format (RTF) lexical analyzer.

=head1 SYNOPSIS

  use RTF::Lexer qw(:all);

  my $parser = RTF::Lexer->new(in => 'text.rtf');
  my $token;
  do {
    $token = $parser->get_token();
  } until $parser->is_stop_token($token);


=head1 DESCRIPTION

RTF::Lexer is a low-level RTF format lexical analyzer. It splits the
input stream into separate tokens, which can be handled by other
high-level modules.

=head1 METHODS

=over 4

=item new

The constructor. Accepts the only argument C<in> which must be an input
file handle or a file name. In the latter case if there is a failure
while opening the file method C<new> throws an exception. By default
the input is read from C<STDIN>.

=item get_token

Returns the next token from the input stream. The token is a reference to
an array those first element is a numeric id of the token type. The second
element is a string representation of the token. The third element may
exists only if the token is a control word and represents the numerical
parameter of this control word.

The following token types are recognized by RTF::Lexer, that are declared
as constants in this module:

=over 8

=item CWORD

Control word (eg. C<\rtf1>, C<\trowd>).

=item CSYMB

Control symbol, mentioned in RTF Specification version 1.7.

=item CUNDF

Unknown control symbol (i.e. not mentioned in RTF Specification).

=item PTEXT

Plain text.

=item ENTER

Start of group (C<{>).

=item LEAVE

End of group (C<}>).

=item DESTN

End of destination group (C<}> that turns off destination mode).

=item ENHEX

Data in hexadecimal format that follows C<\'> control symbol.

=item ENBIN

End of binary data block (started by C<\bin> control word).

=item WRHEX

Symbol which is not a hexadecimal digit found where ENHEX token expected.

=item OKEOF

Normal end of input stream.

=item UNEOF

Unexpected end of input stream.

=item UNBRC

End of group that does not match any start of group.

=back

These constants are not exported by default. Any of them may be exported by request.
All of them may be exported by the use of C<:all> export tag.

=item unget_token($token)

Pushes back token C<$token> so the next call to C<get_token> will return it.

=item set_destination

Turns on the destination mode, i.e. all tokens will be ignored until the end of
current group.

=back

=head1 SEE ALSO

RTF::Tokenizer, Rich Text Format (RTF) Specification.

=head1 BUGS

It is impossible to have more then one RTF::Lexer objects in a single process.

=head1 AUTHOR

Vadim O. Ustiansky <ustiansky@cpan.org>

EOT
