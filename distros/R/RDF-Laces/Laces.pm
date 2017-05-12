package RDF::Laces;
use strict;
use URI::Escape ();
use overload
    '/' => \&RDF::Laces::Impl::catdir,
    '.' => \&RDF::Laces::Impl::cat,
    '""' => \&RDF::Laces::Impl::uri,
    '%{}' => \&RDF::Laces::Impl::get,
    '&{}' => \&RDF::Laces::Impl::resource;

our $VERSION = 0.02;

our $rdf = __PACKAGE__->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
our $rdfs = __PACKAGE__->new('http://www.w3.org/2000/01/rdf-schema#');
our $owl = __PACKAGE__->new('http://www.w3.org/2002/07/owl#');
our $dc = __PACKAGE__->new('http://purl.org/dc/elements/1.1/');

sub new {
    my $class = shift;
    unshift @_, "path" if @_ % 2;   # DWIM
    my %opts = (
	path => '',
	prefix => '',
	prefixes => {},
	@_
    );
    my $self = bless \%opts, ref $class || $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $meth = our $AUTOLOAD;
    $meth =~ s/.*:://;
    return if $meth eq 'DESTROY';
    if(@_) {
	# it's a statement!
	printf "<%s> <%s>", $self, $self->{prefix} . $meth;
	my $i = 0;
	for my $obj (@_) {
	    printf "," if $i++;
	    if(ref $obj and $obj->isa(__PACKAGE__)) {
		printf " <%s>", $obj;
	    } else {
		printf ' "%s"', $obj;
	    }
	}
	printf " .\n";
	return $self;   # allow more statements!
    }


    # if in list context, it's a query!

    # if in void context, SET the prefix inplace
    unless(defined wantarray) {
	$self->{prefix} = $self->{prefixes}{$meth} || '';
	return;
    }
    
    unless(wantarray) {
	# scalar context!
	return $self->new(
	    %$self,
	    prefix => $self->{prefixes}{$meth},
	    root => $self->{prefixes}{$meth}
	);
    }

    return;
}

package RDF::Laces::Impl;

sub cat {
    my($self, $path, $reverse) = @_;
    $path = URI::Escape::uri_escape($path);
    return $self->new(
	%$self,
	path => $reverse ? "$path" . "$self" : "$self" . "$path"
    );
}

sub catdir {
    my($self, $path, $reverse) = @_;
    my $newpath = $self->{path};
    # I wanna support reverse?
    $newpath =~ s#/*$#'/' . URI::Escape::uri_escape($path)#e;
    return $self->new(
	%$self,
	path => $newpath
    );
}

sub get {
    my $self = shift;
    my $caller = (caller)[0];
    return $self if $caller->isa(__PACKAGE__) || $caller->isa('RDF::Laces');

    # return a tied hash which does.... things
    my %hash;
    tie %hash, 'RDF::Laces::Tie', $self;
    return \%hash;
}

my $anonidx = 0;
sub resource {
    my $self = shift;
    return sub {
        my $path = shift || ("_:anon" . ++$anonidx);
	return $self->new(%$self, path => $path);
    }
}

sub uri {
    return shift->{path};
}

sub addprefix {
    my($self, $prefix, $uri) = @_;
    $self->{prefixes}{$prefix} = $uri;
}

sub withfragment {
    my $self = shift;
    my $frag = shift;
    my $base = $self->{root} || $self->{path};

    return $self->new(
	%$self,
	root => $base,
	path => $base . $frag
    );
}

package RDF::Laces::Tie;
use base qw(Tie::Hash);

sub TIEHASH {
    my $class = shift;
    my $inst = shift;
    my $self = bless { inst => $inst }, ref $class || $class;
    return $self;
}

sub FETCH {
    my $self = shift;
    my $key = shift;
    RDF::Laces::Impl::withfragment($self->{inst}, $key);
}

sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    RDF::Laces::Impl::addprefix($self->{inst}, $key, $value);
}

=pod
=head1 NAME

RDF::Laces - A module to string together RDF statements from Perl syntax

=head1 SYNOPSIS

  $doc = new RDF::Laces('http://example.com/document/');
  $doc->foo("bar");        # make statement
  $doc->foo($doc->{bar});  # reference nodes within $doc
  $doc->()->foo("bar");    # use blank node in $doc
  $doc->{example} = $doc;  # create prefix
  $doc->example;           # set default prefix

=head1 DESCRIPTION

This module provides a healthy dose of syntactic sugar to the expression
of RDF statements in Perl. Instead of forcing the mechanics of storage
and representation inline with the statements made within a program,
you can use a standard syntax for making RDF statements
in Perl using regular Perl expressions and variables without regard to
the model being used in the background, or the means to output it.

In order to create an RDF model, a series of RDF triples consisting of 
(subject, predicate, object) need to be constructed. The model is based
on making a series of statements about a subject. In Perl, there needs
to be an easy way to assert these statements inline with code.

=head2 Making Statements in Perl

The following examples assume the reader is familiar with the ntriple
representation of RDF as recommended by the W3 Consortium.

In fact, we can demonstrate the examples from the W3's n3 primer.

    # <#pat> <#knows> <#jo> .
    $doc->{pat}->knows($doc->{jo});

This was a simple statement that C<pat> I<C<knows>> C<jo>. The C<knows>
method called on $doc->{pat} acted as the predicate for the statement,
and is assumed to be a URI relative to the current C<$doc> prefix.
More on that below.

It's possible to make further statements about C<pat>.

    $doc->{pat}
        ->knows($doc->{jo})
	->age(24)
    ;

We've now made two statements about C<pat>: C<pat> C<knows> C<jo>, and C<pat> C<age> C<24>. This example shows how statements against the same subject can
be chained into a single Perl expression.

Also, it's possible for a single predicate to have multiple objects.

    $doc->{pat}
	->child($doc->{al}, $doc->{chaz}, $doc->{mo})
	->age(24)
	->eyecolor("blue")
    ;

In this way, it's possible to chain together an entire description of C<pat>
into a single Perl expression.

However, there are times when you want to reference data without an identifier.
These I<blank> RDF nodes are important containers for aggregate data and
are available from the document.

    $doc->{pat}
	->child(
	    $doc->()
		->age(4),
	    $doc->(),
		->age(3))
    ;

In that example, the $doc->() expression was creating I<blank> nodes which
had C<age> statements made with them as the subject. Those nodes were returned
to be listed as a C<child> of C<pat>.

=head2 Using Prefixes

Any document can use resources and attributes defined in another
RDF document. To ease the use of these documents, they are often referenced
using prefixes within the document; by C<xmlns> in XML, and C<@prefix> in n3.

In Perl, these prefixes can be created and used as well.

    $doc->{dc} = 'http://purl.org/dc/elements/1.1/';
    $doc
	->dc
	    ->title("POD - Learning to use RDF::Laces")
    ;

The prefix was created by assigning a URI (or an RDF::Laces object) to
the name of the desired prefix, C<dc>. By assigning to $doc->{dc},
it caused the C<dc> to be interpreted as the name of a prefix that should
be created.

Once a prefix is created, it's possible to use that prefix by calling it
in the method chain without arguments. It's possible to set $doc's
prefix permanently by calling $doc->dc or whatever the prefix's name you want
is. Also, it is possible to use multiple prefixes per statement.

    $doc->()
	->name("jo")
	->rdf
	    ->type($doc->{Person})
	->rdfs
	    ->range($doc->rdfs->{Resource})
	    ->domain($doc->rdfs->{Resource})
    ;

=head1 TODO

Currently, this module only prints out the N3 statements created by a Perl
expression. There will be a back-end interface for plugging in various RDF
modules, such as RDF::Redland and RDF::Core. When it exists, it should be
documented.

Also, this module may be doing stuff which needs to be documented. I dunno.

=head1 SEE ALSO

Check out RDF::Redland. And, of course, visit http://www.w3.org/ for a full
description of RDF, n3, and all the other topics and terms discussed in this
document.

=head1 AUTHOR

Ashley Winters

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ashley Winters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
# vim:set shiftwidth=4 softtabstop=4:
