package TestNvim;
use strict;
use warnings;
use Config;
use File::Which qw/which/;
use File::Spec::Functions qw/rel2abs/;
use File::Path qw/make_path/;
use HTTP::Tiny;
use Archive::Tar;
use Archive::Zip;
use Proc::Background;
use Test::More;
use Neovim::Ext;

our $BINARY;

my %available =
(
	'linux-64'   =>
	{
		url => 'https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz',
		binary => 'nvim-linux64/bin/nvim',
	},
	'darwin-64'  =>
	{
		url => 'https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz',
		binary => 'nvim-macos/bin/nvim',
	},
	'MSWin32-64' =>
	{
		url => 'https://github.com/neovim/neovim/releases/download/nightly/nvim-win64.zip',
		binary => 'nvim-win64/bin/nvim.exe',
	},
);



sub new
{
	my ($this) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
	};

	return bless $self, $class;
}



sub is_available
{
	my $bits = $Config{ptrsize} == 8 ? 64 : 32;
	my $key = $^O.'-'.$bits;
	my $config = $available{$key};
	if (!$config)
	{
		warn "no nvim package available for '$key'\n";
	}

	return !!$config->{url};
}



sub get_binary
{
	$BINARY = which ('nvim') if (!$BINARY);

	if (!$BINARY)
	{
		if (!is_available())
		{
			die "Not available!";
		}

		my $bits = $Config{ptrsize} == 8 ? 64 : 32;
		my $config = $available{$^O.'-'.$bits};
		my $link = $config->{url};
		my $binary = $config->{binary};

		if (!-f $binary)
		{
			my $fileName = (split (m#/#, $link))[-1];

			if (!-f $fileName)
			{
				diag ("Downloading nvim from $link");
				my $res = HTTP::Tiny->new->get ($link);
				if (!$res->{success})
				{
					die "Download failed!";
				}

				open my $fh, '>', $fileName or
					die "Could not open '$fileName': $!";
				binmode ($fh);
				print $fh $res->{content};
				close $fh;
				diag ("Downloaded $link");
			}

			if ($fileName =~ /\.tar\.gz$/)
			{
				diag ("Untarring nvim");
				my $tar = Archive::Tar->new;
				$tar->read ($fileName);
				$tar->extract();
			}
			elsif ($fileName =~ /\.zip/)
			{
				diag ("Unzipping nvim");
				my $zip = Archive::Zip->new;
				$zip->read ($fileName);
				$zip->extractTree();
				diag ("Unzipped nvim");
			}
		}

		if (-f $binary)
		{
			$binary = rel2abs ($binary);
			$BINARY = $binary;
		}
	}

	return $BINARY;
}



sub start_child
{
	my ($this, $socket) = @_;

	my $binary = get_binary();
	if (!$binary)
	{
		die "No nvim binary available!\n";
	}

	my $cmd = [$binary, '-u', 'NORC', '--embed', '--headless'];
	my $session = Neovim::Ext::MsgPack::RPC::child_session ($cmd);
	return _configure ($session);
}



sub start_socket
{
	my ($this, $socket) = @_;

	my $binary = get_binary();
	if (!$binary)
	{
		die "No nvim binary available!\n";
	}

	$ENV{NVIM_LISTEN_ADDRESS} = $socket;

	my $proc = Proc::Background->new ({die_upon_destroy => 1}, "$binary -u NORC --embed --headless --listen $socket");
	$this->{proc} = $proc;

	my $session = Neovim::Ext::MsgPack::RPC::socket_session ($socket, 50, 100);
	return _configure ($session);
}



sub start
{
	my ($this) = @_;

	my $binary = get_binary();
	if (!$binary)
	{
		die "No nvim binary available!\n";
	}

	$ENV{NVIM_RPLUGIN_MANIFEST} = rel2abs ('t/rplugin.vim');
	$ENV{NVIM_PERL_LOG_FILE} = rel2abs ('t/nvim.log');

	my $proc = Proc::Background->new({die_upon_destroy => 1}, "$binary -u NORC --embed --headless --listen 0.0.0.0:6666");
	$this->{proc} = $proc;

	my $session = Neovim::Ext::MsgPack::RPC::tcp_session ('localhost', 6666, 50, 100);
	return _configure ($session);
}



sub _configure
{
	my ($session) = @_;

	my $vim = Neovim::Ext::from_session ($session);

	$vim->options->{runtimepath} = join (',', rel2abs ('t/'), $vim->options->{runtimepath});
	$vim->command ("call remote#host#Register('perl', '*', function('provider#perl#Require'))");

	my @args = ('-Mblib');
	if ($ENV{HARNESS_PERL_SWITCHES})
	{
		my $value = $ENV{HARNESS_PERL_SWITCHES};
		$value =~ s/^\s*//g;
		$value =~ s/\s$//g;
		push @args, $value;
	}

	$vim->vars->{perl_host_prog} = $^X;
	$vim->vars->{perl_host_args} = \@args;

	return $vim;
}



sub DESTROY
{
	my $this = shift;

	$this->{proc}->die (INT => 1) if ($this->{proc});
}

1;

