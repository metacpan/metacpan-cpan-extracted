sub pp_defc {
  my ($function, %hash) = @_;
  $hash{GenericTypes} ||= [qw(F D)];
  my $doc = $hash{Doc} || "\n=for ref\n\nComplex version of L<PDL::LinearAlgebra::Real/$function>\n\n";
  $hash{Doc} = undef;
  my $decl = delete $hash{_decl};
  $decl =~ s/\$GENERIC\(\)\s*\*/void */g; # dodge float vs float complex ptr problem
  $hash{Code} = "$decl\n$hash{Code}";
  pp_def("__Cc$function", %hash);
  my %hash2 = %hash;
  $hash2{Pars} = join ';', map s/\(2(?:,|(?=\)))/(/ ? "complex $_" : $_, split /;/, $hash2{Pars};
  if ($hash2{RedoDimsCode}) {
    # decrement numbers being compared to, or dims offsets
    $hash2{RedoDimsCode} =~ s/(>\s*)(\d+)|(\[\s*)(\d+)(\s*\])/
      $1
        ? $1.($2 - 1)
        : $3.($4 - 1).$5
    /ge;
  }
  pp_def("__Nc$function", %hash2);
  pp_add_exported("c$function");
  my $sig = join ';', grep defined, @hash2{qw(Pars OtherPars)};
  pp_addpm(<<EOF);
=head2 c$function

=for sig

  Signature: ($sig)

$doc

=cut

sub PDL::c$function {
  barf "Cannot mix PDL::Complex and native-complex" if
    (grep ref(\$_) eq 'PDL::Complex', \@_) and
    (grep UNIVERSAL::isa(\$_, 'PDL') && !\$_->type->real, \@_);
  goto &PDL::__Cc$function if grep ref(\$_) eq 'PDL::Complex', \@_;
  goto &PDL::__Nc$function;
}
*c$function = \\&PDL::c$function;

EOF
}
