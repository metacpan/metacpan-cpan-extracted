{
  pxf => {
    template => {
      INCLUDE_PATH => './tmpl/',       # or list ref
      INTERPOLATE  => 1,               # expand "$var" in plain text
      POST_CHOMP   => 1,               # cleanup whitespace
      EVAL_PERL    => 1,               # evaluate Perl code blocks
    }
  }
}
