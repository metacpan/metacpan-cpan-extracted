sub pp_defc {
  my ($function, %hash) = @_;
  $hash{GenericTypes} ||= [qw(F D)];
  $hash{Doc} ||= "\n=for ref\n\nComplex version of L<PDL::LinearAlgebra::Real/$function>\n\n";
  my $decl = delete($hash{_decl}) || '';
  $decl =~ s/\$GENERIC\(\)\s*\*/void */g; # dodge float vs float complex ptr problem
  $hash{Code} = "$decl\n$hash{Code}";
  $hash{Pars} = join ';', map s/\(2(?:,|(?=\)))/(/ ? "complex $_" : $_, split /;/, $hash{Pars};
  if ($hash{RedoDimsCode}) {
    # decrement numbers being compared to, or dims offsets
    $hash{RedoDimsCode} =~ s/(>\s*)(\d+)|(\[\s*)(\d+)(\s*\])/
      $1
        ? $1.($2 - 1)
        : $3.($4 - 1).$5
    /ge;
  }
  pp_def("c$function", %hash);
}
