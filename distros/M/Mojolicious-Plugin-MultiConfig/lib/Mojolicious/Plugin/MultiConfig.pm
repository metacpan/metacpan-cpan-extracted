package Mojolicious::Plugin::MultiConfig;

use v5.10;
use strict;
use warnings;
use parent 'Mojolicious::Plugin';

use Config::Any;
use File::Spec::Functions;

=head1 NAME

Mojolicious::Plugin::MultiConfig - Load multiple configs and merge

=head1 VERSION

Version 0.2

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

	# In Mojo startup()...

	my $config = $self->plugin('multi_config', foo => 'bar');
	say($config->{this});
	say($self->config->{that});

=head1 DESCRIPTION

L<Mojolicious::Plugin::MultiConfig> is a wrapper around L<Config::Any> to load multiple configuration files and merge them together.

The default behaviour is to load 3 config files based on templates containing moniker (%a), mode (%m), username (%u) and file extenstion (%e):

* %a.%e
* %a.%m.%e
* %a.%m.%u.%e

The config files are loaded in order, with later files in the chain overwriting option(s) in the previous config file.

The filenames are configurable, see OPTIONS section below.

Missing config files are ignored without error. (TODO: config option to be added in the near future ensure an error).

=head1 OPTIONS

L<Mojolicious::Plugin::MultiConfig> supports some options. They can be passed as named args. e.g.:

	$self->plugin('multi_config', option1 => 'value1', foo => 'bar');

=head2 moniker

	moniker => 'appconfig'

Will use this value in place of %a (moniker) in filenames. Defaults to C<$app-E<gt>moniker> if not specified.

=head2 mode

	mode => 'test'

Will use this value in place of %m (mode) in filenames. Defaults to C<$app-E<gt>mode> if not specified.

=head2 dir

	dir => 'my_config_dir'

Will load config files from this directory. Defaults to C<$app-E<gt>home('conf')> if not specified.

=head2 files

	files => ['file1.conf', 'file2.%u.conf']

Will load these config files instead of the default. You can use template codes as per DESCRIPTION section.

Defaults to C<['%a.%e', '%a.%m.%e', '%a.%m.%u.%e']> if not specified.

=head2 ext

	ext => 'yml'

Will use this value in place of %e (file extension) in filenames. Defaults to C<conf> if not specified.

=head1 METHODS

=head2 register

Register as a plugin and load config files. Called automatically by C<$app-E<gt>plugin>

=cut

sub register
{
	my $self = shift;
	my $app  = shift;
	my $arg  = shift;
	my $config = {};
	my $username = (getpwuid($<))[0]; # TODO: Not on Windows!
	my @files;

	# Default args if not set
	$arg->{moniker} //= $app->moniker;
	$arg->{mode}    //= $app->mode;
	$arg->{dir}     //= catfile($app->home, 'conf');
	$arg->{files}   //= ['%a.%e', '%a.%m.%e', '%a.%m.%u.%e'];
	$arg->{ext}     //= 'conf';

	for (my $i = 0; $i < @{$arg->{files}}; $i++) {
		# Prefix dir
		$arg->{files}->[$i] = catfile($arg->{dir}, $arg->{files}->[$i]);

		# Search/replace for codes used in files
		$arg->{files}->[$i] =~ s/\%a/$arg->{moniker}/g;
		$arg->{files}->[$i] =~ s/\%m/$arg->{mode}/g;
		$arg->{files}->[$i] =~ s/\%u/$username/g;
		$arg->{files}->[$i] =~ s/\%e/$arg->{ext}/g;

		if (-e $arg->{files}->[$i]) {
			$app->log->debug(__PACKAGE__ . ': found ' . $arg->{files}->[$i]);
		}
		else {
			$app->log->debug(__PACKAGE__ . ': cannot find ' . $arg->{files}->[$i]);
			splice(@{$arg->{files}}, $i--, 1);
		}
	}

	# Load the config file(s)
	my $config_tmp = Config::Any->load_files({
		files           => $arg->{files},
		use_ext         => 1,
		flatten_to_hash => 1,
		driver_args => {
			General => {-UTF8 => 1},
		},
	});

	# Merge
	$config = {%$config, %{$config_tmp->{$_}}} for (@{$arg->{files}});

	$app->config($config);
	$app->log->debug($app->dumper($config));
	
	return $config;
}

=head1 AUTHOR

Ben Vinnerd, C<< <ben at vinnerd.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2013 Ben Vinnerd.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
