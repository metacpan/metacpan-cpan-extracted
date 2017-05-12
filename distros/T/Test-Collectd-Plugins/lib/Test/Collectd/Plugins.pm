package Test::Collectd::Plugins;

use 5.006;
use strict;
use warnings;
use Carp qw(croak cluck);
use namespace::autoclean;
use Test::Collectd::Config qw(parse);

BEGIN {use Package::Alias Collectd => "FakeCollectd"}

=head1 NAME

Test::Collectd::Plugins - Common out-of-band collectd plugin test suite

=head1 VERSION

Version 0.1008

=cut

our $VERSION = '0.1009';

use base 'Test::Builder::Module';
use IO::File;

our @EXPORT = qw(load_ok read_ok read_config_ok read_values $typesdb);

our $typesdb;

sub import_extra {
	my $class = shift;
	my $list = shift;
	my $args;
	$args = @$list == 1 ? $list->[0] : {@$list};
	@$list = ();
	croak __PACKAGE__." can receive either a hash or a hash reference."
		unless ref $args and ref $args eq "HASH";
	for (keys %$args) {
		if (/^typesdb$/i) {
			$typesdb = $args->{$_};
		} else {
			push @$list, $_ => $args->{$_};
		}
	}
	return;
}

=head1 SYNOPSIS

  use Test::More;
  use Test::Collectd::Plugins typesdb => ["/usr/share/collectd/types.db"];

  plan tests => 4;

  load_ok ("Collectd::Plugins::Some::Plugin");
  read_ok ("Collectd::Plugins::Some::Plugin", "plugin_name_as_returned_by_dispatch");
  read_config_ok ("My::Plugin", "my_plugin", "/path/to/my_plugin.conf");

  my $expected = [[{{ plugin => "my_plugin", type => "gauge", values => [ 42 ] }}]];
  my $got = read_values_config ("My::Plugin", "my_plugin", "/path/to/my_plugin.conf");

  is_deeply ($got, $expected);

  done_testing;

Testing collectd modules outside of collectd's perl interpreter is tedious, as you cannot
simply 'use' them. In fact you can't even 'use Collectd', try it and come back.
This module lets you test collectd plugins outside of the collectd daemon. It is supposed
to be the first step in testing plugins, detecting syntax errors and common mistakes. 
There are some caveats (see dedicated section), and you should use the usual collectd testing
steps afterwards e.g. enabling debug at compile time, then running the collectd binary in
the foreground while using some logging plugin, plus some write plugin. I usually use logfile
to STDOUT and csv plugin.

=head1 MODULE vs. PLUGIN

Most methods will accept either $plugin or $module or both. They correspond to C<collectd-perl>'s C<LoadPlugin $module> and C<Plugin $plugin> respectively. It's easy to mistake one for the other. While $module is as its name suggests the perl module's name, $plugin corresponds to the collectd plugin's name, as called by plugin_dispatch_values. This difference makes it possible for a plugin to dispatch values on behalf of another, or to register multiple plugins. Make sure you ask the methods the right information.

=head1 SUBROUTINES/METHODS

=head2 load_ok <$module> <$message>

Tries to load the plugin module. As collectd-perl plugin modules contain direct calls (upon loading) to L<Collectd/plugin_register>, the former are intercepted by L<FakeCollectd> which is part of this distribution. This has the effect of populating the %FakeCollectd hash. See L<FakeCollectd> for more info.

=cut

sub load_ok ($;$) {
	my $module = shift;
	my $msg = shift || "load OK";
	_load_module($module);
	__PACKAGE__->builder->is_eq($@, "", $msg);
}

sub _load_module ($) {
	my $module = shift;
	eval "require $module";
}

sub _init_plugin ($) {
	my $plugin = shift or die "_init_plugin needs plugin name";
	my $init = $FakeCollectd{$plugin}->{Callback}->{Init};
	if (defined $init) {
		eval "$init()";
	} else {
		return 1;
	}
	if ($@) {
		return undef;
	} else {
		return $init;
	}
}

sub _read ($) {
	my $plugin = shift or die "_read needs plugin name";
	my $reader = $FakeCollectd{$plugin}->{Callback}->{Read};
	if (defined $reader) {
		eval "$reader()";
		return $reader;
	} else {
		eval { die "_read: No reader defined for plugin `$plugin'" };
		return undef;
	}
}

sub _reset_values ($) {
	my $plugin = shift;
	if (exists $FakeCollectd{$plugin}->{Values}) {
		undef @{$FakeCollectd{$plugin}->{Values}};
	}
	return 1;
}

sub _values ($) {
	my $plugin = shift or die "_values needs plugin name";
	if (exists $FakeCollectd{$plugin}->{Values}) {
		return @{$FakeCollectd{$plugin}->{Values}}
	} else {
		return undef
	}
}

sub _config ($$) {
	my $plugin = shift or die "_config(plugin,config)";
	my $cfg = shift or die "_config(plugin,config)";

	my $cb = $FakeCollectd{$plugin}->{Callback}->{Config};
	unless ($cb) {
		eval {croak "plugin $plugin does not provide a config callback"};
		return undef;
	}
	my $config = Test::Collectd::Config::parse($cfg) or croak "failed to parse config";
	# this fires up the plugin's config callback with provided config
	eval {no strict "refs"; &$cb($config)}; # or croak("config callback $cb failed: $@");
	if ($@) {
		return undef;
	} else {
		return $config;
	}
}

=head2 plan tests => $num

See L<Test::More/plan>.

=cut

#sub plan { __PACKAGE__ -> builder -> plan (@_) }
#sub diag { __PACKAGE__ -> builder -> diag (@_) }

=head2 read_ok <$module> <$plugin> [$message]

Loads the plugin module identified by $module, then tries to fire up the registered read callback for this plugin ($plugin), while intercepting all calls to L<Collectd/plugin_dispatch_values>, storing its arguments into the %FakeCollectd hash. The latter are checked against the following rules, which match the collectd guidelines:

=over 2

=cut

sub read_ok ($$;$) {
	my $module = shift;
	my $plugin = shift;
	my $msg = shift || "read OK";

	my $tb = __PACKAGE__->builder;

$tb -> subtest($msg, sub {

	$tb -> ok (_load_module($module), "load plugin module") or $tb -> diag ($@);
	$tb -> ok (_reset_values($module), "reset values") or $tb -> diag ($@);
	$tb -> ok (_init_plugin($plugin),"init plugin"); $tb -> diag ($@) if $@;
	$tb -> ok (_read($plugin),"read plugin") or $tb -> diag ($@);
	my @values = _values ($module);
	$tb -> ok(@values, "read callback returned some values") or $tb -> diag ($@);
	$tb -> ok(scalar @values, "dispatch called");
	for (@values) {
		$tb->is_eq(ref $_,"ARRAY","value is array");

=item * There shall be only one and only one hashref argument

=cut

		$tb -> ok(scalar @$_, "plugin called dispatch with arguments");
		$tb -> cmp_ok (@$_, '>', 1, "only one value_list expected");
		my $ref = ref $_->[0];
		$tb -> is_eq($ref, "HASH", "value is HASH"); # this should be handled already earlier
		my %dispatch = %{$_->[0]};

=item * The following keys are mandatory: plugin, type, values

=cut

		for (qw(plugin type values)) {
			$tb -> ok(exists $dispatch{$_}, "mandatory key '$_' exists") or return;
		}

=item * Only the following keys are valid: plugin, type, values, time, interval, host, plugin_instance, type_instance.

=cut

		for (keys %dispatch) {
			$tb -> like ($_, qr/^(plugin|type|values|time|interval|host|plugin_instance|type_instance)$/, "key $_ is valid");
		}

=item * The key C<type> must be present in the C<types.db> file.

=cut

		my @type = _get_type($dispatch{type});
		$tb -> ok (scalar @type, "type $dispatch{type} found in " . join (", ", @$typesdb));

=item * The key C<values> must be an array reference and the number of elements must match its data type in module's configuration option C<types.db>.

=cut

		my $vref = ref $dispatch{values};
		$tb -> is_eq ($vref, "ARRAY", "values is ARRAY");
		$tb -> is_eq(scalar @{$dispatch{values}}, scalar @type, "number of dispatched 'values' matches type spec for '$dispatch{type}'");

		my $i=0;
		for (@{$dispatch{values}}) {
			$tb -> ok (defined $_, "value $i for $dispatch{plugin} ($dispatch{type}) is defined");
			$i++;
		}

=item * All other keys must be scalar strings with at most 63 characters: C<plugin>, C<type>, C<host>, C<plugin_instance> and C<type_instance>.

=cut

		for (qw(plugin type host plugin_instance type_instance)) {
			if (exists $dispatch{$_}) {
				my $ref = ref $dispatch{$_};
				$tb -> is_eq ($ref, "", "$_ is SCALAR");
				$tb -> cmp_ok(length $dispatch{$_}, '<', 63, "$_ is valid") if $dispatch{$_};
			}
		}

=item * The keys C<time> and C<interval> must be a positive integers.

=cut

		for (qw(time interval)) {
			if (exists $dispatch{$_}) {
				$tb -> cmp_ok($dispatch{$_},'>',0,"$_ is valid");
			}
		}

=item * The keys C<host>, C<plugin_instance> and C<type_instance> may use all ASCII characters except "/".

=cut

		for (qw/host plugin_instance type_instance/) {
			if (exists $dispatch{$_}) {
				$tb -> unlike($dispatch{$_}, qr/\//, "$_ valid");
			}
		}

=item * The keys C<plugin> and C<type> may use all ASCII characters except "/" and "-".

=cut

		for (qw/plugin type/) {
			if (exists $dispatch{$_}) {
				$tb -> unlike($dispatch{$_}, qr/[\/-]/, "$_ valid");
			}
		}

=back

=cut

	}
}); # end subtest
}

=head2 read_config_ok <$module> <$plugin> <$config> [$message]

Same as L<read_ok> but also reads configuration from $plugin_config and fires up the configuration callback of plugin $plugin_module. L<Test::Collectd::Config/parse> will kindly format a configuration file or handle to suit this subroutine.

=cut

sub read_config_ok ($$$;$) {
	my $module = shift;
	my $plugin = shift;
	my $config = shift;
	my $msg = shift || "read with config OK";

	my $tb = __PACKAGE__->builder;
	$tb -> subtest($msg, sub {
			$tb -> plan ( tests => 3 );
			$tb -> ok (_load_module($module), "load plugin module");
			$tb -> ok (_config($plugin,$config),"config ok") or $tb -> diag ($@);
			read_ok ($module,$plugin,$msg);
		}
	);
}


=head2 read_values (module, plugin, [ config ])

Returns arrayref containing the list of arguments passed to L<Collectd/plugin_dispatch_values>. Example:

 [
  # first call to L<Collectd/plugin_dispatch_values>
  [
   { plugin => "myplugin", type => "gauge", values => [ 1 ] },
  ],
  # second call to L<Collectd/plugin_dispatch_values>
  [
   { plugin => "myplugin", type => "gauge", values => [ 2 ] },
  ],
 ]

A config hash can be provided for plugins with a config callback. The format of this hash must be the same as the one described in C<collectd-perl>'s manpage (grep for "Config-Item").
Use L<Test::Collectd::Config/parse> for conveniently yielding such a hash from a collectd configuration file. Only the section concerning the plugin should be provided, e.g. without all global collectd config sections.

=cut

sub read_values ($$;$) {
	my $module = shift;
	my $plugin = shift;
	my $config = shift;
	_load_module($module);
	_init_plugin($plugin);
	# plugin with config callback
	if ($config) {
		_config($plugin,$config);
			#unless (ref $config eq "HASH") {
			#croak "third param to read_values must be a valid config hash";
			#}
			#my $cb = $FakeCollectd{$plugin}->{Callback}->{Config};
			#unless ($cb) {
			#croak "plugin $plugin does not provide a config callback";
			#}
			## this fires up the plugin's config callback with provided config
			#eval {no strict "refs"; &$cb($config)} or croak("config callback $cb failed: $@");
	}
	#
	my $reader = $FakeCollectd{$plugin}->{Callback}->{Read};
	return unless $reader;
	_reset_values($plugin);
	eval "$reader()";
	return if $@;
	if (exists $FakeCollectd{$plugin}->{Values}) {
		@{$FakeCollectd{$plugin}->{Values}};
	} else {
		return;
	}
}

sub _get_type {
	my $type = shift;
	if ($typesdb) {
		my $ref = ref $typesdb;
		if ($ref eq "HASH") {
			warn "typesdb is a hash, discarding its keys";
			$typesdb = [values %$typesdb];
		} elsif ($ref eq "") {
			$typesdb = [ $typesdb ];
		}
	} else {
		require File::ShareDir;
		$typesdb = [ File::ShareDir::module_file(__PACKAGE__, "types.db") ];
		 warn "no typesdb - using builtin ", join ", ", @$typesdb;
	}
	for my $file (@$typesdb) {
		my $fh = IO::File -> new($file, "r");
		unless ($fh) {
			cluck "Error opening types.db: $!";
			return undef;
		}
		while (<$fh>) {
			my ($t, @ds) = split /\s+/, $_;
			if ($t eq $type) {
				my @ret;
				for (@ds) {
					my @stuff = split /:/;
					push @ret, {
						ds   => $stuff[0],
						type => $stuff[1],
						min  => $stuff[2],
						max  => $stuff[3],
					};
				}
				return @ret;
			}
		}
	}
	return ();
}

=head1 CAVEATS

=head2 FakeCollectd

This module tricks the tested collectd plugins into loading L<FakeCollectd> instead of L<Collectd>, and replaces calls thereof by simple functions which populate the %FakeCollectd:: hash in order to store its arguments. As it uses the name of the calling plugin module for its symbols, subsequent calls to the test subs are not really independant, which is suboptimal especially for a test module. If you have a saner solution to do this, please let me know.

=head2 methods

Replacements for most common L<Collectd::Plugins> methods are implemented, as well as constants. We may have missed some or many, and as new ones are added to the main collectd tree, we will have to keep up to date.

=head2 config

Although L<Test::Collectd::Config/parse> has been a straight port of C<liboconfig> (which itself is using C<lex/yacc>) to L<Parse::Yapp>/L<Parse::Lex>, you might get different results in edge cases.

=head2 types.db

If no types.db list is being specified during construction, the object will try to use the shipped version.
Also, if a list is given, the first appearance of the type will be used; this may differ from collectd's mechanism.

=head2 SEE ALSO

L<FakeCollectd>, L<http://collectd.org/wiki/index.php/Naming_schema>

=head1 AUTHOR

Fabien Wernli, C<< <wernli_workingat_in2p3.fr> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/faxm0dem/Test-Collectd-Plugins/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Collectd::Plugins

You can also look for information at:

=over 4

=item * Github: https://github.com/faxm0dem/Test-Collectd-Plugins

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Collectd-Plugins>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Collectd-Plugins>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Collectd-Plugins>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Collectd-Plugins/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Fabien Wernli.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Collectd::Plugins

