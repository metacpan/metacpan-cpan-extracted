package OurNet::BBSApp::Templator;

use bytes; # need byte semantic to fix unicode in formfile()
use base qw/OurNet::BBSApp::Board/;
use fields qw/source params template output filter tmpl_obj flags preview _cache/;
use strict;
use OurNet::Template;
use HTML::FromText;

sub forcearray {
    $_[0] = [ $_[0] ] unless ref($_[0]) eq 'ARRAY';
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{board} ||= $self->{BBS}{boards}{$self->{name}}{$self->{source}};

    $self->{'tmpl_obj'} = Template->new(
        INCLUDE_PATH => $self->{template}{path},
        OUTPUT_PATH  => $self->{output}{path},
        INTERPOLATE  => 1,
        POST_CHOMP   => 1,
    );

    forcearray($self->{output}{file});
    forcearray($self->{template}{file});

    return $self;
}

sub formfile {
    my ($self, $article, $file, $params) = @_;

    return unless $file;

    $file =~ s{\[\%\s*(\w+)(:[^\s]+)?\s*\%\]}{sprintf(substr($2, 1) || '%s',
        defined $params->{$1} ? $params->{$1} :
	UNIVERSAL::can($article, $1) ? $article->$1 :
        exists $article->{$1} ? $article->{$1} : '')}eg;
    # $file =~ s|[\/\\]|-|g;
    return $file;
}

sub post_process {
    my $self = shift;
    no strict 'refs';

    return unless $self->{template}{list};
    local $_;
    my @articles;
    my $recno;
    foreach my $recno ($self->{output}{reversed} ? reverse (1..$#{$self->{board}}) : (1..$#{$self->{board}})){
        print ".";
        my $preview = '';

        if ($self->{output}{preview} and (
            ($self->{output}{reversed} ? $#{$self->{board}} - $recno + 1 : $recno)
            < $self->{output}{preview})
        ) { eval {
            $preview = $self->{board}[$recno]->{body};
            $preview =~ s/^作者: .+ \(.+\).*\n標題: .*\n時間: .+\n+//;
            $preview =~ s/\n: .+//g;
            $preview =~ s/^※ 引述.+\n+//g;
            $preview =~ s/\n\n+/\n/g;
            $preview =~ s/^\n//g;
            $preview = $self->txt2html(($preview =~ m/^(.+\n.+\n.+)\n[\x00-\xff]/) ? $1 : $preview);
        }}
        next if $@;

        push @articles, {
            url => $self->formfile($self->{_cache}[$recno-1],
                (
                    (index(ref($self->{board}[$recno]), 'ArticleGroup') > -1)
                    ? $self->{output}{list}
                    : $self->{output}{file}[0]
                )),
            board => substr($self->{name}, 0),
            # header => $self->{board}[$recno]->{header},
            recno => $recno,
            preview => $preview,
            %{$self->{_cache}[$recno-1]},
        } if $self->{_cache}[$recno-1];
    }

    my @params;

    foreach my $field (@{${ref($self->{BBS}{boards}{$self->{name}})."::"}{packlist}}) {
        push @params, ($field, $self->{BBS}{boards}{$self->{name}}->$field)
            if $self->{BBS}{boards}{$self->{name}}->can($field);
    }

    $self->{output}{pagemax} ||= scalar @articles || 1;
    my @pages;
    foreach my $page (1..(int($#articles / $self->{output}{pagemax})+1)) {
        push @pages, {
            number => $page,
            url    => $self->formfile(
                $self->{board}, $self->{output}{list}, { page => $page }
            ),
        }
    }

    foreach my $page (@pages) {
        my $lastidx = ($page->{number} * $self->{output}{pagemax}) - 1;
        print join(',',(($page->{number} - 1) * $self->{output}{pagemax}) , $lastidx),"\n";
        $lastidx = $#articles if $lastidx > $#articles;
        $self->{'tmpl_obj'}->process($self->{template}{list}, {
            # title => $self->{board}->{title},
            board => substr($self->{name}, 0), # weird hack
            articles => [@articles[(($page->{number} - 1) * $self->{output}{pagemax})
                                   .. $lastidx]],
            @params,
            pages   => \@pages,
            curpage => $page->{number},
            output  => $self->{output},
        }, $page->{url});
    }
    # chdir '/srv/www/elixir/BBS';
    # system('fzindex', 'elixir.idx', '*-a*.html');
    # chdir '/home/staff/autrijus/depot/www.elixus.org/BBS';
}

sub article {
    my ($self, $article) = @_;
    no strict 'refs';
    print "-";
    return if ref($self->{filter}) and !$self->{filter}->($article);

    my $recno = $article->recno;

    foreach my $field (@{${ref($article)."::"}{packlist}}, 'header') {
        $self->{_cache}[$recno]{$field} = $article->{$field};
    }

    $self->{_cache}[$recno]{dir} = $article->dir;
    $self->{_cache}[$recno]{recno} = $recno;
    $self->{_cache}[$recno]{author} =~ s|\@.+|\.|; # crude hack

    my $cache = $self->{_cache}[$recno];

    # %{$self->{_cache}[$article->recno]};

    my $body = $article->{body};
    $body =~ s/^作者: (.+ \(.+\)).*\n標題: .*\n時間: .+\n+//;
    my $from = $1 || $article->{author};

    # XXX should be optional here
    my $replybody = $body;
    $replybody =~ s/\n+/\n: /g;
    $replybody =~ s/\n: : : .*//g;
    $replybody =~ s/\n: : ※ .*//g;

    foreach my $count (0..$#{$self->{template}{file}}) {
        my $url  = $self->formfile($cache, $self->{output}{file}[$count]);
        my $next = $url;
	my $prev = $url;
	$next =~ s/$recno/$recno+1/eg;
	$prev =~ s/$recno/$recno-1/eg;

        $self->{'tmpl_obj'}->process($self->{template}{file}[$count], {
            url   => $url,
	    nexturl => $next,
	    prevurl => $prev,
            board => substr($self->{name}, 0),
            recno => $cache->{recno},
            header => $cache->{header},
            body  => $url =~ m/html?$/ ? $self->txt2html($body) : $body,
            replybody => "※ 引述《$from》之銘言：\n: $replybody",
            %{$cache},
        }, $url);
    }
}

sub txt2html {
    my $self = shift;
    my $body = text2html(
        $_[0],
        metachars => 1,  urls      => 1,
        email     => 1,  underline => 1,
        lines     => 1,  spaces    => 1,
        %{$self->{flags}},
    );
    # strip ANSI codes
    $body =~ s/\x1b\[.*?[mJH]//g;
    # XXX interpolation of some kind.

    return $body;
}

1;
