package MyLibrary::Stylesheet;

use MyLibrary::DB;
use Carp qw(croak);
use strict;


=head1 NAME

MyLibrary::Stylesheet

=head1 SYNOPSIS

	# require the necessary module
	use MyLibrary::Stylesheet;

	# create an undefined Stylesheet object
	my $stylesheet = MyLibrary::Stylesheet->new();

	# get stylesheet id
	my $stylesheet_id = $stylesheet->stylesheet_id();

	# set the attributes for the stylesheet
	$stylesheet->stylesheet_name('Gothic');
	$stylesheet->stylesheet_description('Dark colors, gothic script.');
	$stylesheet->stylesheet('CSS code');

	# commit stylesheet to database
	$stylesheet->commit();

	# get a list of stylesheet objects
	my @stylesheets = MyLibrary::Stylesheet->get_stylesheets();
	my @stylesheets = MyLibrary::Stylesheet->get_stylesheets(sort => 'name');

	# delete a stylesheet from the database
	$stylesheet->delete();

=head1 DESCRIPTION

This module simply allows for the creation and maniuplation of HTML CSS stylesheets. These stylesheets will be used to present data in various contexts throught the browser medium. It also allows for association of stylesheets with patron objects so that patrons can select various styles for the presentation of MyLibrary data. Stylesheets could also be used to syndicate content to other venues and can help to separate style and presentation from content.

=head1 METHODS

=head2 new()

This class method is the constructor for this package. The method is responsible for initializing all attributes associated with a
 given Stylesheet object. The method can also be used to create a Stylesheet object using stylesheet id or name. The stylesheet would thus need to already exist in the database for these parameters to have any effect.

=head2 stylesheet_id()

This method is used exclusively to retrieve an exising stylesheet object id. This method will only return a valid id if the stylesheet has been commited to the database. This accessor method cannot set a stylesheet id.

	# get stylesheet id
	my $stylesheet_id = $stylesheet->stylesheet_id();

=head2 stylesheet_name()

This accessor method simply sets and gets the name of the stylesheet.

	# set the stylesheet name
	$stylesheet->stylesheet_name('Gothic');
	
	# get the stylesheet name
	my $style_name = $stylesheet->stylesheet_name();

=head2 stylesheet_note()

Set or get the stylesheet note. This text will be used to describe the stylesheet in question.

	# set the stylesheet note
	$stylesheet->stylesheet_note('This style is slightly gothic with medieval overtones.');

	# get the stylesheet note
	my $style_desc = $stylesheet->stylesheet_note();

=head2 stylesheet()

Depending upon how you want your application to function, the content of this attribute can be either a pointer to a stylesheet located external to the database or it can be the text of a stylesheet itself.

	# set the stylesheet content
	$stylesheet->stylesheet('CONTENT');

	# retrieve the stylesheet content
	my $stylesheet = $stylesheet->stylesheet();

=head2 get_stylesheets()

This class method should be used to retrieve a list of all of the stylesheet object ids from the database. The list can be sorted according to stylesheet name. The sort parameter is optional. A default stylesheet should always be present in the database with a stylesheet id of '0'. This stylesheet is used if no other stylesheet has been created.

	# get a sorted list of stylesheets
	my @stylesheet_ids = MyLibrary::Stylesheet->get_stylesheets(sort => 'name');

=head2 commit()

Save the stylesheet to the database.

	# commit the stylesheet
	$stylesheet->commit();

=head2 delete()

Delete the stylesheet from the database.

	# delete the stlyesheet
	$stylesheet->delete();


=head1 SEE ALSO

For more information, see the MyLibrary home page: http://dewey.library.nd.edu/mylibrary/.

=head1 AUTHORS

Robert Fox <rfox2@nd.edu>

=cut

sub new {

	my ($class, %opts) = @_;
	my $self = {};

	# check for an id
	if ($opts{id}) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM stylesheets WHERE stylesheet_id = ?', undef, $opts{id});
		if (ref($rv) eq "HASH") { $self = $rv }
		else { return }

	# check for username
	} elsif ($opts{name}) {

		# get a record based on this username
		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM stylesheets WHERE stylesheet_name = ?', undef, $opts{name});
		if (ref($rv) eq "HASH") { $self = $rv }
		else { return }

	}

	# return the object
	return bless $self, $class;

}

sub stylesheet_name {

	my ($self, $name) = @_;
	if ($name) { $self->{stylesheet_name} = $name; }
	else { return $self->{stylesheet_name} }

}

sub stylesheet_description {

	my ($self, $desc) = @_;
	if ($desc) { $self->{stylesheet_description} = $desc; }
	else { return $self->{stylesheet_description} }

}

sub stylesheet {
	
	my ($self, $sheet) = @_;
	if ($sheet) { $self->{stylesheet} = $sheet; }
	else { return $self->{stylesheet} }
}

sub stylesheet_id {

	my $self = shift;
	return $self->{stylesheet_id};

}

sub commit {

	my $self = shift;
	my $dbh = MyLibrary::DB->dbh();

	if ($self->stylesheet_id()) {

		my $return = $dbh->do('UPDATE stylesheets SET stylesheet_name = ?, stylesheet_description = ?, stylesheet = ? WHERE stylesheet_id =?', undef, $self->{stylesheet_name}, $self->{stylesheet_description}, $self->{stylesheet}, $self->{stylesheet_id});

		if ($return > 1 || ! $return) { croak "Stylesheet update in commit() failed. $return records were updated."; }
	
	} else {

		my $id = MyLibrary::DB->nextID();
		my $return = $dbh->do('INSERT INTO stylesheets (stylesheet_id, stylesheet_name, stylesheet_description, stylesheet) VALUES (?,?,?,?)', undef, $id, $self->stylesheet_name(), $self->stylesheet_description(), $self->stylesheet());
		if ($return > 1 || ! $return) { croak 'Stylesheet commit() failed.'; }
		$self->{stylesheet_id} = $id;

	}

	return 1;

}

sub get_stylesheets {

	my $class = shift;
	my %opts = @_;
	my @rf = ();
	
	my $sort;
	if (defined($opts{'sort'})) {
		if ($opts{'sort'} eq 'name') {
			$sort = 'stylesheet_name';
		}
	}

	my $dbh = MyLibrary::DB->dbh();
	my @stylesheet_ids = ();
	if ($opts{'sort'}) {
		my $stylesheet_ids = $dbh->selectcol_arrayref('SELECT stylesheet_id FROM stylesheets ORDER BY stylesheet_name');
		@stylesheet_ids = @{$stylesheet_ids};
	} else {
		my $stylesheet_ids = selectcol_arrayref('SELECT stylesheet_id FROM stylesheets');
		@stylesheet_ids = @{$stylesheet_ids};
	}	

	return @stylesheet_ids;
}

sub delete {

	my $self = shift;

	if ($self->stylesheet_id()) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->do('DELETE FROM stylesheets WHERE stylesheet_id = ?', undef, $self->{stylesheet_id});
		my @patron_ids = $dbh->selectcol_arrayref('SELECT patron_id FROM patrons WHERE patron_stylesheet_id = ?', undef, $self->{stylesheet_id}); 
		if (scalar(@patron_ids) >= 1) {
			my $patron_id_string = join(', ', split(/ /, @patron_ids));
			my $rv = $dbh->do("UPDATE patrons SET patron_stylesheet_id = ? WHERE patron_id IN ($patron_id_string)", undef, $self->{stylesheet_id});
		}

		return 1;
	}

	return 0;
}

1;	
