package Rose::DBx::Bouquet::Config;

use strict;
use warnings;

require Exporter;

use Carp;
use Config::IniFiles;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rose::DBx::Bouquet::Config ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.04';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_verbose => 0,
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

}	# End of Encapsulated class data.

# -----------------------------------------------

sub get_exclude
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'exclude');

} # End of get_exclude.

# -----------------------------------------------

sub get_output_dir
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'output_dir');

} # End of get_output_dir.

# -----------------------------------------------

sub get_tmpl_path
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'tmpl_path');

} # End of get_tmpl_path.

# -----------------------------------------------

sub get_verbose
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'verbose');

} # End of get_verbose.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	my($name) = '.htrose.bouquet.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|Rose/DBx/Bouquet/Config.pm|);

		($path = $INC{$_}) =~ s/Config.pm/$name/;
	}

	$$self{'config'}  = Config::IniFiles -> new(-file => $path);
	$$self{'section'} = 'Rose::DBx::Bouquet';

	if (! $$self{'config'} -> SectionExists($$self{'section'}) )
	{
		Carp::croak "Config file '$path' does not contain the section [$$self{'section'}]";
	}

	return $self;

}	# End of new.

# --------------------------------------------------

1;

=head1 NAME

C<Rose::DBx::Bouquet::Config> - A helper for Rose::DBx::Bouquet

=head1 Synopsis

	See docs for Rose::DBx::Bouquet.

=head1 Description

C<Rose::DBx::Bouquet::Config> is a pure Perl module.

See docs for C<Rose::DBx::Bouquet>.

=head1 Constructor and initialization

Auto-generated code will create objects of type C<Rose::DBx::Bouquet::Config>. You don't need to.

=head1 Method: get_exclude()

Return the value of 'exclude' from the config file lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

=head1 Method: get_output_dir()

Return the value of 'output_dir' from the config file lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

=head1 Method: get_tmpl_path()

Return the value of 'tmpl_path' from the config file lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

=head1 Method: get_verbose()

Return the value of 'verbose' from the config file lib/Rose/DBx/Bouquet/.htrose.bouquet.conf.

=head1 Author

C<Rose::DBx::Bouquet::Config> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
