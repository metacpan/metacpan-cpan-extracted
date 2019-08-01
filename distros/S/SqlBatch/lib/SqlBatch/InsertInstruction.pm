package SqlBatch::InsertInstruction;

# ABSTRACT: Class for an SQL-insert instruction

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use parent 'SqlBatch::InstructionBase';
use Data::Dumper;

sub new {
    my ($class,$config,$content,$sth_placeholder,%args) = @_;

    my $self = SqlBatch::InstructionBase->new($config,$content,%args);

    $self = bless $self, $class;
    $self->{_sth_placeholder} = $sth_placeholder;

    return $self;    
}

sub run {
    my $self = shift;

    my $verbosity    = $self->configuration->verbosity;
    my $field_values = $self->content;
    my @fields       = sort keys %$field_values;
    my $sth_ph       = $self->{_sth_placeholder};
    my $sth          = ${$sth_ph};

    unless (defined $sth) {
	my $table = $self->argument('table');

	my $sql   = sprintf(
	    "insert into %s (%s) values (%s)",
	    $table, 
	    join(",", @fields), 
	    join(",", ("?")x@fields)
	    );

	say "Run insert-sql pattern: ".$sql if $verbosity > 1;

	$sth       = $self->databasehandle->prepare($sql);	    
	${$sth_ph} = $sth;
    }

    my @values = @{$field_values}{@fields};
    eval {
	my $rv = $sth->execute(@values);
	$self->runstate->_returnvalue($rv);
    };
    if ($@) {
	$self->runstate->_error($@);
	self->show_error("Failed running instruction: ".Dumper($self));
	croak($@);
    }
}

1;

__END__

=head1 NAME

SqlBatch::InsertInstrution

=head1 DESCRIPTION

This class executes an insert-instruction within a L<SqlBatch::Plan>

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
