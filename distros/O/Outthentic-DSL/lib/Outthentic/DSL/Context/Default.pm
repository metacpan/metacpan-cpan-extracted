package Outthentic::DSL::Context::Default;


sub new { bless {}, __PACKAGE__ }

sub change_context { 

    my $self        = shift;
    my $cur_ctx     = shift; # current search context
    my $orig_ctx    = shift; # original search context
    my $succ        = shift; # latest succeeded items

    return $cur_ctx;
}

sub update_stream  {}

1;

