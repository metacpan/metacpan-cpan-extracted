package MyLibrary::Interface::Admin;

use MyLibrary::DB;
use base qw(MyLibrary::Interface);
use Carp qw(croak);
use strict;

my $dbh = MyLibrary::DB->dbh();

=head1 NAME

MyLibrary::Interface::Admin

=head1 SYNOPSIS

	use MyLibrary::Interface::Admin;

=head1 DESCRIPTION

Modular admin interface components for MyLibrary.

=head1 EXPORT

Few methods will be exported.

=head1 METHODS

Most of the methods employed here are class methods. However, class objects are created with 
embedded attributes.

=head1 edit_html(\%attr)

=cut

sub edit_interface {
	my $q = qq(SELECT * FROM interface WHERE name='edit_html');
	my $interface = $dbh->selectrow_hashref($q);
	my ($class, %opts) = @_;
	my @names = @{get_interface_names()};
	if ($opts{interface_name}) {
		my $q = qq(SELECT * FROM interface where name='$opts{interface_name}');
		$opts{interface_text} = $dbh->selectrow_hashref($q)->{'html'};
		$opts{interface_text} =~ s/</&lt;/g;
		$opts{interface_text} =~ s/>/&gt;/g;
		$opts{interface_options} = $dbh->selectrow_hashref($q)->{'options'};
		$opts{interface_id} = $dbh->selectrow_hashref($q)->{'interface_id'};
	} 
	my $self = {
		interface_name => undef,
		interface_text => undef,
		interface_options => undef,
		html => $interface->{'html'},
		name_menu => 1,
		names => [@names],
		%opts 
	};
	return bless $self, $class;
} # end sub edit_html

=head1 define_interface(\%attr)

This is a constructor method which can be used to create the vital attributes
of an interface object. These attributes are then subsumed when the edit_html
constructor is called. Use this method to directly manipulate the attributes
of the interface being called.

=cut


sub define_interface {
	my ($class, %opts) = @_;
	my $self = {
		interface_id => undef,
		interface_name => undef,
		interface_text => undef,
		interface_options => undef,
		%opts
	};
	return bless $self, $class;
}

=head1 interface_text()

=cut

sub interface_text {
	my ($self, $interface_text) = @_;
	if ($interface_text) {
		$self->{interface_text} = $interface_text;
	} else {
		return $self->{interface_text};
	}
}

sub html {
	my ($self, $html) = @_;
	if ($html) {
		$self->{html} = $html;
	} else {
		return $self->{html};
	}
}

=head1 interface_name()

=cut

sub interface_name {
        my ($self, $interface_name) = @_;
        if ($interface_name) {
                $self->{interface_name} = $interface_name;
        } else {
                return $self->{interface_name};
        }
}

=head1 get_interface_names(\%attr)

=cut

sub get_interface_names {
	my $q = qq(SELECT name FROM interface);
	my $ary_ref = $dbh->selectcol_arrayref($q);
	return $ary_ref;
}

=head1 commit_interface()

This method can be used to either update the definition of an interface or
creat a new interface.

	# create and commit a new interface (use the interface() constructor method)
	$interface = $MyLibrary::Interface::Admin->interface(interface_name => $name, interface_text => $html);
	$interface->commit_interface();

	# update the values of an existing interface
	

=cut

sub commit_interface {
	my $self = shift;
	if ($self->{interface_id}) {
		$self->{interface_text} =~ s/&lt;/</g;
		$self->{interface_text} =~ s/&gt;/>/g;
		my $return = $dbh->do('UPDATE interface SET html = ?, options = ? WHERE interface_id = ?', undef, $self->{interface_text}, $self->{interface_options}, $self->{interface_id});
		if ($return != 1) { croak 'commit_interface() failed.'; }
	} else {
		my $id = MyLibrary::DB->nextID();
		my $return = $dbh->do('INSERT INTO interface (interface_id, name, html, options) VALUES (?, ?, ?, ?)', undef, $id, $self->{interface_name}, $self->{interface_text}, $self->{interface_options});	
		if ($return != 1) { croak 'commit_interface() failed.'; }
		$self->{interface_id} = $id;
	}
	return 1;
}

1;
