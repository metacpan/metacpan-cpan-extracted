package SqlBatch::SqlInstruction;

# ABSTRACT: Class for an unspecific SQL-instruction

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use parent 'SqlBatch::InstructionBase';
use Data::Dumper;

sub new {
    my ($class,$config,$content,%args) = @_;

    my $self = SqlBatch::InstructionBase->new($config,$content,%args);

    $self = bless $self, $class;
    return $self;    
}

sub run {
    my $self = shift;

    my $verbosity = $self->configuration->verbosity;
    my $sql       = $self->content;
    
    eval {
	chomp $sql;
	say "Run sql: ".$sql if $verbosity > 1;

	my $rv = $self->databasehandle->do($sql);
	$self->runstate->_returnvalue($rv);
    };
    if($@) {
	$self->runstate->_error($@);
	self->show_error("Failed running instruction: ".Dumper($self->state_dump));
	croak($@);
    }
}

1;

__END__

=head1 NAME

SqlBatch::SqlInstrution

=head1 DESCRIPTION

This class executes a sql-instruction within a L<SqlBatch::Plan>

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
