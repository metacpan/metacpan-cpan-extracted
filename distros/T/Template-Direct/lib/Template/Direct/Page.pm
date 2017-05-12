package Template::Direct::Page;

use base Template::Direct::Base;

use strict;
use warnings;

=head1 NAME

Template::Direct::Page - Handle an entire page as an object

=head1 DESCRIPTION

  Provide over all support for a page object

=head1 METHODS

=cut

use Carp;

my $findTag = qr/(?<!\\)\[(\/?)([\w]+)\s*(.*?)(\/?)(?<!\\)\]/;


=head2 I<$class>->new( $template, %p )

  Create a new Page object with specified template content.

=cut
sub new {
	my ($class, $template, %p) = @_;
	my $self = $class->SUPER::new( %p );
	$self->{'content'} = $template;
	return $self;
}

=head2 I<$page>->tagName( )

  Returns 'page'

=cut
sub tagName { 'page' }

=head2 I<$page>->singleTag( )

  Returns true

=cut
sub singleTag { 1 }

=head2 I<$page>->subTags( )

  Returns all expected page tags: [ if, list, page ]

=cut
sub subTags {
	{
		'if'    => 'Template::Direct::Conditional',
		'list'  => 'Template::Direct::List',
		'page'  => 'Template::Direct::SubPage',
		'maths' => 'Template::Direct::Maths',
	}
}

=head2 I<$page>->parent( )

  Page tags have no parent tags, returns undef.

=cut
sub parent { undef }

=head2 I<$page>->depth( )

  Page tags have no tag depth being root, returns 0.

=cut
sub depth { 0 }

=head2 I<$page>->classDepth( )

  Page tags have no class depth being root, returns 0.

=cut
sub classDepth { 0 }

=head2 I<$page>->classParent( )

  Page tags have no class parent tags, returns undef.

=cut
sub classParent { undef }

=head2 $object->compile( )

  Returns the template correctly processed with the data

=cut
sub compile {
	my ($self, $data) = @_;
	if(ref($data) ne 'Template::Direct::Data') {
		$data = Template::Direct::Data->new($data);
		# $data->dataDump();
	}
	# Arrange any pre-compile steps
	if(not $self->isPreCompiled()) {
		$self->markAllTags( \$self->{'content'} );
		#warn "Content found: $self->{'content'}\n";
		$self->{'preCompiled'} = 1;
	}

	# running parents compile rutine will process any structures
	# found by the above pre-compile step.
	my $body = $self->{'content'};
	$self->SUPER::compile( $data, \$body );
	$self->cleanContent( \$body );

	$self->{'body'} = $body;
	return $self->{'body'};
}


=head2 $object->isPreCompiled( )

  Returns 1 if the template has been compiled into
  It's tag marked form, this pairs up with the children
  structure to compile the template with a data set.

=cut
sub isPreCompiled { $_[0]->{'preCompiled'} || 0 }


=head2 $object->markAllTags( \$content )

 Take any kind of structure and mark it out with unique id's, returns a structure of objects
 that relate to the first layer of items.

=cut
sub markAllTags {
	my ($self, $content) = @_;

	my $tagIndex = 0;
	my @stack;
	my %class;
	my $tags = $self->subTags();

	while ( $$content =~ s/$findTag/{{TAG$tagIndex}}/ ) {
		my $endTag = $1 eq '/';
		my $simpleTag = $4 eq '/';
		my $name = $2;
		my $data = $3;

		# Initalise this class parent stack
		$class{$name} = [] if not defined $class{$name};
		my $cstack = $class{$name};

		if(not $endTag) {
			if($tags->{$name}) {
				# Initalise this class parent stack
				$class{$name} = [] if not defined $class{$name};
				my $cstack = $class{$name};

				# Start of a new template tag
				my $object = $tags->{$name}->new( $tagIndex, $data,
					Language  => $self->{'Language'},
					Directory => $self->{'Directory'},
				);

				# Create miriad double links
				$object->setParent( @stack > 0 ? $stack[$#stack] : $self );

				# Create class double links (same set of classes)
				$object->setClassParent( $cstack->[$#{$cstack}] ) if @{$cstack} > 0;

				if($object->singleTag()) {
					# End current tag right now
					if(@stack) {
						$stack[$#stack]->addChild($object);
					} else {
						$self->addChild($object);
					}
				} else {
					# Stack the objects up for depth
					push @stack, $object;
					push @{$cstack}, $object;
				}

			} else {
				my $found = 0;
				for(my $i=0;$i<=$#stack;$i++) {
					if($stack[$#stack-$i]->hasTag( $name )) {
						$stack[$#stack-$i]->addSubTag( $name, $tagIndex, $data );
						$found = 1;
						last;
					}
				}
				if(not $found) {
					die "Unknown tag: '$name' at $tagIndex; stopping\n";
				}
			}
		} else {
			if($stack[$#stack]->tagName() eq $name) {
				# End of current template tag set
				my $cobj = pop @{$cstack};
				my $obj = pop @stack;
				$obj->setEndTag( $tagIndex );
				if(@stack) {
					$stack[$#stack]->addChild($obj);
				} else {
					$self->addChild($obj);
				}
			} elsif($stack[$#stack]->hasTag( $name )) {
				# End of a sub structure tag
				$stack[$#stack]->addEndSubTag( $name, $tagIndex );
			} else {
				die "Unknown or misplaced template tag, $name at $tagIndex; stopping\n";
			}
		}

		$tagIndex++;
	}
	return $self;
}

=head1 AUTHOR

  Martin Owens - Copyright 2007, AGPL

=cut
1;
