#!/usr/local/bin/perl

use strict;
use warnings;
no warnings 'redefine';

use File::Spec;
use File::Basename;
use constant PATH  => dirname(File::Spec->rel2abs(__FILE__));
use constant SLASH => $ENV{SLASH_USER};

use lib PATH . '/lib';

use Slash::OurNet;

our ($LangHandle, $Language, $FullScreen, $AllBoards, %StandaloneVars,
     $TopClass, $TopArticles, $NewId, $MailBox, $Customize, $BugReport,
     $Organization, @Connection, $RootDisplay, $DefaultUser, $TrappedExcept,
     $DefaultNick, $Login, $Auth_Local, $Strip_ANSI, $bbs);

sub loc { goto &Slash::OurNet::loc }
BEGIN { do(PATH . '/ournet.conf'); die $@ if $@ }

use if $TrappedExcept, 'PerlIO::via::trap';
PerlIO::via::trap->import(qw(open mkdir)) if $TrappedExcept;

use if  SLASH, 'Slash';
use if  SLASH, 'Slash::DB';
use if  SLASH, 'Slash::Display';
use if  SLASH, 'Slash::Utility';
use if !SLASH, 'Slash::OurNet::Standalone';
Slash::OurNet::Standalone->import unless SLASH;

our %Vars = ( loc => \&loc, slash => (SLASH ? 1 : 0), %StandaloneVars );

# }}}

=head2 MAPPINGS

# http://localhost/ournet/				=> op=default
# http://localhost/ournet/Group/			=> op=group
# http://localhost/ournet/Group/Board/			=> op=board
# http://localhost/ournet/Group/Board/articles/NumOrStr	=> op=article
# http://localhost/ournet/Group/Board/archives/NumOrStr?edit  => op=board
# http://localhost/ournet/Group/Board/archives/NumOrStr?reply => op=board

=cut

sub main {
    my %ops = (
	login 		=> \&displayLogin,
	userlogin 	=> \&displayLogin,
	userclose 	=> \&displayLogout,
	search	 	=> \&displaySearch,
	group		=> \&displayGroup,
	board		=> \&displayBoard,
	article		=> \&displayArticle,
	article_edit	=> \&editArticle,
	default		=> \&displayDefault,
	reply		=> \&editArticle,
#	newid		=> \&displayNewId,
    );

    $Vars{script} = exists $ENV{SCRIPT_NAME} ? $ENV{SCRIPT_NAME} : $0;

    $ops{mail} = \&displayMailBox if $MailBox;
    $ops{top}  = \&displayTop	  if $TopArticles;

    my %safe = map { $_ => 1 } 
	qw/login userlogin newid group board article top default/;

    my $form = getCurrentForm();
    my $constants = getCurrentStatic();

    print "Content-Type: text/html; charset=utf-8\n\n";

    my $rootdir = exists $ENV{SCRIPT_NAME} ? $ENV{SCRIPT_NAME} : $0;
    $rootdir =~ s/[\\\/][^\\\/]+$//;
    $Vars{rootdir}  = $rootdir;
    $Vars{imagedir} = $rootdir."/images";

    my $op = $form->{'op'};

    my $pathinfo = $ENV{PATH_INFO};
    $pathinfo =~ s|/\Q$0\E/?|| if $pathinfo;
    
    if (defined $op or !$ENV{PATH_INFO}) {
	$op = 'default' unless $ops{$op || ''};
    }
    else {
	# let's translate the pathinfo into *real* requests
	# warn "PATH: $ENV{PATH_INFO}\n$ENV{QUERY_STRING}\n$form->{begin}\n";
	my @path = split('/', $ENV{PATH_INFO}, -1);
	my ($group, $board, $child, $article, $chunk, $legit);

	shift @path unless length($path[0]);
	$article = pop(@path);
	$child	 = '';

	while ($chunk = pop(@path)) {
	    $child = "$chunk/$child";
	    ($legit++, last) if $chunk =~ /^(?:mailbox|archives|articles)$/;
	}

	if ($legit) {
	    chop $child; # removes trailing /
	    $board = pop(@path);
	}
	else {
	    push @path, split('/', $child);
	    undef $child;
	}

	$group = join('/', @path);

	$op = $article ? exists $form->{edit}  ? 'edit'
		       : exists $form->{reply} ? 'reply'
		       : 'article'
	    : $child   ? 'board' 
	    : $group   ? 'group'
	    : 'default';

	@{$form}{qw/group board child name/}
	    = ($group, $board, $child, $article);
    }

    my $uid = $form->{'uid'};
    my $slashdb = getCurrentDB();
    my $name = $slashdb->getUser($uid, 'nickname') if $uid;
    $name ||= getCurrentUser('nickname');
    $name ||= $DefaultUser;

    # defaults to plaintext on localhost.
    $bbs = $Slash::OurNet::ALLBBS{$name} ||= Slash::OurNet->new(
	getCurrentVirtualUser(), (@Connection, $Auth_Local ? ($name, 1, 1) : ())
    );

    # XXX: local auth
    # $bbs->{bbs} = OurNet::BBS->new('OurNet', $bbs->{bbs}, $name) if $name ne $DefaultUser;

    my $nick = $slashdb->getUser($form->{uid}, 'fakeemail') if $form->{uid};
    $nick ||= getCurrentUser('fakeemail');
    $nick ||= $DefaultNick;

    $Vars{username} = $name;
    $Vars{usernick} = $nick;

    if ($name eq $DefaultUser) {
	$op = 'default' unless $safe{$op};
    }

    return $ops{$op}->($form, $bbs, $constants, $name, $nick)
	if ($ops{$op} == \&displayLogin);

    if ($FullScreen) {
	slashDisplay('header', { 
	    %Vars,
	    organization => $Organization,
	});
    }
    else {
	header("$Organization - $name");
	titlebar("100%","$Organization - $name");
    }

    slashDisplay('navigation', { 
	%Vars,
	user       => $name,
	newid	   => $NewId,
	login	   => $Login,
	mailbox    => $MailBox,
	bugreport  => $BugReport,
	customize  => $Customize,
	topclass   => $TopClass,
	slash_user => $ENV{SLASH_USER},
    });

    $ops{$op}->($form, $bbs, $constants, $name, $nick);

    if ($FullScreen) {
	slashDisplay('footer', { %Vars });
    }
    else {
	footer();
    }
}

sub displayLogin {
    if ($ENV{SLASH_USER}) {
	# shouldn't be here unless Anonymous Coward is turned off.
	print CMSG(4, "You haven't logged in. Please press login in the left side bar.");
    }
    else {
	# slashDisplay('login', { %Vars });
	print "<HTML><HEAD><META HTTP-EQUIV='Refresh' CONTENT='0;url=$Vars{rootdir}/'></HEAD><BODY></BODY></HTML>\n\n";
    }
}

sub displaySearch {
    slashDisplay('search', { %Vars });
}

sub displayLogout {
    # somehow log out here
    print "<HTML><HEAD><META HTTP-EQUIV='Refresh' CONTENT='0;url=$Vars{rootdir}/'></HEAD><BODY></BODY></HTML>\n\n";
}

sub displayDefault {
    if ($AllBoards) {
	displayAllBoards(@_, '', $TopClass);
    }
    else {
	displayGroup(@_, '', $TopClass);
    }

    if ($TopArticles) {
	print "<hr>";
	displayTop(@_);
    }
}

sub displayTop {
    my ($form, $bbs, $constants, $name) = @_;
    my $articles = $bbs->top;

    slashDisplay('board', {
	%Vars,
	articles => $articles, 
	display  => 'top',
	message  => $TopArticles,
	topclass => $TopClass,
    });
}

sub displayAllBoards {
    my ($form, $bbs, $constants, $name, $nick, $group, $board) = @_;
    my $brds = $bbs->{bbs}{boards};

    slashDisplay('group', { 
	%Vars,
	board	=> $board,
	group	=> $group,
	boards	=> $bbs->mapBoards($TopClass, grep {$_} map {eval{$brds->{$_}}} $brds->KEYS),
	display	=> $RootDisplay,
	message	=> loc('Home'),
	topclass => $TopClass,
    });
}

sub displayGroup {
    my ($form, $bbs, $constants, $name, $nick, $group, $board) = @_;
    $group ||= $form->{group};
    $board ||= $form->{board};

    if (!$board) {
	($group, $board) = ($board, $group);
	($group, $board) = (split('/', $board))[-2,-1] if index($board, '/') > -1;
    }

    my ($boards, $message) = $bbs->group($group, $board);
    return unless $boards and @{$boards};
    # goto &displayAllBoards unless @{$boards};

    slashDisplay('group', { 
	%Vars,
	board	=> $board,
	group	=> $group,
	boards	=> $boards, 
	display	=> ($form->{board} || $RootDisplay),
	message	=> (
	    ($form->{board} and $form->{board} ne $TopClass) 
		? $message : loc('Home'),
	),
	topclass => $TopClass,
    });
}

sub displayBoard {
    my ($form, $bbs, $constants, $name) = @_;
    unless ($bbs->{bbs}{boards}{$form->{board}}) {
	print CMSG(5, 'No such board.<hr>'), $form->{board};
	printf(CMSG(
	    6, '<div align="center">[ <a href="%s">Back to main menu</a> ]</div>'
	), $0);
	return;
    }

    my $brd = $bbs->{bbs}{boards}{$form->{board}};
    $form->{child} ||= 'articles';

    my ($message, $pages, $articles) 
	= $bbs->board(@{$form}{qw/group board child begin/});

    slashDisplay('board', { 
	%Vars,
	group	 => $form->{group},
	child	 => $form->{child},
	board	 => $form->{board},
	articles => $articles, 
	pages    => $pages, 
	display	 => $form->{board},
	message  => $message,
	topclass => $TopClass,
	archives_count => $#{$brd->{archives}},
	articles_count => $#{$brd->{articles}},
    });
}

sub displayMailBox {
    my ($form, $bbs, $constants, $name) = @_;
    my ($message, $pages, $articles) 
	= $bbs->board('', $name, 'mailbox', $form->{begin});
    
    slashDisplay('board', {
	%Vars,
	group	 => '',
	child	 => 'mailbox',
	board	 => $name,
	articles => $articles, 
	pages    => $pages, 
	display	 => 'mailbox',
	message  => $message,
	topclass => $TopClass,
	archives_count => 0,
    });
}

sub editArticle {
    my ($form, $bbs, $constants, $name, $nick) = @_;
    my $message = '';
    my $article;

    my $mode = $form->{reply} ? 'reply' : $form->{name} ? 'edit' : 'new';

    if ($form->{state} or $mode eq 'new') {
	# insert it, take message, return to board
	($article, $message) = $bbs->article_save(
	    @{$form}{qw/group board child name reply title body state/}, 
	    $name, $nick,
	);

	# back to board if nothing's wrong, otherwise fall through
	return displayBoard(@_) unless $message; 
    }
    else {
	$article = ($bbs->article(
	    @{$form}{qw/group board child name reply/})
	)[0]; # ignore related

	$article->{header}{From} = "$name ($nick)";

	my $offset = sprintf("%+0.4d", getCurrentUser('off_set') / 36);
	$offset =~ s/([1-9][0-9]|[0-9][1-9])$/$1 * 0.6/e;
	$article->{header}{Date} = timeCalc(
	    scalar localtime, "%a %b %e %H:%M:%S $offset %Y"
	);
    }

    $article->{header}{Subject} =~ s/^(?!Re:)/Re: / if $mode eq 'reply';

    slashDisplay('article', {
	%Vars,
	group	=> $form->{group},
	child	=> $form->{child},
	board   => $form->{board},
	name   	=> $form->{name},
	article => $article, # undef if $mode eq 'new'
	message	=> $message,
	display	=> 'edit',
	ansi2html => !$Strip_ANSI,
    });
}

sub displayArticle {
    my ($form, $bbs, $constants) = @_;

    my ($article, $related)
	= $bbs->article(@{$form}{qw/group board child name/});

    slashDisplay('article', {
	%Vars,
	group	=> $form->{group},
	child	=> $form->{child},
	board   => $form->{board},
	name   	=> $form->{name},
	article => $article, 
	display	=> 'display',
	related	=> $related,
	ansi2html => !$Strip_ANSI,
    });
}

# locate a melix installation by looking at various places
sub find_bbs {
    local $@;
    
    if ($^O eq 'MSWin32' and eval 'use Win32::TieRegistry; 1') {
		no warnings 'once';
        my $Registry = $Win32::TieRegistry::Registry;
		my $binary_path = (
			$Registry->{'HKEY_LOCAL_MACHINE\Software\Elixir\melix\\'}->{''} ||
            $Registry->{'HKEY_LOCAL_MACHINE\Software\Cygnus Solutions\\'.
                        'Cygwin\mounts v2\/\native'}
        );
        
        unshift(@_, "$binary_path/home/melix") if defined $binary_path;
    }

    foreach my $path (@_, '.') {
	return $path if -d $path
	    and (-e "$path/.BRD" or -e "$path/.USR" or
		 -e "$path/bin/bbsd" or -e "$path/bin/bbsd.exe");
    }

    die "cannot find Melix BBS's .BRD file in path: (@_).\n"
}

sub httpd {
    require HTTP::Daemon;
    require HTTP::Status;
	local $SIG{CHLD} = 'IGNORE';

    my $d = HTTP::Daemon->new(
	LocalPort => 7977
    ) or die "cannot create web server";
    
    use constant IsWin32 => ($^O eq 'MSWin32');
    # use open (IsWin32 ? (IN => ':raw', OUT => ':raw') : ());
    my $url = (IsWin32 ? 'http://localhost:7977/' : $d->url);

    print "Please contact me at: <$url>\n";
    print "Press Ctrl-C to shut down this server.";

    if (grep { /^-\w*l\w*$/ } @ARGV) {
	# evil local override code
	@Connection     = ('MELIX', $ENV{EBX_BBSROOT} || (
	    IsWin32 ? find_bbs(
		'c:/cygwin/home/melix', 'c:/program files/melix/home/melix'
	    ) : find_bbs('/home/melix', '/home/bbs')
	));

	system('start',  $url) if ($^O eq 'MSWin32');
    }
	
    while (my $c = $d->accept) {
	next if ($^O ne 'MSWin32') and fork();
	while (my $r = $c->get_request) {
	    no warnings 'uninitialized';
	    delete $INC{'CGI.pm'};
	    require CGI;

	    $ENV{REQUEST_METHOD} = 'GET';
	    $ENV{COOKIE} = $r->headers->header('COOKIE');
	    $ENV{HTTP_COOKIE} = $r->headers->header('HTTP_COOKIE');
	    $ENV{CONTENT_LENGTH} = $r->headers->header('CONTENT_LENGTH');
	    $ENV{PATH_INFO} = $r->url->path || '';
	    $ENV{PATH_TRANSLATED} = $0;
	    $ENV{QUERY_STRING} = $r->url->query || $r->content || '';
	    $ENV{SCRIPT_NAME} = substr($url, 0, -1); # $r->url->path;

	    if ($r->method eq 'GET' or $r->method eq 'POST') {
			if ($ENV{PATH_INFO} =~ m|^/images/|) {
			    $c->send_file_response(dirname($0).$ENV{PATH_INFO});
			}
			else {
			    $c->send_basic_header;
			    select $c; main();
			    select STDOUT;
				CGI->delete_all;
				CGI->new->delete_all;
			}
			$c->force_last_request;
	    } else {
			$c->send_error(HTTP::Status::RC_FORBIDDEN())
	    }
	}
	$c->close;
	undef($c);
	exit unless ($^O eq 'MSWin32');
    }
}

createEnvironment();
(grep { /^-\w*d\w*$/ } @ARGV) ? httpd() : main();

1;
