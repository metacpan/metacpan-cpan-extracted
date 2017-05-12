#*********************************************************************
#*** ResourcePool::Resource::Alzabo
#*** Copyright (c) 2004 Texas A&M University, <jsmith@cpan.org>
#*** Based on ResourcePool::Resource::DBI
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: Alzabo.pm,v 1.2 2004/04/15 20:59:43 jgsmith Exp $
#*********************************************************************

package ResourcePool::Resource::Alzabo;

use vars qw($VERSION @ISA);
use strict;
use DBI;
use ResourcePool::Resource::DBI;
use Alzabo::Runtime::Schema;

$VERSION = "1.0100";
push @ISA, "ResourcePool::Resource::DBI";

sub new($$$$$$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
        my $name = shift;
	my $self = $class->SUPER::new(@_);

        return unless $self;

	bless($self, $class);

        my $schema = Alzabo::Runtime::Schema -> load_from_file( name => $name );

        $schema -> driver -> handle($self -> {dbh});
        $schema -> connect;

        $self -> {schema} = $schema;

	return $self;
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{schema};
}

1;
