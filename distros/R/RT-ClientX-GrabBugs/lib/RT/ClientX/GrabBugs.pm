use 5.010;
use strict;
use warnings;
use utf8;

package RT::ClientX::GrabBugs;

BEGIN {
	$RT::ClientX::GrabBugs::AUTHORITY = 'cpan:TOBYINK';
	$RT::ClientX::GrabBugs::VERSION   = '0.002';
}

use Moose;
use namespace::autoclean;

use Try::Tiny                qw(try catch finally);
use Types::Standard          qw(-types);
use Getopt::ArgvFile         qw(argvFile);
use Getopt::Long             qw(GetOptionsFromArray);
use RDF::Trine               qw(literal blank iri);
use RT::Client::REST         qw();
use RT::Client::REST::Queue  qw();
use Cwd                      qw(cwd);
use Path::FindDev            qw(find_dev);

use RDF::Trine::Namespace qw/rdf rdfs owl xsd/;
my $dbug   = RDF::Trine::Namespace->new('http://ontologi.es/doap-bugs#');
my $dc     = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $doap   = RDF::Trine::Namespace->new('http://usefulinc.com/ns/doap#');
my $foaf   = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $status = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/rt/status/');
my $prio   = RDF::Trine::Namespace->new('http://purl.org/NET/cpan-uri/rt/priority/');

has [qw/user pass/] => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has server => (
	is       => 'ro',
	isa      => Str,
	default  => 'https://rt.cpan.org',
);

has project_uri => (
	is       => 'ro',
	isa      => Str,
	lazy     => 1,
	builder  => '_build_project_uri',
);

has queue => (
	is       => 'ro',
	isa      => Str,
	lazy     => 1,
	builder  => '_build_queue',
);

has queue_model => (
	is       => 'ro',
	isa      => InstanceOf['RDF::Trine::Model'],
	lazy     => 1,
	builder  => '_build_queue_model',
);

has dest => (
	is       => 'ro',
	isa      => Str | InstanceOf['Path::Tiny'],
	default  => sub { find_dev(cwd)->child('meta/rt-bugs.ttl') },
);

sub main
{
	my ($class, @argv) = @_;
	
	argvFile(
		array           => \@argv,
		startupFilename => '.rt-grabbugs',
		current         => 1,
		home            => 1,
	);
	
	my %opts;
	GetOptionsFromArray(
		\@argv,
		\%opts,
		qw/
			queue=s
			dest=s
			user=s
			pass=s
			server=s
			project_uri=s
		/,
	);
	
	$class->new(%opts)->process;
}

sub _build_queue
{
	my $self = shift;
	my $root = find_dev(cwd);
	
	my $ini = $root->child('dist.ini');
	if ($ini)
	{
		my @ini = grep /^;;/, do { my $fh = $ini->openr; <$fh> };
		chomp @ini;
		my %config = map {
			s/(?:^;;\s*)|(?:\s*$)//g;
			my ($key, $value) = split /\s*=\s*/, $_, 2;
			$key => scalar(eval($value));
		} @ini;
		return $config{name} if $config{name};
	}

	confess "Unable to determine RT queue. Please specify manually.";
}

sub _build_project_uri
{
	my $self  = shift;
	sprintf('http://purl.org/NET/cpan-uri/dist/%s/project', $self->queue);
}

sub _build_queue_model
{
	my $self  = shift;
	my $model = RDF::Trine::Model->new;
	
	warn sprintf "Logging in to %s\n", $self->server;
	
	my $rt;
	try
	{
		$rt = RT::Client::REST->new(
			server   => $self->server,
			timeout  => 60,
		);
		push @{ $rt->_ua->{requests_redirectable} }, 'POST';
		$rt->login(
			username => $self->user,
			password => $self->pass,
		);
	}
	catch
	{
		require Data::Dumper;
		die Data::Dumper::Dumper($_);
	};
	
	warn sprintf "Retrieving queue for %s\n", $self->queue;
	
	my $queue = RT::Client::REST::Queue->new(
		rt       => $rt,
		id       => $self->queue,
	)->retrieve;
	my $tickets = $queue->tickets->get_iterator;
	
	while (my $ticket = $tickets->())
	{
		$self->_process_ticket($model, $queue, $ticket);
	}

	return $model;
}

my %EMAIL;
sub _process_ticket
{
	my $self = shift;
	my ($model, $queue, $ticket) = @_;
	
	warn sprintf("Processing RT#%d\n", $ticket->id);
	
	my $P = iri $self->project_uri;
	my $T = iri sprintf('http://purl.org/NET/cpan-uri/rt/ticket/%d', $ticket->id);
	
	$model->add_statement($_) for (
		RDF::Trine::Statement->new($P, $dbug->issue, $T),
		RDF::Trine::Statement->new($T, $rdf->type, $dbug->Issue),
		RDF::Trine::Statement->new($T, $dbug->id, literal($ticket->id)),
		RDF::Trine::Statement->new($T, $dbug->page, iri sprintf('https://rt.cpan.org/Public/Bug/Display.html?id=%d', $ticket->id)),
		RDF::Trine::Statement->new($T, $dbug->status, $status->${\ $ticket->status }),
		RDF::Trine::Statement->new($T, $dc->created, literal($ticket->created, undef, $xsd->dateTime)),
		RDF::Trine::Statement->new($T, $rdfs->label, literal($ticket->subject)),
	);
	
	for my $email ($ticket->requestors) {
		my $R = ($email =~ /\A(\w+)\@cpan.org\z/i)
			? iri(sprintf 'http://purl.org/NET/cpan-uri/person/%s', $1)
			: ( $EMAIL{$email} ||= blank() );
		$model->add_statement($_) for (
			RDF::Trine::Statement->new($T, $dc->reporter, $R),
			RDF::Trine::Statement->new($R, $rdf->type, $foaf->Agent),
			RDF::Trine::Statement->new($R, $foaf->mbox, iri sprintf('mailto:%s', $email)),
		);
	}
}

sub process
{
	my $self = shift;
	
	my $model = $self->queue_model;
	
	my $ser = eval { require RDF::TrineX::Serializer::MockTurtleSoup }
		? 'RDF::TrineX::Serializer::MockTurtleSoup'
		: 'RDF::Trine::Serializer::Turtle';
	
	warn sprintf("Writing to %s using %s\n", $self->dest, $ser);
	
	open my $fh, '>:encoding(UTF-8)', $self->dest;
	
	$ser->new(namespaces => {
			dbug   => 'http://ontologi.es/doap-bugs#',
			dc     => 'http://purl.org/dc/terms/',
			doap   => 'http://usefulinc.com/ns/doap#',
			foaf   => 'http://xmlns.com/foaf/0.1/',
			rdfs   => 'http://www.w3.org/2000/01/rdf-schema#',
			rt     => 'http://purl.org/NET/cpan-uri/rt/ticket/',
			status => 'http://purl.org/NET/cpan-uri/rt/status/',
			prio   => 'http://purl.org/NET/cpan-uri/rt/priority/',
			xsd    => 'http://www.w3.org/2001/XMLSchema#',
		})->serialize_model_to_file($fh, $model);
	
	$self;
}

__PACKAGE__
__END__

=head1 NAME

RT::ClientX::GrabBugs - download bugs from an RT queue and dump them as RDF

=head1 SYNOPSIS

 RT::ClientX::GrabBugs
   ->new({
     user      => $rt_username,
     pass      => $rt_password,
     queue     => $rt_queue,
     dest      => './output_file.ttl',
     })
   ->process;

=head1 DESCRIPTION

This module downloads bugs from an RT queue and dumps them as RDF.

=head2 Constructor

=over

=item C<< new(%attrs) >>

Fairly standard Moosey C<new> constructor, accepting a hash of named
parameters.

=item C<< main(@argv) >>

Alternative constructor. Processes C<< @argv >> like command-line arguments.
e.g.

 RT::ClientX::GrabBugs->main('--user=foo', '--pass=bar',
                             '--queue=My-Module');

This constructor uses L<Getopt::ArgvFile> to read additional options from
C<< ~/.rt-grabbugs >> and C<< ./.rt-grabbugs >>.

The constructor supports the options "--user", "--pass", "--queue" and
"--dest".

=back

=head2 Attributes

=over

=item * C<server>, C<user>, C<pass>

Details for logging into RT.

=item * C<dest>

The file name where you want to save the data. This defaults to
"./meta/rt-bugs.ttl".

=item * C<queue>

Queue to grab bugs for. Assuming that you're grabbing from rt.cpan.org, this
corresponds to a CPAN distribution (e.g. "RT-ClientX-GrabBugs").

If not provided, this module will try to guess which queue you want. It does
this by looking for a file called "dist.ini" in the project directory. Within
this file, it looks for a line with the following format:

	;; name="Foo-Bar"

This type of line is commonly found in dist.ini files designed for
L<Dist::Inkt>. If you're using L<Dist::Zilla> it should be possible to add
such a line without breaking anything. (Dist::Zilla sees lines beginning with
a semicolon as comments.)

=item * C<project_uri>

URI to use for doap:Project in output.

=item * C<queue_model>

An RDF::Trine::Model generated by calling the C<add_to_model> method on each
bug in the C<queue_table> list. Here you probably want to rely on the default
model that the class builds.

=back

=head2 Methods

=over

=item * C<< process >>

Saves the model from C<queue_model> to the destination C<dest> as Turtle.

Returns C<$self>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RT-ClientX-GrabBugs>.

=head1 SEE ALSO

L<RDF::DOAP>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

