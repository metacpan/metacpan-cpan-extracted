use 5.006;

package MoneyWorks;

our $VERSION = '0.11'; # Update MoneyWorks.pod, too.

use #
strict; use #
warnings; no #
warnings qw 'utf8 parenthesis regexp once qw';
use warnings'register;

use Carp 'croak';
use Exporter 5.57 'import';
use IPC::Open3;
use Scalar::Util 'blessed';
use Symbol 'geniosym';

our @EXPORT = qw( mw_cli_quote mw_str_quote);
our %EXPORT_TAGS = ( all => \@EXPORT );
BEGIN {
 *IMPORT = \&import;
 undef *import;
}

our @BinPaths = (
 '/Applications/MoneyWorks Gold.app/Contents/MacOS/MoneyWorks Gold',
 '/usr/bin/moneyworks',
 'C:/Program Files/MoneyWorks Gold/MoneyWorks Gold.exe',
);

#our %Fields; # defined further down, to keep it out of the whey

no constant 1.03 ();
use constant::lexical {
 # publicly accessible fields
  _rego => 0,
  _user => 1,
  _pswd => 2,
  _file => 3,
  _bina => 4,
  _live => 5,

 # behind the scenes
  _hndl => 6,
  _prid => 7,
};

sub new {
 my ($class,%args) = @_;
 my $self = [];
 $self->[_rego] = delete $args{rego};
 $self->[_user] = delete $args{user};
 $self->[_pswd] = delete $args{password};
 $self->[_file] = delete $args{file};

 unless( $self->[_bina] = delete $args{bin} ) {
  # find the executable if we can
  for(@BinPaths) {
   -e and $self->[_bina] = $_, last;
  }
 }
 
 $self->[_live] = exists $args{keep_alive} ? delete $args{keep_alive} : 1;
 bless $self, $class;;
}

sub rego      { unshift @_, _rego; goto &_accessor }
sub user      { unshift @_, _user; goto &_accessor }
sub password  { unshift @_, _pswd; goto &_accessor }
sub file      { unshift @_, _file; goto &_accessor }
sub bin       { unshift @_, _bina; goto &_accessor }
sub keep_alive{ unshift @_, _live; goto &_accessor }
sub _accessor {
 @_ > 2 ? ( $_[1][$_[0]] = $_[2], $_[1]->close, $_[2] ) : $_[1][$_[0]]
}

sub command {
 my $self = shift;
 my $command = shift;

 croak "Commands cannot contain line breaks" if $command =~ /[\r\n]/;
 warnings'warnif(__PACKAGE__,"Command contains null chars")
  if $command =~ y/\0//d;

 # Used by the SIGPIPE handle
 my $tries;
 MoneyWorks_COMMAND:

 my($rh,$wh,$maybe_open_file);
 my $tmp; # For single-process mode: the stderr handle (which is not even
          # used) needs to last till the end of the sub to avoid giving the
          # child proc a SIGPIPE

 my $live = $self->[_live];
 if($live) { # keep-alive
  # fetch the handles, creating them if necessary
  ($rh, $wh) = @{ $self->[_hndl] ||= do{
   # start the process
   my $pid = _open($self, my($wh,$rh), my $eh = geniosym);
   $self->[_prid] = $pid;
   ++$maybe_open_file;

   # return the handles
   [$rh,$wh,$eh] # $eh is not used but we hang on to it to avoid SIGPIPING
  } };           # the child process.
 }
 else { # single command (the easy way)
  _open( $self, $wh, $rh, $tmp = geniosym );
  ++$maybe_open_file;
 }

 local $\ = "\n";
 select +( select($wh), $|=1 )[0];

 # open a file if necessary
 if($maybe_open_file and defined $self->[_file]) {
   # avoid problems with files named -e
   (my $file = $self->[_file]) =~ s|^-|./-|;
   
   # prepare the open file command
   my $command = "open file=".mw_cli_quote($file);
   my($u,$p) = @$self[_user,_pswd];
   no warnings 'uninitialized';
   defined $u && length $u and
    $command .= " login=".mw_cli_quote("$u:$p");

   my $retry;
   local $SIG{PIPE} = sub {
    $tries++ < 3 and $self->close, $retry = 1;
   };
   # send the command
   print $wh $command;

   # See whether there was a SIGPIPE
   goto MoneyWorks_COMMAND if $retry;

   # check result
   my $headers = _read_headers($rh);
   $$headers{Status} eq 'OK'||_croak($self,$headers);
 }

 # send the command
 print $wh $command;

 # parse output headers
 my $headers = _read_headers($rh);

 # check status
 $$headers{Status} eq 'OK' or _croak($self,$headers);

 # return data
 if(exists $$headers{'Content-Length'}) { # omitted when the empty string
   my $data;                               # is returned
   read $rh, $data, $$headers{'Content-Length'};

   $data;
 }
 else { '' }
}

my @bad_env_vars = qw(PATH IFS CDPATH ENV BASH_ENV);

sub _open {
 my $self = shift;

 # insanity check
 defined $self->[_bina]
    or croak "MoneyWorks could not be run: no path specified";

 # remove unsafe env vars temporarily
 local(@ENV{@bad_env_vars}), delete @ENV{@bad_env_vars} if ${^TAINT};

 my $rego = $self->[_rego];
 open3(@_, $self->[_bina], '-h', $rego ? ('-r', $rego) : ())
    or croak "MoneyWorks ($self->[_bina]) could not be run: $!";
}

# From: Rowan Daniell <rowan [at a server named] cognito.co.nz>
# Subject: Re: Concerning HTTP-style output
# Date: Mon, 4 May 2009 09:02:46 +1200
#
# > The ‘-h’ mode output does not look exactly like HTTP to me :-). It
# > seems a lot simpler (which is good). Can I confirm with you that
# > the format is as follows? (I’m trying to make sure that my programs
# > don’t break in the future because I didn’t take all possibilities.
# > of the syntax into account.) Each header is a word followed by a
# > colon and a space (chr 32), and then the header’s value verbatim
# > (no escapes, quotes or line breaks as per HTTP) followed by a line
# > feed (chr 10). A blank line ("\n\n") indicates the end of the
# > header. Is this correct? And is the line break character the same
# > on both platforms?
# 
# Yes. That is all correct.

# Except that after that exchange I found that \r\n is the line break char.

sub _read_headers {
 my $handle = shift;
 local $/ = "\r\n";

 my %headers;
 my $past_first;
 while(my $line = <$handle>) {
  $line =~ s/\r\n\z//
   or croak "Mangled output from MoneyWorks (no CRLF): $line";
  # When run under root, MoneyWorks sometimes puts
  # "Address already in use\n" (without the \r) at the beginning of
  # its output.
  $past_first++ or $line =~ s/^Address already in use\n//;
  length $line or last;
  $line =~ s/^([^:]+): // or croak "Mangled output from MoneyWorks: $line";
  $headers{$1} = $line;
 }
 return \%headers;
}

sub _croak { # Extracts error message from headers hash
 my $self  = shift;
 my $h = shift;
 my $msg;
 if(exists $$h{Diagnostic}) {
  ($msg = $$h{Diagnostic}) =~ s/^\[ERROR] //;
  $msg .= ": " if exists $$h{Error};
 }
 $msg .= $$h{Error} if exists $$h{Error};
 $self->close;
 croak("Moneyworks error: $msg");
}

sub version {
 shift->command('version');
}

sub eval {
 my($self,$expr) = @_;
 $expr =~ y/\r\n/  /;
 shift->command('evaluate expr=' . mw_cli_quote($expr));
}

sub import {
 my($self,%args) = @_;
 defined blessed $self and $self->isa(__PACKAGE__) or goto &IMPORT;

 my $data_arg;
 my $map_arg;

 if(exists $args{map}) {
  ($map_arg = delete $args{map}) =~ /[\r\n]/
   and croak "Import map file names cannot contain line breaks";
            # This is a MoneyWorks limitation. The syntax doesn’t allow it.
  $map_arg = mw_cli_quote($map_arg);
  if(exists $args{data_file}) {
   $data_arg = 'file=' . mw_cli_quote(delete $args{data_file});
  }
  else {
   my $data = delete $args{data};
   $data =~ s/(?:\r\n?|\n)\z//;
   if($data =~ /[\n\r]/) {
    # write the data to a temporary file and use that
    require File::Temp;
    my($fh,$filename)
     = File'Temp'tempfile(uc suffix => '.txt', uc unlink => 1);
    local $\;
    print $fh $data;
    close $fh or croak "Couldn't close temp file for import: $!";
    $data_arg = 'file=' . mw_cli_quote($filename);
   }
   else { $data_arg = 'data=' . mw_cli_quote($data) }
  }
 }
 else {
  croak "The map arg to import is not optional";

=cut

This may be added later. There are currently serious problems with it.

  # fetch the fields for the table
  my $table = lc delete $args{table};
  exists $Fields{$table} or croak "Unrecognised table: $table";
  my $fields = $Fields{$table};

  # create a temporary file
  require File::Temp;
  my($fh,$filename)
   = File'Temp'tempfile(uc suffix => '.txt', uc unlink => 1);

  # for each record
  for( map +{%$_}, @{ delete $args{data} } ) { # copy each hash to avoid
   my $line = '';                    # modifying what belongs to the caller

   # add fields to $line
   for my $f(@$fields) {
    no warnings 'uninitialized';
    (my $val = delete $_->{$f}) =~ /[\t\r\n]/
     and croak "Field values cannot contain tabs or line breaks";
    $line .= "$val\t";
   }

   # croak if fields are left over
   local $" = ' ';
   %$_ and croak "Invalid fields: @{ keys %$_ }";

   # remove trailing tab
   chop $line;

   # print to temp file
   local $\ = "\n";
   print $fh $line;
  }

  close $fh or croak "Couldn't close temp file for import: $!";

  $data_arg = 'file=' . mw_cli_quote($filename);

  # find the map
  my $f;
  # I pilfered this code from  Unicode::Collate  (and
  # modified it slightly).
  for (@INC) { 
    $f = "$_/MoneyWorks/maps/$table.impo";
    last if open $fh, $f;
    $f = undef;
  }
  defined $f or
    croak "MoneyWorks: Can't locate MoneyWorks/maps/$table.impo" .
        " in \@INC (\@INC contains @INC).\n";
  $map_arg = mw_cli_quote($f);

=cut

 }

 my $ret = $self->command("import $data_arg map=$map_arg");
 return unless defined wantarray;

 my %ret;
 for(split /;\s*/, $ret) {
  @_ = split /:\s*/;
  $ret{$_[0]} = $_[1];
 }
 \%ret;
}

my %all_fields;

sub export {
 my($self,%args) = @_;

 # determine what the rettype will be
 my $using_hash = exists $args{key};
 my $key = delete $args{key};

 # get the list of fields
 my $table = delete $args{table};
 my $qtable = mw_cli_quote($table);
 my $fields = delete $args{fields};
 defined $fields or $fields = $all_fields{lc $table} ||= [
  split "\t", (
   $self->command(
    "export table=$qtable search='='"
   ) =~ /([^\r\n]+)/
  )[0]
 ];

 # determine whether the key needs to be added to the list of fields
 my $key_is_in_fields;
 if($using_hash) {
  for(@$fields) {
   $_ eq $key and ++$key_is_in_fields, last;
  }
  $key_is_in_fields or push @$fields, $key;
 }

 # prepare the command
 my $command =
  'export'
  .' table=' . mw_cli_quote($table)
  .' format=' . mw_cli_quote(
                 join('\t', map "[$_]", @$fields).'\n'
                );
 exists $args{search} and $command .=
   ' search=' . mw_cli_quote(delete $args{search});

 # send the command
 my $output = $self->command($command);

 # parse the output
 my $ret = $using_hash
           ? {}
           : [];
 for my $line(split /\n/, $output) {
  my %record;
  @record{ @$fields } = split /\t/, $line;
  $using_hash
   ? $$ret{$record{$key}} = \%record
   : push @$ret, \%record;
  delete $record{$key} if $using_hash && ! $key_is_in_fields;
 }

 # return
 $ret;
}

# ~~~ report

sub pid { shift->[_prid] }

sub close {
 my $self = shift;
 my $pid = delete $$self[_prid];
 return unless my $handles = delete $$self[_hndl];
 close $handles->[1]
  or $! and croak "Error while terminating MoneyWorks: $!";
 waitpid $pid, 0;
 ()
}

# ---------------- Ties ----------------- #

sub tie {
 tie my %h, 'MoneyWorks::_table_tie', @_;
 \%h;
}

sub TIEHASH {
 my($package,%args) = @_;
 my $table = delete $args{table};
 my $key = delete $args{key};
 my $self = $package->new(%args);
 MoneyWorks::_table_tie->new($self, $table, $key);
}

{
 use constant::lexical {
  parent => 0, cached => 1, table => 2, key => 3, row => 4
 };

 sub MoneyWorks::_table_tie::new {
  my($class,$parent,$table,$key) = @_;
  return bless [$parent,undef,$table,$key], $class;
 }
 *MoneyWorks::_table_tie::TIEHASH = *MoneyWorks::_table_tie::new;
 sub MoneyWorks::_table_tie::FETCH {
  my($self,$row) = @_;
  return unless $self->EXISTS($row);
  CORE::tie
    my %row, 'MoneyWorks::_row_tie', @$self[parent,table,key], $row;
  \%row;
 }
 sub MoneyWorks::_table_tie::EXISTS {
  my($self,$row) = @_;
  $self->[parent]->command(
   (
    $self->[cached] ||= 
     'export'
      .' table=' . MoneyWorks::mw_cli_quote($self->[table])
      .' format="1"'
      .' search='
   ) . MoneyWorks::mw_cli_quote(
         "Replace($self->[key],`\@`,`\1`)=Replace("
           . MoneyWorks'mw_str_quote($row)
         .",`\@`,`\1`)"
       )
  );
 }

 sub MoneyWorks::_row_tie::TIEHASH {
  my($class,$parent,$table,$key,$row) = @_;
  return bless [$parent,undef,$table,$key,$row], $class;
 }
 sub MoneyWorks::_row_tie::FETCH {
  my($self,$field) = @_;
  $self->[parent]->eval(
    'Find('
     . mw_str_quote("$self->[table].$field") . ','
     . ( 
        $self->[cached]
          ||= do {
           (my $row = $$self[row]) =~ y/\@/\1/;
           mw_str_quote(
            "Replace($self->[key],`\@`,`\1`)=" . mw_str_quote($row)
           )
          }
       )
   .')'
  );
 }
}

# ------------------ Functions ---------------- #


sub mw_cli_quote($) {
 my $str = shift;
 warnings'warnif
   __PACKAGE__,"Argument to mw_cli_quote contains line breaks"
  if $str =~ /[\r\n]/;
 my $delim = chr 0x7f;
 while(index $str, $delim, != -1) {
  --vec $delim, 0, 8, == 31
   and croak "Can't quote $str; no delimiters available"
 }
 "$delim$str$delim";
}

{
 my %escapes = (
  '"' => '\"',
  '	' => '\t',
  "\n" => '\n',
  "\r" => '\r',
  '\\' => '\\\\',
 );
 sub mw_str_quote($) {
  my $str = shift;
  if($str =~ /`/) {
   $str =~ s/(["\t\n\r\\])/$escapes{$1}/g;
   return qq/"$str"/;
  }
  else {
   $str =~ s/([\t\n\r\\])/$escapes{$1}/g;
   return "`$str`";
  }
 }
}

# ------------ Misc stuff -------------- #

sub DESTROY {
 shift->close;
}

=cut

BEGIN {
 %Fields = (
  product => [qw/ Code Supplier SuppliersCode Description Comment Category1 Category2 Category3 Category4 SalesAcct StockAcct COGAcct SellUnit SellPrice SellPriceB SellPriceC SellPriceD SellPriceE SellPriceF QtyBrkSellPriceA1 QtyBrkSellPriceA2 QtyBrkSellPriceA3 QtyBrkSellPriceA4 QtyBrkSellPriceB1 QtyBrkSellPriceB2 QtyBrkSellPriceB3 QtyBrkSellPriceB4 QtyBreak1 QtyBreak2 QtyBreak3 QtyBreak4 BuyUnit BuyPrice ConversionFactor SellDiscount SellDiscountMode ReorderLevel Type Colour UserNum UserText Plussage BuyWeight StockTakeQty StockTakeValue StockTakeNewQty BarCode BuyPriceCurrency Custom1 Custom2 Custom3 Custom4 LeadTimeDays SellWeight Flags MinBuildQty NormalBuildQty /],
 );
 name => [qw/ Code Name Contact Position Address1 Address2 Address3 Address4 Delivery1 Delivery2 Delivery3 Delivery4 Phone Fax Category1 Category2 Category3 Category4 CustomerType SupplierType DebtorTerms CreditorTerms Bank AccountName BankBranch TheirRef CreditLimit Discount Comment RecAccount PayAccount Colour Salesperson TaxCode PostCode State BankAccountNumber PaymentMethod DDI eMail Mobile AfterHours Contact2 Position2 DDI2 eMail2 Mobile2 AfterHours2 WebURL ProductPricing SplitAcct1 SplitAcct2 SplitPercent Hold UserNum UserText CustPromptPaymentTerms CustPromptPaymentDiscount SuppPromptPaymentTerms SuppPromptPaymentDiscount
Currency CreditCardNum CreditCardExpiry CreditCardName TaxNumber Custom1 Custom2 Custom3 Custom4 DeliveryPostcode DeliveryState AddressCountry DeliveryCountry ReceiptMethod /],
}

=cut

!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!*!!*!
