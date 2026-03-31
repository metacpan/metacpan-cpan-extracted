BEGIN {
    local @INC = grep $_ ne './inc', @INC;
    delete $INC{'PDL/Graphics/PGPLOT/Window.pm'};
    my $PDL_GRAPHICS_PGPLOT_WINDOW = eval 'use PDL::Graphics::PGPLOT::Window; 1';
    eval { use PDL::Graphics::PGPLOT::Window; }
      if $PDL_GRAPHICS_PGPLOT_WINDOW;
}

1;

