package PHP::MySource::Session;
$VERSION = 0.03;

use strict;
use vars qw( $AUTOLOAD );

use Carp;
use Data::Dumper;
use PHP::Session;

sub new
{
	my ($class, %args) = @_;

	bless
		{	_mysource_root	=> $args{'mysource_root'}	|| croak('You must supply your MySource installation directory.'),
			_mysource_cache	=> $args{'mysource_cache'}	|| $args{'mysource_root'} . '/cache',
			_session_id		=> $args{'session_id'}		|| croak('You must supply a MySource session id.'),
			_session_obj	=> new PHP::Session($args{'session_id'}, {save_path=>$args{'mysource_cache'}	|| $args{'mysource_root'} . '/cache'})
		}, $class;
}

{

	my %_attrs =
		(	_mysource_root	=> 'read',
			_mysource_cache	=> 'read',
			_session_id		=> 'read'
		);

	sub _accessible
	{
		my ($self, $attr, $mode) = @_;
		no warnings;
		$_attrs{$attr} =~ /$mode/;
		use warnings;
	}
}

{
	my %_parent_attrs =
		(
			registered_name	=> 'read',
			editor_pages	=> 'read',
			print_errors	=> 'read',
			result_message	=> 'read',
			user			=> 'read',
			external_vars	=> 'read',
			error_call		=> 'read',
			login_attempts	=> 'read',
			access_groups	=> 'read',
			error_msg		=> 'read',
			login_key		=> 'read',
			last_access		=> 'read'
		);

	sub _parent_accessible
	{
		my ($self, $attr, $mode) = @_;
		no warnings;
		$_parent_attrs{$attr} =~ /$mode/;
		use warnings;
	}
}

sub is_logged_in
{
	my $self = shift;

	$self->{'_session_obj'}->{'_data'}->{'SESSION'}->{'user'};
}

# Just dump out all of the Session variables
sub dump
{
	my $self = shift;

	Dumper($self->{'_session_obj'}->{'_data'}->{'SESSION'});
}

sub AUTOLOAD
{
	no strict "refs";
	my ($self, $newval) = @_;

	# was a get method called?
	if ($AUTOLOAD =~ /.*::get(_\w+)/ && $self->_accessible($1, 'read'))
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
		return $self->{$attr_name};
	}

	# was a set method called?
	if ($AUTOLOAD =~ /.*::set(_\w+)/ && $self->_accessible($1, 'write'))
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
		$self->{$1} = $newval;
		return
	}

	# was a get method called on the parent obj?
	if ($AUTOLOAD =~ /.*::get_(\w+)/ && $self->_parent_accessible($1, 'read'))
	{
		my $attr_name = $1;
		#print $self->{'_session_obj'}->{"_data"}->{'SESSION'}->{$attr_name};
		*{$AUTOLOAD} = sub { return $_[0]->{'_session_obj'}->{'_data'}->{'SESSION'}->{$attr_name} };
		return $self->{'_session_obj'}->{'_data'}->{'SESSION'}->{$attr_name};
	}

	# was a set method called on the parent obj?
	if ($AUTOLOAD =~ /.*::set_(\w+)/ && $self->_parent_accessible($1, 'write'))
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { $_[0]->{'_session_obj'}->{'_data'}->{'SESSION'}->{$attr_name} = $_[1]; return };
		$self->{'_session_obj'}->{'_data'}->{'SESSION'}->{$1} = $newval;
		return
	}

	croak ("No such method: $AUTOLOAD");

}

sub DESTROY
{
	# nothing to do but make AUTOLOAD happy
}

1;
__END__

=head1 NAME

PHP::MySource::Session - read / write MySource PHP session files

=head1 SYNOPSIS

  use PHP::MySource::Session;

  my $session =
  PHP::MySource::Session->new
  (    mysource_root=>"/mysource/root",
       session_id=>"01234567890abcdef01234567890abcd"
  );

  # see if this user is logged in
  my $foo = $session->is_logged_in();

  my $foo = $session->get_registered_name();

  my $foo = $session->get_editor_pages();

  my $foo = $session->get_print_errors();

  my $foo = $session->get_result_message();

  my $foo = $session->get_user();

  my $foo = $session->get_external_vars();

  my $foo = $session->get_error_call();

  my $foo = $session->get_login_attempts();

  my $foo = $session->get_access_groups();

  my $foo = $session->get_error_msg();

  my $foo = $session->get_login_key();

  my $foo = $session->get_last_access();

  # Just dump out all of the Session variables
  print $session->dump();

=head1 DESCRIPTION

PHP::MySource::Session provides a way to read variables from PHP4
session files created by version 2.8.2 of the MySource content
management system.

MySource is available at http://mysource.squiz.net. The author
of this module has no affiliation with MySource other than being
a happy customer.

=head1 OPTIONS

MySource saves PHP4 session files to the "cache" directory under
the MySource root directory by default. If the cache directory
is located somewhere else or named differently, you can pass
mysource_cache to the constructor method.

=head1 NOTES

=over 4

=item *

This is very basic and is based on gross assumptions of how
MySource works. As I have time, I will hopefully be able to
refine these assumptions.

=back

=head1 TODO

=over 4

=item *

Allow "set" methods

=item *

Create methods that do more than just retrieve and save
variables (i.e. is_logged_in, get_acess_groups)

=back

=head1 AUTHOR

Dave Homsher, II <dave@homsher.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<PHP::Session manpage>

=cut