# $Id: Callback.pm 184 2009-06-11 06:44:27Z rcaputo $

=head1 NAME

POE::Callback - object wrapper for callbacks with lexical closures

=head1 SYNOPSIS

	# TODO - Make this a complete working example.
	my $callback = POE::Callback->new(
		name => "Pkg::sub",
		code => \&coderef,
	);
	$callback->(@arguments);

=head1 DESCRIPTION

POE::Callback wraps coderefs in magic that makes certain lexical
variables persistent between calls.

It's used internally by the classes that comprise POE::Stage.

=cut

package POE::Callback;

use warnings;
use strict;

use PadWalker qw(var_name peek_my peek_sub);
use Scalar::Util qw(blessed reftype weaken);
use Devel::LexAlias qw(lexalias);
use Carp qw(croak);

# Track our wrappers to avoid wrapping them.  Otherwise hilarity may
# ensue.

my %callbacks;
use constant CB_SELF => 0;
use constant CB_NAME => 1;

=head2 new CODEREF

Creates a new callback from a raw CODEREF.  Returns the callback,
which is just the CODEREF blessed into POE::Callback.

=cut

sub new {
	my ($class, $arg) = @_;

	foreach my $required (qw(name code)) {
		croak "POE::Callback requires a '$required'" unless $arg->{$required};
	}

	my $code = $arg->{code};
	my $name = $arg->{name};

	# Don't wrap callbacks.
	return $code if exists $callbacks{$code};

	# Gather the names of persistent variables.
	my $pad = peek_sub($code);
	my @persistent = grep {
		/^\$(self|req|rsp)$/ || /^([\$\@\%])(req|rsp|arg|self)_(\S+)/
	} keys %$pad;

	# No point in the wrapper if there are no persistent variables.

	unless (@persistent) {
		my $self = bless $code, $class;
		return $self->_track($name);
	}

	my $b_self = '';        # build $self
	my $b_rsp = '';         # build $rsp
	my $b_req = '';         # build $req
	my $b_arg = '';         # build $arg
	my $b_req_id = '';      # build $req->get_id()
	my $b_rsp_id = '';      # build $rsp->get_id()

	my $a_self = '';
	my $a_rsp = '';
	my $a_req = '';

	my @vars;

	foreach my $var_name (@persistent) {
		if ($var_name eq '_b_self') {
			$b_self = q{  my $self = POE::Stage::self();};
			next;
		}

		if ($var_name eq '_b_req') {
			push @persistent, '$self' unless $b_self;
			$b_req = q{  my $req = $self->_get_request();};
		}

		if ($var_name eq '_b_rsp') {
			push @persistent, '$self' unless $b_self;
			$b_rsp = q{  my $rsp = $self->_get_response(); };
		}

		if ($var_name eq '$self') {
			push @persistent, '_b_self' unless $b_self;
			$a_self = q{  lexalias($code, '$self', \$self);};
			next;
		}

		if ($var_name eq '_b_rsp_id') {
			push @persistent, '_b_rsp' unless $b_rsp;
			$b_rsp_id = q{  my $rsp_id = $rsp->get_id();};
			next;
		}

		if ($var_name eq '_b_req_id') {
			push @persistent, '_b_req' unless $b_req;
			$b_req_id = q{  my $req_id = $req->get_id();};
			next;
		}

		if ($var_name eq '$req') {
			push @persistent, '_b_req' unless $b_req;
			$a_req = q{  lexalias($code, '$req', \$req);};
			next;
		}

		if ($var_name eq '$rsp') {
			push @persistent, '_b_rsp' unless $b_rsp;
			$a_rsp = q{lexalias($code, '$rsp', \$rsp);};
			next;
		}

		next unless $var_name =~ /^([\$\@\%])(req|rsp|arg|self)_(\S+)/;

		my ($sigil, $prefix, $base_member_name) = ($1, $2, $3);
		my $member_name = $sigil . $base_member_name;

		# Arguments don't need vivification, so they come before @vivify.

		if ($prefix eq 'arg') {
			$b_arg ||= (
				q/  my $arg; { package DB; my @x = caller(0); $arg = $DB::args[1]; }/
			);

			my $def = (
				qq/  \$var_reference = \$pad->{'$var_name'};/
			);

			if ($sigil eq '$') {
				push @vars, (
					$def,
					qq/  \$\$var_reference = \$arg->{'$base_member_name'};/
				);
				next;
			}

			if ($sigil eq '@') {
				push @vars, (
					$def,
					qq/  \@\$var_reference = \@{\$arg->{'$base_member_name'}};/
				);
				next;
			}

			if ($sigil eq '%') {
				push @vars, (
					$def,
					qq/  \%\$var_reference = \%{\$arg->{'$base_member_name'}};/
				);
				next;
			}
		}

		# Common vivification code.

		my @vivify = ( q/  unless( defined $member_ref ) {/ );
		if ($sigil eq '$') {
			push @vivify, q(    my $new_scalar; $member_ref = \$new_scalar;);
		}
		elsif ($sigil eq '@') {
			push @vivify, q(    $member_ref = [];);
		}
		elsif ($sigil eq '%') {
			push @vivify, q(    $member_ref = {};);
		}

		# Determine which object to use based on the prefix.

		my $obj;
		if ($prefix eq 'req') {
			push @persistent, '_b_req_id' unless $b_req;

			# Get the existing member reference.
			push @vars, (
				q{  $member_ref = } .
				q{$self->_request_context_fetch(} .
				qq{\$req_id, '$member_name');}
			);

			# Autovivify if necessary.
			push @vars, (
				@vivify,
				q{    $self->_request_context_store(} .
				qq{\$req_id, '$member_name', \$member_ref);},
				q(  }),
				# Alias the member.
				qq{  lexalias(\$code, '$var_name', \$member_ref);}
			);
			next;
		}

		if ($prefix eq 'rsp') {
			push @persistent, '_b_rsp_id' unless $b_rsp;
			push @persistent, '$self' unless $b_self;

			# Get the existing member reference.
			push @vars, (
				q{  $member_ref = } .
				q{$self->_request_context_fetch(}.
				qq{\$rsp_id, '$member_name');}
			);

			# Autovivify if necessary.
			push @vars, (
				@vivify,
				q{    $self->_request_context_store(} .
				qq{    \$rsp_id, '$member_name', \$member_ref);},
				qq(  \}),
				# Alias the member.
				qq{  lexalias(\$code, '$var_name', \$member_ref);}
			);
			next;
		}

		if ($prefix eq 'self') {
			push @persistent, '$self' unless $b_self;

			# Get the existing member reference.
			push @vars, (
				qq{\$member_ref = \$self->_self_fetch('$member_name');}
			);

			# Autovivify if necessary.
			push @vars, (
				@vivify,
				qq{    \$self->_self_store('$member_name', \$member_ref);},
				qq(  \}),
				# Alias the member.
				qq{  lexalias(\$code, '$var_name', \$member_ref);}
			);

			next;
		}
	}

	unshift @vars, (
		$b_self, $b_arg, $b_req, $b_rsp, $b_req_id, $b_rsp_id,
		$a_self, $a_rsp, $a_req,
	);

	my $sub = join "\n", (
		"sub {",
		"  my \$pad = peek_sub(\$code);",
		"  my (\$member_ref, \$var_reference);",
		@vars,
		"  goto \$code;",
		"};"
	);
	#warn $sub; # for debugging generated code
	my $coderef = eval $sub;
	if( $@ ) {
		while( $@ =~ /line (\d+)/g ) {
			my $line = $1;
			for( ($line-10) .. $line-4 ) {
				warn $_+4, ": $vars[$_]\n";
			}
		}
		die $@;
	}

	my $self = bless $coderef, $class;
	return $self->_track($name);
}

# Track a callback so we don't accidentally wrap it.

sub _track {
	my ($self, $name) = @_;
	$callbacks{$self} = [
		$self,  # CB_SELF
		$name,  # CB_NAME
	];
	weaken($callbacks{$self}[CB_SELF]);
	return $self;
}

# When the callback object is destroyed, it's also removed from the
# tracking hash.

sub DESTROY {
	my $self = shift;
	warn "!!! Destroying untracked callback $self" unless (
		exists $callbacks{$self}
	);
	delete $callbacks{$self};
}

# End-of-run leak checking.

END {
	my @leaks;
	foreach my $callback (sort keys %callbacks) {
		no strict 'refs';
		my $cb_name = $callbacks{$callback}[CB_NAME];
		next if *{$cb_name}{CODE} == $callbacks{$callback}[CB_SELF];
		push @leaks, "!!!   $callback = $cb_name\n";
	}
	if (@leaks) {
		warn "\n!!! callback leak:";
		warn @leaks;
	}
}

1;
