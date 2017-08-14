package PerlX::Generator::Compiler;

use strictures 2;
use re 'eval';
use Filter::Util::Call;
use Module::Compile -base;
use PPR::X;

our $Found_Start;

our @Found;

sub top_keyword { 'generator' }

sub yield_keyword { 'yield' }

sub pmc_compile {
  my ($class, $code) = @_;
  my ($top, $yield) = ($class->top_keyword, $class->yield_keyword);
  my $grammar = qr{
    (?(DEFINE)
      (?<PerlCall>
        (?:
          ${top}
          (?&PerlOWS)
          (?{ local $Found_Start = pos() })
          (?&PerlBlock)
          (?{ push @Found, [ $Found_Start, pos() - $Found_Start ] })
        )
        | (?&PerlStdCall)
      )
    )
    $PPR::X::GRAMMAR
  }x;
  local @Found;
  unless ($code =~ /\A (?&PerlDocument) \Z $grammar/x) {
    warn "Failed to parse file; expect complication errors, sorry.\n";
    return undef;
  }
  my $offset = 0;
  my $sym_gen = 'A001';
  foreach my $case (@Found) {
    my ($start, $len) = @$case;
    $start += $offset;
    my $block = substr($code, $start, $len);
    my $new_block = $block;
    $new_block =~ s/^{/{ __gen_resume; / or die "Whither block start?";
    $new_block =~ s{(${yield}(?&PerlOWS)((?&PerlCommaList)?+)) $grammar}{
      my $gen = '__GEN_'.$sym_gen++;
      "do { __gen_suspend '${gen}', $2; ${gen}: __gen_sent }";
    }xeg;
    # I deleted the refaliasing support part temporarily because argh
    # I also deleted support for 'our $foo' and 'state $foo' because wtf
    $new_block =~ s!
     for(?:each)?+ \b
     (?>(?&PerlOWS))
     (?:
         (?:
             my
             (?>(?&PerlOWS)) ((?&PerlVariableScalar))
         )?+
         (?>(?&PerlOWS))
         (?> ((?&PerlParenthesesList)) )
         (?>(?&PerlOWS))
         {
      )
      $grammar
    !
      my ($name, $over) = ($1, $2);
      my $gen_ary_a = '@__gen_'.$sym_gen++;
      (my $gen_ary_s = $gen_ary_a) =~ s/^\@/\$/;
      my $gen_idx = '$__gen_'.$sym_gen++;
      "my ${gen_ary_a} = ${over}; for (my ${gen_idx} = 0; ${gen_idx} < ${gen_ary_a}; ${gen_idx}++) { my ${name} = ${gen_ary_s}[${gen_idx}];";
    !xeg;
#warn "New: ${new_block}"; die;
    substr($code, $start, $len) = $new_block;
    $offset += length($new_block) - $len;
  }
  return $code;
}

1;
