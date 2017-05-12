#line 1
package Test::FTP::Server;

use strict;
use warnings;

our $VERSION = '0.012';

use Carp;

use File::Find;
use File::Spec;
use File::Copy;
use File::Temp qw/ tempfile tempdir /;

use Test::FTP::Server::Server;

sub new {
	my $class = shift;
	my (%opt) = @_;

	my @args = ();

	if (my $users = $opt{'users'}) {
		foreach my $u (@$users) {
			if (my $base = $u->{'sandbox'}) {

				croak($base . ' is not directory.') unless -d $base;

				my $dir = tempdir(CLEANUP => 1);
				File::Find::find({
					'wanted' => sub {
						my $src = my $dst = $_;
						$dst =~ s/^$base//;
						$dst = File::Spec->catfile($dir, $dst);

						if (-d $_) {
							mkdir($dst);
						}
						else {
							File::Copy::copy($src, $dst);
						}

						chmod((stat($src))[2], $dst);
						utime((stat($src))[8,9], $dst);
					},
					'no_chdir' => 1,
				}, $base);

				$u->{'root'} = $dir;
			}

			croak(
				'It\'s necessary to specify parameter that is ' .
				'"root" or "sandbox" for each user.'
			) unless $u->{'root'};

			croak($u->{'root'} . ' is not directory.') unless -d $u->{'root'};
			croak('"user" is required.') unless $u->{'user'};
			croak('"pass" is required.') unless $u->{'pass'};

			$u->{'root'} =~ s{/+$}{};
		}
		push(@args, '_test_users', $users);
	}

	if ($opt{'ftpd_conf'}) {
		if (ref $opt{'ftpd_conf'}) {
			my ($fh, $filename) = tempfile();
			while (my ($k, $v) = each %{ $opt{'ftpd_conf'} }) {
				print($fh "$k: $v\n");
			}
			close($fh);

			push(@args, '-C', $filename);
		}
		else {
			push(@args, '-C', $opt{'ftpd_conf'});
		}
	}

	my $self = bless({ 'args' => \@args }, $class);
}

sub run {
	my $self = shift;
	Test::FTP::Server::Server->run($self->{'args'});
}

1;
__END__

#line 243
