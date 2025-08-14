# This code is part of Perl distribution OODoc version 3.01.
# The POD got stripped from this file by OODoc version 3.01.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package OODoc::Export;{
our $VERSION = '3.01';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use HTML::Entities qw/encode_entities/;
use POSIX          qw/strftime/;


our %exporters =
  ( json   => 'OODoc::Export::JSON'
  );


sub new(%)
{   my $class = shift;
    $class eq __PACKAGE__
        or return $class->SUPER::new(@_);

    my %args   = @_;
    my $serial = $args{serializer} or panic;

    my $pkg    = $exporters{$serial}
        or error __x"exporter serializer '{name}' is unknown.";

    eval "require $pkg";
    $@ and error __x"exporter {name} has compilation errors: {err}", name => $serial, err => $@;

    $pkg->new(%args);
}

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{OE_serial} = delete $args->{serializer} or panic;
    $self->{OE_markup} = delete $args->{markup}     or panic;

	$self->markupStyle eq 'html'   # avoid producing errors in every method
        or error __x"only HTML markup is currently supported.";

    $self;
}

#------------------

sub serializer()  { $_[0]->{OE_serial} }
sub markupStyle() { $_[0]->{OE_markup} }
sub parser()      { $_[0]->{OE_parser} }
sub format()      { $_[0]->{OE_format} }

#------------------

sub tree($%)
{   my ($self, $doc, %args)   = @_;
	$args{exporter}      = $self;

    my $selected_manuals = $args{manuals};
    my %need_manual      = map +($_ => 1), @{$selected_manuals || []};
    my @podtail_chapters = $self->podChapters($args{podtail});

    my %man;
    foreach my $package (sort $doc->packageNames)
    {
        foreach my $manual ($doc->manualsForPackage($package))
        {   !$selected_manuals || $need_manual{$manual} or next;
            my $man = $manual->publish(\%args) or next;

            push @{$man->{chapters}}, @podtail_chapters;
            $man{$manual->name} = $man->{id};
        }
    }

    my $meta = $args{meta} || {};
    my %meta = map +($_ => $self->markup($meta->{$_}) ), keys %$meta;

     +{
        project        => $self->markup($doc->project),
        distribution   => $doc->distribution,
        version        => $doc->version,
        manuals        => \%man,
        meta           => \%meta,
        distributions  => $args{distributions} || {},
		index          => $self->publicationIndex,

        generated_by   => {
			program         => $0,
			program_version => $main::VERSION // undef,
            oodoc_version   => $OODoc::VERSION // 'devel',
            created         => (strftime "%F %T", localtime),
        },
      };
}

sub publish { panic }


sub _formatterHtml($$)
{	my ($self, $manual, $parser) = @_;

	sub {
		# called with $html, %settings
		$parser->cleanupHtml($manual, @_, create_link => sub {
			# called with ($manual, ...);
			my (undef, $object, $html, $settings) = @_;
			$html //= encode_entities $object->name;
			my $unique = $object->unique;
			qq{<a class="jump" href="$unique">$html</a>};
		});
	};
}

sub _formatterPod($$)
{	my ($self, $manual, $parser) = @_;

	sub {
		# called with $text, %settings
		$parser->cleanupPod($manual, @_, create_link => sub {
			# called with ($manual, ...);
			my (undef, $object, $text, $settings) = @_;
			OODoc::Format::Pod->link($manual, $object, $text, $settings);
		});
	};
}

sub processingManual($)
{	my ($self, $manual) = @_;
	my $parser = $self->{OE_parser} = defined $manual ? $manual->parser : undef;

	if(!defined $manual)
	{	delete $self->{OE_parser};
		$self->{OE_format} = sub { panic };
		return;
	}

	my $style  = $self->markupStyle;
	$self->{OE_format}
	  = $style eq 'html' ? $self->_formatterHtml($manual, $parser)
	  : $style eq 'pod'  ? $self->_formatterPod($manual, $parser)
	  : panic $style;

	$self;
}


sub markup($)
{	my ($self, $string) = @_;
	defined $string && $self->markupStyle eq 'html' ? encode_entities $string : $string;
}


sub boolean($) { !! $_[1] }


sub markupBlock($%)
{	my ($self, $text, %args) = @_;
	$self->format->($text, %args);
}


sub markupString($%)
{	my ($self, $string, %args) = @_;
	my $up = $self->format->($string, %args);
	$self->markupStyle eq 'html' or return $up;

	$up =~ s!</p>\s*<p>!<br>!grs  # keep line-breaks
		=~ s!<p\b.*?>!!gr         # remove paragraphing
		=~ s!\</p\>!!gr;
}


sub podChapters($)
{	my ($self, $pod) = @_;
	defined $pod && length $pod or return ();

    my $parser = OODoc::Parser::Markov->new;  # supports plain POD
    ...
}

1;

__END__
