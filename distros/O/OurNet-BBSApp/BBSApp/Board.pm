package OurNet::BBSApp::Board;

use strict;
use fields qw/BBS board name article_cnt mtime prefix/;
use OurNet::BBS;

sub new {
    my $class = shift;
    my $self = fields::new($class);
    $self->{BBS} = shift;
    my %var = %{scalar shift};
    while(my ($k, $v) = each %var) {
        $self->{$k} = $v if exists $self->[0]{$k};
    }
    $self->{article_cnt} = 1;
    $self->{mtime} = 0;
    return $self;
}

sub refresh {
    my $self = shift;
    $self->{board}->refresh;
    return ($self->{mtime} != $self->{board}->mtime);
}

sub post_process {}

sub process {
    my $self = shift;
    my $board = $self->{board};
    my $boardmtime = $board->mtime;
    my $article_cnt = $#{$board}+1;

    print ref($self).": processing: $self->{name}\n" if $OurNet::BBSApp::DEBUG;

    foreach my $item (@{$board}[$self->{article_cnt}..$#{$board}]) {
        next unless eval { $item->btime > $self->{mtime} };
        next if $@;

        if (index(ref($item), 'ArticleGroup') > -1) {
            # recursive call
            # print $#{$item}, ": ", $item->dir, ": ",$item->mtime," - \n";
            if (defined &OurNet::BBSApp::Monitor::add) {
                OurNet::BBSApp::Monitor::add($self->new(
                    $self->{BBS}, {
                        %{$self},
                        board       => $item,
                        article_cnt => 1,
                        mtime       => 0
                    }
                ));
            }
        }
        else {
            $self->article($item);
        }
    }

    $self->{article_cnt} = $article_cnt;
    $self->{mtime} = $boardmtime;
    $self->post_process;
}

1;
