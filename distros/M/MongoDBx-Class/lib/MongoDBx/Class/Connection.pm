package MongoDBx::Class::Connection;

# ABSTARCT: A connection to a MongoDB server

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Module::Load;
use version;

if (version->parse($MongoDB::VERSION) < v0.502.0) { 
	extends 'MongoDB::Connection';
} else {
	extends 'MongoDB::MongoClient';
}

=head1 NAME

MongoDBx::Class::Connection - A connection to a MongoDB server

=head1 VERSION

version 1.030002

=head1 EXTENDS

L<MongoDB::Connection>

=head1 SYNOPSIS

	# connect to a MongoDB server
	my $conn = $mongodbx->connect(host => '10.10.10.10', port => 27017);

	# the connection object is automatically saved to the 'conn'
	# attribute of the L<MongoDBx::Class> object (C<$mongodbx> above)

	$conn->get_database('people');

=head1 DESCRIPTION

MongoDBx::Class::Connection extends L<MongoDB::Connection>. This class
provides the document expansion and collapsing methods that are used
internally by other MongoDBx::Class classes.

Note that a L<MongoDBx::Class> object can only have one connection at a
time. Connection is only made via the C<connect()> method in MongoDBx::Class.

=head1 ATTRIBUTES

Aside for attributes provided by L<MongoDB::Connection>, the following
special attributes are added:

=head2 namespace

A string representing the namespace of document classes to load (e.g.
MyApp::Schema). This is a required attribute (automatically received from
the MongoDBx::Class object).

=head2 doc_classes

A hash-ref of document classes loaded. This is a required attribute
(automatically received from the MongoDBx::Class object).

=head2 safe

A boolean value indicating whether to use safe operations (e.g. inserts
and updates) by default - without the need to pass C<< { safe => 1 } >> to
relevant methods - or not. False by default.

=head2 is_backup

This boolean attribute is used by L<MongoDBx::Class::ConnectionPool> objects
that use a backup connection.

=cut

has 'namespace' => (is => 'ro', isa => 'Str', required => 1);

has 'doc_classes' => (is => 'ro', isa => 'HashRef', required => 1);

has 'safe' => (is => 'rw', isa => 'Bool', default => 0);

has 'is_backup' => (is => 'ro', isa => 'Bool', default => 0);

=head1 OBJECT METHODS

Aside from the methods provided by L<MongoDB::Connection>, the following
methods and modifications are added:

=head2 get_database( $name )

Returns a L<MongoDBx::Class::Database> object representing the MongoDB
database named C<$name>.

=cut

override 'get_database' => sub {
	my $conn_key = version->parse($MongoDB::VERSION) < v0.502.0 ? '_connection' : '_client';

	MongoDBx::Class::Database->new($conn_key => shift, name => shift);
};

=head2 safe( $boolean )

Overrides the current value of the safe attribute with a new boolean value.

=head2 expand( $coll_ns, \%doc )

Receives the full name (a.k.a namespace) of a collection (that is the database
name, followed by a dot, and the collection name), and a document hash-ref,
and attempts to expand it according to the '_class' attribute that should
exist in the document. If it doesn't exist, the document is returned as
is.

This is mostly used internally and you don't have to worry about expansion,
it's done automatically.

=cut

sub expand {
	my ($self, $coll_ns, $doc) = @_;

	# make sure we've received the namespace and a hash-ref document
	return unless $coll_ns && $doc && ref $doc eq 'HASH';

	# extract the database name and the collection name from the namespace
	my ($db_name, $coll_name) = ($coll_ns =~ m/^([^.]+)\.(.+)$/);

	# get the collection
	my $coll = $self->get_database($db_name)->get_collection($coll_name);

	# return the document as is if it doesn't have a _class attribute
	return $doc unless $doc->{_class};

	# remove the schema namespace from the document class (we do not
	# use the full package name internally) and attempt to find that
	# document class. return the document as is if class isn't found
	my $dc_name = $doc->{_class};
	my $ns = $self->namespace;
	$dc_name =~ s/^${ns}:://;

	my $dc = $self->doc_classes->{$dc_name};

	return $doc unless $dc;

	# start building the document object
	my %attrs = (
		_collection => $coll,
		_class => $doc->{_class},
	);

	foreach ($dc->meta->get_all_attributes) {
		# is this a MongoDBx::Class::Reference?
		if ($_->{isa} eq 'MongoDBx::Class::CoercedReference') {
			my $name = $_->name;
			$name =~ s!^_!!;
			
			next unless exists $doc->{$name} &&
				    defined $doc->{$name} && 
				    ref $doc->{$name} eq 'HASH' &&
				    exists $doc->{$name}->{'$ref'} &&
				    exists $doc->{$name}->{'$id'};

			$attrs{$_->name} = MongoDBx::Class::Reference->new(
				_collection => $coll,
				_class => 'MongoDBx::Class::Reference',
				ref_coll => $doc->{$name}->{'$ref'},
				ref_id => $doc->{$name}->{'$id'},
			);
		# is this an array-ref of MongoDBx::Class::References?
		} elsif ($_->{isa} eq 'ArrayOfMongoDBx::Class::CoercedReference') {
			my $name = $_->name;
			$name =~ s!^_!!;

			next unless exists $doc->{$name} &&
				    defined $doc->{$name} && 
				    ref $doc->{$name} eq 'ARRAY';

			foreach my $ref (@{$doc->{$name}}) {
				push(@{$attrs{$_->name}}, MongoDBx::Class::Reference->new(
					_collection => $coll,
					_class => 'MongoDBx::Class::Reference',
					ref_coll => $ref->{'$ref'},
					ref_id => $ref->{'$id'},
				));
			}
		# is this an embedded document (or array-ref of embedded documents)?
		} elsif ($_->documentation && $_->documentation eq 'MongoDBx::Class::EmbeddedDocument') {
			my $edc_name = $_->{isa};
			$edc_name =~ s/^${ns}:://;
			if ($_->{isa} =~ m/^ArrayRef/) {
				my $name = $_->name;
				$name =~ s!^_!!;
				
				$edc_name =~ s/^ArrayRef\[//;
				$edc_name =~ s/\]$//;

				next unless exists $doc->{$name} &&
					    defined $doc->{$name} && 
					    ref $doc->{$name} eq 'ARRAY';

				$attrs{$_->name} = [];

				foreach my $a (@{$doc->{$name}}) {
					$a->{_class} = $edc_name;
					push(@{$attrs{$_->name}}, $self->expand($coll_ns, $a));
				}
			} elsif ($_->{isa} =~ m/^HashRef/) {
				my $name = $_->name;
				$name =~ s!^_!!;
				
				$edc_name =~ s/^HashRef\[//;
				$edc_name =~ s/\]$//;

				next unless exists $doc->{$name} &&
					    defined $doc->{$name} && 
					    ref $doc->{$name} eq 'HASH';
				
				$attrs{$_->name} = {};
				
				foreach my $key (keys %{$doc->{$name}}) {
					$doc->{$name}->{$key}->{_class} = $edc_name;
					$attrs{$_->name}->{$key} = $self->expand($coll_ns, $doc->{$name}->{$key});
				}
			} else {
				next unless exists $doc->{$_->name} && defined $doc->{$_->name};
				$doc->{$_->name}->{_class} = $edc_name;
				$attrs{$_->name} = $self->expand($coll_ns, $doc->{$_->name});
			}
		# is this an expanded attribute?
		} elsif ($_->can('does') && $_->does('Parsed') && $_->parser) {
			next unless exists $doc->{$_->name} && defined $doc->{$_->name};
			load $_->parser;
			my $val = $_->parser->new->expand($doc->{$_->name});
			$attrs{$_->name} = $val if defined $val;
		# is this a transient attribute?
		} elsif ($_->can('does') && $_->does('Transient')) {
			next;
		# just pass the value as is
		} else {
			next unless exists $doc->{$_->name} && defined $doc->{$_->name};
			$attrs{$_->name} = $doc->{$_->name};
		}
	}

	return $dc->new(%attrs);
}

=head2 collapse( \%doc )

Receives a document hash-ref and returns a collapsed version of it such
that it can be safely inserted to the database. For example, you can't
save an embedded document directly to the database, you need to convert
it to a hash-ref first.

This method is mostly used internally and you don't have to worry about
collapsing, it's done automatically.

=cut

sub collapse {
	my ($self, $doc) = @_;

	# return the document as is if it doesn't have a _class attribute
	return $doc unless $doc->{_class};

	# remove the schema namespace from the document class (we do not
	# use the full package name internally) and attempt to find that
	# document class. return the document as is if class isn't found
	my $dc_name = $doc->{_class};
	my $ns = $self->namespace;
	$dc_name =~ s/^${ns}:://;

	my $dc = $self->doc_classes->{$dc_name};

	my $new_doc = { _class => $doc->{_class} };

	foreach (keys %$doc) {
		next if $_ eq '_class';

		my $attr = $dc->meta->get_attribute($_);
		if ($attr && $attr->can('does') && $attr->does('Parsed') && $attr->parser) {
			load $attr->parser;
			my $parser = $attr->parser->new;
			if (ref $doc->{$_} eq 'ARRAY') {
				my @arr;
				foreach my $val (@{$doc->{$_}}) {
					push(@arr, $parser->collapse($val));
				}
				$new_doc->{$_} = \@arr;
			} else {
				$new_doc->{$_} = $parser->collapse($doc->{$_});
			}
		
		} elsif ($attr && $attr->can('does') && $attr->does('Transient')) {
			next;
		} else {
			$new_doc->{$_} = $self->_collapse_val($doc->{$_});
		}
	}

	return $new_doc;
}

=head1 INTERNAL METHODS

=head2 _collapse_val( $val )

=cut

sub _collapse_val {
	my ($self, $val) = @_;

	if (blessed $val && $val->isa('MongoDBx::Class::Reference')) {
		return { '$ref' => $val->ref_coll, '$id' => $val->ref_id };
	} elsif (blessed $val && $val->can('does') && $val->does('MongoDBx::Class::Document')) {
		return { '$ref' => $val->_collection->name, '$id' => $val->_id };
	} elsif (blessed $val && $val->can('does') && $val->does('MongoDBx::Class::EmbeddedDocument')) {
		return $val->as_hashref;
	} elsif (ref $val eq 'ARRAY') {
		my @arr;
		foreach (@$val) {
			if (blessed $_ && $_->isa('MongoDBx::Class::Reference')) {
				push(@arr, { '$ref' => $_->ref_coll, '$id' => $_->ref_id });
			} elsif (blessed $_ && $_->can('does') && $_->does('MongoDBx::Class::Document')) {
				push(@arr, { '$ref' => $_->_collection->name, '$id' => $_->_id });
			} elsif (blessed $_ && $_->can('does') && $_->does('MongoDBx::Class::EmbeddedDocument')) {
				push(@arr, $_->as_hashref);
			} else {
				push(@arr, $_);
			}
		}
		return \@arr;
	} elsif (ref $val eq 'HASH') {
		my $h = {};
		foreach (keys %$val) {
			if (blessed $val->{$_} && $val->{$_}->isa('MongoDBx::Class::Reference')) {
				$h->{$_} = { '$ref' => $val->{$_}->ref_coll, '$id' => $val->{$_}->ref_id };
			} elsif (blessed $val->{$_} && $val->{$_}->can('does') && $val->{$_}->does('MongoDBx::Class::Document')) {
				$h->{$_} = { '$ref' => $val->{$_}->_collection->name, '$id' => $val->{$_}->_id };
			} elsif (blessed $val->{$_} && $val->{$_}->can('does') && $val->{$_}->does('MongoDBx::Class::EmbeddedDocument')) {
				$h->{$_} = $val->{$_}->as_hashref;
			} else {
				$h->{$_} = $val->{$_};
			}
		}
		return $h;
	}

	return $val;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::Connection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDBx::Class>, L<MongoDB::Connection>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
