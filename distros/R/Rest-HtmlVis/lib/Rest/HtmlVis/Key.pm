package Rest::HtmlVis::Key;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Rest::HtmlVis::Key - Base class for easy-to-use html vis

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

All you have to do is to inherit from Rest::HtmlVis::Key and then implement the callback html.

Example:

    package Rest::HtmlVis::MyGraph;
	use parent qw( Rest::HtmlVis::Key );
	
	use YAML::Syck;

	sub html {
		my ($self) = @_;

		local $Data::Dumper::Indent=1;
		local $Data::Dumper::Quotekeys=0;
		local $Data::Dumper::Terse=1;
		local $Data::Dumper::Sortkeys=1;

		return '<div class="col-lg-12">'.Dump($self->getStruct).'</div>';
	}

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
	my ($class, $baseurl) = @_;
	return bless {baseurl => $baseurl}, $class;
}

=head2 baseurl

=cut

sub baseurl {
	return $_[0]->{baseurl};
}

=head2 setHeader

=cut

sub setHeader{
	my ($self, $header) = @_;
	my %hash = @{$header};
	$self->{header} = \%hash;
}

=head2 getHeader

=cut

sub getHeader {
	my ($self) = @_;
	return $self->{header};
}

=head2 setStruct

=cut

sub setStruct {
	my ($self, $key, $struct, $env) = @_;
	if ($struct && ref $struct eq 'HASH' && exists $struct->{$key}){
		$self->{struct} = $struct->{$key};
		$self->{env} = $env;
		return 1;
	}else{
		$self->{struct} = undef;
	}
	return undef;
}

=head2 getStruct

Return html hash with input structure.

=cut

sub getStruct {
	my ($self) = @_;
	return $self->{struct};
}

=head2 getEnv

Return env variables.

=cut

sub getEnv {
	my ($self) = @_;
	return $self->{env};
}

=head2 getOrder

Return wight on elemnt on html page. Default 1 means in middle;

=cut

sub getOrder {
	return 1;
}

=head2 blocks

Number of blocks in row. Max 12. (ala bootstrap)

Default is 12;

=cut

sub blocks {
	my ($self) = @_;
	return 12;
}

=head2 newRow

Define if element is on new row or is the part of previous row.

Default is 0 - no new row;

=cut

sub newRow {
	my ($self) = @_;
	return 0;
}

=head2 head

Return head of page as HTML string.

Default empty.

=cut

sub head {
	my ($self) = @_;
	return;
}

=head2 head

Return footer of page as HTML string.

Default empty.

=cut

sub footer {
	my ($self) = @_;
	return;
}

=head2 onload

Return onload javascript function of onload attr in body. It must ends with ;

Default empty.

=cut

sub onload {
	my ($self) = @_;
	return;
}

=head2 html

Return body part of HTML.

Default empty.

=cut

sub html {
	my ($self) = @_;
	return;
}

=encoding utf-8

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to github repository.

=head1 ACKNOWLEDGEMENTS

Inspired by L<https://github.com/towhans/hochschober>

=head1 REPOSITORY

L<https://github.com/vasekd/Rest-HtmlVis>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vaclav Dovrtel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Rest::HtmlVis::Key
