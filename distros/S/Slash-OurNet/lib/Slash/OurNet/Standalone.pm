package Slash::OurNet::Standalone;

our $VERSION = '0.02';

require CGI;
use base 'Exporter';

our @EXPORT = qw(
    getCurrentVirtualUser getCurrentForm getCurrentStatic slashDisplay
    getCurrentDB getUser getCurrentUser createEnvironment header
    titlebar footer SetCookie timeCalc
);

our %Sessions;

sub header {
    print "<title>@_</title>";
}

sub footer {
    print "<hr>@_</body></html>";
}

sub titlebar {
    shift;
    print "<h3>@_</h3>";
}

sub getCurrentVirtualUser {
    return 'guest';
}

sub getCurrentForm {
    my $flavor = 'OurNetBBS';
    my $show_cookie;
    my ($cookie);

    require SDBM_File;

    use Fcntl;
    tie(%Sessions, 'SDBM_File', Slash::OurNet::PATH . '/ournet.db', O_RDWR|O_CREAT, 0666) or die $!;

    require Encode;
    require CGI::Cookie;

    my $CGI = CGI->new;
    my $vars = {map Encode::decode_utf8($_), %{$CGI->Vars}};
    $CGI->delete_all;

    if (exists $vars->{op} and $vars->{op} eq 'userlogin') {
	my ($uid, $pwd) = @{$vars}{qw/unickname upasswd/};
	my $bbs = (values(%Slash::OurNet::ALLBBS))[0];
	$bbs = $bbs->{bbs} if $bbs;
	$bbs ||= OurNet::BBS->new(@Slash::OurNet::Connection);
	if (exists $bbs->{users}{$uid}) {
	    my $user = $bbs->{users}{$uid};
	    my $crypted = $user->{passwd};
	    if (crypt($pwd, $crypted) eq $crypted) {
		my $val = SetCookie();
		$Sessions{$val} = $vars->{unickname};
		$show_cookie = 1;
	    }
	}
    }
    elsif ($CGI->path_translated() or $CGI::MOD_PERL or $^O ne 'MSWin32') {
	my %cookies = CGI::Cookie->fetch;
	$cookie = $cookies{$flavor} if exists $cookies{$flavor};
    }
    else {
	$cookie = CGI::Cookie->new(-value => 'localhost');
    }

#    print << '.';
#Content-Type: text/html; charset=UTF-8
#.

    if ($cookie and $Sessions{$cookie->value}) {
        if (exists $vars->{op} and $vars->{op} eq 'userclose') {
	    delete $Sessions{$cookie->value};
        }
	else {
	    my $sescook = CGI::Cookie->new(
		-name    => $flavor,
		-value   =>  $cookie->value,
		-expires =>  '+1h',
		-domain  =>  $cookie->domain
	    );

	    print "Set-Cookie: $sescook\n" if $show_cookie;
	    $vars->{uid} = $Sessions{$cookie->value};
	}
    }

    untie(%Sessions);
#    print "\n\n\n";

    return $vars;
}

sub getCurrentStatic {
}

sub getCurrentDB {
    my $a;
    return bless \$a, __PACKAGE__;
}

sub getUser {
    my ($self, $uid, $key) = @_;

    return $uid if $key eq 'nickname';
    if ($key eq 'fakeemail') {
		my $bbs = $Slash::OurNet::ALLBBS{$uid}{bbs};
		my $user = $bbs->{users}{$uid};
		return $user->{username};
    }
}

sub getCurrentUser {
    my ($self, $key) = @_;
    return unless $key;

    if ($key eq 'is_anon') {
		return ($vars->{username} eq $Slash::OurNet::DefaultUser);
    }
    elsif ($key eq 'off_set') {
		require Time::Local;
		return ((timegm(localtime) - timegm(gmtime)) / 3600);
    }
}

my $template;

sub slashDisplay {
    my ($file, $vars) = @_;
    my $path = exists $ENV{SCRIPT_FILENAME} ? $ENV{SCRIPT_FILENAME} : $0;
    $path =~ s|[\\/][^\\/]+$|/templates| or $path = './templates';
    $path .= "/$Slash::OurNet::Theme" if $Slash::OurNet::Theme;
    $path = "$path/$file;ournet;default";

    $vars->{user} = $Slash::OurNet::Colors;
    $vars->{user}{nickname} = $vars->{username};
    $vars->{user}{fakeemail} = $vars->{usernick};
    $vars->{user}{is_anon}  = ($vars->{username} eq $Slash::OurNet::DefaultUser);

    local $/;
    open my $fh, $path or die "cannot open template: $path ($!)";
    binmode($fh, ':utf8');
    my $text = <$fh>;
    $text =~ s/.*\n__template__\n//s;
    $text =~ s/__seclev__\n.*//s;

    require Template;
    $template ||= Template->new;
    my $selfh = select() eq 'main::STDOUT' ? undef : select();
    return $template->process(\$text, $vars, $selfh) || die($template->error);
}

sub createEnvironment {
}

sub SetCookie {
    my $flavor  = shift || 'OurNetBBS';
    my $sescook = CGI::Cookie->new(
	-name    => $flavor,
        -value   =>  crypt(time, substr(CGI::remote_host(), -2)),
        -expires =>  '+1h'
    );

    print "Set-Cookie: $sescook\n";
    return $sescook->value;
}

sub timeCalc {
    return scalar localtime;
}

1;
