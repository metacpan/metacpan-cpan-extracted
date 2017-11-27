use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # INGY/YAML-Full-0.0.1/lib/YAML/Full/Base.pm
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'build::e'}=sub{my($P,$e)=@_;$e->{new}=sub{$c=shift;my$s=&{$M.Object::new}($c,@_);my@B;do{@B=($c.::BUILD,@B)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@B;$s}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=\&{$P.$b}and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};use constant XXX_skip=>1;my$dm='YAML::XS';*{$M.'xxx::e'}=sub{my($P,$e)=@_;$e->{WWW}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::WWW(@_)};$e->{XXX}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::XXX(@_)};$e->{YYY}=sub{require XXX;local$XXX::DumpModule=$dm;XXX::YYY(@_)};$e->{ZZZ}=sub{require XXX;local$XXX::DumpModule=$dm}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};*{$M.'nonlazy::e'}=sub{${shift.':N'}=1};@f=qw[build default builder xxx import nonlazy];use strict;use warnings;
TEST

test(<<'TEST'); # TYEMQ/Acme-ESP-1.002007/ESP.pm
sub O'o { [ shift,oO( @_ ) ]->[!$[] }

package Acme::ESP::Scanner;

use overload(
    '.' => \&scan,
    nomethod => \&explode,
);
TEST

test(<<'TEST'); # YAPPO/Class-Component-0.17/t/MyClass/Plugin/ExtAttribute.pm
sub args_0 :Method Dump {}
sub args_1 :Method Dump('hoge') {}
sub args_1_2 :Method Dump("hoge") {}
sub args_2 :Method Dump('hoge1', 'hoge2') {}
sub args_2_2 :Method Dump('hoge1', "hoge2") {}
sub args_2_3 :Method Dump("hoge1", 'hoge2') {}
sub args_2_4 :Method Dump("hoge1", "hoge2") {}
sub args_2_5 :Method Dump(qw(hoge1 hoge2)) {}
sub args_2_6 :Method Dump(qw/hoge1 hoge2/) {}

sub ref_array_1 :Method Dump([1,2,3,4]) {}
sub ref_array_2 :Method Dump([qw/1 2 3 4/]) {}
sub ref_array_3 :Method Dump([qw(1 2 3 4)]) {}
sub ref_array_4 :Method Dump(["1",'2','3',"4"]) {}
sub ref_array_5 :Method Dump(['1', '2', '3', '4']) {}
sub ref_array_6 :Method Dump(["1", "2", "3", "4"]) {}

sub hash_1 :Method Dump(key=>'value') {}
sub ref_hash_1 :Method Dump({ key => 'value' }) {}
sub ref_hash_2 :Method Dump({ key => { key => 'value' } }) {}

sub ref_hash_array :Method Dump({ key => [qw/ foo bar baz /] }) {}

sub ref_array_hash_1 :Method Dump([ 'foo', { key => 'value' }, 'baz' ]);
sub ref_array_hash_2 :Method Dump('foo', { key => 'value' }, 'baz');

sub ref_code_1 :Method Dump(sub { return 'code' }->()) {}
sub ref_code_2 :Method Dump(sub { _code }->()) {}
sub ref_code_3 :Method Dump(sub { _code2 4, 5 }->()) {}

sub run_code_1 :Method DumpRun(sub { return 'code' }) {}
sub run_code_2 :Method DumpRun(sub { _code }) {}
sub run_code_3 :Method DumpRun(sub { _code2 4, 5 }) {}
TEST

test(<<'TEST'); # ZEFRAM/Debug-Show-0.000/lib/Debug/Show.pm
sub debug_hide { }

cv_set_call_checker(\&debug_hide, sub ($$$) {
    my($entersubop, undef, undef) = @_;
    # B::Generate doesn't offer a way to explicitly free ops.
    # We ought to be able to implicitly free $entersubop via constant
    # folding, by something like
    #
    #     return B::LOGOP->new("and", 0,
    #         B::SVOP->new("const", 0, !1),
    #         $entersubop);
    #
    # but empirically that causes memory corruption and it's not
    # clear why.  For the time being, leak $entersubop.
    return B::SVOP->new("const", 0, !1);
}, \!1);
TEST

test(<<'TEST'); # STEVEB/Devel-Trace-Subs-0.22/lib/Devel/Trace/Subs.pm
    push @{$data->{stack}}, {
        in       => (caller(1))[3] || '-',
        package  => (caller(1))[0] || '-',
        sub      => (caller(2))[3] || '-',
        filename => (caller(1))[1] || '-',
        line     => (caller(1))[2] || '-',
    };
TEST

test(<<'TEST'); # JRED/CIPP-2.50/lib/CIPP.pm
sub Chunk_Out {
#
# INPUT:    1. Referenz auf Chunk
#       2. Befindet Parser sich in einem PRINT Statement
#       3. wie soll der Chunk ausgegeben werden:
#          1    als print Befehl
#          0    unver?ndert
#          -1   mit Escaping von } Zeichen (f?r Variablenzuweisung)
#       4. Start-Zeilennummer des Chunks
#       5. Ende-Zeilennummer des Chunks
#
# OUTPUT:   -
#
    my $self = shift;
    my ($chunk_ref, $in_print_statement, $gen_print,
        $from_line) = @_;
    my $output = $self->{output};

    if ( $$chunk_ref ne '' && $$chunk_ref =~ /[^\r\n\s]/ ) {
        # Chunk ist nicht leer
        my $context = $self->{context_stack}->
                    [@{$self->{context_stack}}-1];

        if ( $context eq 'html' or $context eq 'force_html' ) {
            if ( ($gen_print and $context eq 'html') or
                 $context eq 'force_html' ) {
                # HTML-Context: es wird ein print qq[] Befehl
                # generiert
                # ggf. Debugging-Code erzeugen
                $output->Write (
                    "\n\n\n\n# cippline $from_line ".'"'.
                     $self->{call_path}.'"'."\n" );

                # Chunk muss via print ausgegeben werden
                $output->Write ("print qq[");
                $$chunk_ref =~ s/\[/\\\[/g;
                $$chunk_ref =~ s/\]/\\\]/g;
                $output->Write ($$chunk_ref);
                $output->Write ("];\n");
            }
        } elsif ( $context eq 'perl' ) {
            # <?PERL>Context
            # Chunk wird unveraendert uebernommen
            $output->Write ($$chunk_ref);
        } elsif ( $context eq 'var' ) {
            # <?VAR> Context
            # Chunk wird mit escapten } uebernommen
            $$chunk_ref =~ s/\}/\\\}/g;
            $output->Write ($$chunk_ref);
        } elsif ( $context eq 'comment' ) {
            # Hier machen wir nix.
        } else {
            die "Unknown context '$context'";
        }
    }
}
TEST

test(<<'TEST'); # JWALT/Apache-AxKit-Plugin-Session-1/lib/AxKit/XSP/Auth.pm
sub check_permission : XSP_attribOrChild(target,reason) XSP_childStruct($text(lang))
{
	return 'if (do {'.has_permission(@_).'}) { '.deny_permission(@_).' }';
}
TEST

test(<<'TEST'); # AWWAIID/Continuity-1.6/lib/Continuity.pm
  my $self = bless { 
    docroot => '.',   # default docroot
    mapper => undef,
    adapter => undef,
    debug_level => 1,
    debug_callback => sub { print STDERR "@_\n" },
    reload => 1, # XXX
    callback => (exists &{caller()."::main"} ? \&{caller()."::main"} : undef),
    staticp => sub { $_[0]->url =~ m/\.(jpg|jpeg|gif|png|css|ico|js)$/ },
    no_content_type => 0,
    reap_after => undef,
    allowed_methods => ['GET', 'POST'],
    @_,
  }, $class;
TEST

test(<<'TEST'); # TODDR/Net-Ident-1.24/Ident.pm
    print STDDBG "Net::Ident::newFromInAddr localaddr=", sub { inet_ntoa( $_[1] ) . ":$_[0]" }
      ->( sockaddr_in($localaddr) ), ", remoteaddr=", sub { inet_ntoa( $_[1] ) . ":$_[0]" }
      ->( sockaddr_in($remoteaddr) ), ", timeout=", defined $timeout ? $timeout : "<undef>", "\n"
      if $DEBUG > 1;
TEST

test(<<'TEST'); # MIK/CryptX-0.028/lib/Crypt/PRNG.pm
{
  ### stolen from Bytes::Random::Secure
  #
  # Instantiate our random number generator(s) inside of a lexical closure,
  # limiting the scope of the RNG object so it can't be tampered with.
  my $RNG_object = undef;
  my $fetch_RNG = sub { # Lazily, instantiate the RNG object, but only once.
    $RNG_object = Crypt::PRNG->new unless defined $RNG_object && ref($RNG_object) ne 'SCALAR';
    return $RNG_object;
  };
  sub rand(;$)                { return $fetch_RNG->()->double(@_) }
  sub irand()                 { return $fetch_RNG->()->int32() }
  sub random_bytes($)         { return $fetch_RNG->()->bytes(@_) }
  sub random_bytes_hex($)     { return $fetch_RNG->()->bytes_hex(@_) }
  sub random_bytes_b64($)     { return $fetch_RNG->()->bytes_b64(@_) }
  sub random_bytes_b64u($)    { return $fetch_RNG->()->bytes_b64u(@_) }
  sub random_string_from($;$) { return $fetch_RNG->()->string_from(@_) }
  sub random_string(;$)       { return $fetch_RNG->()->string(@_) }
}
TEST

test(<<'END'); # MIKER/Net-DNS-Dig-0.12/Dig.pm
sub for($$$) {
  ...
}
END

done_testing;
