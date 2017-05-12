package TM::PSI;

=pod

=head1 NAME

TM::PSI - Topic Maps, PSI (published subject identifiers)

=head1 DESCRIPTION

This package provides predefined subjects, all of which will be preloaded in B<every> map which is
instantiated with the L<TM> package hierarchy. When the subjects are defined also their relationship
are kept here (example: I<isa is an instance of an assertion>).

Every such subject is defined by its

=over

=item B<item identifier>

The internal identifier, which does not really mean much.

=item B<subject identifier>

The subject indicator(s), which is ultimately B<the one> which identifies any of the subjects here.

=back

B<NOTE>: For none of the subjects declared here a subject address exists. All concepts are
TM-related concepts.

The subjects are sorted:

=over

=item B<TMRM>-related

These are the minimal subjects which make a map what it is. Examples are C<isa> and
its related role (type) C<class> and C<instance>, and C<is-subclass-of> and its related
roles.

=item B<TMDM>-related (XTM things)

These are the additional concepts which are mandated by TMDM.

=item B<AsTMa>-related

Here are more concepts which are needed by the AsTMa= language(s), such as C<template> or
C<ontology>.

=item B<TMQL>-related

Here are more concepts which are needed by TMQL.

=back

To learn about these predefined concepts, you can do one of the following

   use TM::PSI;
   warn Dumper ($TM::PSI::core, $TM::PSI::topicmaps_inc, $TM::PSI::astma_inc, $TM::PSI::tmql_inc);

=head2 Taxonometry

Two association types are predefined by the standard(s): C<is-subclass-of> and C<isa>.  Together
with these roles are defined C<subclass>, C<superclass> and C<instance>, C<class>, respectively.

The TM::* suite of packages has these not only built in, but also works under the assumption that
these association types and also the roles B<CANNOT> be subclassed themselves. This means that no
map is allowed to use, say, C<is-specialization-of> as a subclass of C<is-subclass-of>.  The costs
of this constraint is quite small compared to the performance benefits.

=cut

our $core = { # this makes the TM::Store work
    mid2iid => {
#            'assertion'      => \ 'http://psi.tm.bond.edu.au/pxtm/1.0/#assertion',
        'assertion-type' => [ 'http://psi.tm.bond.edu.au/pxtm/1.0/#assertion-type' ],
	'is-subclass-of' => [ 'http://psi.topicmaps.org/sam/1.0/#supertype-subtype',
			      'http://www.topicmaps.org/xtm/#psi-superclass-subclass' ],
	'isa'            => [ 'http://psi.topicmaps.org/sam/1.0/#type-instance',
			      'http://www.topicmaps.org/xtm/core.xtm#class-instance' ],
	'class'          => [ 'http://psi.topicmaps.org/sam/1.0/#type',
			      'http://www.topicmaps.org/xtm/core.xtm#class' ],
	'instance'       => [ 'http://psi.topicmaps.org/sam/1.0/#instance',
			      'http://www.topicmaps.org/xtm/core.xtm#instance' ],
	'superclass'     => [ 'http://psi.topicmaps.org/sam/1.0/#supertype',
			      'http://www.topicmaps.org/xtm/#psi-superclass' ],
	'subclass'       => [ 'http://psi.topicmaps.org/sam/1.0/#subtype',
			      'http://www.topicmaps.org/xtm/#psi-subclass' ],
	'scope'          => [ 'http://psi.tm.bond.edu.au/pxtm/1.0/#scope' ],
	'us'             => [ 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-universal-scope' ],

	'topicmap'       => [ 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-topicmap' ],

    },
    assertions => [
		   [ 'isa', [ 'class', 'instance' ], [ 'scope', 'us' ] ],
		   [ 'isa', [ 'class', 'instance' ], [ 'assertion-type', 'isa' ] ],
		   [ 'isa', [ 'class', 'instance' ], [ 'assertion-type', 'is-subclass-of' ] ],
		   [ 'is-subclass-of', [ 'subclass', 'superclass' ], [ 'assertion-type',    'class' ] ],
		   ],
};

our $topicmaps_inc = {
    mid2iid => {
	'xtm-topic'              => [ 'http://www.topicmaps.org/xtm/1.0/#psi-topic' ],
	'association'            => [ 'http://psi.topicmaps.org/sam/1.0/#association',
				      'http://www.topicmaps.org/xtm/1.0/#psi-association' ],
	'sort'                   => [ 'http://psi.topicmaps.org/sam/1.0/#sort',
				      'http://www.topicmaps.org/xtm/#psi-sort' ],
	'display'                => [ 'http://psi.topicmaps.org/sam/1.0/#display',
				      'http://www.topicmaps.org/xtm/#psi-display' ],
	'characteristic'         => [ 'http://psi.tm.bond.edu.au/pxtm/1.0/characteristic'],
	'unique-characteristic'  => [ 'http://psi.topicmaps.org/sam/1.0/#unique-characteristic'],
	'xtm-psi-occurrence'     => [ 'http://www.topicmaps.org/xtm/1.0/#psi-occurrence' ],
	'variant'                => [ 'http://psi.topicmaps.org/sam/1.0/#variant'],
	'occurrence'             => [ 'http://psi.topicmaps.org/sam/1.0/#occurrence',
				      'http://www.topicmaps.org/xtm/1.0/#psi-occurrence' ],
	'association-role'       => [ 'http://psi.topicmaps.org/sam/1.0/#association-role' ],
	
	'name'                   => [ 'http://psi.tm.bond.edu.au/pxtm/1.0/name' ],

    },
    assertions => [
		   [ 'is-subclass-of', [ 'subclass', 'superclass' ], [ 'characteristic',        'association' ] ],
		   [ 'is-subclass-of', [ 'subclass', 'superclass' ], [ 'occurrence',            'characteristic' ] ],
		   [ 'is-subclass-of', [ 'subclass', 'superclass' ], [ 'unique-characteristic', 'characteristic' ] ],
		   [ 'is-subclass-of', [ 'subclass', 'superclass' ], [ 'name',                  'characteristic' ] ],
		   ],
};

our $astma_inc = {
    mid2iid => {
	'thing'          => [ 'http://virtual.cvut.cz/kifb/en/concepts/_entity.html' ],
        'value'          => [ 'http://psi.tm.bond.edu.au/astma/2.0/#value' ],
        'ontology'       => [ 'http://psi.tm.bond.edu.au/astma/2.0/#ontology' ],
        'implementation' => [ 'http://psi.tm.bond.edu.au/astma/2.0/#implementation' ],
        'template'       => [ 'http://psi.tm.bond.edu.au/astma/2.0/#template' ],
        'return'         => [ 'http://psi.tm.bond.edu.au/astma/2.0/#return' ],
        'body'           => [ 'http://psi.tm.bond.edu.au/astma/2.0/#body' ],
    },
    assertions => [
		   ],
};

our $tmql_inc = {
    mid2iid => {
#	'function'       => [ 'http://www.isotopicmaps.org/tmql/#function' ],
    },
    assertions => [
		   ],
};

=pod

=head2 Infrastructure Concepts

To make the whole machinery work, every topic map must contain infrastructure topics such as
C<name>, C<occurrence> etc. They are topics like the topics a user may put into the map. While
this is the right thing to do, in practical situation you often will want to filter out these
I<infrastructure topics>.  You can always get a list of these via


@@@ fix docu @@@@@

    $tm->mids (keys %{$TM::PSI::topicmaps->{mid2iid}});

=cut

use constant {
    TOPICMAP => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-topicmap',
    US => 'us'
};

=pod

=head1 SEE ALSO

L<TM>

=head1 AUTHOR INFORMATION

Copyright 200[1-68], Robert Barta <drrho@cpan.org>, All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION  = '0.18';
our $REVISION = '$Id: PSI.pm,v 1.28 2006/11/29 10:31:15 rho Exp $';

1;

__END__









use constant ONTOLOGY => '
tau-object
bn: Tau Object
sin: http://astma.it.bond.edu.au/ns/tau/1.0/object

tau-map subclasses tau-object
bn: map
sin: http://astma.it.bond.edu.au/ns/tau/1.0/map

tau-ontology subclasses tau-object
bn: ontology
sin: http://astma.it.bond.edu.au/ns/tau/1.0/ontology

tau-query subclasses tau-object
bn: query
sin: http://astma.it.bond.edu.au/ns/tau/1.0/query

tau-collection subclasses tau-object
bn: collection
sin: http://astma.it.bond.edu.au/ns/tau/1.0/collection

';



#	'sum-ergo-sum'                => [ 'http://psi.tm.bond.edu.au/astma/1.0/#psi-sum-ergo-sum'],
#	'regexp'                      => [ 'http://psi.tm.bond.edu.au/astma/1.0/#psi-regexp'],
#	'validates'                   => [ 'http://psi.tm.bond.edu.au/astma/1.0/#psi-validates'],
#	'astma-left'                  => [ 'http://psi.tm.bond.edu.au/astma/1.0/#psi-left'],
#	'astma-right'                 => [ 'http://psi.tm.bond.edu.au/astma/1.0/#psi-right'],



our %PSIs = (
# core
	     'xtm-psi-topic'               => 'http://www.topicmaps.org/xtm/1.0/#psi-topic',
	     'xtm-psi-association'         => 'http://www.topicmaps.org/xtm/1.0/#psi-association',
	     'is-a'                        => 'http://www.topicmaps.org/xtm/core.xtm#class-instance',
	     'class'                       => 'http://www.topicmaps.org/xtm/core.xtm#class',
	     'instance'                    => 'http://www.topicmaps.org/xtm/core.xtm#instance',
	     'is-subclass-of'              => 'http://www.topicmaps.org/xtm/#psi-superclass-subclass',
	     'superclass'                  => 'http://www.topicmaps.org/xtm/#psi-superclass',
	     'subclass'                    => 'http://www.topicmaps.org/xtm/#psi-subclass',
	     'xtm-psi-sort'                => 'http://www.topicmaps.org/xtm/#psi-sort',
	     'xtm-psi-display'             => 'http://www.topicmaps.org/xtm/#psi-display',

# Perl TM extensions
	     'universal-scope'             => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-universal-scope',
	     'basename'                    => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-basename',
	     'name'                        => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-name',
	     'has-indicator'               => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-has-indicator',
	     'subject-indicator'           => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-subject-indicator',
	     'is-reified-by'               => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-is-reified-by',
	     'reified'                     => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-reified',
	     'reifier'                     => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-reifier',
	     'has-data-occurrence'         => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-has-data-occurrence',
	     'has-uri-occurrence'          => 'http://psi.tm.bond.edu.au/pxtm/1.0/#psi-has-uri-occurrence',

# AsTMa extensions
	     'sum-ergo-sum'                => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-sum-ergo-sum',
	     'regexp'                      => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-regexp',
	     'validates'                   => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-validates',
	     'left'                        => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-left',
	     'right'                       => 'http://psi.tm.bond.edu.au/astma/1.0/#psi-right',

);

our @NATURAL_CONSTANTS = qw(
			    thing
			    universal-scope
			    is-a
			    instance
			    class
			    is-subclass-of
			    superclass
			    subclass
			    xtm-psi-association
			    );


