sub switchtest {
  my $opts = shift;
  my $didpass = 0;
  switch $opts->{topic}, sub {
    case $opts->{failc}, sub { };
    pass sprintf '%s<=>%s: incorrect case skipped', @$opts{qw/ t_type m_type /}; 
    case $opts->{passc}, sub {
      $didpass =
        pass sprintf '%s<=>%s: matched correct case',
                     @$opts{qw/ t_type m_type /};
    };
  };

  fail sprintf '%s<=>%s: correct case not matched',@$opts{qw/ t_type m_type /}
    unless $didpass;
}

{
  package Switch::Perlish::_test;
  sub JUSTDONT { 1 }
  sub amethod  { 'specifically for smatch-object.t' }
}
our($nay,$yay) = ( bless([], 'main'), bless([], 'Switch::Perlish::_test') );

1;
