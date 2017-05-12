package Slash::OurNet;
use 5.006;

our $VERSION = '1.41';

use strict;
use warnings;
no warnings qw(once redefine);

use Date::Parse;
use Date::Format;
use File::Spec;
use File::Basename;
use Lingua::ZH::Wrap;

use constant PATH  => File::Spec->rel2abs(dirname($ENV{SCRIPT_FILENAME} or $0));
use constant SLASH => $ENV{SLASH_USER};

use lib PATH . '/lib';
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon {
    en    => [ Gettext => PATH . '/po/en.po' ],
    zh_tw => [ Gettext => PATH . '/po/zh_tw.po' ],
    zh_cn => [ Gettext => PATH . '/po/zh_cn.po' ],
};

use if  SLASH, 'Slash';
use if  SLASH, 'Slash::DB';
use if  SLASH, 'Slash::Display';
use if  SLASH, 'base' => qw(Slash::DB::Utility Slash::DB::MySQL);
use if !SLASH, 'Slash::OurNet::Standalone';
Slash::OurNet::Standalone->import unless SLASH;

$Lingua::ZH::Wrap::columns = 75;
$OurNet::BBS::Client::NoCache = 1; # avoids bloat

our %Lexicon = ( _AUTO => 1 );
our ($TopClass, $MailBox, $Organization, @Connection, $SecretSigils,
     $BoardPrefixLength, $GroupPrefixLength, $Strip_ANSI, $Use_RealEmail,
     $Thread_Prev, $Date_Prev, $Thread_Next, $Date_Next, $Language, $Colors,
     $DefaultUser, %CachedTop, $LanguageHandle, $SourceEncoding, $Theme,
     $TrappedExcept, $ALLBBS);

sub loc {
    use Encode;
    return decode_utf8(($LanguageHandle ||= __PACKAGE__->get_handle($Language))->maketext(@_));
}

BEGIN { do(PATH . '/ournet.conf'); die $@ if $@ }

use OurNet::BBS $SourceEncoding;

sub new {
    return unless @_; # to satisfy pudge's automation scripts
    my ($class, $name) = splice(@_, 0, 2);

    no warnings 'once';
    my $self = {
	bbs => OurNet::BBS->new(@_),
	virtual_user => $name,
    };

    return bless($self, $class);
}

sub article_save {
    my ($self, $group, $board, $child, $artid, $reply, 
        $title, $body, $state, $name, $nick) = @_;

    $child ||= 'articles';
    my $artgrp = $self->{bbs}{boards}{$board};

    $body = ($body);

    # honor 75-column tradition of legacy BBS systems
    $body = wrap('','', $body) if $body and length($body) > 75;

    no warnings 'uninitialized';
    my $offset = sprintf("%+0.4d", getCurrentUser('off_set') / 36);
    $offset =~ s/([1-9][0-9]|[0-9][1-9])$/$1 * 0.6/e;

    if ($Use_RealEmail and SLASH) {
	$name = getCurrentUser('realemail');
	$nick = getCurrentUser('nickname');
    }

    # we could ignore the $reply until a Reply-To header is supported
    my $article = {
	header	=> {
	    From    => "$name ($nick)",
	    Subject => $title || '',
	    Board   => $board,
	    Date    => timeCalc(
		scalar localtime, "%a %b %e %H:%M:%S $offset %Y"
	    ),
	},
	body	=> $body || '',
    };

    my $error; # error message

    $error .= loc('Please enter a subject.<hr>')
	unless (length($article->{header}{Subject}));
    $error = '&nbsp;' unless $state;

    $PerlIO::via::trap::PASS = 1 if $TrappedExcept eq 'post';
    $artgrp->{articles}{$artid || ''} = $article unless $error;
    $PerlIO::via::trap::PASS = 0 if $TrappedExcept eq 'post';

    return ($article, $error);
}

sub article {
    my ($self, $group, $board, $child, $artid, $reply) = @_;
    my (@related, $artgrp, $is_reply);

    # put $reply to $name and set flag for further processing
    $is_reply++ if !defined($artid) and defined($artid = $reply);
    return unless defined $artid; # happens when a new article's made

    $child ||= 'articles';
    $artgrp = $self->{bbs}{($child eq 'mailbox') ? 'users' : 'boards'}{$board};

    foreach my $chunk (split('/', $child)) {
	$artgrp = ($chunk =~ /^\d+$/ ? $artgrp->[$chunk] : $artgrp->{$chunk});
    }

    # number OR name
    my $article	= ($artid =~ /^\d+$/ ? $artgrp->[$artid] : $artgrp->{$artid});

    my $related = ($is_reply || $child =~ m/^archives/) ? [] :  $self->related_articles(
	[ group => $group, board => $board, child => $child ],
	$artgrp, $article,
    ); # do not calculate related article during reply

    return ($self->mapArticle(
	$group, $board, $child, $artid, $article, $is_reply
    ), $related);
}

sub related_articles {
    my ($self, $params, $artgrp, $article) = @_;
    return unless $article;

    my $header	= $article->{header};
    my $recno	= $article->recno;
    my $size	= $#{$artgrp};
    my $title	= $header->{Subject};
    my $related = [];

    $title = "Re: $title" unless substr($title, 0, 4) eq 'Re: ';

    my %cache;

    # grepping for thread_prev
    if ($Thread_Prev) { foreach my $i (reverse(($recno - 5) .. ($recno - 1))) {
	next if $i < 0;
	my $art = $artgrp->[$i];
	my $title2 = $art->{header}->{Subject};
	next unless $title eq $title2 or $title eq "Re: $title2";
	pushy(\%cache, $related, $params, $Thread_Prev, $art);
	last;
    } }

    pushy(\%cache, $related, $params, $Date_Prev, $artgrp->[$recno - 1]) 
	if $Date_Prev and $recno;

    if ($Thread_Next) { foreach my $i (($recno + 1) .. ($recno + 5)) {
	next if $i > $size - 1;
	my $art = $artgrp->[$i];
	my $title2 = $art->{header}{Subject};
	next unless $title eq $title2 or $title eq "Re: $title2";
	pushy(\%cache, $related, $params, $Thread_Next, $art);
	last;
    } }

    pushy(\%cache, $related, $params, $Date_Next, $artgrp->[$recno + 1])
	if $Date_Next and $recno < $size - 1;

    return $related;
}

sub pushy {
    my ($cache, $self, $params, $relation, $art) = @_;
    return unless defined $art;

    my $name = $art->name;
    return if $cache->{$name}++;
    my $header = $art->{header};
    my $author = $art->{author};
    $author =~ s/(?:\.\.?bbs)?\@.+/\./;

    push @{$self}, {
	@{$params}, 
	relation => $relation, name => $name, header => $header,
	author => $author
    } unless $params->[5] ne 'articles' and $art->REF =~ /Group/;
}

sub board {
    my ($self, $group, $board, $child, $begin) = @_;
    my ($artgrp, $bm, $title, $etc);

    my $PageSize = 20;
    if ($child eq 'mailbox') {
	$artgrp = $self->{bbs}{users}{$board};
	$bm	= $board;
	$title	= $MailBox;
	$etc	= '';
    }
    else {
	$artgrp	= $self->{bbs}{boards}{$board};
	$bm	= $artgrp->{bm};
	$title	= $artgrp->{title};
	if ($etc = $artgrp->{etc_brief}) {
	    $etc = (split(/\n\n+/, $etc, 2))[1];
	    $etc =~ s/\x1b\[[\d\;]*m//g;
	    $etc =~ s/\n+/<br>/g;
	}
    }
    
    die "no such board" unless $artgrp;
    return unless $artgrp;

    die "permission denied"
        if $child ne 'mailbox' and $SecretSigils and
	    index(substr($artgrp->{title}, 0, index($artgrp->{title}, ' ')), $SecretSigils) > -1;

    foreach my $chunk (split('/', $child)) {
	$artgrp = $artgrp->{$chunk};
    }

    die "permission denied"
	if $artgrp->can('readlevel') and $artgrp->readlevel and $artgrp->readlevel ne 4294967295;

    my $reversed = ($child eq 'articles' or $child eq 'mailbox');
    my $size = eval { $#{$artgrp} } || 0;

    $begin = $reversed ? ($size - $PageSize + 1) : 0
	unless defined $begin;

    my @pages;

    foreach my $page (1..(int($size / $PageSize)+1)) {
	my $thisbegin = $reversed
	    ? ($size - ($page * $PageSize) + 1)
	    : (($page - 1) * $PageSize + 1);
	my $iscurpage = ($thisbegin == $begin);
        push @pages, {
            number     => $page,
	    begin      => $thisbegin,
	    iscurpage  => $iscurpage,
        };
    }

    $size = $begin + $PageSize - 1 if ($begin + $PageSize - 1 <= $size);
    $begin = 0 if $begin < 0;

    my $message = "| $board | ".
		(($artgrp->name or $child eq 'mailbox') 
		    ? $title : substr($title, $BoardPrefixLength)).
		" | $bm |<hr>";
    $message .= $etc if defined $etc;

    my @range = $reversed
	? reverse ($begin .. $size) : ($begin.. $size);

    local $_;
    return ($message, ($#pages ? \@pages : undef), $self->mapArticles(
	$group, $board, $child, \@range,
	map { eval { $artgrp->[$_] } || 0 } @range
    ));
}

sub group {
    my ($self, $group, $board) = @_;
    my $boards;
    
    $self->{bbs}{groups}->toplevel($TopClass);

    if ($board eq $TopClass) {
	$boards = $self->{bbs}{groups};
    }
    else {
#	$group =~ s|^\Q$TopClass\E/?||;
	$boards = ($group =~ m!^\Q$TopClass\E/?$!)
	    ? $self->{bbs}{groups}{$board}
	    : $self->{bbs}{groups}{$group}{$board};
    }

    my ($thisgroup, $title, $bm, $etc);

    if ($board eq $TopClass) {
	$bm = 'SYSOP';
	$title = 'All Boards';
    }
    elsif ($title = $boards->{title}) {
	$bm = $boards->{bm}; # XXX!
	$bm = $boards->{owner};
	$etc = $self->{bbs}{boards}{$board}{etc_brief}
	    if exists $self->{bbs}{boards}{$board};
    }

    local $_;
    $title ||= '';
    my $title2 = substr($title, $GroupPrefixLength);
    $title2 =~ s|^[^/]+/\s+||; # XXX: melix special case

    my $message = "| $board | ".
		    ( $title2 || $Organization) .
		($bm ? " | $bm |<hr>" : ' |<hr>');
    $message .= $etc if defined $etc;

#    $boards->refresh;

    return ($self->mapBoards(
	"$group/$board",
	map { 
	    $boards->{$_} 
	} sort {
	    uc($a) cmp uc($b)
	} grep {
	    $_ !~ /^(?:owner|id|title)$/
	} keys (%{$boards}),
    ), $message);
}

sub top {
    my $self = shift;

    # XXX kludge!
    my $top = $self->{bbs}{files}{'@-day'} || $self->{bbs}{files}{day};
    my $brds = $self->{bbs}{boards};
    my @ret;
    
    if (($self->{top} || '') eq $top) {
	@ret = $CachedTop{"@Connection"};
    }
    else { while (
	$top =~ s/^.*?32m([^\s]+).*?33m\s*([^\s]+)\n.*?37m\s*([^\x1b]+?)\x20*\x1b//m
    ) {
	my ($board, $author, $title) = ($1, $2, $3);
	my $artgrp = $brds->{$board}{articles};

	foreach my $art (reverse(0..$#{$artgrp})) {
	    my $article = $artgrp->[$art];
	    next unless ($article->{title} eq $title);
	    push @ret, $article;
	    last;
	}
    } 
	$CachedTop{"@Connection"} = \@ret;
	$self->{top} = $top;
    }

    return $self->mapArticles($TopClass, '', 'articles', [], @ret);
}

sub mapArticles {
    my ($self, $group, $board, $child, $range) = splice(@_, 0, 5);

    local $_; 
    return [ map {
	my $recno = shift(@{$range});
	my ($type, $title, $date, $author, $board, $artid);

	if (UNIVERSAL::isa($_, 'UNIVERSAL')) {
	    $type   = ($_->REF =~ /Group/) ? 'group' : 'article'; 
	    $title  = $_->{title};
	    $title  =~ s/\x1b\[[\d\;]*m//g; 
	    $date   = $_->{date},
	    $author = $_->{author};
	    $author =~ s/(?:\.bbs)?\@.+//;
	    $board  = $board || $_->board;
	    $artid  = $_->name;
	}
	else { # deleted article
	    $type   = 'deleted';
	    $title  = loc('<< This article has been deleted >>');
	    $board  = $board;
	    $author = '&nbsp;';
	    $date   = '&nbsp;';
	}

	{ 
	    title	=> $title,
	    child	=> $child,
	    group	=> $group,
	    type	=> $type,
	    date	=> $date,
	    author	=> $author,
	    board	=> $board,
	    name	=> $artid,
	    recno 	=> $recno,
	    articles_count	=> $type eq 'group' ? $#{$_} : 1,
	}
    } @_ ];
}

sub mapArticle {
    my ($self, $group, $board, $child, $artid, $article, $is_reply) = @_;
    my $header = { %{$article->{header} || {}} };
    my $title = $header->{Subject} || '(untitled)';
    $header->{Subject} =~ s/\x1b\[[\d\;]*m//g; 

    return {
	body	=> txt2html($article, $is_reply),
	header	=> $header,
	title	=> $title,
	board	=> $board,
	group	=> $group,
	child	=> $child,
	name 	=> $artid,
    };
}

sub mapBoards {
    my $self  = shift;
    my $group = shift;

    my (@group, @board);
    local $_;
    no strict 'refs';

    foreach (@_) {
	my $type = 'board';
	my $board;
	my $etc;
	my ($title, $date, $bm);

	if ($_->REF =~ /Group$/) {
	    $title = $_->{title} or next;

	    $board = $1 if $title =~ s|^([^/]+)/\s+||;
	    $bm = $_->{owner};
	    $bm = '' if $bm =~ /\W/; # XXX melix 0.8 bug

	    $type = 'group';
	}
	else {
	    $board = $_->board or next;
	    if ($etc = $_->{etc_brief}) {
		$etc = (split(/\n\n+/, $etc, 2))[1];
		$etc =~ s/\n+/\n/g;
	    }
	    $bm = $_->{bm},
	    $title = substr($_->{title}, $BoardPrefixLength) or next;
	}

        next if $SecretSigils and index(substr($_->{title}, 0, index($_->{title}, ' ')), $SecretSigils) > -1;

        next if $TopClass and $board eq $TopClass;

	my $entry = {
	    title	=> $title,
	    bm		=> $bm,
	    etc_brief	=> $etc,
	    group	=> $group,
	    board	=> $board,
	    type	=> $type,
#	    archives_count => (
#		($type eq 'group') ? '' : $#{$_->{archives}}
#	    ),
#	    articles_count => (
#		($type eq 'group') ? '&nbsp;' : $#{$_->{articles}}
#	    ),
	};

	if ($type eq 'group') {
	    push @group, $entry;
	}
	else {
	    push @board, $entry;
	}
    }

    return [ @group, @board ];
}

sub txt2html {
    my ($article, $is_reply) = @_;

    # reply mode decorations
    my $body = $article->{body};

    if ($is_reply) {
	$body =~ s/^(.+)\n+--+\n.+/$1/sg;
	$body =~ s/\n+/\n: /g;
	$body =~ s/\n: : : .*//g;
	$body =~ s/\n: : ※ .*//g;
	$body =~ s/: \n+/\n/g;
	$body = sprintf(loc("*) %s wrote:")."\n: %s", $article->{header}{From}, $body);
    }
    elsif ($Strip_ANSI) {
	require HTML::FromText;

        $body =~ s/\x1b\[.*?[mJH]//g;
	$body = HTML::FromText::text2html(
	    $body,
	    metachars => 1,  urls      => 1,
	    email     => 1,  underline => 1,
	    lines     => 1,  spaces    => 1,
	);

	$body =~ s/<TT><A&nbsp;HREF/<A HREF/g;
	$body =~ s/<\/TT>//g;

	$body = << ".";
<font class="text1" face="fixedsys, lucida console, terminal, vga, monospace">
$body
</font>
.
    }
    else {
	require HTML::FromANSI;
        $body = HTML::FromANSI::ansi2html($body);
    }

    return $body;
}

1;

__END__

=head1 NAME

Slash::OurNet - Web Interface for OurNet::BBS

=head1 SYNOPSIS

(Currently, this project exists mainly for historical/archival
purposes, not for active development.)

=head1 DESCRIPTION

This module provides a web interface to telnet-based BBS systems
as well as NNTP servers, either as a Slash plugin or as a stand-alone
CGI daemon in F<ournet.pl> included with this distribution.

To install this module, either copy the whole distribution under
the F<plugins/> directory before installing Slash, or use the standard
perl module install process:

    perl Makefile.PL
    make
    make install

and then use the F<bin/install-plugin> utility (usually located in
F</usr/local/slash/bin/>) to install it as a feature of your site.

Please remember to change the C<ournet.conf> settings to suit the
specific configurations of your C<bbscomd> daemon. See related 
documentations in L<OurNet::BBS> for an overview.

=head1 AUTHORS

Chia-Liang Kao E<lt>clkao@clkao.orgE<gt>,
Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

=head1 COPYRIGHT

Copyright 2001-2010 by
Chia-Liang Kao E<lt>clkao@clkao.orgE<gt>,
Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
