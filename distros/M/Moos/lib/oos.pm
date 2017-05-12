package oos;

sub import {
    moos() if $0 eq '-';
    require Moos;
    splice @_, 0, 1, 'Moos';
    goto &Moos::import;
}

sub moos {
  print <<'EOEOMOO';
                              ______   ______
                             < Moo! > < !ooM >
                              ------   ------
                     ^__^   /                 \   ^__^
             _______/(öö)  /                   \  (oo)\_______
         /\/( ingy  /(__)                         (__)\  tsm  )\/\
            | w----||                              /  ||----w |
            ||     ||                                 ||     ||
EOEOMOO
  exit 0;
}

1;
