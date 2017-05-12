package Module::Install::Admin::Credits;

use 5.008;
use base qw(Module::Install::Base);
use strict;

our $AUTHOR_ONLY = 1;
our $AUTHORITY   = 'cpan:TOBYINK';
our $VERSION     = '0.009';

use Module::Install::Contributors 0.001;
use Module::Install::Admin::RDF 0.003;
use RDF::Trine qw( iri literal statement variable );

use RDF::Trine::Namespace qw( RDF RDFS OWL XSD );
my $DBUG = RDF::Trine::Namespace->new('http://ontologi.es/doap-bugs#');
my $DCS  = RDF::Trine::Namespace->new('http://ontologi.es/doap-changeset#');
my $DOAP = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $FOAF = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');

sub write_credits_file
{
	my $self   = shift;
	my @people = $self->_people;
	
	open my $fh, ">:encoding(utf-8)", "CREDITS";
	
	for my $role (qw/ maintainer contributor thanks /)
	{
		my @peeps = grep $_->{role} eq $role, @people;
		next unless @peeps;
		
		printf $fh "%s:\n", ucfirst $role;
		for my $person (@peeps)
		{
			printf $fh "- %s", ($person->{name}//$person->{nick}//$person->{cpanid}//"Anon");
			printf $fh " (cpan:%s)", uc $person->{cpanid} if $person->{cpanid};
			printf $fh " <%s>", $person->{mbox} if $person->{mbox};
			printf $fh "\n";
			
			if ($role eq "contributor")
			{
				my $mbox = $person->{mbox};
				$mbox =~ s/^mailto://i if defined $mbox;
				
				my $contributor = $mbox
					? sprintf("%s <%s>", ($person->{name}//$person->{nick}//$person->{cpanid}//"Anon"), $mbox)
					: sprintf("%s",      ($person->{name}//$person->{nick}//$person->{cpanid}//"Anon"));
				$self->contributors($contributor);
			}
		}
		printf $fh "\n";
	}

	$self->clean_files('CREDITS');
}

my @predicates = (
	$DOAP->maintainer,
	$DOAP->developer,
	$DOAP->documenter,
	$DOAP->translator,
	$DOAP->tester,
	$DOAP->helper,
	$DBUG->reporter,
	$DBUG->assignee,
	$DCS->blame,
	$DCS->thanks,
	$DCS->uri("released-by"),
);

my %roles = (
	$DOAP->maintainer  => "maintainer",
	$DOAP->developer   => "contributor",
	$DOAP->documenter  => "contributor",
	$DOAP->translator  => "contributor",
	$DOAP->tester      => "thanks",
	$DOAP->helper      => "thanks",
	$DBUG->reporter    => "thanks",
	$DBUG->assignee    => "contributor",
	$DCS->blame        => "contributor",
	$DCS->thanks       => "thanks",
	$DCS->uri("released-by") => "maintainer",
);

sub _people
{
	my $self  = shift;
	my $model = Module::Install::Admin::RDF::rdf_metadata($self);
		
	my %people;
	for my $p (@predicates)
	{
		for my $o ($model->objects(undef, $p))
		{
			$people{$o}{node} = $o;
			push @{ $people{$o}{predicates} }, $p;
		}
	}
	
	for my $p (values %people)
	{
		$p->{role} = +{ map { ;$roles{$_} => 1 } @{$p->{predicates}} };
		delete $p->{predicates};
		
		if ($p->{role}{maintainer})
			{ $p->{role} = "maintainer" }
		elsif ($p->{role}{contributor})
			{ $p->{role} = "contributor" }
		elsif ($p->{role}{thanks})
			{ $p->{role} = "thanks" }
		
		if ($p->{node}->is_resource
		and $p->{node}->uri =~ m{^http://purl.org/NET/cpan-uri/person/(\w+)$})
		{
			$p->{cpanid} = uc $1;
		}
		
		($p->{name}) =
			map  $_->literal_value,
			grep $_->is_literal,
			$model->objects_for_predicate_list($p->{node}, $FOAF->name, $RDFS->label);
		
		($p->{mbox}) =
			map  $_->uri,
			grep $_->is_resource,
			$model->objects_for_predicate_list($p->{node}, $FOAF->mbox);
		$p->{mbox} //= sprintf('mailto:%s@cpan.org', lc($p->{cpanid})) if $p->{cpanid};
		
		($p->{nick}) =
			map  $_->literal_value,
			grep $_->is_literal,
			$model->objects_for_predicate_list($p->{node}, $FOAF->nick);
		$p->{nick} //= $p->{cpanid};
	}
	
	return values %people;
}

1;

__END__

=head1 NAME

Module::Install::Admin::Credits - author-side part of Module::Install::Credits

=head1 DESCRIPTION

Not really documented much right now.

=begin private

=item write_credits_file

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Install-Copyright>.

=head1 SEE ALSO

L<Module::Install::Credits>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

