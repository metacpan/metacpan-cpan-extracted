# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/OurNet/BBS.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 3978 $ $DateTime: 2003/01/28 12:07:29 $

package OurNet::BBS::OurNet::BBS;

use strict;
use warnings;
no warnings 'deprecated';

sub new { 
    if (UNIVERSAL::isa($_[2], 'OurNet::BBS::Base')) {
	# hooking an existing BBS object
	die "No such user: $_[3]\n" unless exists $_[2]->{users}{$_[3]};

	undef $OurNet::BBS::CurrentUser;
	$OurNet::BBS::CurrentUser = $_[2]->{users}{$_[3]};

	_hook(ref($_[2]));
	_wrap(\%OurNet::BBS::Base::);
	return $_[2];
    }
    elsif (ref($_[1])) {
	# hashref
	require OurNet::BBS::Client;
	return OurNet::BBS::Client->new(@{$_[1]}{qw{
	    bbsroot peerport keyid user password cipher_level auth_level
	}});
    }
    else {
	# plain
	require OurNet::BBS::Client;
	return OurNet::BBS::Client->new(@_[2..$#_]);
    }
}

sub _hook {
    my $base = shift;
    my $dir = $base;
    $dir =~ s!::!/!g;
    $dir = $INC{"$dir.pm"};
    $dir =~ s![^/]+\Z!*!g;
    $base =~ s!BBS\Z!!;

    foreach my $mod (glob($dir)) {
	no strict 'refs';
	$mod = substr($mod, length($dir) - 1);
	$mod =~ s!\.pm\Z!!;
	$mod = "$base$mod";

	my $file = $mod;
	$file =~ s!::!/!g;
	require "$file.pm";

	_wrap(\%{$mod . '::'});
    }
}

use constant OP_WRITE  => { map { $_=>1 } qw(
    STORE DELETE PUSH POP SHIFT UNSHIFT CLEAR
)};
use constant OP_IGNORE => { map { $_=>1 } qw(
    DESTROY daemonize initvars writeok readok
    new timestamp fillmod fillin remove pack unpack ego
    _write_ok _read_ok has_perm
    AUTOLOAD INJECT REF SPAWN TIEARRAY TIEHASH TIESCALAR READOK WRITEOK
    backend carp confess contains croak filestamp import
    module purge refresh basedir basepath bbsroot
)};

my %_wrapped;
sub _wrap {
    my $sym = shift;
    return if $_wrapped{$sym}++;

    require Hook::LexWrap;

    my ($read, $write) = map {
	exists $sym->{$_} && _strip(*{$sym->{$_}}{CODE})
    } qw(readok writeok);

    foreach my $key (sort keys %$sym) {
	my $sub = $sym->{$key} or next;
	next unless *$sub{CODE};

	my $proto = prototype($sub);
	next if defined($proto) and !$proto; # skip constants

	next if $key =~ /^[_(:]/;
	next if $key =~ /^[A-Z\d]+_[A-Z\d]+$/;
	next if $key =~ /^refresh_/;
	next if OP_IGNORE->{$key};

	if (OP_WRITE->{$key}) {
	    Hook::LexWrap::wrap(substr($sub, 1), pre => \&_write_ok) if $write;
	}
	elsif ($read) {
	    Hook::LexWrap::wrap(substr($sub, 1), pre => \&_read_ok);
	}
    }
}

sub _strip { 
    my $code = shift or return 1;

    require B::Deparse;
    $code = B::Deparse->new->coderef2text($code);

    $code =~ s/^\{\s*|\s*\}$//g;
    $code =~ s/^\s*package \S+;$//m;
    $code =~ s/^\s*(?:use|no) strict\b.*;$//m;
    $code =~ s/^\s*(?:use|no) warnings\b.*;$//m;
    $code =~ s/^\s*1;$//m;
    $code =~ s/\n+//g;

    return $code;
}

sub _write_ok {
    return unless $OurNet::BBS::CurrentUser;
    return if $_[0]->writeok($OurNet::BBS::CurrentUser, 'STORE', [@_[1..$#_]]);
    die "Can't write to $_[0]: Permission denied for ".$OurNet::BBS::CurrentUser->id."\n";
}

sub _read_ok {
    return unless $OurNet::BBS::CurrentUser;
    return if $_[0]->readok($OurNet::BBS::CurrentUser, 'FETCH', [@_[1..$#_]]);
    die "Can't read from $_[0]: Permission denied for ".$OurNet::BBS::CurrentUser->id."\n";
}

1;
