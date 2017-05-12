package Template::Plugin::Data::HTMLDumper;

use 5.008003;
use strict;
use warnings;

require Exporter;

use base qw( Template::Plugin );
use Template::Plugin;
require Data::HTMLDumper;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.10';

sub load {
	my $class = shift;
	my $context = shift;
	return $class;
}

sub new {
	my $class   = shift;
	my $context = shift;
	my $self = bless {
			'_CONTEXT' => $context,
			}, $class;
	return $self;
}

sub dump {
	my $self = shift;
	my $content = Data::HTMLDumper::Dumper(@_);
	return $content;
}

1;
__END__
=head1 NAME

Template::Plugin::Data::HTMLDumper - Template Toolkit plugin interface to Data::HTMLDumper.

=head1 SYNOPSIS

  [% USE Data.HTMLDumper %]

  [% Data.HTMLDumper.dump(myvar) %]

=head1 DESCRIPTION

A very simple Template Toolkit Plugin Interface to the Data::HTMLDumper module.  The Data::HTMLDumper module displays output from the Data::Dumper module as HTML tables.

=head1 METHODS

There is one method supported by the Data.HTMLDumper object.

=head2 dump()

Generates nested HTML tables using output from the Data::Dumper module.

=head1 SEE ALSO

l<Template|Template>, L<Data::HTMLDumper|Data::HTMLDumper>, L<Data::Dumper|Data::Dumper>

=head1 AUTHOR

Dennis SutchE<lt>dennis@sutch.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dennis Sutch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
