package Perl::Dist::WiX::Fragment::StartMenu;

=pod

=head1 NAME

Perl::Dist::WiX::Fragment::StartMenu - A <Fragment> tag that handles the Start menu.

=head1 VERSION

This document describes Perl::Dist::WiX::Fragment::StartMenu version 1.500.

=head1 SYNOPSIS

	my $fragment = Perl::Dist::WiX::Fragment::StartMenu->new(
		directory_id => 'D_App_Menu',
	);
	
	$fragment->add_shortcut(
		name        => 'CPAN',
		description => 'CPAN Shell (used to install modules)',
		target      => "[D_PerlBin]cpan.bat",
		id          => 'CpanShell',
		working_dir => PerlBin,
		icon_id     => 'I_CpanBat',
	);

=head1 DESCRIPTION

This object represents a Start Menu directory, and creates the tags required 
so that the Start Menu is created when the .msi is installed.

=cut

use 5.010;
use Moose 0.90;
use MooseX::Types::Moose qw( Str Bool HashRef );
use Perl::Dist::WiX::Types qw( DirectoryRef );
use WiX3::Exceptions;
use Perl::Dist::WiX::IconArray qw();
use Perl::Dist::WiX::DirectoryTree qw();
use Perl::Dist::WiX::Tag::DirectoryRef qw();
use WiX3::XML::Component qw();
use WiX3::XML::CreateFolder qw();
use WiX3::XML::RemoveFolder qw();
use WiX3::XML::DirectoryRef qw();
use WiX3::XML::Shortcut qw();

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

extends 'WiX3::XML::Fragment';
with 'WiX3::Role::Traceable';

=head1 METHODS

This class inherits from L<WiX3::XML::Fragment|WiX3::XML::Fragment> 
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Fragment::StartMenu> object.

It inherits all the parameters described in the 
L<< WiX3::XML::Fragment->new()|WiX3::XML::Fragment/new >> 
method documentation.

If the C<id> parameter is omitted, it defaults to C<'StartMenuIcons'>.

=head3 icons

The C<icons> parameter is a 
L<Perl::Dist::WiX::IconArray|Perl::Dist::WiX::IconArray> object containing 
the icons that have already been used.

New icons created for this fragment are added to this IconArray object.

=cut



has icons => (
	is      => 'ro',
	isa     => 'Perl::Dist::WiX::IconArray',
	default => sub { return Perl::Dist::WiX::IconArray->new() },
	reader  => 'get_icons',
);



has _roots => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => HashRef [DirectoryRef],
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		'_get_root'    => 'get',
		'_root_exists' => 'exists',
		'_set_root'    => 'set',
	},
);



sub _build_root {
	my $self         = shift;
	my $directory_id = shift;

	# Get the directory object so we can create a reference to it.
	my $tree      = Perl::Dist::WiX::DirectoryTree->instance();
	my $directory = $tree->get_directory_object($directory_id);
	if ( not defined $directory ) {
		PDWiX->throw(
			"Could not find directory object for id $directory_id");
	}
	my $root = Perl::Dist::WiX::Tag::DirectoryRef->new($directory);

	# Add the component that removes the start menu folder.
	my $remove = WiX3::XML::RemoveFolder->new(
		id => 'RF_' . $directory_id,
		on => 'uninstall',
	);
	my $remove_component =
	  WiX3::XML::Component->new( id => 'RF_' . $directory_id, );

	# Get the start of the tree right.
	$remove_component->add_child_tag($remove);
	$root->add_child_tag($remove_component);
	$self->add_child_tag($root);

	$self->_set_root( $directory_id => $root );

	return 1;
} ## end sub _build_root



=head2 get_icons

Returns the C<icons> parameter that was passed in to new.

This object may have been changed since it was passed in.

=cut



# Called by Moose::Object->new()
sub BUILDARGS {
	my $class = shift;
	my %args;

	# Process out arguments.
	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw( 'Parameters incorrect (not a hashref '
			  . 'or hash) for ::Fragment::StartMenu' );
	}

	# Set our default id.
	if ( not exists $args{'id'} ) {
		$args{'id'} = 'StartMenuIcons';
	}

	return \%args;
} ## end sub BUILDARGS



=head2 add_shortcut

	$fragment->add_shortcut(
		name         => 'CPAN',
		description  => 'CPAN Shell (used to install modules)',
		target       => "[D_PerlBin]cpan.bat",
		id           => 'CpanShell',
		working_dir  => 'D_PerlBin',
		icon_id      => 'I_CpanBat',
		directory_id => 'D_App_Menu_Tools',
	);

This method creates the tag objects that represent a Start Menu shortcut, 
and attaches them to this fragment.

The C<name> and C<description> parameters are the name and the comment of 
the shortcut being created, the C<target> is the command to be executed,
the C<working_dir> is the ID of the working directory of the shortcut,
the C<icon_id> is the ID of the icon to be used with this shortcut, 
the C<id> is the ID of the shortcut itself, and the C<directory_id> is
the ID for the directory that the shortcut is going to go into.

The C<name>, C<target>, C<working_dir>, and C<id> parameters are required.
(C<description> defaults to being empty, C<directory_id> defaults to 
'D_App_Menu', and a missing C<icon_id> allows Windows to follow its default 
rules for choosing an icon to display.)

=cut

sub add_shortcut {
	my $self = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = (@_);
	} else {
		PDWiX->throw( 'Parameters incorrect (not a hashref or hash) '
			  . 'for ::Fragment::StartMenu->add_shortcut()' );
	}

	# Check that the arguments exist.
	if ( not defined $args{id} ) {
		PDWiX::Parameter->throw(
			parameter => 'id',
			where     => 'P::D::W::Fragment::StartMenu->add_shortcut'
		);
	}
	if ( not defined $args{name} ) {
		PDWiX::Parameter->throw(
			parameter => 'name',
			where     => 'P::D::W::Fragment::StartMenu->add_shortcut'
		);
	}
	if ( not defined $args{target} ) {
		PDWiX::Parameter->throw(
			parameter => 'target',
			where     => 'P::D::W::Fragment::StartMenu->add_shortcut'
		);
	}
	if ( not defined $args{working_dir} ) {
		PDWiX::Parameter->throw(
			parameter => 'working_dir',
			where     => 'P::D::W::Fragment::StartMenu->add_shortcut'
		);
	}

	$args{directory_id} ||= 'D_App_Menu';

	if ( not $self->_root_exists( $args{directory_id} ) ) {
		$self->_build_root( $args{directory_id} );
	}

	# "Fix" the ID to have only identifier characters.
	$args{id} =~ s{[[:^alnum:]]}{_}msgx;

	# Start creating tags.
	my $icon_id = undef;
	if ( defined $args{icon_id} ) {
		$icon_id = "I_$args{icon_id}";
	}
	my $component = WiX3::XML::Component->new( id => "S_$args{id}" );
	my $shortcut = WiX3::XML::Shortcut->new(
		id               => $args{id},
		name             => $args{name},
		description      => $args{description},
		target           => $args{target},
		icon             => $icon_id,
		workingdirectory => $args{working_dir},
	);
	$component->add_child_tag($shortcut);
	my $cf =
	  WiX3::XML::CreateFolder->new( directory => $args{directory_id} );
	$component->add_child_tag($cf);
	$self->_get_root( $args{directory_id} )->add_child_tag($component);

	return;
} ## end sub add_shortcut

# The fragment is already generated. No need to regenerate.
sub _regenerate { ## no critic(ProhibitUnusedPrivateSubroutines)
	return;
}

# No duplicates will be here to check.
sub _check_duplicates { ## no critic(ProhibitUnusedPrivateSubroutines)
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
