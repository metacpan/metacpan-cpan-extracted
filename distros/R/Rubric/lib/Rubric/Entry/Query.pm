use strict;
use warnings;
package Rubric::Entry::Query;
# ABSTRACT: construct and execute a complex query
$Rubric::Entry::Query::VERSION = '0.156';
#pod =head1 DESCRIPTION
#pod
#pod Rubric::Entry::Query builds a query based on a simple hash of parameters,
#pod performs that query, and returns the rendered report on the results.
#pod
#pod =cut

use Date::Span;
use Digest::MD5 qw(md5_hex);

use Rubric::Config;

#pod =head1 METHODS
#pod
#pod =head2 query(\%arg, \%context)
#pod
#pod This is the only interface to this module.  Given a hashref of named arguments,
#pod it returns the entries that match constraints built from the arguments.  It
#pod generates these constraints with C<get_constraint> and its helpers.  If any
#pod constraint is invalid, an empty set of results is returned.
#pod
#pod The second hashref passed to the method provides context for generating
#pod implicit query parameters; for example, if the querying user is indicated in
#pod the context, private entries for that user will be returned.
#pod
#pod =cut

sub _private_constraint {
	my ($self, $user) = @_;
	my $priv_tag = Rubric::Config->private_tag;
	   $priv_tag = Rubric::Entry->db_Main->quote($priv_tag);

	return "id NOT IN (SELECT entry FROM entrytags WHERE tag=$priv_tag)"
		unless $user;

	$user = Rubric::Entry->db_Main->quote($user);
	return
		"((username = $user) OR " .
		"id NOT IN (SELECT entry FROM entrytags WHERE tag=$priv_tag))";
}

sub _nolist_constraint {
	return q{id NOT IN (SELECT entry FROM entrytags WHERE tag='@nolist')};
}

sub query {
	my ($self, $arg, $context) = @_;
	$context ||= {};

	my @constraints = map { $self->get_constraint($_, $arg->{$_}) } keys %$arg;
	@constraints = ("1 = 0") if grep { not defined } @constraints;

  push @constraints, $self->_nolist_constraint;
	push @constraints, $self->_private_constraint($context->{user})
		if exists $context->{user};

  ## no critic (ConditionalDeclarations)
	my $order_by = "$context->{order_by} DESC"
		if $context->{order_by}||'' =~ /\A(?:created|modified)\Z/;

	$self->get_entries(\@constraints, $order_by);
}

#pod =head2 get_constraint($param => $value)
#pod
#pod Given a name/value pair describing a constraint, this method will attempt to
#pod generate part of an SQL WHERE clause enforcing the constraint.  To do this, it
#pod looks for and calls a method called "constraint_for_NAME" where NAME is the
#pod passed value of C<$param>.  If no clause can be generated, it returns undef.
#pod
#pod =cut

sub get_constraint {
	my ($self, $param, $value) = @_;

  ## no critic (ReturnUndef)
	return undef unless my $code = $self->can("constraint_for_$param");
	$code->($self, $value);
}

#pod =head2 get_entries(\@constraints)
#pod
#pod Given a set of SQL constraints, this method builds the WHERE and ORDER BY
#pod clauses and performs a query with Class::DBI's C<retrieve_from_sql>.
#pod
#pod =cut

sub get_entries {
	my ($self, $constraints, $order_by) = @_;
	$order_by ||= 'created DESC';
	return Rubric::Entry->retrieve_all unless @$constraints;
	Rubric::Entry->retrieve_from_sql(
		join(" AND ", @$constraints)
		. " ORDER BY $order_by"
	);
}

#pod =head2 constraint_for_NAME
#pod
#pod These methods are called to produce SQL for the named parameter, and are passed
#pod a scalar argument.  If the argument is not valid, they return undef, which will
#pod cause C<query> to produce an empty set of records.
#pod
#pod =head3 constraint_for_user($user)
#pod
#pod Given a Rubric::User object, this returns SQL to limit results to entries by
#pod the user.
#pod
#pod =cut

sub constraint_for_user {
	my ($self, $user) = @_;
  ## no critic (ReturnUndef)
	return undef unless $user;
	return "username = " . Rubric::Entry->db_Main->quote($user);
}

#pod =head3 constraint_for_tags($tags)
#pod
#pod =head3 constraint_for_exact_tags($tags)
#pod
#pod Given a set of tags, this returns SQL to limit results to entries marked
#pod with the given tags.
#pod
#pod The C<exact> version of this constraint returns SQL for entries with only the
#pod given tags.
#pod
#pod =cut

sub constraint_for_tags {
	my ($self, $tags) = @_;

  ## no critic (ReturnUndef)
	return undef unless $tags and ref $tags eq 'HASH';
  ## use critic
	return unless %$tags;

  my @snippets;
  while (my ($tag, $tag_value) = each %$tags) {
    my $tn = Rubric::Entry->db_Main->quote($tag);
    my $tv = Rubric::Entry->db_Main->quote($tag_value);
    push @snippets, defined $tag_value
      ? "id IN (SELECT entry FROM entrytags WHERE tag=$tn AND tag_value=$tv)"
      : "id IN (SELECT entry FROM entrytags WHERE tag=$tn)"
  }

	return join ' AND ', @snippets;
}

sub constraint_for_exact_tags {
	my ($self, $tags) = @_;

  ## no critic (ReturnUndef)
	return undef unless $tags and ref $tags eq 'HASH';
  ## use critic

  my $count = keys %$tags;

	# XXX determine which one is faster
	return
		"(SELECT COUNT(tag) FROM entrytags WHERE entry = entries.id) = $count",
#		"id IN (SELECT entry FROM entrytags GROUP BY entry HAVING COUNT(tag) = $count)",
		$self->constraint_for_tags($tags);
}

#pod =head3 constraint_for_desc_like($value)
#pod
#pod =cut

sub constraint_for_desc_like {
	my ($self, $value) = @_;
	my $like = substr Rubric::Entry->db_Main->quote($value), 1, -1;
	"(description LIKE '\%$like\%' OR title LIKE '\%$like\%')"
}

#pod =head3 constraint_for_body_like($value)
#pod
#pod =cut

sub constraint_for_body_like {
	my ($self, $value) = @_;
	my $like = substr Rubric::Entry->db_Main->quote($value), 1, -1;
	"(body LIKE '\%$like\%')"
}

#pod =head3 constraint_for_like($value)
#pod
#pod =cut

sub constraint_for_like {
	my ($self, $value) = @_;
	"("  . $self->constraint_for_desc_like($value) .
	"OR" . $self->constraint_for_body_like($value) . ")"
}

#pod =head3 constraint_for_has_body($bool)
#pod
#pod This returns SQL to limit the results to entries with bodies.
#pod
#pod =cut

sub constraint_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? "body IS NOT NULL" : "body IS NULL";
}

#pod =head3 constraint_for_has_link($bool)
#pod
#pod This returns SQL to limit the results to entries with links.
#pod
#pod =cut

sub constraint_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? "link IS NOT NULL" : "link IS NULL";
}

#pod =head3 constraint_for_first_only($bool)
#pod
#pod This returns SQL to limit the results to the first entry posted for any given
#pod link.
#pod
#pod =cut

sub constraint_for_first_only {
	my ($self, $bool) = @_;
	return $bool
		? "(link is NULL OR id IN (SELECT MIN(id) FROM entries GROUP BY link))"
		: ();
}

#pod =head3 constraint_for_urimd5($md5)
#pod
#pod This returns SQL to limit the results to entries whose link has the given
#pod md5sum.
#pod
#pod =cut

sub constraint_for_urimd5 {
	my ($self, $md5) = @_;
  ## no critic (ReturnUndef)
	return undef unless my ($link) = Rubric::Link->search({ md5 => $md5 });
  ## use critic

	return "link = " . $link->id;
}

#pod =head3 constraint_for_{timefield}_{preposition}($datetime)
#pod
#pod This set of six methods return SQL to limit the results based on its
#pod timestamps.
#pod
#pod The passed value is a complete or partial datetime in the form:
#pod
#pod  YYYY[-MM[-DD[ HH[:MM]]]]  # space may be replaced with 'T'
#pod
#pod The timefield may be "created" or "modified".
#pod
#pod The prepositions are as follows:
#pod
#pod  after  - after the latest part of the given unit of time
#pod  before - before the earliest part of the given unit of time
#pod  on     - after (or at) the earliest part and before (or at) the latest part
#pod
#pod =cut

## here there be small lizards
## date parameter handling below...

sub _unit_from_string {
	my ($datetime) = @_;
	return unless my @unit = $datetime =~
		qr/^(\d{4})(?:-(\d{2})(?:-(\d{2})(?:(?:T|)(\d{2})(?::(\d{2}))?)?)?)?$/o;
	$unit[1]-- if $unit[1];
	return @unit;
}

{
  ## no critic (NoStrict)
	no strict 'refs';
	for my $field (qw(created modified)) {
		for my $prep (qw(after before on)) {
			*{"constraint_for_${field}_${prep}"} = sub {
				my ($self, $datetime) = @_;
        ## no critic (ReturnUndef)
				return undef unless my @time = _unit_from_string($datetime);
        ## use critic

				my ($start,$end) = range_from_unit(@time);
				return
					( $prep eq 'after'  ? "$field > $end"
					: $prep eq 'before' ? "$field < $start"
					:                     "$field >= $start AND $field <= $end")
#					: $prep eq 'on'     ? "$field >= $start AND $field <= $end"
#					: die "illegal preposition in temporal comparison" )
			}
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::Entry::Query - construct and execute a complex query

=head1 VERSION

version 0.156

=head1 DESCRIPTION

Rubric::Entry::Query builds a query based on a simple hash of parameters,
performs that query, and returns the rendered report on the results.

=head1 METHODS

=head2 query(\%arg, \%context)

This is the only interface to this module.  Given a hashref of named arguments,
it returns the entries that match constraints built from the arguments.  It
generates these constraints with C<get_constraint> and its helpers.  If any
constraint is invalid, an empty set of results is returned.

The second hashref passed to the method provides context for generating
implicit query parameters; for example, if the querying user is indicated in
the context, private entries for that user will be returned.

=head2 get_constraint($param => $value)

Given a name/value pair describing a constraint, this method will attempt to
generate part of an SQL WHERE clause enforcing the constraint.  To do this, it
looks for and calls a method called "constraint_for_NAME" where NAME is the
passed value of C<$param>.  If no clause can be generated, it returns undef.

=head2 get_entries(\@constraints)

Given a set of SQL constraints, this method builds the WHERE and ORDER BY
clauses and performs a query with Class::DBI's C<retrieve_from_sql>.

=head2 constraint_for_NAME

These methods are called to produce SQL for the named parameter, and are passed
a scalar argument.  If the argument is not valid, they return undef, which will
cause C<query> to produce an empty set of records.

=head3 constraint_for_user($user)

Given a Rubric::User object, this returns SQL to limit results to entries by
the user.

=head3 constraint_for_tags($tags)

=head3 constraint_for_exact_tags($tags)

Given a set of tags, this returns SQL to limit results to entries marked
with the given tags.

The C<exact> version of this constraint returns SQL for entries with only the
given tags.

=head3 constraint_for_desc_like($value)

=head3 constraint_for_body_like($value)

=head3 constraint_for_like($value)

=head3 constraint_for_has_body($bool)

This returns SQL to limit the results to entries with bodies.

=head3 constraint_for_has_link($bool)

This returns SQL to limit the results to entries with links.

=head3 constraint_for_first_only($bool)

This returns SQL to limit the results to the first entry posted for any given
link.

=head3 constraint_for_urimd5($md5)

This returns SQL to limit the results to entries whose link has the given
md5sum.

=head3 constraint_for_{timefield}_{preposition}($datetime)

This set of six methods return SQL to limit the results based on its
timestamps.

The passed value is a complete or partial datetime in the form:

 YYYY[-MM[-DD[ HH[:MM]]]]  # space may be replaced with 'T'

The timefield may be "created" or "modified".

The prepositions are as follows:

 after  - after the latest part of the given unit of time
 before - before the earliest part of the given unit of time
 on     - after (or at) the earliest part and before (or at) the latest part

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
