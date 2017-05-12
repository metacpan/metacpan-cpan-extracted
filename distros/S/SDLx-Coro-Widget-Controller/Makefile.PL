use 5.006000;
use ExtUtils::MakeMaker;

# Bump 'EV' up to the top of the requires list. We do this because Coro
# won't build Coro::EV unless EV is already installed.
sub MY::metafile {
  package MY;
  my $self = shift;
  my $out = $self->SUPER::metafile_target(@_);
  $out =~ s/
   ( [^\n]*requires:[^\n]* )
   (.*)
   ( \n[^\n]* EV [^\n]* )
  /$1$3$2/xs;
  $out =~ s/(generated_by:.*?)'/$1 and then some'/;
  return $out;
}


WriteMakefile(
    NAME              => 'SDLx::Coro::Widget::Controller',
    VERSION_FROM      => 'lib/SDLx/Coro/Widget/Controller.pm',
    ABSTRACT_FROM     => 'lib/SDLx/Coro/Widget/Controller.pm',
    AUTHOR            => 'Brock Wilcox <awwaiid@thelackthereof.org>',
    LICENSE           => 'perl',
    PREREQ_PM         => {
      EV              => 0,
      Coro            => 4.37,
      Coro::EV        => 0,
      SDLx::Widget::Controller => 0,
    },
);

