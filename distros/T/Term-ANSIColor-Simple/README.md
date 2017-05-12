Term::ANSIColor::Simple
=======

Make colored output easily.


Synopsis
-------

![relax](http://cdn-ak.f.st-hatena.com/images/fotolife/z/zentoo/20101105/20101105135811.jpg)


Install
-------

cpanm Term::ANSIColor::Simple

or

git clone git://github.com/zentooo/p5-term-ansicolor-simple.git
cd p5-term-ansicolor-simple
perl Makfile.PL && make && make install


Usage
-------

    use Term::ANSIColor::Relax;
    use feature qw/say/;
    
    say color("I")->green;
    say color("love")->magenta->bold->underscore;
    say color("you")->white->on_blue;
    
    my $timtoady = <<'TIMTOADY';
    #####  ###  #    #  #####   ###     #    ####   #   #  
      #     #   ##  ##    #    #   #   # #   #   #  #   #  
      #     #   # ## #    #    #   #  #   #  #   #   # #   
      #     #   #    #    #    #   #  #####  #   #    #    
      #     #   #    #    #    #   #  #   #  #   #    #    
      #    ###  #    #    #     ###   #   #  ####     #    
    TIMTOADY
    
    say color($timtoady)->rainbow;
