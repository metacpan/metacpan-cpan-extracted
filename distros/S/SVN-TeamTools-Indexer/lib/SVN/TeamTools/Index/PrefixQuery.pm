use 5.008_000;
use strict;
use warnings;

package SVN::TeamTools::Index::PrefixQuery;
{
        $SVN::TeamTools::Index::PrefixQuery::VERSION = '0.002';
}
# ABSTRACT: Used to restrict searches based on a base path

use parent 'Lucy::Search::Query';

use Data::Dumper;

use Carp;
use Scalar::Util qw( blessed );

my %prefix;
my %field;

sub new {
	my $class	= shift;
	my %args	= @_;
	my $prefix	= delete $args{prefix};
	my $field	= delete $args{field};

	my $self	= $class->SUPER::new(%args);

	$prefix{$$self}	= $prefix;
	$field{$$self}	= $field;
	return $self;
}
sub get_prefix {
	my $self		= shift;
	return $prefix{$$self};
}

sub get_field {
	my $self		= shift;
	return $field{$$self};
}

sub equals {
	my $self		= shift;
	my $other		= shift;
	return 0 unless blessed($other);
	return 0 unless $other->isa("PrefixQuery");
	return 0 unless $self->get_field() eq $other->get_field();
	return 0 unless $self->get_prefix() eq $self->get_prefix();
	return 1;
}

sub make_compiler {
	my $self	= shift;
	my %args	= @_;
	my $subordinate	= delete $args{subordinate};
	my $compiler	= PrefixCompiler->new( %args, parent => $self );
	$compiler->normalize() unless $subordinate;
	return $compiler;
}
sub DESTROY {
	my $self = shift;
	delete $prefix{$$self};
	delete $field{$$self};
	$self->SUPER::DESTROY;
}
package PrefixCompiler;
use parent 'Lucy::Search::Compiler';

sub make_matcher {
	my $self	= shift;
	my %args	= @_;
	my $seg_reader	= $args{reader};

	my $lex_reader	= $seg_reader->obtain("Lucy::Index::LexiconReader");
	my $pl_reader	= $seg_reader->obtain("Lucy::Index::PostingListReader");

	my $substring	= $self->get_parent()->get_prefix();
#	$substring 	=~ s/\*.\s*$//;
	my $field	= $self->get_parent()->get_field();
	my $lexicon	= $lex_reader->lexicon( field => $field );
	return unless $lexicon;
	$lexicon->seek($substring);

	my @posting_lists;
	while ( defined( my $prefix = $lexicon->get_term() ) ) {
		last unless $prefix =~ m#^$substring#;
		my $posting_list = $pl_reader->posting_list(
			field	=> $field,
			term	=> $prefix,
		);
		if ($posting_list) {
			push (@posting_lists, $posting_list);
		}
		last unless $lexicon->next();
	}
	return unless @posting_lists;
	return PrefixMatcher->new( posting_lists => \@posting_lists );
}

package PrefixMatcher;
use parent 'Lucy::Search::Matcher';
use Data::Dumper;
my %docs;
my %pos;

sub new {
	my $class	= shift;
	my %args	= @_;
	my $posting_lists = delete $args{posting_lists};
	my $self	= $class->SUPER::new(%args);
	my %all_doc_ids;
	for my $posting_list (@$posting_lists) {
		while ( my $doc_id = $posting_list->next() ) {
			$all_doc_ids{$doc_id} = undef;
		}
	}
	my @doc_ids	= sort { $a <=> $b } keys %all_doc_ids;
	$docs{$$self} = \@doc_ids;
	$pos{$$self}	= -1;

	return $self;
}
sub next {
	my $self	= shift;
	my $docs	= $docs{$$self};
	my $pos		= ++$pos{$$self};
	return 0 if ($pos{$$self} >= scalar(@$docs));
	return $docs->[$pos];
}
sub get_doc_id {
	my $self	= shift;
	my $pos		= $pos{$$self};
	my $docs	= $docs{$$self};
	return $pos < scalar (@$docs) ? $docs->[$pos] : 0;
}

sub score { 
	return 1.0;
}
sub DESTROY {
	my $self = shift;
	delete $docs{$$self};
	delete $pos{$$self};
	$self->SUPER::DESTROY;
}
1;

=pod

=head1 NAME

SVN::TeamTools::Index::PrefixQuery

=head1 DESCRIPTION

Used to restrict searches based on a base path. For internal use...

This is an adapted version of the PrefixQuery methodology as described in the Lucy example.

=head1 AUTHOR

Mark Leeuw (markleeuw@gmail.com)

=head1 COPYRIGHT AND LICENSE

This software is copyrighted by Mark Leeuw

This is free software; you can redistribute it and/or modify it under the restrictions of GPL v2

=cut

