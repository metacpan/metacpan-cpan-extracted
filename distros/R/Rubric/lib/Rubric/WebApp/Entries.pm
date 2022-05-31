use strict;
use warnings;
package Rubric::WebApp::Entries 0.157;
# ABSTRACT:  process the /entries run method

#pod =head1 DESCRIPTION
#pod
#pod Rubric::WebApp::Entries implements a URI parser that builds a query based
#pod on a query URI, passes it to Rubric::Entries, and returns the rendered report
#pod on the results.
#pod
#pod =cut

use Date::Span 1.12;
use Digest::MD5 qw(md5_hex);

use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;
use Rubric::WebApp::URI;

#pod =head1 METHODS
#pod
#pod =head2 entries($webapp)
#pod
#pod This method is called by Rubric::WebApp.  It returns the rendered template for
#pod return to the user's browser.
#pod
#pod =cut

sub entries {
	my ($self, $webapp) = @_;
	my %arg;

	while (my $param = $webapp->next_path_part) {
		my $value = $webapp->next_path_part;
		$arg{$param} = $self->get_arg($param, $value);
	}
	if (my $uri = $webapp->query->param('uri')) {
		$arg{urimd5} = md5_hex($uri) unless $arg{urimd5};
	}

	for (qw(like desc_like body_like)) {
		if (my $param = $webapp->query->param($_)) {
			$arg{$_} = $self->get_arg($_, $param);
		}
	}

	unless (%arg) {
		$webapp->param(recent_tags => Rubric::Entry->recent_tags_counted);
		$arg{first_only} = 1 unless %arg;
	}

	my $user     = $webapp->param('current_user');
	my $order_by = $webapp->query->param('order_by');

	my $entries = Rubric::Entry->query(\%arg,
	                                   { user => $user, order_by => $order_by });
	$webapp->param(query_description => $self->describe_query(\%arg));

	$webapp->page_entries($entries)->render_entries(\%arg);
}

#pod =head2 describe_query(\%arg)
#pod
#pod returns a human-readable description of the query described by C<%args>
#pod
#pod =cut

sub describe_query {
	my ($self, $arg) = @_;
	my $desc;
	$desc .= "$arg->{user}'s " if $arg->{user};
	$desc .= "entries";
	for (qw(body link)) {
		if (defined $arg->{"has_$_"}) {
			$desc .= " with" . ($arg->{"has_$_"} ? "" : "out") . " a $_,";
		}
	}
	if ($arg->{exact_tags}) {
    if (%{ $arg->{exact_tags} }) {
      $desc .= " filed under { "
            .  join(', ',
               map { defined $arg->{exact_tags}{$_}
                   ? "$_:$arg->{exact_tags}{$_}"
                   : $_ }
               keys %{$arg->{exact_tags}}) . " } exactly";
    } else {
      $desc .= " without tags"
    }
	} elsif ($arg->{tags} and %{ $arg->{tags} }) {
		$desc .= " filed under { "
          .  join(', ',
             map { defined $arg->{tags}{$_} ?  "$_:$arg->{tags}{$_}" : $_ }
             keys %{$arg->{tags}}) . " }";
	}
	$desc =~ s/,\Z//;
	return $desc;
}

#pod =head2 get_arg($param => $value)
#pod
#pod Given a name/value pair from the path, this method will attempt to
#pod generate part of hash to send to << Rubric::Entry->query >>.  To do this, it
#pod looks for and calls a method called "arg_for_NAME" where NAME is the passed
#pod value of C<$param>.  If no clause can be generated, it returns undef.
#pod
#pod =cut

sub get_arg {
	my ($self, $param, $value) = @_;

	return unless my $code = $self->can("arg_for_$param");
	$code->($self, $value);
}

#pod =head2 arg_for_NAME
#pod
#pod Each of these functions returns the proper value to put in the hash passed to
#pod C<< Rubric::Entries->query >>.  If given an invalid argument, they will return
#pod undef.
#pod
#pod =head3 arg_for_user($username)
#pod
#pod Given a username, this method returns the associated Rubric::User object.
#pod
#pod =cut

sub arg_for_user {
	my ($self, $user) = @_;
	return unless $user;
	return Rubric::User->retrieve($user) || ();
}

#pod =head3 arg_for_tags($tagstring)
#pod
#pod =head3 arg_for_exact_tags($tagstring)
#pod
#pod Given "happy fuzzy bunnies" this returns C< [ qw(happy fuzzy bunnies) ] >
#pod
#pod =cut

sub arg_for_tags {
	my ($self, $tagstring) = @_;

	my $tags;
	eval { $tags = Rubric::Entry->tags_from_string($tagstring) };
	return $tags;
}

sub arg_for_exact_tags { (shift)->arg_for_tags(@_) }

#pod =head3 arg_for_desc_like
#pod
#pod =cut

sub arg_for_desc_like {
	my ($self, $value) = @_;
	return $value;
}

#pod =head3 arg_for_body_like
#pod
#pod =cut

sub arg_for_body_like {
	my ($self, $value) = @_;
	return $value;
}

#pod =head3 arg_for_like
#pod
#pod =cut

sub arg_for_like {
	my ($self, $value) = @_;
	return $value;
}

#pod =head3 arg_for_has_body($bool)
#pod
#pod Returns the given boolean as 0 or 1.
#pod
#pod =cut

sub arg_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

#pod =head3 arg_for_has_link($bool)
#pod
#pod Returns the given boolean as 0 or 1.
#pod
#pod =cut

sub arg_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

#pod =head3 arg_for_first_only($bool)
#pod
#pod Returns the given boolean as 0 or 1.
#pod
#pod =cut

sub arg_for_first_only {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

#pod =head3 arg_for_urimd5($md5sum)
#pod
#pod This method returns the passed value, if that value is a valid 32-character
#pod md5sum.
#pod
#pod =cut

sub arg_for_urimd5 {
	my ($self, $md5) = @_;
	return unless $md5 =~ /\A[a-z0-9]{32}\Z/i;
	return $md5;
}

#pod =head3 arg_for_{timefield}_{preposition}($datetime)
#pod
#pod These methods correspond to those described in L<Rubric::Entry::Query>.
#pod
#pod They return the passed string unchanged.
#pod
#pod =cut

## more date-arg handling code
{
  ## no critic (ProhibitNoStrict)
	no strict 'refs';
	for my $field (qw(created modified)) {
		for my $prep (qw(after before on)) {
			*{"arg_for_${field}_${prep}"} = sub {
				my ($self, $datetime) = @_;
				return $datetime;
			}
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::WebApp::Entries - process the /entries run method

=head1 VERSION

version 0.157

=head1 DESCRIPTION

Rubric::WebApp::Entries implements a URI parser that builds a query based
on a query URI, passes it to Rubric::Entries, and returns the rendered report
on the results.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 METHODS

=head2 entries($webapp)

This method is called by Rubric::WebApp.  It returns the rendered template for
return to the user's browser.

=head2 describe_query(\%arg)

returns a human-readable description of the query described by C<%args>

=head2 get_arg($param => $value)

Given a name/value pair from the path, this method will attempt to
generate part of hash to send to << Rubric::Entry->query >>.  To do this, it
looks for and calls a method called "arg_for_NAME" where NAME is the passed
value of C<$param>.  If no clause can be generated, it returns undef.

=head2 arg_for_NAME

Each of these functions returns the proper value to put in the hash passed to
C<< Rubric::Entries->query >>.  If given an invalid argument, they will return
undef.

=head3 arg_for_user($username)

Given a username, this method returns the associated Rubric::User object.

=head3 arg_for_tags($tagstring)

=head3 arg_for_exact_tags($tagstring)

Given "happy fuzzy bunnies" this returns C< [ qw(happy fuzzy bunnies) ] >

=head3 arg_for_desc_like

=head3 arg_for_body_like

=head3 arg_for_like

=head3 arg_for_has_body($bool)

Returns the given boolean as 0 or 1.

=head3 arg_for_has_link($bool)

Returns the given boolean as 0 or 1.

=head3 arg_for_first_only($bool)

Returns the given boolean as 0 or 1.

=head3 arg_for_urimd5($md5sum)

This method returns the passed value, if that value is a valid 32-character
md5sum.

=head3 arg_for_{timefield}_{preposition}($datetime)

These methods correspond to those described in L<Rubric::Entry::Query>.

They return the passed string unchanged.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
