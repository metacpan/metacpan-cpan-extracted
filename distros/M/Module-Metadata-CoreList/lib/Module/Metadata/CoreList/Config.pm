package Module::Metadata::CoreList::Config;

use Config::Tiny;

use File::HomeDir;

use Hash::FieldHash ':all';

use Path::Class;

fieldhash my %config           => 'config';
fieldhash my %config_file_path => 'config_file_path';
fieldhash my %section          => 'section';

our $VERSION = '1.07';

# -----------------------------------------------

sub init
{
	my($self, $arg)         = @_;
	$$arg{config_file_path} ||= Path::Class::file(File::HomeDir -> my_dist_config('Module-Metadata-CoreList'), '.htmodule.metadata.corelist.conf');

} # End of init.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;

	$class -> init(\%arg);

	my($self) = from_hash(bless({}, $class), \%arg);

	$self -> read($path);

	return $self;

} # End of new.

# -----------------------------------------------

sub read
{
	my($self) = @_;
	my($path) = $self -> config_file_path;

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );

	if (Config::Tiny -> errstr)
	{
		die Config::Tiny -> errstr;
	}

	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of read.

# --------------------------------------------------

1;

=head1 NAME

L<Module::Metadata::CoreList::Config> - Cross-check Build.PL/Makefile.PL with Module::CoreList

=head1 Synopsis

See L<Module::Metadata::CoreList/Synopsis>.

=head1 Description

L<Module::Metadata::CoreList::Config> is a pure Perl module.

It's a helper for L<Module::Metadata::CoreList>, to load the config file .htmodule.metadata.corelist.conf
from a directory found by L<File::HomeDir>.

The config file is shipped in the config/ directory of the distro, and is copied to its final destination
during installation of L<Module::Metadata::CoreList>. You can run scripts/copy.config.pl to copy the file
manually.

=head1 Constructor and initialization

new(...) returns an object of type L<Module::Metadata::CoreList::Config>.

This is the class's contructor.

Usage: C<< Module::Metadata::CoreList::Config -> new >>.

This method takes no options.

=head1 Methods

=head2 config()

Returns a hashref of config options. Used like this:

	my($config)        = Module::Metadata::CoreList::Config -> new -> config;
	my($template_path) = $$config{template_path};

=head1 Author

L<Module::Metadata::CoreList::Config> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
