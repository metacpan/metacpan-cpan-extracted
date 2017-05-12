package RDF::TrineX::Parser::RDFa;

use 5.010;
use strict qw(subs vars);

use RDF::Trine;
use RDF::RDFa::Parser;
use Scalar::Util qw(blessed reftype);

use base qw(RDF::Trine::Parser);

our (%file_extensions, %media_types, %parser_names, %format_uris);
our ($AUTHORITY, $VERSION);

%parser_names = (rdfa => __PACKAGE__);

BEGIN
{
	$AUTHORITY = 'cpan:TOBYINK';
	$VERSION   = '1.097';
	
	my @flavours = qw(XHTML HTML32 HTML4 HTML5 XHTML5 Atom DataRSS SVG XML OpenDocument);
	my @versions = qw(1.0 1.1);
	
	foreach my $flavour (@flavours)
	{
		foreach my $version (@versions)
		{
			no strict 'refs';
			no warnings;
			(my $digits = $version) =~ s/\D//g;
			my $class = sprintf 'RDF::TrineX::Parser::%s_RDFa%s', $flavour, $digits;
			$parser_names{ lc sprintf('%srdfa%s', $flavour, $digits) } = $class;
			$parser_names{ lc sprintf('%srdfa', $flavour) } = $class;
			$INC{ sprintf('RDF/TrineX/Parser/%s_RDFa%s', $flavour, $digits) } = $class;
			@{join q(::), $class, q(ISA)}       = __PACKAGE__;
			${join q(::), $class, q(AUTHORITY)} = $AUTHORITY;
			${join q(::), $class, q(VERSION)}   = $VERSION;
			*{join q(::), $class, q(new)} = sub
			{
				my ($klass, %opts) = @_;
				@opts{qw[flavour version]} = map {;lc} ($flavour, $version);
				new($klass, %opts);
			}
		}
	}
	
	%file_extensions = (
		html     => 'RDF::TrineX::Parser::HTML5_RDFa11',
		shtml    => 'RDF::TrineX::Parser::HTML5_RDFa11',
		htm      => 'RDF::TrineX::Parser::HTML5_RDFa11',
		xhtml    => 'RDF::TrineX::Parser::XHTML_RDFa11',
		xhtm     => 'RDF::TrineX::Parser::XHTML_RDFa11',
		svg      => 'RDF::TrineX::Parser::SVG_RDFa11',
		atom     => 'RDF::TrineX::Parser::Atom_RDFa11',
		(map {$_ => 'RDF::TrineX::Parser::OpenDocument_RDFa11';} qw[odt ods odp odg]),
		rdfa     => 'RDF::TrineX::Parser::XML_RDFa11',
	);
	
	%media_types = (
		'text/html'             => 'RDF::TrineX::Parser::HTML5_RDFa11',
		'application/xhtml+xml' => 'RDF::TrineX::Parser::XHTML_RDFa11',
		'image/svg'             => 'RDF::TrineX::Parser::SVG_RDFa11',
		'application/atom+xml'  => 'RDF::TrineX::Parser::Atom_RDFa11',	
		'application/vnd.oasis.opendocument.text'         => 'RDF::TrineX::Parser::OpenDocument_RDFa11',
		'application/vnd.oasis.opendocument.spreadsheet'  => 'RDF::TrineX::Parser::OpenDocument_RDFa11',
		'application/vnd.oasis.opendocument.presentation' => 'RDF::TrineX::Parser::OpenDocument_RDFa11',
		'application/vnd.oasis.opendocument.graphics'     => 'RDF::TrineX::Parser::OpenDocument_RDFa11',
	);
	
	%format_uris = (
		q<http://www.w3.org/ns/formats/RDFa> => 'RDF::TrineX::Parser::XHTML_RDFa10',
	);
	
	sub _merge_hashes
	{
		my ($src, $dest) = (shift, shift);
		$dest->{$_} //= $src->{$_} for keys %$src;
		goto \&_merge_hashes if @_;
	}
	
	_merge_hashes(
		\%parser_names    => \%RDF::Trine::Parser::parser_names,
		\%file_extensions => \%RDF::Trine::Parser::file_extensions,
		\%media_types     => \%RDF::Trine::Parser::media_types,
		\%format_uris     => \%RDF::Trine::Parser::format_uris,
	);
}

sub new
{
	my ($class, %opts) = @_;
	
	my $flavour      = lc(delete($opts{flavour})   // 'xhtml');
	my $version      = lc(delete($opts{version})   // '1.1');
	my $canonicalize = delete($opts{canonicalize}) // '';
	
	$flavour = 'xhtml' if lc($flavour) eq 'xhtml1';
	$flavour = 'opendocument-zip' if lc($flavour) eq 'opendocument';
	
	my $config  = RDF::RDFa::Parser::Config->new($flavour, $version, %opts);
	
	bless +{
		flavour      => $flavour,
		version      => $version,
		config       => $config,
		canonicalize => $canonicalize,
	} => $class;
}

sub rdfa_flavour { shift->{flavour} }
sub rdfa_version { shift->{version} }

sub parse
{
	my ($self, $base, $string, $handler) = @_;
	
	my $parser = RDF::RDFa::Parser->new(
		$string,
		$base,
		$self->{config},
	);
	
	return $self->__parser_handler($parser, $handler);
}

sub parse_url_into_model
{
	my ($proto, $url, $model, %args) = @_;
	
	my $context = delete $args{context};
	my $self    = blessed($proto) ? $proto : $proto->new(%args);
	
	my $parser = RDF::RDFa::Parser->new_from_url(
		$url,
		$self->{config},
	);
	
	my $handler = sub
	{
		my $st = shift;
		$st = RDF::Trine::Statement::Quad->new($st->nodes, $context)
			if $context;
		$model->add_statement($st);
	};
	
	$model->begin_bulk_ops;
	my $r = $self->__parser_handler($parser, $handler);
	$model->end_bulk_ops;
	return $r;
}

sub __parser_handler
{
	my ($self, $parser, $handler) = @_;
	
	$parser->set_callbacks({
		ontriple => sub {
			my ($p, $el, $st) = @_;
			if (reftype($handler) eq 'CODE')
			{
				if ($self->{canonicalize})
				{
					my $o = $st->object;
					if ($o->isa('RDF::Trine::Node::Literal') and $o->has_datatype)
					{
						my $dt    = $o->literal_datatype;
						my $canon = RDF::Trine::Node::Literal
							-> canonicalize_literal_value($o->literal_value, $dt, 1);
						
						$st->object(RDF::Trine::Node::Literal->new($canon, undef, $dt));
					}
				}
				$handler->($st);
			}
			return 1;
		}
	});
	
	$parser->consume;
}

__PACKAGE__
__END__

=head1 NAME

RDF::TrineX::Parser::RDFa - RDF::Trine::Parser-compatible interface for RDF::RDFa::Parser

=head1 DESCRIPTION

While RDF::RDFa::Parser is a good RDFa parser, its interface is a tad...
shall we say... crufty.

RDF::TrineX::Parser::RDFa provides a much nicer interface, and is a
subclass of L<RDF::Trine::Parser>, so you get super-polymorphic benefits.
Yay!

=head2 Class Method

=over

=item C<< parse_url_into_model($url, $model, %args) >>

As per the method of the same name in L<RDF::Trine::Parser>, this retrieves
the URL and parses it into a model.

Unlike L<RDF::Trine::Parser>, this method always assumes you're trying to
parse some variety of RDFa.

=back

=head2 Constructor

=over

=item C<< new(%options) >>

Constructs a new RDF::TrineX::Parser::RDFa parser.

The two important options are flavour (which defaults to 'xhtml') and
version (which defaults to '1.1'). Other options are documented in
L<RDF::RDFa::Parser::Config>.

Let's imagine that you want to parse RDFa 1.1 in HTML5, and you want
to also parse the C<role>, C<longdesc> and C<cite> attibutes (which are
not strictly part of RDFa, but nevertheless often interesting). Then
you'd use:

  my $parser = RDF::TrineX::Parser::RDFa->new(
    flavour        => 'html5',
    version        => '1.1',
    role_attr      => 1,
    longdesc_attr  => 1,
    cite_attr      => 1,
  );

=back

=head2 Object Methods

The following methods are supported, as documented in L<RDF::Trine::Parser>.

=over

=item C<< parse_into_model($base_uri, $data, $model [,context => $context]) >>

=item C<< parse($base_uri, $data, \&handler) >>

=item C<< parse_file_into_model($base_uri, $fh, $model [,context => $context]) >>

=item C<< parse_file($base_uri, $fh, \&handler) >>

=back

The following additional methods are supported:

=over

=item C<< rdfa_flavour >>

Returns the RDFa host language being used.

=item C<< rdfa_version >>

Returns the RDFa version number being used.

=back


=head2 Subclasses

The following subclasses of RDF::TrineX::Parser::RDFa exist:

=over

=item RDF::TrineX::Parser::XHTML_RDFa10

=item RDF::TrineX::Parser::HTML32_RDFa10

=item RDF::TrineX::Parser::HTML4_RDFa10

=item RDF::TrineX::Parser::HTML5_RDFa10

=item RDF::TrineX::Parser::XHTML5_RDFa10

=item RDF::TrineX::Parser::Atom_RDFa10

=item RDF::TrineX::Parser::DataRSS_RDFa10

=item RDF::TrineX::Parser::SVG_RDFa10

=item RDF::TrineX::Parser::XML_RDFa10

=item RDF::TrineX::Parser::OpenDocument_RDFa10

=item RDF::TrineX::Parser::XHTML_RDFa11

=item RDF::TrineX::Parser::HTML32_RDFa11

=item RDF::TrineX::Parser::HTML4_RDFa11

=item RDF::TrineX::Parser::HTML5_RDFa11

=item RDF::TrineX::Parser::XHTML5_RDFa11

=item RDF::TrineX::Parser::Atom_RDFa11

=item RDF::TrineX::Parser::DataRSS_RDFa11

=item RDF::TrineX::Parser::SVG_RDFa11

=item RDF::TrineX::Parser::XML_RDFa11

=item RDF::TrineX::Parser::OpenDocument_RDFa11

=back

By using these classes, you can skip the need to pass the 'flavour' and
'version' options to the constructor. For example:

  my $parser = RDF::TrineX::Parser::HTML5_RDFa11->new(
    role_attr      => 1,
    longdesc_attr  => 1,
    cite_attr      => 1,
  );

Note that these are classes, but they are not modules. You should not
attempt to load them with C<require> or C<use>.

=head1 SEE ALSO

L<RDF::Trine::Parser>,
L<RDF::RDFa::Parser>,
L<RDF::RDFa::Parser::Config>.

L<http://www.perlrdf.org/>, L<http://rdfa.info/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2012 Toby Inkster

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
